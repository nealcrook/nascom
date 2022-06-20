# Sources

This is not a NASCOM monitor ROM, rather it is the RP/M ROM for the Gemini CPU
cards (GM811 and GM813).

There were 3 released versions: 2.0, 2.1 and 2.3, all written by Richard Beal
(the author of all but the earliest NASCOM ROM monitor programs). Unlike the
NASCOM monitors, the source code was not published for RP/M.

The differences between the 3 versions is very small. The patch for RP/M 2.0 to
2.1 was published and explained in 80-Bus News vol.2 iss.1 and the patch for
RP/M 2.1 to 2.3 was published and explained in 80-Bus News vol.3 iss.6.

The source code here has been created by disassembly of the 2.3 code; the
comments are the result of code inspection and inspection of the
documentation. Conditional assembly has been added to allow a single source file
to generate any of the 3 versions.

The binary files:

    rpm20.bin_golden
    rpm21.bin_golden
    rpm23.bin_golden

are all 4096 bytes in size and came from John Newcombe's web site https://glasstty.com/gemini-80-bus-resource/

The recreated source code is

    rpmXX.asm

The RP/M 2.0 documentation can be found at https://nascom.files.wordpress.com/2017/10/rp-m-manual.pdf and the 80-bus article referenced above describes the changes to the B command for RP/M 2.3


To assemble it, I use the GNU Z80 assembler (which is somewhat crude, but
effective). For each RP/M version there is a corresponding setverXX.asm file
which is assembled along with the common rpmXX.asm to generate the appropriate
binary and listings. The script check_rebuild builds all 3 versions and compares
the resultant binaries with the golden binaries:

    #!/bin/sh
    #
    # rebuild from source and check that the binary matches the golden version

    z80asm -i setver20.asm -i rpmXX.asm -lrpm20.lst -orpm20.bin
    z80asm -i setver21.asm -i rpmXX.asm -lrpm21.lst -orpm21.bin
    z80asm -i setver23.asm -i rpmXX.asm -lrpm23.lst -orpm23.bin

    # check them
    diff rpm20.bin rpm20.bin_golden
    diff rpm21.bin rpm21.bin_golden
    diff rpm23.bin rpm23.bin_golden

This script should run "instantly" and produces no terminal output if all 3
binaries are generated correctly.

# Guided disassembly

The script dis_rom operates on rpm23.bin_golden to create rpm23.txt and
rpm23.asm. rpm23.asm was the starting-point for rpmXX.asm but the latter has
been hand-edited to add more comments, to change the formatting and to add the
conditional assembly stuff.