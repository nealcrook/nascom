Sources
=======

The monitor source code:

NASBUGT2.asm

came from thenascomhomepage but has been fixed up to match the assembler
syntax and to move the workspace declaration to the end of the file.

The binary file:

NASBUGT2.bin_golden

is 1024 bytes in size and converted from the file Nasbugt2.nas on thenascomhomepage
(converted using nascon).

The documentation:

NASBUGT2_manual.pdf

came from thenascomhomepage "Nascom 1 Nasbug manual.pdf" and is a scan of the
"NASCOM Microcomputer NASCOM 1 Software Notes" document, which includes documentation
on NASBUGT2 (including a source listing) and other programming notes. Casual inspection
of the source listing shows that the NASBUGT2.asm contains the same content and comments
as this listing (but I have not checked it in detail).

Rebuild From Source
===================

To assemble it, I use the GNU Z80 assembler (which is somewhat crude, but effective)
invoked using this script, named "build":


#!/bin/sh
#
# $1 is the program base-name
#
# expect to find z80asm (from https://www.nongnu.org/z80asm/index.html) on $PATH
z80asm ${1}.asm -l${1}.lst -o${1}.bin


so:

$ ./build NASBUGT2

creates:

NASBUGT2.bin
NASBUGT2.lst

The .bin is 1104 in size because of the way that the assembler handles the workspace
declarations.

Split the workspace off the end:

$ split -b 1024 NASBUGT2.bin && rm xab && mv xaa NASBUGT2.bin_trim

Now:

$ diff NASBUGT2.bin_golden NASBUGT2.bin_trim
(no output => files match)
$ diff NASBUGT2.bin_golden NASBUGT2.bin
Binary files NASBUGT2.bin_golden and NASBUGT2.bin differ

This shows that the original binary can be faithfully reproduced.

You can use nascon (https://github.com/nealcrook/nascom/blob/master/converters/nascon)
to convert to .NAS format

$ ../../converters/nascon NASBUGT2.bin_golden NASBUGT2.NAS_golden       -in bin -out nas -org 0 -csum
$ ../../converters/nascon NASBUGT2.bin_trim   NASBUGT2.NAS_trim_rebuilt -in bin -out nas -org 0 -csum
$ ../../converters/nascon NASBUGT2.bin        NASBUGT2.NAS_rebuilt              -out nas -org 0 -csum
$ diff NASBUGT2.NAS_golden NASBUGT2.NAS_trim_rebuilt
(no output => files match)
$ diff NASBUGT2.NAS_golden NASBUGT2.NAS_rebuilt
128a129,138
> 0400 00 00 00 00 00 00 00 00 04
> 0408 00 00 00 00 00 00 00 00 0C
> 0410 00 00 00 00 00 00 00 00 14
> 0418 00 00 00 00 00 00 00 00 1C
> 0420 00 00 00 00 00 00 00 00 24
> 0428 00 00 00 00 00 00 00 00 2C
> 0430 00 00 00 00 00 00 00 00 34
> 0438 00 00 00 00 00 00 00 00 3C
> 0440 00 00 00 00 00 00 00 00 44
> 0448 00 00 00 00 00 00 00 00 4C
