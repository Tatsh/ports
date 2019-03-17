#!/usr/bin/env python
from os.path import join as path_join, realpath
from typing import List
import argparse
import os
import plistlib
import re
import subprocess as sp
import sys
import tempfile

from dir2xinstall import has_libstdcxx

def hdiutil_info():
    return plistlib.loads(sp.check_output(['hdiutil', 'info', '-plist']))


def mount_dmg(mountroot: str, dmg: str):
    sp.check_call([
        'hdiutil', 'attach', '-noverify', '-noautofsck', '-noautoopen',
        '-private', '-nobrowse', '-readonly', '-mount', 'required',
        '-mountroot', mountroot, '-quiet', dmg
    ])


def unmount_dmg(mountpoint: str):
    sp.check_call(['hdiutil', 'detach', '-quiet', mountpoint])


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('dmg', metavar='DMG', nargs=1)
    parser.add_argument('app_name', metavar='APP_NAME', nargs=1)
    args = parser.parse_args()

    dmg: str = realpath(args.dmg[0])
    app_name: str = args.app_name[0]
    if not app_name.endswith('.app'):
        app_name += '.app'

    for x in hdiutil_info()['images']:
        p = realpath(x['image-path'])
        if p != dmg:
            continue
        for s in x['system-entities']:
            try:
                unmount_dmg(s['mount-point'])
            except (KeyError, sp.CalledProcessError):
                pass

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
    start: str = path_join(realroot, app_name)

    if has_libstdcxx(start):
        print('libstdc++ detected', file=sys.stderr)
        unmount_dmg(realroot)
        return 1

    print('''destroot {{
    file copy "${{worksrcpath}}/{}"
        "${{destroot}}${{prefix}}${{applications_dir}}/"
}}'''.format(app_name))

    unmount_dmg(realroot)


if __name__ == '__main__':
    sys.exit(main())
