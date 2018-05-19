# Host programs for nascom_sdcard

These are programs in z80 assembler intended to run on the NASCOM.

## Common code

* sd_sub1.asm - common subroutines used by all the other programs. Accesed by "including" this file.


## Development programs

* sd_loop.asm - test program that uses the loopback command to send values and check that they are received back correclty.
* sd_rd1.asm - test program for reading a file from SDcard into RAM
* sd_wr1.asm - test program for writing RAM to SDcard

These are designed to be small so that they can be typed in by hand. They all
use the same set of subroutines and the subroutines are at the start of the
program so that, having typed in one program, that part does not need to be
retyped in order to run one of the other two programs.


## ROMs

* sd_util.asm - Set of utilities for read/write to SDcard. Slightly more polite than the "development programs" versions. Can be executed from RAM or ROM. Padded to 2Kbytes.
* polydos_rom.asm - version of the PolyDos boot ROM that accesses the SDcard. Can be executed from RAM or ROM. 2Kbytes.
* polydos_util_rom.asm - version of the PolyDos boot ROM that accesses the SDcard, combined with a cut-down version of the utils (so that they still fit in 2K). Can be executed from RAM or ROM. 2Kbytes.


## PolyDos utilities

* scrape.asm - intended to be run from PolyDos disk version. Copies physical disk images to SDcard file images
* setdrv.asm - intended to be run from PolyDos SDcard version. Reports which SDcard files are associated with PolyDos drives, and allows them to be changed.
* sddir.asm - intended to be run from PolyDos SDcard version. Reports directory listing of the SDcard.
* cadsk.asm - intended to be run from PolyDos disk or SDcard version. Replaces NAS-SYS R, W commands so that some other program can be tricked into saving/loading to disk instead of to tape.

## Tools

I use the gnu z80 assembler, z80asm, version 1.8

This is a simple assembler that generates binaries directly (no linker step) in
the same way as the old-style NASCOM assemblers like ZEAP.

## Help for PolyDos utilities

### SCRAPE

Copy a complete floppy disk image to SDcard.

  $ SCRAPE

Prompts you to "Insert disk then press ENTER, or SPACE to quit". After you press
enter, each sector of the disk in turn is read, and the sectors are written to a
file on the SDcard. The filename is automatically chosen to be the next free
(unused) name of the form NASxxx.BIN where xxx is a 3-digit decimal number.

As the copy proceeds, a "." is printed for each successful (group of) reads and a
* is printed for a failed (group of) reads. In case of a failed read, the copy
should continue but the image will have a corresponding invalid region.

When the copy has completed, the same prompt is printed; you can insert a new
floppy (which will be saved to a new filename).

To run this program you must be booted into disk PolyDos and have the
nascom_sdcard hardware connected.


### SETDRV

Display and change virtual drives on nascom_sdcard

  $ SETDRV

Report the files mounted for each drive

  $ SETDRV n filename

Unmount any SDcard file currently associated with drive (FID) n (0..3) and mount filename. filename must be a legal FAT "8.3" name.

  $ SETDRV 1 DRV0.BIN

In this example, drive 1 is now associated with the SDcard file DRV0.BIN

Mounting a file that does not exist on the SDcard will create that file (of zero
size). This is not a useful behaviour and could be considered a bug.


### SDDIR

Perform a directory listing of the SDcard, with paging

  $ SDDIR

Lists all of the files and directories in the (root directory of the)
SDcard. After each screen of output, you are invited to "Press [SPACE] to
continue". There is no abort; you must page through the whole listing.


### CASDSK

Allows disk load/store for a program that was designed to use the W and R tape routines.

Intercepts the NAS-SYS W and R routines and redirects them to a single
pre-defined disk file. Acts as a "terminate and stay resident" program and
therefore must sit in free memory somewhere.

Example: Colossal cave adventure can "save" the game state using tape routines. Do this:

  $ CASDSK CAVE.ME
  Installed
  $ COLOSSAL

Now, using SAVE and RESTORE within the program will still call W and R but now

* W (write to tape) will actually write to the file CAVE.ME, deleting any
pre-existing file of that name.

* R (read from tape) will result in the contents of CAVE.ME being loaded into
memory at the address from which it was saved.

  $ CASDSK
  Uninstalled

When executed like this, with no operands, the normal R and
W vectors are restored; The memory used by CASDSK can now be
reused.

 $ CASDSK
 Not installed

When executed like this, with no operands, if not previously installed, just
displays a message and returns.

Implementation notes:

# The usual operation of PolyDos is to read and write data with a minimal
granularity of 256 bytes. When saving, the same approach is taken: the write
data is rounded up to the nearest 256 bytes. However, that may not be acceptable
on reads, because it may overwrite data in memory.  Therefore, on writes, the
valid data size in the final sector (1-256 bytes) is stored in the low byte of
the "execution address" entry of the data file (CAVE.ME in the example
above). On reads, this size byte is used to transfer the file size.

# The algorithm can support any file size but the NAS-SYS calls that are
intercepted are limited to a maximum size of 64Kbyte.

# This utility would work just as well on a real floppy-disk version of PolyDos.
