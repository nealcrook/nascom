# ROMs

This area is my attempt to collate NASCOM ROM/EPROM software, with documentation
and (where possible) source code that can be used to reproduce the original
binary.

NAS-SYS 1 and the NASCOM 2 alpha-numeric character generator were originally
supplied as 2Kx8 masked ROMs. NASCOM ROM BASIC was only (as far as I know)
supplied as an 8Kx8 masked ROM. All the other software described here was
originally supplied in EPROMs -- either in 2708 1Kx8 parts or in 2716 2Kx8
parts.

In the case of DIS/DEBUG, later releases came on a tape with a relocator
allowing the purchaser to generate versions at any address. The code could run
from ROM or from RAM and the documentation recommended ROM addresses.


## Versions

Some ROM software had multiple versions over its life-time, but due to the fixed
size available the changes seem to only have been minor bug-fixes. These are the
ones that I know of:

* ZEAP - there was a 2.0 and a 2.1 version. Changes between them unknown.
* NAS-SYS 3 - there was a NAS-SYS 3a which added a couple of instructions to initialise the AVC display
* NAS-DEBUG - the DEBUG part of NAS-DIS/DEBUG had a version 3.1 and a version 3.2. Changes between them unknown.
* NAS-DOS - there seem to be several versions around, but I think this is related to support for different disk drives or number of tracks. One set of images seems to have been hacked to support use on one particular emulator.


## Serial numbers

Some ROM software included serial numbers to discourage copying. Some versions
on The Internet have been hacked to remove them. These are the ones that I know
of:

* ZEAP - the ROM version of ZEAP included serial numbers and (I think) a
checksum routine that verified the integrity of the image. The purchaser was
encouraged to register by sending in a form that included the serial number.
* NAS-DOS - the ROMs include serial numbers.


## Elsewhere

In addition to the material in this tree, see

* [PolyDos ROMS](../PolyDos/rom) -- source code for the PolyDos ROM-resident code
* [NASDOS](https://github.com/nealcrook/NASDOS) -- re-assemblable source for NAS-DOS

Also, [converters](../converters) has software for converting files between various formats,
including NASCOM-related audio and digital formats.


## Assembler syntax

Unless otherwise stated, the code here is designed for re-assembly using the GNU
Z80 assember, [z80asm](https://www.nongnu.org/z80asm/) -- this assembler is
somewhat crude but effective. This means that there are some small syntax
changes compared to the original published source.

Contemporary assemblers included ZEAP, ZEN, PolyZAP (on PolyDos) and M80
(Microsoft assembler on CP/M). The earliest NASCOM monitors were hand-assembled
but later versions used ZEAP, as did NAS-DIS/DEBUG (ZEAP listing files print a
"ZEAP" banner at the top).

There are minor syntax differences between different Z80 assemblers. Most can be
fixed with a bit of simple editing. Here are the ones that I know about (please
let me know of any others you spot):

* Most assemblers insist that only a comment or a label can start in column 1.
  ZEN is the exception; it allows labels to start in any column, and it
  allows non-labelled statements to start in column 1.

* Some assemblers require that a label ends with a colon (":"). ZEN, M80 and the
  GNU assembler require this. In PolyZap it's optional and ZEAP does not allow
  it.

* Some assemblers require at least 1 space between a label-terminating colon and
  the next statement. ZEN does not and will happily accept source like this:
  "LOOP:INC A".

* ZEN does not allow unary minus. For example "LD HL,-1" in the NAS-SYS source
  is acceptable to other assemblers but generates an error in ZEN. The fix is to
  express it thus: "LD HL,0-1".

* ZEN generates an error if an argument is expected to be 8 bits but overflows;
  other assemblers silently truncater. Example 1 in the NAS-SYS source: "DEFB
  BRRES-$-1" is acceptable to other assemblers, but generates an error in
  ZEN. The fix is to explicitly truncate it, thus: "DEFB
  BRRES-$-1&0FFH". Example 2 in the NAS-SYS source: "LD A,-1" is acceptable to
  other assemblers but generates an error in ZEN, as mentioned above. The first
  attempted fix is "LD A,0-1" but this falls foul of the overflow problem, so
  the actual fix is to code it as "LD A,0-1&0FFH". I'm sure that ZEN is Only
  Trying To Help but in these cases it's actually hindering!

* (the standard version of) ZEN does not provide a DEFM pseudo-op, but its DEFB
  pseudo-op supports string arguments.

* Some assemblers provide pseudo-ops for the NASCOM monitor calls (eg, SCAL,
  RCAL, PRS).

* (the standard version of) ZEN does not allow labels to use "reserved words"
  (any pseudo-op or op-code name) so that "IN: PUSH HL" in the NAS-SYS source
  generates an error. This restriction seems needless; when I patched the
  assembler to remove the check that imposes this restriction, it seemed to work
  correctly.

* In Zilog programming manual, the SUB instruction implicitly targets A so that
  "SUB C" is legal. Some assemblers (maybe only the GNU assembler?) require this
  to be coded as "SUB A,C".

* Most assemblers allow string literals to be used like this: LD A, "E" but ZEAP
  does not. In ZEAP, only the opening quote is used: LD A, "E

* Some assemblers require the pseudo-op END at the end of the source; ZEN
  behaviour is quite confusing if END is omitted.

* Most assemblers allow space and tab as whitespace characters. ZEN only allows
  space.

* Most assemblers have particular requirements about line-endings.
  Traditionally, NASCOM files use ^M (0x0D, carriage-return) line endings.
