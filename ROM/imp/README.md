# Sources

This is not a NASCOM monitor ROM, rather it is the 2KByte EPROM for the
Z80-based controller in the NASCOM IMP (Impact Matrix Printer). 

There was no protective label over the quartz window of this EPROM and no
version marking.

# Rebuilding from source

imp.bin_golden is the original ROM dump that I made. The recreated source
file is imp.asm

I use the GNU Z80 assembler (which is somewhat crude, but effective). The
check_rebuild script reassembles all the versions from source, compares each
generated binary with its corresponding bin_golden file, and reports any
differences. For example:

    #!/bin/sh
    #
    # rebuild from source and check that the binary matches the golden version

    z80asm -i imp.asm -limp.lst -oimp.bin

    # check
    diff imp.bin imp.bin_golden

check_rebuild should run "instantly" and produces no terminal output if the
.bin file matches the .bin_golden file.


# Guided disassembly

The script dis_rom operates on imp.bin_golden to create imp_dis.txt and
imp_dis.asm. imp_dis.asm was the starting-point for imp.asm but the
latter has been hand-edited to add more comments and to change the formatting.


# WANTED

If you have any original documentation or other versions, please get in
touch.
