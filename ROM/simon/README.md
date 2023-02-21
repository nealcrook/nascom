# Sources

This is not a NASCOM monitor ROM, rather it is the SIMON (SImple MON) ROM for
the Gemini CPU cards (GM811 and GM813 and ??).

I know of these released versions: 3.1MP, 4.1MFB, 4.2, 4.3, 4.4, 4.5s and 5.0.
Unlike the NASCOM monitors, the source code was not published for SIMON. RP/M
and all but the earliest NASCOM ROM monitor programs were written by Richard
Beal, but I don't know whether he was also responsible for SIMON.

The source code here has been created by disassembly of some versions of the
code; the comments and labels are the result of code inspection.

The MFB version is for the "Multi-format BIOS" machine (maybe MP and S is also
for a MFB machine). These versions expect a different magic number in the CP/M
disk's boot sector and ?do some kind of protection by running a blob of code on
the intelligent video card?

    3.1MP  -- magic is GG     Copyright message: (C) dci software 26-10-82
    4.1MFB -- magic is mG     Copyright message: (C) dci software 17-06-85
    4.2    -- magic is GG     Copyright message: (C) dci software 10-06-86
    4.3    -- magic is mG     Copyright message: (C) dci software 10-06-86
    4.4    -- magic is GG     Copyright message: (C) dci software 10-03-87
    4.5s   -- magic is mG     Copyright message: (C) dci software 10-03-87
    5.0    -- magic is GG     Copyright message: (C) dci software 29-01-88

Version 5.0 was for a Hitachi HD64180 which has an extended capability compared
with a Z80, so this version will not function on GM811/GM813 boards.


# Rebuilding from source

For each version XX there is a binary file simonXX.bin_golden whose origin is
described below. There is a corresponding recreated source file simonXX.asm

I use the GNU Z80 assembler (which is somewhat crude, but effective). The
check_rebuild script reassembles all the versions from source, compares each
generated binary with its corresponding bin_golden file, and reports any
differences. For example:

    #!/bin/sh
    #
    # rebuild from source and check that the binary matches the golden version

    z80asm -i simon31mp.asm -lsimon31mp.lst -osimon31mp.bin

    # check
    diff simon31mp.bin simon31mp.bin_golden

check_rebuild should run "instantly" and produces no terminal output if every
.bin file matches its corresponding bin_golden file.



# Version 3.1 MP

The binary file:

    simon31mp.bin_golden

is 2048 bytes in size and came from Paul, M0EYT. It came with (but was not in) his TimeClaim DX3 Gemini system.


# Version 4.1 MFB

The binary file:

    simon41mbf.bin_golden

is 2048 bytes in size and came from John Newcombe's web site https://glasstty.com/gemini-80-bus-resource/


# Version 4.2

The binary file:

    simon42.bin_golden

is 2048 bytes in size and came from John Newcombe's web site https://glasstty.com/gemini-80-bus-resource/


# Version 4.3

The binary file:

    simon43.bin_golden

is 2048 bytes in size and came from Paul, M0EYT. It came with (but was not in) his TimeClaim DX3 Gemini system.


# Version 4.4

The binary file:

    simon44.bin_golden

is 1920 bytes in size and came from John Newcombe's web site https://glasstty.com/gemini-80-bus-resource/


# Version 4.5s

The binary file:

    simon45s.bin_golden

is 2048 bytes in size and was supplied by Paul, M0EYT. It came from his TimeClaim DX3 Gemini system.

The recreated source code is:

    simon45s.asm

Note: There seems to be an error in the binary dump of this ROM. In the source code, the PRS routine
starts like this:

    f39f 6e                 PRS:    ld l, (hl)      ; SURELY this should be ld a, (hl)
    f3a0 23                         inc hl
    f3a1 b7                         or a
    f3a2 c8                         ret z

In all other versions (eg, 4.4), the code looks like this:

    f3cb 7e                 PRS:    ld a, (hl)
    f3cc 23                         inc hl
    f3cd b7                         or a
    f3ce c8                         ret z

# Version 5.0

The binary file:

    simon50.bin_golden

is 8192 bytes in size (but with 2 large empty sections) and was supplied by
Richard Espley


# Guided disassembly

The script dis_rom operates on simon42.bin_golden to create simon42_dis.txt and
simon42_dis.asm. simon42_dis.asm was the starting-point for simon42.asm but the
latter has been hand-edited to add more comments and to change the formatting.

Likewise, dis_rom50 operates on simon50.bin_golden (etc)

# WANTED

If you have any original documentation or other versions, please get in
touch. The only documentation I have found is here:

https://nascom.wordpress.com/gemini/software/si-mon-disk-boot-eprom/

and the command list does not seem to match the disassembled code.
