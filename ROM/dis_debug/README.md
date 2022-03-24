# Introduction

NAS-DIS (also known as revas) and NAS-DEBUG were two separate developments, but
(often/always?) sold together. My copy came on tape with a relocatable loader
and with separate printed manuals: "NAS-DIS disassembler for NASCOM
microcomputers" with a yellow cover and "NAS-DEBUG Dynamic Debugger a monitor
extension package for NAS-SYS".

Each manual contains an assembly listing of its code.

The code could be executed from RAM or could be programmed into EPROM. The usual
place in the memory map was to put them in a 4Kbyte slot starting at 0C000H --
NAS-DEBUG occupies locations 0C000H-0C3FFH and NAS-DIS occupies locations
0C400H-0CFFFH.

# Versions

My NAS-DEBUG manual is marked "Produced and distributed by: GEMINI COMPUTERS
Ltd. Copyright (c) 1981 CCsoft (Southfields)". Inside, and on the code listing,
The manual is marked "V3.1" but the code listing within it is marked "NAS-DEBUG
V3.2 22nd Feb 1981 (C) CCSOFT (Southfields) 1981 Written by Mick Scutt".

My NAS-DIS manual has the same style of cover but no markings or version
numbers. The code listing inside is marked "REVAS subroutine Version N1.1
08-03-80" and "Written by David Parkinson (C) Copyright David Parkinson".


# Sources

The golden executable:

    dis_debug.NAS_golden

came from Odebdis.nas from nascomhomepage.com; includes line checksums which were all intact/correct.

The source code:

    dis_debug.asm

Has been recreated by disassembly of the binary (see below). Since the original
source code was published in the manuals, the original label names have been
used. Restoring the original formatting and comments is a work-in-progress. The
source code does assemble to produce a match to the golden binary.

The binary file:

    dis_debug.bin_golden

is 4096 bytes in size and converted from Odebdis.bas using [nascon](../../converters/nascon)

The documentation:

    TBD

came from nascomhomepage.com "NASCOM_T4_MANUAL.pdf" and is a scan of the original
documentation, which is written as a supplement to the T2 document. Unlike the other
monitors, no source code seems to have been published for this code.

# Disassembly

The disassembly was produced using the script dis_dis_debug.


# Rebuild From Source

To assemble it, I use the GNU Z80 assembler (which is somewhat crude, but effective)
invoked using this script, named "build":


    #!/bin/sh
    #
    # $1 is the program base-name
    #
    # expect to find z80asm (from https://www.nongnu.org/z80asm/index.html) on $PATH
    z80asm ${1}.asm -l${1}.lst -o${1}.bin


so:

    $ ./build dis_debug

creates:

    dis_debug.bin
    dis_debug.lst

The .bin is 4096 bytes in size. You can diff it against the golden binary, but then any changes are difficult to see. It's easier to convert it to .NAS format and compare it to the golden .NAS file.

Executing the script:

    $ ./check_rebuild

Runs the assembler, converts the result to .NAS and diff's against the golden
.NAS file. When run successfully, it produces no output.

# TODO

* recover my version from tape and preserve the loader/locator
* add documentation/manuals
* annotate comments to the source code
* ..and in the process, verify that my manual match the golden code
* There seems to have been just 1 version if NAS-DIS but more than one version of NAS-DEBUG
