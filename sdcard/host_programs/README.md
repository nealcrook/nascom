# Host programs for nascom_sdcard

These are programs in z80 assembler intended to run on the NASCOM.

## Common code

sd_sub1.asm - common subroutines used by all the other programs. Accesed by "including" this file.


## Development programs

sd_loop.asm - test program that uses the loopback command to send values and check that they are received back correclty.
sd_rd1.asm - test program for reading a file from SDcard into RAM
sd_wr1.asm - test program for writing RAM to SDcard

These are designed to be small so that they can be typed in by hand. They all
use the same set of subroutines and the subroutines are at the start of the
program so that, having typed in one program, that part does not need to be
retyped in order to run one of the other two programs.


## ROMs

sd_util.asm - Set of utilities for read/write to SDcard. Slightly more polite than the "development programs" versions. Can be executed from RAM or ROM. Padded to 2Kbytes.
polydos_rom.asm - version of the PolyDos boot ROM that accesses the SDcard. Can be executed from RAM or ROM. 2Kbytes.
polydos_util_rom.asm - version of the PolyDos boot ROM that accesses the SDcard, combined with a cut-down version of the utils (so that they still fit in 2K). Can be executed from RAM or ROM. 2Kbytes.


## PolyDos utilities

scrape.asm - intended to be run from PolyDos disk version. Copies physical disk images to SDcard file images
setdrv.asm - intended to be run from PolyDos SDcard version. Reports which SDcard files are associated with PolyDos drives, and allows them to be changed.
sddir.asm - intended to be run from PolyDos SDcard version. Reports directory listing of the SDcard.

## Tools

I use the gnu z80 assembler, z80asm, version 1.8

This is a simple assembler that generates binaries directly (no linker step) in
the same way as the old-style NASCOM assemblers like ZEAP.
