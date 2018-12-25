#!/usr/bin/env python
from os.path import dirname
from typing import List
import os
import re
import sys


def dir2xinstall(start: str):
    dirpath: str
    dirnames: List[str]
    filenames: List[str]
    for dirpath, dirnames, filenames in os.walk(start):
        yield 'xinstall -d "${{destroot}}/${{applications_dir}}/{}"'.format(
            dirpath)
        for dirname_arg in dirnames:
            yield ('xinstall -d '
                   '"${{destroot}}/${{applications_dir}}/{}/{}"').format(
                       dirpath, dirname_arg)
        for fn in filenames:
            fpath = '{}/{}'.format(dirpath, fn)
            mode = '0755' if os.stat(fpath).st_mode & 1 else '0644'
            yield (
                'xinstall -m {mode} "${{worksrcpath}}/{dirpath_arg}/{fn_arg}" '
                '"${{destroot}}${{applications_dir}}{dirpath_arg}/{fn_arg}"'
            ).format(
                mode=mode, dirpath_arg=dirpath, fn_arg=fn)


def main():
    prefix_re: re.Pattern = re.compile('{}'.format(dirname(sys.argv[1])))
    for cmd in dir2xinstall(sys.argv[1]):
        cmd = re.sub(prefix_re, '', cmd, count=2)
        cmd = re.sub(r'/+', '/', cmd)
        print('    {}'.format(cmd))


if __name__ == '__main__':
    sys.exit(main())
