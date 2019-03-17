#!/usr/bin/env python
from os.path import basename
from typing import List
import os
import subprocess as sp
import sys


def has_libstdcxx(start: str):
    dirpath: str
    dirnames: List[str]
    filenames: List[str]
    for dirpath, dirnames, filenames in os.walk(start):
        for fn in filenames:
            fpath = '{}/{}'.format(dirpath, fn)
            if os.stat(fpath).st_mode & 1:
                proc = sp.run(['otool', '-L', fpath],
                              capture_output=True,
                              text=True)
                if 'libstdc++' in proc.stdout:
                    return True
    return False


def main():
    if has_libstdcxx(sys.argv[1]):
        print('libstdc++ detected', file=sys.stderr)
        return 1

    print('''destroot {{
    file copy "${{worksrcpath}}/{}"
        "${{destroot}}${{prefix}}${{applications_dir}}/"
}}'''.format(basename(sys.argv[1].rstrip('/'))))


if __name__ == '__main__':
    sys.exit(main())
