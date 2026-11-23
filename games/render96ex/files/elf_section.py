"""Write the contents of one section of a little-endian ELF64 object to a file.

usage: elf_section.py SECTION INPUT.o OUTPUT
"""
import struct
import sys

section, src, dst = sys.argv[1:4]
with open(src, 'rb') as f:
    data = f.read()
if data[:4] != b'\x7fELF' or data[4] != 2 or data[5] != 1:
    sys.exit(f'{src}: not a little-endian ELF64 object')
shoff, = struct.unpack_from('<Q', data, 0x28)
shentsize, shnum, shstrndx = struct.unpack_from('<HHH', data, 0x3A)
headers = [struct.unpack_from('<IIQQQQ', data, shoff + i * shentsize) for i in range(shnum)]
strtab = headers[shstrndx]
for name, _type, _flags, _addr, offset, size in headers:
    start = strtab[4] + name
    if data[start:data.index(b'\0', start)].decode() == section:
        with open(dst, 'wb') as f:
            f.write(data[offset:offset + size])
        break
else:
    sys.exit(f'{src}: no {section} section')
