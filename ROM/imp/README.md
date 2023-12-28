# Sources

This is not a NASCOM monitor ROM, rather it is the 2KByte EPROM for the
Z80-based controller in the NASCOM IMP (Impact Matrix Printer). 

There was no protective label over the quartz window of this EPROM and no
version marking.

# Rebuilding from source

imp.bin_golden is the original ROM dump that I made. The recreated source
file is imp_dis_edit.asm

I use the GNU Z80 assembler (which is somewhat crude, but effective). The
check_rebuild script reassembles all the versions from source, compares each
generated binary with its corresponding bin_golden file, and reports any
differences. For example:


    #!/bin/sh
    #
    # rebuild from source and check that the binary matches the golden version

    z80asm -i imp_dis.asm       -limp.lst        -oimp.bin
    z80asm -i imp_dis_edit.asm  -limp_edit.lst   -oimp_edit.bin

    # check
    diff imp.bin      imp_edit.bin
    diff imp.bin      imp.bin_golden
    diff imp_edit.bin imp.bin_golden

check_rebuild should run "instantly" and produces no terminal output if the
.bin file matches the .bin_golden file.

*However*, there is a bug in z80asm where (ix) references get assembled
incorrectly (the offset byte is omitted from the generated code so that the code
is both wrong and the wrong size). The fix is to replace each occurrence of (ix)
and (iy) with (ix+0), (iy+0) respectively.

Therefore, the imp.bin code will not match.. but imp_dis.bin will match.

# Guided disassembly

The script dis_rom operates on imp.bin_golden to create imp_dis.txt and
imp_dis.asm. imp_dis.asm was the starting-point for imp_dis_edit.asm but the
latter has been hand-edited to add more comments and to change the formatting.


# WANTED

If you have any original documentation or other versions, please get in
touch.
