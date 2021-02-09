# Sources

The monitor source code:

    BBUG.asm

was recreated by disassembly of the binary (see below). BBUG was a 2Kbyte
monitor in which the first 1Kbyte was a patched near-copy of NASBUG T2.  This
source code has been re-created by disassembling a BBUG ROM dump, making the
labels/comments in the first 1Kbyte match NASBUG T2 (and highlighting the parts
that are changed) then using the source listing in the BBUG documentation to get
label names and comments for the remaining code.

The binary file:

    BBUG.bin_golden

is 2048 bytes in size. The starting point for this was the file BBUG.NAS on
nascomhomepage.com This file is in "dump" format with a checksum byte per line,
and nascon reports multiple checksum errors:

    $ ./../converters/nascon BBUG.NAS bbug.bin
    ERROR bad checksum at line 5 -- calculated 0xDC but read 0xBB
    ERROR bad checksum at line 18 -- calculated 0x83 but read 0x6E
    ERROR bad checksum at line 23 -- calculated 0x2 but read 0xFA
    ERROR bad checksum at line 34 -- calculated 0x10 but read 0x30
    ERROR bad checksum at line 70 -- calculated 0x8F but read 0x7A
    ERROR bad checksum at line 72 -- calculated 0xF4 but read 0xC
    ERROR bad checksum at line 88 -- calculated 0xA9 but read 0x21
    ERROR bad checksum at line 89 -- calculated 0x56 but read 0x9E
    ERROR bad checksum at line 97 -- calculated 0x57 but read 0x2C
    ERROR bad checksum at line 98 -- calculated 0x1 but read 0x38
    ERROR bad checksum at line 99 -- calculated 0x60 but read 0x73
    ERROR bad checksum at line 100 -- calculated 0x4B but read 0xDD
    ERROR bad checksum at line 101 -- calculated 0xE2 but read 0x1
    ERROR bad checksum at line 104 -- calculated 0x5D but read 0x78
    ERROR bad checksum at line 107 -- calculated 0x7A but read 0x6E
    ERROR bad checksum at line 108 -- calculated 0x81 but read 0x7C
    ERROR bad checksum at line 128 -- calculated 0x69 but read 0x7D

The errors were inspected; in all cases the problem seemed to be with the
checksum byte itself; the code seems to match the listing. Here is a diff
of the original against a version with repaired checksums:

    $ diff BBUG.NAS BBUG_fixcsum.NAS
    5c5
    < 0020 E3 2B E3 C3 05 03 00 00 BB
    ---
    > 0020 E3 2B E3 C3 05 03 00 00 DC
    18c18
    < 0088 F1 B7 C3 8A 04 00 CD 35 6E
    ---
    > 0088 F1 B7 C3 8A 04 00 CD 35 83
    23c23
    < 00B0 D6 3A 09 0C E6 10 B0 87 FA
    ---
    > 00B0 D6 3A 09 0C E6 10 B0 87 02
    34c34
    < 0108 20 A9 8A A1 99 0D 2C 41 30
    ---
    > 0108 20 A9 8A A1 99 0D 2C 41 10
    70c70
    < 0228 00 18 D4 F5 81 4F F1 C3 7A
    ---
    > 0228 00 18 D4 F5 81 4F F1 C3 8F
    72c72
    < 0238 2B 02 00 00 3E 20 18 17 0C
    ---
    > 0238 2B 02 00 00 3E 20 18 17 F4
    88,89c88,89
    < 02B8 63 03 7E B7 CA 60 07 23 21
    < 02C0 B9 28 04 23 23 18 F3 5E 9E
    ---
    > 02B8 63 03 7E B7 CA 60 07 23 A9
    > 02C0 B9 28 04 23 23 18 F3 5E 56
    97,101c97,101
    < 0300 32 1A 0C 18 D0 F5 E5 3A 2C
    < 0308 00 0C D3 00 3A 1A 0C B7 38
    < 0310 28 13 2A 15 0C 7E 32 17 73
    < 0318 0C 36 E7 AF 32 1A 0C 00 DD
    < 0320 00 E1 F1 ED 45 D5 C5 21 01
    ---
    > 0300 32 1A 0C 18 D0 F5 E5 3A 57
    > 0308 00 0C D3 00 3A 1A 0C B7 01
    > 0310 28 13 2A 15 0C 7E 32 17 60
    > 0318 0C 36 E7 AF 32 1A 0C 00 4B
    > 0320 00 E1 F1 ED 45 D5 C5 21 E2
    104c104
    < 0338 56 23 00 ED 53 3B 0C 22 78
    ---
    > 0338 56 23 00 ED 53 3B 0C 22 5D
    107,108c107,108
    < 0350 02 CD 3C 02 10 F1 C3 56 6E
    < 0358 07 2A 15 0C 3A 17 0C 77 7C
    ---
    > 0350 02 CD 3C 02 10 F1 C3 56 7A
    > 0358 07 2A 15 0C 3A 17 0C 77 81
    128c128
    < 03F8 10 0C ED B0 C9 00 76 76 7D
    ---
    > 03F8 10 0C ED B0 C9 00 76 76 69


The repaired .NAS file was converted to binary using nascon.

The documentation:

    BBUG_manual.pdf

came from nascomhomepage "B-BUG Nascom 1 monitor" (bbug.zip) and is a scan of the
original documentation, including a somewhat crude source code listing with notes.

# Disassembly

(This is just to explain how I did it; there is no need to repeat this step)

This was done iteratively as a 2-stage process. The first stage is to use the
PERL script "dis_bbug" which uses the a disassembler module and uses the
BBUG.bin_golden file to generate BBUG_dis.txt (a straight disassembly
considering everything as code) and BBUG_dis.asm (a disassembly guided by
definitions in dis_bbug. By running dis_bbug, inspecting BBUG_dis.asm file,
adding more definitions to dis_debug and running again, the source file can
be made more and more complete.

Eventually, you hit the law of diminishing returns: the source isn't perfect but
controlling it from the disassembler control script becomes more trouble than
simply editing the source directly. This is the start of the second stage. Copy
BBUG_dis.asm and run the second script "check_rebuild". This does an assembly of
the source and compares the binary against the BBUG.bin_golden. Since the
process is near-instantaneous, it's easy to make tidy-up edits and continually
check that the integrity of the source code has not been compromised.


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

    $ ./build BBUG

creates:

    BBUG.bin
    BBUG.lst

The .bin is 2128 in size because of the way that the assembler handles the workspace
declarations.

Split the workspace off the end:

    $ split -b 2048 BBUG.bin && rm xab && mv xaa BBUG.bin_trim

Now:

    $ diff BBUG.bin_golden BBUG.bin_trim
    (no output => files match)
    $ diff BBUG.bin_golden BBUG.bin
    Binary files BBUG.bin_golden and BBUG.bin differ

This shows that the original binary can be faithfully reproduced.

You can use nascon (https://github.com/nealcrook/nascom/blob/master/converters/nascon)
to convert to .NAS format

    $ ../../converters/nascon BBUG.bin_golden BBUG.NAS_golden       -in bin -out nas -org 0 -csum
    $ ../../converters/nascon BBUG.bin_trim   BBUG.NAS_trim_rebuilt -in bin -out nas -org 0 -csum
    $ ../../converters/nascon BBUG.bin        BBUG.NAS_rebuilt              -out nas -org 0 -csum
    $ diff BBUG.NAS_golden BBUG.NAS_trim_rebuilt
    (no output => files match)
    $ diff BBUG.NAS_golden BBUG.NAS_rebuilt
    256a257,266
    > 0800 00 00 00 00 00 00 00 00 08
    > 0808 00 00 00 00 00 00 00 00 10
    > 0810 00 00 00 00 00 00 00 00 18
    > 0818 00 00 00 00 00 00 00 00 20
    > 0820 00 00 00 00 00 00 00 00 28
    > 0828 00 00 00 00 00 00 00 00 30
    > 0830 00 00 00 00 00 00 00 00 38
    > 0838 00 00 00 00 00 00 00 00 40
    > 0840 00 00 00 00 00 00 00 00 48
    > 0848 00 00 00 00 00 00 00 00 50

# Futures

Annotate comments from hand-written source code in the manual. Currently, the
comments are restricted to stuff patched in from t2 source code.
