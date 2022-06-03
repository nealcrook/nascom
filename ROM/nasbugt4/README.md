# Sources

The monitor source code:

    NASBUGT4.asm

Has been recreated by disassembly of the binary (see below).  It seems that
early copies of T4 did not come with source code, even though source was
published for earlier (T2) and later (NAS-SYS) monitors. Much of the first
1Kbytes is very similar to T2 and so label names and comments have been pasted
from that code. T4 was the first sight of the R/W/G commands and some label
names and comments for these have been pasted the NAS-SYS1 source.  Some stuff
here still needs tidying up, but this does assemble to produce a match to the
golden binary.

The binary file:

    NASBUGT4.bin_golden

is 2048 bytes in size and converted from the file Nasbugt4.nas on nascomhomepage.com
(converted using nascon).

The documentation:

    NASBUGT4_manual.pdf

came from nascomhomepage.com "NASCOM_T4_MANUAL.pdf" and is a scan of the
original documentation, which is written as a supplement to the T2 document. It
does not include source code.

    NASBUGT4_manual2.pdf

is a scan that I made from an original copy of T4 documentation that was
gifted to me. This is a full manual, including source code.

In an article written by Richard Beal (the author of T4) he explained that T4
was hand-assembled. It was only later that he had a copy of the Zeap
assembler. I concluded that "manual2" was created later in the life of T4 and
replaced the older material.

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

    $ ./build NASBUGT4

creates:

    NASBUGT4.bin
    NASBUGT4.lst

The .bin is 2128 in size because of the way that the assembler handles the workspace
declarations.

Split the workspace off the end:

    $ split -b 2048 NASBUGT4.bin && rm xab && mv xaa NASBUGT4.bin_trim

Now:

    $ diff NASBUGT4.bin_golden NASBUGT4.bin_trim
    (no output => files match)
    $ diff NASBUGT4.bin_golden NASBUGT4.bin
    Binary files NASBUGT4.bin_golden and NASBUGT4.bin differ

This shows that the original binary can be faithfully reproduced.

You can use nascon (https://github.com/nealcrook/nascom/blob/master/converters/nascon)
to convert to .NAS format

    $ ../../converters/nascon NASBUGT4.bin_golden NASBUGT4.NAS_golden       -in bin -out nas -org 0 -csum
    $ ../../converters/nascon NASBUGT4.bin_trim   NASBUGT4.NAS_trim_rebuilt -in bin -out nas -org 0 -csum
    $ ../../converters/nascon NASBUGT4.bin        NASBUGT4.NAS_rebuilt              -out nas -org 0 -csum
    $ diff NASBUGT4.NAS_golden NASBUGT4.NAS_trim_rebuilt
    (no output => files match)
    $ diff NASBUGT4.NAS_golden NASBUGT4.NAS_rebuilt
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
