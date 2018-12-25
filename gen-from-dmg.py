#!/usr/bin/env python
from os.path import join as path_join
from typing import List
import argparse
import os
import re
import subprocess as sp
import sys
import tempfile

from dir2xinstall import dir2xinstall


def mount_dmg(mountroot: str, dmg: str):
    sp.check_call([
        'hdiutil', 'attach', '-noverify', '-noautofsck', '-noautoopen',
        '-readonly', '-mount', 'required', '-mountroot', mountroot, '-quiet',
        dmg
    ])


def unmount_dmg(mountpoint: str):
    sp.check_call(['hdiutil', 'detach', '-quiet', mountpoint])


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('dmg', metavar='DMG', nargs=1)
    parser.add_argument('app_name', metavar='APP_NAME', nargs=1)
    args = parser.parse_args()

    dmg: str = args.dmg[0]
    app_name: str = args.app_name[0]
    if not app_name.endswith('.app'):
        app_name += '.app'

    mountroot: str = tempfile.mkdtemp()
    mount_dmg(mountroot, dmg)

    ld: List[str] = os.listdir(mountroot)
    if len(ld) != 1:
        print('Mount root has more than one item?!', file=sys.stderr)
        return 1
    if not len(ld):
        print('Nothing mounted?!', file=sys.stderr)
        return 1
    root_prefix: str = os.listdir(mountroot)[0]
    realroot: str = path_join(mountroot, root_prefix)
    realroot_re: re.Pattern = re.compile(realroot)

    for cmd in dir2xinstall(path_join(realroot, app_name)):
        cmd = re.sub(realroot_re, '', cmd, count=2)
        cmd = re.sub(r'/+', '/', cmd)
        print('    {}'.format(cmd))

    unmount_dmg(realroot)


if __name__ == '__main__':
    sys.exit(main())
