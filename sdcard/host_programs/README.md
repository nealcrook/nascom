# Host programs for nascom_sdcard

These are programs associated with the nascom_sdcard hardware. Most of them are z80
assembler programs intended to run on the NASCOM.

## ROMs

* sd_util.asm - Set of utilities for read/write to SDcard. Can be executed from RAM or ROM. Padded to 2Kbytes.
* polydos_rom.asm - version of the PolyDos boot ROM that accesses the SDcard. Can be executed from RAM or ROM. 2Kbytes.
* polydos_util_rom.asm - version of the PolyDos boot ROM that accesses the SDcard, combined with a cut-down version of the utils (so that they still fit in 2K). Can be executed from RAM or ROM. 2Kbytes. There are pre-built binaries and listings for this code, at origins of $B800 and $D800.

polydos_rom/polydos_util_rom are based on the PolyDos 2 ROM code and are configured for a virtual disk size of 315Kbytes.

The (ROM-based) utilities executed through a jump-table at the end of the ROM. The execution addresses shown below assume a ROM assembled at address $D800

* E DFF4 -- CSUM
* E DFF7 -- RDFILE
* E DFFA -- WRFILE
* E DFFD -- SCRAPE

Examples:

````
E DFF4 1000 800
````

Calculate and report a checksum of the 800 (hex) bytes starting at address 1000 (hex).

````
E DFF7 1000 34
````

Read file from SDcard into memory starting at address 1000 (hex). The transfer
size is equal to the file size. The filename is NAS034.BIN - all but the number
is hard-wired; the number comes from the last 3 digits of the argument (so
34, 034 and 1034 would all result in the same filename).

````
E DFFA 1000 17FF AB
E DFFA 1000 17FF
````

Write data from memory address range 1000-17FF (hex, inclusive) to SDcard. In
the first form, the filename is NAS0AB.BIN (see description above). In the
second form, the filename is "auto-picked" -- the next unused name of the form
NASxxx.BIN (where xxx are digits in the range 0..9) is chosen.

A note on auto-picked filenames: filenames explicitly specified by you can
include hex digits, but the auto-pick algorithm (which runs on nascom_sdcard)
uses decimal numbering. If you have created filenames NAS001.BIN, NAS002.BIN,
NAS003.BIN, NAS004.BIN, NAS005.BIN, NAS008.BIN, NAS009.BIN, NAS00A.BIN,
NAS012.NAS and then use auto-pick a few times, the auto-picked names will be
NAS000.BIN, NAS006.BIN, NAS007.BIN, NAS010.BIN, NAS011.BIN,
NAS013.BIN. Auto-pick will fail if all 1000 possible filenames are in use.


````
E DFFD
````

Access the PolyDos floppy disk in drive 0 and copy its contents to a file on
SDcard. The filename is "auto-picked" -- the next unused name of the form
NASxxx.BIN (where xxx are digits in the range 0..9) is chosen.


## PolyDos utilities

* scrape.asm - intended to be run from PolyDos disk version. Copies physical disk images to SDcard file images
* setdrv.asm - intended to be run from PolyDos SDcard version. Reports which SDcard files are associated with PolyDos drives, and allows them to be changed.
* sddir.asm - intended to be run from PolyDos SDcard version. Reports directory listing of the SDcard.
* casdsk.asm - intended to be run from PolyDos disk or SDcard version. Replaces NAS-SYS R, W commands so that some other program can be tricked into saving/loading to disk instead of to tape.
* scrape5.asm - intended to be run from PolyDos disk or SDcard version. Copies CP/M physical disk images to SDcard file images; assumes 35 track DSDD disks with 10 sectors per side, each of 512 bytes (so 35*10*2*512=350KBytes per disk).
* sdoff.asm -  intended to be run from PolyDos SDcard version. Puts SDcard interface into a quiescent state so that the PIO can be used for something else.

## Other utilities

* serboot.asm - boot loader for NASCOM digital tape recorder. A utility program that is loaded through the serial interface and which provides a simple command-line environment for communicating with the NASCOM digital tape recorder. The NASCOM digital tape recorder uses an ATMEL controller and an SDcard to provide solid-state storage for a NASCOM through an unmodified serial/cassette interface.
* dskboot.asm - boot loader for virtual disk. Refer to the comments in the code.
* SDBOOT0.asm - sample bootstrap program, invoked by sdboot. Refer to the comments in dskboot.asm.
* NASconsole - a PERL program to run on a PC that is attached to nascom_sdcard hardware. Allows file exchange between PC and the SDcard without the need to remove the SDcard or interrupt the NASCOM session.


## Library code

* sd_sub1.asm - common subroutines used by several other programs. Accessed by "including" this file. Refer to [Parallel interface programming examples](../doc/parallel_interface_programming.md)

## Development programs

* sd_loop.asm - test program that uses the loopback command to send values and check that they are received back correctly.
* sd_rd1.asm - test program for reading a file from SDcard into RAM
* sd_wr1.asm - test program for writing RAM to SDcard

These were used as test programs during the development of the nascom_sdcard
hardware.

sd_util.asm provides the same functionality (and more) in more user-friendly
form. The chief virtues of these programs are:

1. They are very small, so that they can be typed in by hand.

2. They all start with a lump of common code (the sd_sub1.asm code) so that,
having typed in one program, that part does not need to be retyped in order to
run one of the other programs.

sd_wr1.asm and sd_rd1.asm both use a hard-coded filename (NAS000.BIN) but the
name can be patched in memory if required.


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
"*" is printed for a failed (group of) reads. In case of a failed read, the copy
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

Unmount any SDcard file currently associated with drive (FID) n (0..3) and mount
filename. filename must be a legal FAT "8.3" name.

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

1. The usual operation of PolyDos is to read and write data with a minimal
granularity of 256 bytes. When saving, the same approach is taken: the write
data is rounded up to the nearest 256 bytes. However, that may not be acceptable
on reads, because it may overwrite data in memory.  Therefore, on writes, the
valid data size in the final sector (1-256 bytes) is stored in the low byte of
the "execution address" entry of the data file (CAVE.ME in the example
above). On reads, this size byte is used to transfer the file size.

2. The algorithm can support any file size but the NAS-SYS calls that are
intercepted are limited to a maximum size of 64Kbyte.

3. This utility would work just as well on a real floppy-disk version of PolyDos.


### SDOFF

Shut down the SDcard so that it (should be) quiescent on the PIO

    $ SDOFF

The idea is to allow some other piece of hardware to use the PIO. Specifically
developed and tested with the Bits&PCs EPROM programmer.

Obviously, before running this program you need to get everything you need into
memory (the EPROM programming software and the data to be programmed).

In order to restart the SDcard you need to reset it then reset the NASCOM and
re-boot PolyDos. Even if you have (eg) uploaded an EPROM to RAM, it should be
possible to restart and then save the EPROM image with no risk of corruption -
certainly this seems to work reliably on my NASCOM 2.
