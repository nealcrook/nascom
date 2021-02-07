# Sources

The monitor source code:

    NASBUGT4.asm

DOES NOT YET EXIST

The binary file:

    NASBUGT4.bin_golden

is 2048 bytes in size and converted from the file Nasbugt4.nas on nascomhomepage.com
(converted using nascon).

The documentation:

    NASBUGT4_manual.pdf

came from nascomhomepage.com "NASCOM_T4_MANUAL.pdf" and is a scan of the original
documentation, which is written as a supplement to the T2 document. Unlike the other
monitors, no source code seems to have been published for this code.

# Rebuild From Source

NOT YET POSSIBLE. IGNORE TEXT BELOW

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

The .bin is 1104 in size because of the way that the assembler handles the workspace
declarations.

Split the workspace off the end:

    $ split -b 1024 NASBUGT4.bin && rm xab && mv xaa NASBUGT4.bin_trim

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
