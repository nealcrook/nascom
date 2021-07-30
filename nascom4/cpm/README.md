# CP/M for NASCOM 4

The goal: CP/M 2.2 using the MAP80 BIOS modified so that it supports real
(magnetic) floppies and also virtual floppies stored on the NASCOM 4 on-board
SDcard.

PolyDos supported 4 virtual drives and 16 virtual disks

each disk is 512Kbytes but doubled on the SDcard so that each disk occupies
1MByte on the sdcard (2048 sectors, at offsets 0-0x7ff from some start address)

SDcard uses 24-bit addressing.

Address $0000 $03ff used to store the N4 boot menu and ROM images, so that the
PolyDos images are at $0400 + $0000, $0400 + $0800, $0400 + $1000 etc.

Each CP/M disk could be 350Kbyte (like the Pertec) but it seems sensible to size
them at 1MByte (and, unlike the PolyDos disks, to use all of the storage). The
geometry of the drive can be chosen to make the track/sector -> linear
conversion straightforward.  For example, 1024 * 1024 / 512 = 2048 sectors: 128
tracks at 16 tracks/sector.

BUT the existing BIOS code has a SIDES equate that applies to all floppies so,
at least for the initial work where I'm pretending that the SDcard disk images
are accessed through the floppy disk controller, the easiest approach is to
pretend that the SDcard disk images are 2-sided to match the Pertec drives.

This affects the equates:

MXTKSD goes from 128 (single-sided) to 64 (double-sided)
MXSCSS goes from 16  (single-sided) to 32 (double-sided)
OFFSD  goes from 2   (single-sided) to  1 (double-sided)

.. and affects the setup in David's emulator for the SD*.config files

.. but does NOT affect the disk images themselves, or the cpmtools setup, where
the sides are invisible.

If I supported 16 CP/M disks I'd have to move to 24-bit addressing to
accommodate the final one. Probably best to design it with that in mind, so that
I can eventually support an unfragmented FAT filesystem.

Then CP/M images will be at $0400 + $8000, $0400 + $8800. Last one at $1.7C00

Can store a disk id (4-bit value) and hard-code the base address (that's what I
did for PolyDos) or can store the base address of each image.

I think, for the start, I'll just store the id, as for PolyDos - and maybe store
the base address in memory (rather than hard-coded) This means that the group of
disks could later sit inside a 16MByte unfragmented FAT32 file.

Start from the original BIOS which supports 2 floppy disks. Retain the boot from
magnetic floppies and add support for 4 additional drives C, D, E, F that map
to the SDcard.

Required for initial debug:

* Script for generating blank floppies (simply full of $E5 bytes, like a
  newly-formatted disk)

* cpmtools disk definition to all files to be moved in and out of virtual SDcard
  disk images.


After initial debug:

* Create a utility to change the disk mappings, like the PolyDos one.

* Put the new system image onto the system track of the SDcard disk image and
switch the disk order so that A, B, C, D are SDcard disks and E, F are the
magnetic floppies.

The system track on the magnetic floppies is both sides of 1 track: 2*10*512 =
10Kbytes. In the BIOS definition this counts as 1 (double-sided) track. In the
cpmtools definition it counts as 2 (single-sided, interleaved) tracks.

The proposed Sdcard image geometry is single-sided; both the BIOS and cpmtools
setup consider the track size to be 16 sectors; in both cases, need to reserve 2
system tracks (2*16*512 = 16Kbytes).

Q: are the blocking/unblocking routines portable (for different geometrys)
provided that the physical sector size is constant (which it is: 512 bytes)

Q: what is CP/M text file format? Why does nbios.mac file appear with ^M at the
end of each line but bios.mac does not? Must be a corruption somewhere in the
nbios.mac - both files have 0d/0a line endings; bios.mac is interpreted by emacs
as a DOS file. Seems to have been something to do with the ^Z at the end of
file?

## CPMTOOLS setup

I added these 2 entries to /etc/cpmtools/diskdefs

````
# NASCOM CP/M Pertec 35-track DS DD by Neal 18Jul2021
# blocksize is from BIOS source; maxdir is by trial and error on a real disk
# The first 10 sectors are side 0, the next 10 are side 1 so that the 2-sided
# characteristic is invisible here but accommodated by doubling the track
# count from 35 to 70. Image size is 350Kbyte.
diskdef nascom-pertec
  seclen 512
  tracks 70
  sectrk 10
  blocksize 2048
  maxdir 128
  skew 0
  boottrk 2
  os 2.2
end

# NASCOM 4 SD-card disk image by Neal 25Jul2021
# Geometry is arbitrary, but chosen to make it simple to map from tracks/sectors
# to linear block addressing. Image size is 1MByte.
diskdef nascom4-sd
  seclen 512
  tracks 128
  sectrk 16
  blocksize 2048
  maxdir 128
  skew 0
  boottrk 2
  os 2.2
end
````

## Configuration Notes

By comparing EQU.MAC and NEQU.MAC it appears that the equates are already set up
correctly for my system, specifically:

* NASCOM 2
* NASCOM keyboard
* MAP80 RAM board
* MAP80 VFC board
* 2 Pertec 35-track DSDD drives

## Build Notes

BIOSDEV.DSK.ORIG is as a copy of my CP/M disk scrape NAS051.BIN. It is a system
disk that boots on a real system and on NASCOM 4, using a real disk or from
GOTEK.

Directory listings created in linux like this:

````
$ cpmls -f nascom-pertec foo.dsk
````

Extract files like this:

````
$ cpmcp -f nascom-pertec foo.dsk 0:format.com format.com
````

..and reverse the parameters to import a file to the disk image.

The nascom-pertec definition seems OK in emulation (not yet tried on GOTEK).


* BIOSDEV1.DSK - clean

* BIOSDEV2.DSK - with files imported using cpmls - using regen_build_disk

* BIOSDEV3.DSK - clean, then BIOS rebuilt in David's emulator (hand-edited the
message in the boot track and confirmed the disk at boot time
then confirmed that the BIOS has been replaced successfully.


Create a blank disk image to go onto the SDcard, then import a file onto it:

````
$ ./make_blank_sd_floppy > SD0.DSK
$ cpmcp -f nascom4-sd SD0.DSK ../../sdcard/cpm_scrapes/biosman.txt 0:biosman.txt
````

## Build process

````
A> SUB N4PT12
A> MOVECPM 62 *
A> SYSGEN

A


````

Or, N4PT1 followed by N4PT2 followed by the MOVECPM and SYSGEN commands.


## Files

* bios.mac     - original MAP80 BIOS
* equ.mac      - original MAP80 BIOS includes
* cpm.sub      - original MAP80 BIOS rebuild script

* nbios.mac    - MAP80 BIOS with my mods, circa May 1986
* nequ.mac     - MAP80 BIOS with my mods, circa May 1986

* n4bios.mac   - MAP80 BIOS for NASCOM 4
* n4equ.mac    - MAP80 BIOS includes for NASCOM 4
* n4cpm.sub    - MAP80 BIOS rebuild script for NASCOM 4

* regen_build_disk - script to create BIOSDEV.DSK from BIOSDEV.DSK.ORIG and the n4 files


## Review of code changes

BIOS calls HOME, SELDSK, SETTRK, SETSEC, SETDMA, READ, WRITE, SCTRAN and
underlying routines are liable to need changes. DBOOT (used by warm boot) needs
to change if booting from SDcard. In addition, may need some additional
workspace.

Workspace:

24-bit start address of 16 consecutive 1MByte SDdisk (virtual disk images)
24-bit start address of currently-selected SDdisk
4-bit value of SDdisk associated with drive C
4-bit value of SDdisk associated with drive D .. etc.

HOME, SELDSK, SETTRK, SETSEC, SETDMA, SCTRAN need no change.

READ checks for RAMdisk and, if so, goes there (no deblocking). Otherwise goes
to ALLOC. Ends up in RWOPER, used for read and write.

RWOPER uses SECSHF which relies on CPMRPS (computing host sector) but this is
the same for both floppy types and for SDcard and so no change is needed.

Eventually calls RWHST, which does the hw operation based on floppy geometry;
HSTSEC, HSTTRK, HSTDSK, HSTDMA. It does a floppy vs winchester test - will add
in a test for SDdisk drive and JP to new code. This is the point at which the
SDcard offset can be calculated. From here, the code change is straightforward.

Can compute the 24-bit start address of the selected SDdisk: calculate and store

base + image_number*image_size (where image_size = 1024*1024/512 = 2048)

and also store the disk ID of the selected drive, so can easily decide whether
this needs to be recalculated or not. Do this in routine SHIFT or

WRITE checks for RAMdisk and, if so, goes there (no blocking). Can see that this
code is hard-wired to use a single floppy geometry: BLKSIZ, HSTSIZ, SPTF,
MAXTRK, CPMRPS are all taken from floppy parameters. Of these, the SPTF (sectors
per track) and MAXTRK differ between 48TPI drives and my SDdrive.

SPTF is used in DBOOT and used to calculate RPTF (records/host track floppy)

RPTF is used in WRITE code (just before GOTREC). This will need changing to
select between floppy and SDcard geometry. Eventually gets through to RWOPER,
common code for read and write.

MAXTRK is only used in SEEK and then only for 96TPI -- 96TPI drives can be
1-sided or 2-sided and somehow this code is coping with either.. ??don't quite
understand how, yet.

There is storage CPMDSK, CPMTRK, CPMSEC DMAADR set by BIOS calls, then HSTDSK,
HSTTRK, HSTSCT, HSTDMA used by the hardware r/w.


Summary of changes needed:

* Define workspace bytes
* DBOOT to reload system track on warm boot (but only after SDdisk is used for boot)
* Boot sector to load system track (but only after SDdisk is used for boot)
* Bootstrap for N4 menu (but only after SDdisk is used for boot)
* Option to make SDdisks first/bootable
* RWHST to test for SDdisk and JP to a new piece of code for read/write based on stored parameters
* GOTREC to select between floppy and SDdisk and calculate track wrap based on geometry
* Review SEEK to understand how MAXTRK is used and how side select works. Update notes above and delete this bullet.
* DON'T want to do anything on SELDSK because there could be buffered data to flush


NOTE: This is the work to co-exist with 48TPI drives. In order to co-exist with
96TPI drives, the SDdrive parameters will need to change to become more aligned
with 96TPI rather than 48TPI.


## Problems

1/ running script N4PT123.SUB which does the entire build (including MOVECPM and
SYSGEN) aborts the simulator with the message:

Halt instructions at address 0375

N4PT12.SUB (Which does all but MOVECPM and SYSGEN) works successfully.

(try this with instruction tracing enabled)


## Next

1/ DONE create blank sd disk image (1MByte of $E5)
2/ DONE test cpmdefs by writing/listing disk contents
3/ DONE modify BIOS to support 2 real disks and 2 SD disks, set up the geometry in the headers
4/ DONE build it in the emulator, and test using 2 magnetic and 2 SD image
5/ create new labels to fix NAC HACK in code
6/ DONE fix signon message where extra LF are present
7/ DONE extend .sub file to include the sysgen
8/ debug emulator problem with N4PT123
9/ change bios to actually read/write SDcard
10/ create sdcard image with the disk images present
11/ test on N4 hardware
12/ swap disk order so it boots from SDcard
13/ create utility to allow SD disk images to be selected



24-bit base address
+  disk id * disk size
+  track * track size
+  sector

..all in units of block size