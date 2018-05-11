# PolyDos boot ROMs

PolyDos was supplied as a floppy disk, a set of manuals and 2, 1Kx8 2708
EPROMs. The EPROMs were intended to be decoded at address $D000 and $D400.

The EPROMs contained boot code, hardware-indepdent sub-routines and
hardware-dependent disk drivers. The code was designed so that the ROMs could be
entered at boot time (by setting the NASCOM 2 reset jump switches) or explicitly
started from NAS-SYS with a "E D000" command.

The source code listing for the ROM was included in the manual and provided on
the system disk. It could be rebuilt from within PolyDos using the PolyZap
assembler.

The disk/ directory elsewhere contains that source code in its original form.

Files here:

* PolyDos_2_Boot_ROM.nas - "nas" format hex dump of the PolyDos 2 boot
  ROM. Scraped from a real system and exactly 2Kbytes in size.

* PolyDos_2_Boot_ROM.bin - binary file converted from the .nas file.

* PolyDos_2_Boot_ROM_mod.asm - source file derived from PD2S.TX with a tiny
  number of modifications to make it assemble under the control of the GNU z80
  assembler, and to pad it to 2Kbytes. The binary produced from assembling this
  file is an exact match of PolyDos_2_Boot_ROM.bin (but PolyDos_2_Boot_ROM.bin
  was not generated from this source).

* PolyDos_3_Boot_ROM.nas - "nas" format hex dump of the PolyDos 3 boot
  ROM. 1720 bytes so not the full size of the ROM.

* PolyDos_3_Boot_ROM.bin - binary file converted from the .nas file.

* PolyDos_3_Boot_ROM_mod.asm - source file derived from PD3S.TX with a tiny
  number of modifications to make it assemble under the control of the GNU Z80
  assembler, and with a few bytes of padding added to the end. The binary
  produced from assembling this file is an exact match of PolyDos_3_Boot_ROM.bin
  (but PolyDos_3_Boot_ROM.bin was not generated from this source).

* build - a trivial shell script to invoke the GNU Z80 assembler.

* SYSEQU.asm - a set of equates that is "included" for the build of either .asm
  files. Extracted from SYSEQU.SY on the PolyDos system disk.
