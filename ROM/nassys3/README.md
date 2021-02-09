# Sources

The monitor source code:

    NASSYS3.asm

came from nascomhomepage.com but has been fixed up to match the assembler
syntax and to move the workspace declaration to the end of the file.

The binary file:

    NASSYS3.bin_golden

is 2048 bytes in size and is a dump from an original/contemporary NAS-SYS 3 EPROM.

The documentation:

    NAS-SYS_3A_ocr.odt
    NAS-SYS_3A_ocr.pdf

is an OCR conversion of the NAS-SYS 3A manual (NAS-SYS 3A has a tiny number of code
changes to accommodate the NASCOM AVC). The .pdf is an export from the .odt file.
Obvious typos in the original have been corrected, along with all of the OCR errors
that I have spotted. I have messed with the font size in a few places in an attempt
to maintain the pagination of the original as much as possible.

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

    $ ./build NASSYS3

creates:

    NASSYS3.bin
    NASSYS3.lst

The .bin is 2176 in size because of the way that the assembler handles the workspace
declarations.

Split the workspace off the end:

    $ split -b 2048 NASSYS3.bin && rm xab && mv xaa NASSYS3.bin_trim

Now:

    $ diff NASSYS3.bin_golden NASSYS3.bin_trim
    (no output => files match)
    $ diff NASSYS3.bin_golden NASSYS3.bin
    Binary files NASSYS3.bin_golden and NASSYS3.bin differ

This shows that the original binary can be faithfully reproduced.

You can use nascon (https://github.com/nealcrook/nascom/blob/master/converters/nascon)
to convert to .NAS format

    $ ../../converters/nascon NASSYS3.bin_golden NASSYS3.NAS_golden       -in bin -out nas -org 0 -csum
    $ ../../converters/nascon NASSYS3.bin_trim   NASSYS3.NAS_trim_rebuilt -in bin -out nas -org 0 -csum
    $ ../../converters/nascon NASSYS3.bin        NASSYS3.NAS_rebuilt              -out nas -org 0 -csum
    $ diff NASSYS3.NAS_golden NASSYS3.NAS_trim_rebuilt
    (no output => files match)
    $ diff NASSYS3.NAS_golden NASSYS3.NAS_rebuilt
    256a257,272
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
    > 0850 00 00 00 00 00 00 00 00 58
    > 0858 00 00 00 00 00 00 00 00 60
    > 0860 00 00 00 00 00 00 00 00 68
    > 0868 00 00 00 00 00 00 00 00 70
    > 0870 00 00 00 00 00 00 00 00 78
    > 0878 00 00 00 00 00 00 00 00 80
