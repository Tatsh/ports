#!/usr/bin/env python
from os.path import join as path_join
import argparse
import os
import re
import subprocess as sp
import sys
import tempfile


def mount_dmg(mountroot, dmg):
    sp.check_call([
        'hdiutil', 'attach', '-noverify', '-noautofsck', '-noautoopen',
        '-readonly', '-mount', 'required', '-mountroot', mountroot, '-quiet',
        dmg
    ])


def unmount_dmg(mountpoint):
    sp.check_call(['hdiutil', 'detach', '-quiet', mountpoint])


def dir2xinstall(start, strip):
    for dirpath, dirnames, filenames in os.walk(start):
        dirpath_arg = strip(dirpath)
        yield 'xinstall -d "${{destroot}}${{applications_dir}}{}"'.format(
            dirpath_arg)
        for dirname in dirnames:
            dirname_arg = strip(dirname)
            yield ('xinstall -d '
                   '"${{destroot}}${{applications_dir}}{}/{}"').format(
                       dirpath_arg, dirname_arg)
        for fn in filenames:
            fpath = '{}/{}'.format(dirpath, fn)
            mode = '0755' if os.stat(fpath).st_mode & 1 else '0644'
            yield (
                'xinstall -m {mode} "${{worksrcpath}}{dirpath_arg}/{fn_arg}" '
                '"${{destroot}}${{applications_dir}}{dirpath_arg}/{fn_arg}"'
            ).format(
                mode=mode, dirpath_arg=dirpath_arg, fn_arg=fn)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('dmg', metavar='DMG', nargs=1)
    parser.add_argument('app_name', metavar='APP_NAME', nargs=1)
    args = parser.parse_args()

    dmg = args.dmg[0]
    app_name = args.app_name[0]
    if not app_name.endswith('.app'):
        app_name += '.app'

    mountroot = tempfile.mkdtemp()
    mount_dmg(mountroot, dmg)

    ld = os.listdir(mountroot)
    if len(ld) != 1:
        print('Mount root has more than one item?!', file=sys.stderr)
        return 1
    if not len(ld):
        print('Nothing mounted?!', file=sys.stderr)
        return 1
    root_prefix = os.listdir(mountroot)[0]
    realroot = path_join(mountroot, root_prefix)
    realroot_re = re.compile('^{}'.format(realroot))

    for cmd in dir2xinstall(
            path_join(realroot, app_name),
            lambda x: re.sub(realroot_re, '', x)):
        print('    {}'.format(cmd))

    unmount_dmg(realroot)


if __name__ == '__main__':
    sys.exit(main())
