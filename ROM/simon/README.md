# Sources

This is not a NASCOM monitor ROM, rather it is the SIMON (SImple MON) ROM for
the Gemini CPU cards (GM811 and GM813 and ??).

I know of 3 released versions: 4.1, 4.2, 4.5s and 5.0. The first 2 are
(probably?)  both written by Richard Beal (the author of all but the earliest
NASCOM ROM monitor programs). I'm not sure about 4.5s or 5.0. Unlike the NASCOM
monitors, the source code was not published for SIMON.

I have disassembled 4.2 and have not (yet) investigated differences between 4.1
and 4.2.

I have disassembled 5.0, which was for a Hitachi HD64180 and will not function
on GM811/GM813 boards.

The source code here has been created by disassembly of the 4.2/5.0 code; the
comments are the result of code inspection.

# Version 4.1 MFB

The binary file:

    simon41mbf.bin_golden

is 2048 bytes in size and came from John Newcombe's web site https://glasstty.com/gemini-80-bus-resource/

The recreated source code is:

    simon41mbf.asm

To assemble it, I use the GNU Z80 assembler (which is somewhat crude, but
effective). The script check_rebuild builds the binary/listing from source and
compares the resultant binary with the golden binary:

    #!/bin/sh
    #
    # rebuild from source and check that the binary matches the golden version
    
    z80asm -i simon41mbf.asm -lsimon41mbf.lst -osimon41mbf.bin
    
    # check
    diff simon41mbf.bin simon41mbf.bin_golden


# Version 4.2

The binary file:

    simon42.bin_golden

is 2048 bytes in size and came from John Newcombe's web site https://glasstty.com/gemini-80-bus-resource/

The recreated source code is:

    simon42.asm

To assemble it, I use the GNU Z80 assembler (which is somewhat crude, but
effective). The script check_rebuild builds the binary/listing from source and
compares the resultant binary with the golden binary:

    #!/bin/sh
    #
    # rebuild from source and check that the binary matches the golden version
    
    z80asm -i simon42.asm -lsimon42.lst -osimon42.bin
    
    # check
    diff simon42.bin simon42.bin_golden


# Version 4.4

The binary file:

    simon44.bin_golden

is 1920 bytes in size and came from John Newcombe's web site https://glasstty.com/gemini-80-bus-resource/

The recreated source code is:

    simon44.asm

To assemble it, I use the GNU Z80 assembler (which is somewhat crude, but
effective). The script check_rebuild builds the binary/listing from source and
compares the resultant binary with the golden binary:

    #!/bin/sh
    #
    # rebuild from source and check that the binary matches the golden version
    
    z80asm -i simon44.asm -lsimon44.lst -osimon44.bin
    
    # check
    diff simon44.bin simon44.bin_golden


# Version 4.5s

The binary file:

    simon45s.bin_golden

is 2048 bytes in size and was supplied by Paul, M0EYT. It came from his TimeClaim DX3 Gemini system.

The recreated source code is:

    simon45s.asm

To assemble it, I use the GNU Z80 assembler (which is somewhat crude, but
effective). The script check_rebuild builds the binary/listing from source and
compares the resultant binary with the golden binary:

    #!/bin/sh
    #
    # rebuild from source and check that the binary matches the golden version
    
    z80asm -i simon45s.asm -lsimon45s.lst -osimon45s.bin
    
    # check
    diff simon45s.bin simon45s.bin_golden

# Version 5.0

The binary file:

    simon50.bin_golden

is 8192 bytes in size (but with 2 large empty sections) and was supplied by
Richard Espley

The recreated source code is:

    simon50.asm

To assemble it, I use the GNU Z80 assembler (which is somewhat crude, but
effective). The script check_rebuild builds the binary/listings from source and
compares the resultant binaries with the golden binaries:

    #!/bin/sh
    #
    # rebuild from source and check that the binary matches the golden version
    
    z80asm -i simon50.asm -lsimon50.lst -osimon50.bin
    
    # check
    diff simon50.bin simon50.bin_golden

This script should run "instantly" and produces no terminal output if the
binary is generated correctly.

# Guided disassembly

The script dis_rom operates on simon42.bin_golden to create simon42_dis.txt and
simon42_dis.asm. simon42_dis.asm was the starting-point for simon42.asm but the
latter has been hand-edited to add more comments and to change the formatting.

Likewise, dis_rom50 operates on simon50.bin_golden.

# WANTED

If you have any original documentation or other versions, please get in
touch. The only documentation I have found is here:

https://nascom.wordpress.com/gemini/software/si-mon-disk-boot-eprom/

and the command list does not seem to match the disassembled code.
