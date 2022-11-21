# Converters

Here are PERL programs for converting NASCOM files between different formats.

* [nascon](nascon) - convert between nas/cas/bin/hex/dmp formats.
* [wav2bin](wav2bin) - converts NASCOM audio files at 1200 or 300 baud into binary.
* a_mastermind_1200_1blk.wav - one block of .cas format audio, 1200 baud
* nas2cas - (obsolete) convert .nas format to .cas
* cas2nas - (obsolete) convert .cas format to .nas (also spits out a binary file)
* [sy_extract](sy_extract) - Polydos allowed creation of a symbol table in a compiled format that could be read in to the polyzap assembler. This program reads a symbol table in this compiled format and writes it out as a set of equates.
* polydos_vfs - mount upto 4 PolyDos disk images and inspect/manipulate them. Extensive built-in [help](polydos_vfs_help.md)
* [toZ80](toZ80) - convert assembler source from 8080 mnemonics to Z80 mnemonics. This originated as an AWK script written by Douglas Beattie Jr. cira 2003, but it had some bugs. I used a2p to convert it to PERL then fixed the bugs and added support for some 8080 instructions that had been missing.

All of those programs are written in PERL. If you use Linux or Mac you will have
PERL installed. If you use Windows I recommend Strawberry PERL which is free.

And miscellaneous/general-purpose converters:

* bin2char_array - convert a binary file to a C char data structure.


## Using wav2bin

The file a_mastermind_1200_1blk.wav is a tiny piece of audio recovered from
magnetic audio tape for test purposes.

   $ ./wav2bin a_mastermind_1200_1blk.wav mas.cas
   Header format: siz=16 AudioFormat=1 NumChannels=2 SampleRate=44100 ByteRate=176400 BlockAlign=4 BitsPerSample=16
   Look for data sub-chunk
   Data sub-chunk OK size=408280
   Bad symbol at 252 after output byte 0
   Look for data sub-chunk

Now:

   $ hexdump -C mas.cas
   00000000  00 00 00 00 ff ff ff ff  d6 10 00 08 ee 15 19 51  |...............Q|
   00000010  19 ea 19 f9 10 00 00 e6  10 b0 87 b3 10 80 81 7f  |................|
   00000020  20 31 38 20 30 30 30 30  45 29 c3 81 cb eb 39 00  | 18 0000E)....9.|
   00000030  00 1e 11 05 00 8e 20 2a  2a 2a 20 20 20 4d 20 41  |...... ***   M A|
   00000040  20 53 20 54 20 45 20 52  20 4d 20 49 20 4e 20 44  | S T E R M I N D|
   00000050  20 2a 2a 2a 00 42 11 06  00 8e 20 2a 2a 2a 2a 2a  | ***.B.... *****|
   00000060  20 28 63 29 20 4e 2e 20  43 72 6f 6f 6b 20 31 39  | (c) N. Crook 19|
   00000070  38 30 20 2a 2a 2a 2a 2a  00 58 11 0a 00 4b b4 be  |80 *****.X...K..|
   00000080  28 30 29 ae ad 31 3a 20  51 b4 be 28 4b 29 00 70  |(0)..1: Q..(K).p|
   00000090  11 14 00 94 20 a7 41 28  58 29 b4 b7 28 be 28 31  |.... .A(X)..(.(1|
   000000a0  29 ae 58 ac 31 29 00 8b  11 1e 00 8e 2a 2a 2a 73  |).X.1)......***s|
   000000b0  65 74 20 75 70 20 47 45  54 20 72 6f 75 74 69 6e  |et up GET routin|
   000000c0  65 00 a7 11 1f 00 96 20  33 32 30 30 2c 32 35 33  |e...... 3200,253|
   000000d0  31 31 3a 96 20 33 32 30  32 2c 33 31 32 00 c5 11  |11:. 3202,312...|
   000000e0  20 00 96 20 33 32 30 34  2c 31 38 33 35 31 3a 96  | .. 3204,18351:.|
   000000f0  20 33 32 30 36 2c 31 30  39 32 37 00 e1 11 21 00  | 3206,10927...!.|
   00000100  96 20 33 32 30 38 2c ad  38 31 37 39 3a c9 00 00  |. 3208,.8179:...|
   00000110  00 00 00 00 00 00 00 00  00 ff ff ff ff           |.............|
   0000011d

You can see the NASCOM .cas format, the load address of 10d6 hints that it is a
BASIC program (though the BASIC file-name header is missing - see ".cas format"
below.

So, it can be processed (albeit reluctantly) by nascon:

  $ ./nascon mas.cas mas.dmp
  Look for block header..
  Found blk 8 (0x100 bytes at address 0x10D6)
  Look for block header..
  ERROR reached end of file while trying to read block address
  ERROR reached end of file while trying to read block address
  ERROR reached end of file while trying to read block length
  ERROR reached end of file while trying to read block number
  ERROR reached end of file while trying to read block header checksum
  ERROR bad header checksum in block 1 - calculated 0x4 but read 0x1
  ERROR bad header block number in block 1 -- expected 0x7 but read 0x1
  Found blk 1 (0x1 bytes at address 0x0101)
  ERROR reached end of file while trying to read block data
  ERROR reached end of file while trying to read block data checksum
  ERROR cas file finished at block 1 - expected it to finish at block 0
  Sum of all input data bytes (usually a checkum would be the low 8 bits of this): 0x41ca

There are multiple errors because nascon expects to see a series of blocks,
ending with a block number of 0. Now inspect what nascon produced:

  $ cat mas.dmp
  000010d6: 15 19 51 19 ea 19 f9 10 - 00 00 e6 10 b0 87 b3 10   ..Q..... ........
  000010e6: 80 81 7f 20 31 38 20 30 - 30 30 30 45 29 c3 81 cb   ... 18 0 000E)...
  000010f6: eb 39 00 00 1e 11 05 00 - 8e 20 2a 2a 2a 20 20 20   .9...... . ***   
  00001106: 4d 20 41 20 53 20 54 20 - 45 20 52 20 4d 20 49 20   M A S T  E R M I 
  00001116: 4e 20 44 20 2a 2a 2a 00 - 42 11 06 00 8e 20 2a 2a   N D ***. B.... **
  00001126: 2a 2a 2a 20 28 63 29 20 - 4e 2e 20 43 72 6f 6f 6b   *** (c)  N. Crook
  00001136: 20 31 39 38 30 20 2a 2a - 2a 2a 2a 00 58 11 0a 00    1980 ** ***.X...
  00001146: 4b b4 be 28 30 29 ae ad - 31 3a 20 51 b4 be 28 4b   K..(0).. 1: Q..(K
  00001156: 29 00 70 11 14 00 94 20 - a7 41 28 58 29 b4 b7 28   ).p....  .A(X)..(
  00001166: be 28 31 29 ae 58 ac 31 - 29 00 8b 11 1e 00 8e 2a   .(1).X.1 )......*
  00001176: 2a 2a 73 65 74 20 75 70 - 20 47 45 54 20 72 6f 75   **set up  GET rou
  00001186: 74 69 6e 65 00 a7 11 1f - 00 96 20 33 32 30 30 2c   tine.... .. 3200,
  00001196: 32 35 33 31 31 3a 96 20 - 33 32 30 32 2c 33 31 32   25311:.  3202,312
  000011a6: 00 c5 11 20 00 96 20 33 - 32 30 34 2c 31 38 33 35   ... .. 3 204,1835
  000011b6: 31 3a 96 20 33 32 30 36 - 2c 31 30 39 32 37 00 e1   1:. 3206 ,10927..
  000011c6: 11 21 00 96 20 33 32 30 - 38 2c ad 38 31 37 39 3a   .!.. 320 8,.8179:
  00000101: 01

In contrast to the dump of the .cas file, the block structure has been
used/removed, leaving just the payload. The start address of the dump is 0x10d6,
extracted from the .cas format file. The .dmp format is provided for
inspection/debug purposes. In the case of a complete .cas file, it would be
usual to select .nas format to generate a file that can be loaded straight into
memory (eg, on a nascom emulator) or imported into a PolyDos disk image, using
polydos_vfs


## NASCOM File formats

Files for use with NASCOM emulators are commonly of 2 file types: .nas and .cas

A .nas file is ASCII text, a hex dump in the format produced by the NAS-SYS "T" command.

In a real system, a .nas file would be loaded into memory using the NAS-SYS 1
"L" command (the "L" command was removed from NAS-SYS 3). In emulation, a .nas
file is typically loaded directly into memory under the control of the emulator.

A .cas file is binary, in the cassette tape format produced by the NAS-SYS "W"
or "G" commands or by programs that use the NAS-SYS sub-routines (e.g. NASCOM 8K
ROM BASIC).

In a real system. a .cas file represents the byte stream that would be recovered
from the cassette interface and loaded into memory under the control of the
NAS-SYS "R" command. In emulation, a .cas file is typically presented by the
emulator as a serial byte stream that is read by the emulated cassette
interface.


### .cas format

by default it is just a sequence of binary blocks. The format can be inferred
from the NAS-SYS listing.

However..

.. if it is a BASIC program it has a header which is a single letter.

BASIC will not load a program until it has found one of these headers. From
BASIC, CLOAD with no argument will read the *next* header and its data. CLOAD
with an argument will report each header in turn until it finds the right one,
and will then load.

The header has this format:

    0xd3 0xd3 0xd3 0xZZ

where ZZ is the "file-name"

When NAS-SYS is waiting for input from the keyboard, it will also accept input
from tape. Therefore, some .cas (and .nas) files also have ASCII text strings
before/after the main program data.

For example, a .cas file generated by the NAS-SYS 3 "G" command has this format:

    (CR)E0(CR)R(CR)

then data in the same format as the "W" command, then

    Ezzzz(CR)

where zzzz is the execution address of the program, as supplied to the G command.


### .nas format

Lines are in one of 2 formats:

1/ a 4-digit hex load address value followed by between 1 and 8 2-digit hex data
values. Each value is space-separated from the others. For example:

    1000 0A 0A 91 57 91 3D 53 E8
    1008 11 6A C5 12 96

2/ a 4-digit hex load address value followed by 9 2-digit hex data values. Each
value is space-separated from the others. In this case, the 9th value is the
mod-256 sum of the 10 previous bytes (the address counts as 2 bytes). For example:

    1000 0A 0A 91 57 91 3D 53 E8 15
    1008 11 6A C5 12 96 A8 14 51 0D

In both cases, the line ends with a (CR). In some cases, there are CTRL-H and
NUL (ASCII 0) characters at the end of the line before the (CR).

In principle, the two formats can be mixed in a single file. However, if they
were generated by NAS-SYS all lines in a file will be in the same format.

Some .nas files seem to have other line-ending formats, for example (CR)(LF)

If a .nas file was being loaded on a real system under the control of NAS--SYS,
it would be loaded using the "L" command. The "L" command is terminated by a "."
and therefore some .nas files end in the same way. For example:

    2938 25 CA 26 DE 27 66 27 FA
    2940 27 43 28 72
    .

An emulator that loads .nas files directly into memory should ignore the "."



### nas2cas

parse a .nas file. Generate the equivalent .cas file. By default there is no additional header
or trailer.

FUTURES/TODO:

    -g zzzz -- add ASCII header/trailer in NAS-SYS "G"enerate format, with an execution address of zzzz
    -b Z    -- add MBASIC header with file-name Z


### cas2nas

parse a .cas file. Report any header/trailer information. Generate the equivalent .nas file. By default
there is no additional header or trailer.

FUTURES/TODO:

    -t      -- add "." trailer
