# Sources

This is not a NASCOM monitor ROM, rather it is the SIMON (SImple MON) ROM for
the Gemini CPU cards (GM811 and GM813).

I know of 2 released versions: 4.1 and 4.2, (probably?) both written by Richard
Beal (the author of all but the earliest NASCOM ROM monitor programs). Unlike
the NASCOM monitors, the source code was not published for SIMON.

I have disassembled 4.2 and have not (yet) investigated differences between 4.1
and 4.2.

The source code here has been created by disassembly of the 4.2 code; the
comments are the result of code inspection.

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

This script should run "instantly" and produces no terminal output if the
binary is generated correctly.

# Guided disassembly

The script dis_rom operates on simon42.bin_golden to create simon42_dis.txt and
simon42_dis.asm. simon42_dis.asm was the starting-point for simon42.asm but the
latter has been hand-edited to add more comments and to change the formatting.

# WANTED

If you have any original documentation or other versions, please get in
touch. The only documentation I have found is here:

https://nascom.wordpress.com/gemini/software/si-mon-disk-boot-eprom/

and the command list does not seem to match the disassembled code.
