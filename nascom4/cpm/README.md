# CP/M for NASCOM 4

CP/M 2.2 using the MAP80 BIOS will run on NASCOM 4 without modification, using
the FDC and either real floppy disk drives or GOTEK drives.

This code is a modified version of the MAP80 BIOS. The modifications allow the
NASCOM 4 SDcard to provide (virtual) disk storage. These drives can co-exist
with real floppy disk drives/GOTEK drives. The default configuration boots from
an SDcard drive and has 2 SDcard drives (A, B) and 2 real floppy disk drives (C,
D). One alternative is to swap the ordering, so that the system boots from
floppy.

All of the customisation of CP/M takes place within the BIOS. I started with the
source code provided by MAP80 systems.

## Getting Started - preparing the SDcard image

TODO

## Getting Started - booting from floppy

Put the image BIOSDEV2.DSK on floppy or GOTEK. It is a Pertec 35-track 48TPI image.

From the NASCOM 4 boot menu, select the letter associated with "MAP80 VFC
CP/M". The screen should re-sync and switch to 80-columns. The message "BOOTING"
should appear top-left, and almost immediately be replaced by the CP/M startup
screen.

The startup screen should announce that A, B are floppy disk drives and C, D are SD drives.

## Getting Started - booting from SDcard

Prepare the SDcard image as described above.

From the NASCOM 4 boot menu, select the letter associated with "MAP80 VFC
CP/M-LSD" (LSD = Local SDcard). The screen should re-sync and switch to
80-columns. The message "SDBOOT" should appear top-left, and almost immediately
be replaced by the CP/M startup screen.

The startup screen should announce that A, B are SD drives and C, D are floppy disk drives.

## How this version differs from one using floppy disks

There are 2 (virtual) drives (A, B or C, D) and 16 (virtual) disk images (0-9,
A-F). At boot time, drive A is associated with disk 0 and drive B is associated
with disk 1.

The utility SETDRV is used to associate a disk image with a drive. For example,
"SETDRV B 6" mounts disk image 6 on B.

If the system boots from an SD drive (ie, if drive A is an SD drive) then any
disk image mounted on A must be a system disk (various CP/M operations trigger a
re-load of the CCP, BDOS and BIOS from drive A and the system will hang if the
disk in drive A is not a system disk).

An disk can be made into a system disk by running the CP/M utility SYSGEN. The
system tracks are not available for any other purpose and so there is no
disadvantage to making every disk a system disk.

## Utilities

* SETDRV - utility to map drives to disk images
* HALT - execute 76H (halt). Useful in emulation to get back to the BIOS monitor but probably of no use on a real system
* WARM - execute a jump to 0 (CP/M warm start) - Can be used as a NOP command in a script.
* FAST - writes 0 to I/O port 1AH followed by jump to 0 to switch a NASCOM 4 to full-speed (0-wait) operation. Keyboard scanning will not work!
* SLOW - writes 20H to I/O port 1AH followed by jump to 0 to switch a NASCOM 4 to nominal 4MHz-equivalent speed operation.

There are 2 virtual drives (A, B or C, D) and 16 virtual disks (0-9, A-F). Type:

````
$ SETDRV n m
````
to associate drive n with disk m

Type:
````
$ SETDRV
````
to see a usage hint and a report of the current drive mappings.


# Disk Images

* BIOSDEV1.DSK - this started out as my "disk 26" which was scraped as NAS051.BIN. Its system track is a circa-1983
  BIOS build for my NASCOM with 48tpi pertec drives. The NASCOM4 BIOS sources and a few other files have been added
  (file list below). This image can be used as the starting-point to bootstrap the other two disk images (see
  bootstrap instructions below).
* BIOSDEV2.DSK - this started out as BIOSDEV1.DSK and the N4BIOS was rebuilt and sysgen'd onto the system track, so
  that the system track and the MOVECPM.COM image are the only differences from BIOSDEV2.DSK


# Bootstrap

Boot using BIOSDEV1.DSK. The n4equ.mac file has "SDBOOT F" (false). The system announces as "Neal's MAP 80 BIOS Version 2.1a"
with "Double sided 48 tpi drives on ABCD".

````
A>sub n4cpm                                       *** type this line

.
.
(xsub active)
A>SAVE 54 MOVECPM.COM
A>                                                *** press return to cause warm start
A>MOVECPM 62 *                                    *** type this line

Constructing 62k CP/M vers 2.2
Ready for "SYSGEN" or
"SAVE 47 CPM62.COM"
A>SYSGEN                                          *** type this line
SYSGEN VER 2.48
SOURCE Drive name (or RETURN to skip)             *** press return
DESTINATION Drive name (or RETURN to reboot)A     *** press A
DESTINATION on A, then type RETURN                *** press return
FUNCTION COMPLETE
DESTINATION Drive name (or RETURN to reboot)      *** press return

Wrong System/Size - Press any Key                 *** reset/reboot the system
````

After reset/reboot the system announces as "MAP 80 BIOS Version 2.1 01/10/83" with
"Double sided 48 tpi drives on AB" and "SDcard virtual drives on CD".

Edit n4equ.mac to change "SDBOOT T" (true). Replace the file on the disk image:

````
$ cpmrm -f nascom-pertec BIOSDEV1.DSK 0:n4equ.mac
$ cpmcp -f nascom-pertec BIOSDEV1.DSK n4equ.mac 0:n4equ.mac
````

The (modified) disk image is now identical to BIOSDEV2.DSK.

Now, boot using BIOSDEV2.DSK (or the modified BIOSDEV1.DSK), rebuild the BIOS
and sysgen it onto the SD drive:

````
A>sub n4cpm                                       *** type this line

.
.
(xsub active)
A>SAVE 54 MOVECPM.COM
A>                                                *** press return to cause warm start
A>MOVECPM 62 *                                    *** type this line

Constructing 62k CP/M vers 2.2
Ready for "SYSGEN" or
"SAVE 47 CPM62.COM"
A>SYSGEN                                          *** type this line
SYSGEN VER 2.48
SOURCE Drive name (or RETURN to skip)             *** press return
DESTINATION Drive name (or RETURN to reboot)C     *** press C
DESTINATION on A, then type RETURN                *** press return
FUNCTION COMPLETE
DESTINATION Drive name (or RETURN to reboot)      *** press return

A>DIR C:                                          *** type this line
C: SD0      TXT
A>PIP C:=A:*.*                                    *** type this line
.
.
A>
````

This leaves the new image on drive c: but the boot loader on this system track loads from SD etc. need to
boot it


- add cpmtools setup in this section




# Implementation notes

The goal: CP/M 2.2 using the MAP80 BIOS modified so that it supports real
(magnetic) floppies and also virtual floppies stored on the NASCOM 4 on-board
SDcard.

SDcard uses 24-bit linear block addressing, with each block being 512 bytes.

PolyDos supports 4 virtual drives and 16 virtual disks. Each virtual disk is
512Kbytes but each 256-byte PolyDos sector occupies 1 512-byte block (the second
half of the block is unused) so that each virtual disk occupies 1MByte on the
SDcard (2048 blocks, at offsets 0-0x7ff from some start address).

On the SDcard, blocks $0000-$03ff store the N4 boot menu and ROM images, so that
first PolyDos disk image starts at $0400 + (0 * $800) = $400 and the last starts
at $0400 + (15 * $800) = $7c00 and ends at $83ff.

Each CP/M disk could be 350Kbyte (like the Pertec) but I've chosen to make them
bigger: 1MByte. The CP/M sector size (512bytes) matches the SDcard block size
and so all of the block is used; so that each virtual disk occupies 1MByte on
the SDcard (2048 blocks, at offsets 0-0x7ff from some start address).

The first CP/M disk image starts at $0400 + $8000 + (0 * $800) = $8400 and the
last starts at $0400 + $8000 + (15 * $800) = $fc00 and ends at $1.03ff.

This shows that (unlike the PolyDos port) the driver will need to support 24-bit
addressing, in order to address the final virtual disk.

The geometry of the drive is chosen to make the track/sector -> linear
conversion straightforward. For example, 1024 * 1024 / 512 = 2048 sectors: 128
tracks at 16 sectors/track.

BUT the existing BIOS code has a SIDES equate that applies to all floppies so,
at least for the initial work where I'm pretending that the SDcard disk images
are accessed through the floppy disk controller, the easiest approach is to
pretend that the SDcard disk images are 2-sided to match the Pertec drives.

This affects the equates:
````
MXTKSD goes from 128 (single-sided) to 64 (double-sided)
MXSCSS goes from 16  (single-sided) to 32 (double-sided)
OFFSD  goes from 2   (single-sided) to  1 (double-sided)
````

.. but does NOT affect the disk images themselves, or the cpmtools setup, where
the sides are invisible.

In the BIOS, I intend to support 2 real drives (floppy or gotek) and 2 drives
that map to SDcard storage. The SDcard storage will support 16 disk images. At
boot, the first two disk images will be associated with the 2 SDcard drives. A
utility will be provided that maps either SDcard drive with any of the 16 disk
images. Also, there will be a script to extract disk images from the SDcard, and
a cpmtools setup that allows thes disk images to be created/listed/edited.

To map a disk image to an SDcard drive, can either store a disk id (4-bit value)
and hard-code the base address (that's what I did for PolyDos) or can store a
24-bit base address for each image.

I think, for the start, I'll just store the id, as for PolyDos - and maybe store
the base address in memory (rather than hard-coded) This means that the group of
disks could later sit inside a 16MByte unfragmented FAT32 file.

Required for initial debug:

* Script for generating blank floppies (simply full of $E5 bytes, like a
  newly-formatted disk)

* cpmtools disk definition to all files to be moved in and out of virtual SDcard
  disk images.


After initial debug:

* Create a utility to change the disk mappings, like the PolyDos one.

* Put the new system image onto the system track of the SDcard disk image and
switch the disk order so that A, B, are SDcard disks and C, D are the
magnetic floppies.

The system track on the magnetic floppies is both sides of 1 track: 2*10*512 =
10Kbytes. In the BIOS definition this counts as 1 (double-sided) track. In the
cpmtools definition it counts as 2 (single-sided, interleaved) tracks.

The proposed Sdcard image geometry is single-sided; both the BIOS and cpmtools
setup consider the track size to be 16 sectors; in both cases, need to reserve 2
system tracks (2*16*512 = 16Kbytes). The Pertec configuration reserved 10Kbytes
and used nearly all of it, so 8Kbytes would not be enough.

Q: are the blocking/unblocking routines portable (for different geometrys)
provided that the physical sector size is constant (which it is: 512 bytes)

Q: what is CP/M text file format? Why does nbios.mac file appear with ^M at the
end of each line but bios.mac does not? Must be a corruption somewhere in the
nbios.mac - both files have 0d/0a line endings; bios.mac is interpreted by emacs
as a DOS file. Seems to have been something to do with the ^Z at the end of
file?

## CPMTOOLS setup

I added these 2 entries to /etc/cpmtools/diskdefs:

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
this needs to be recalculated or not. Do this in routine SHIFT?

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
* DON'T want to do anything on SELDSK because there could be buffered data to flush
* MAY need to do something around CLEAN and TRACK0 (CLEAN might get called when it's not needed; TRACK0 initialises the track map, but TRACK0 is not being called by SDcard code.


NOTE: This is the work to co-exist with 48TPI drives. In order to co-exist with
96TPI drives, the SDdrive parameters will need to change to become more aligned
with 96TPI rather than 48TPI.


## Creating the SDcard image

For now, I simply added 2 disk images to the end of the SDcard image prepared for the PolyDos port

````
$ cp ../PolyDos/nascom4_sdcard_bp.img .
$ cat nascom4_sdcard_bp.img SD0.DSK SD1.DSK > xx
$ mv xx nascom4_sdcard_bp.img
````

## Problem: Cannot do entire build from XSUB

Running script N4PT123.SUB which does the entire build (including MOVECPM and
SYSGEN) aborts the simulator with a "Synchronization error" during the MOVECPM
step.

This error is an assertion that the serial number of the running system does not
match the serial number in the MOVECPM image.

When running final step by hand (MOVECPM followed by SYSGEN) no sync error occurs.

With sync error:

````
0000 C3 2F D0 D5 00 C3 06 D0  C/PU.C.P
0008 76 76 76 76 76 76 76 76  vvvvvvvv

0373 F3 76 00 D0 0D 0A 43 6F  sv.P..Co
037B 6E 73 74 72 75 63 74 69  nstructi
````

.. a HALT instruction has been written to 374

without sync error:

````
0000 C3 03 E8 D5 00 C3 06 DA  C.hU.C.Z
0008 76 76 76 76 76 76 76 76  vvvvvvvv

0373 20 6F 6E 20 5A 2C 20 74   on Z, t
037B 68 65 6E 20 74 79 70 65  hen type
````

The "06 D0/06 DA" is the BDOS entry point. When running without XSUB the BDOS
entry point is DA06h. When XSUB is run it installs itself by fiddling with the
vector in low memory, redirecting it to XSUB in high memory below the CCP. CCP
is 0800h in size so if XSUB were 200h it would explain why the BDOS address
(when XSUB is running) changes from DA00 to D000.

By HALTing the system while it's running the XSUB script, memory examination
shows that the BDOS is at D006 -- ie, the apparent BDOS intercept.

So, now the question is: why does MOVECPM fail when running from XSUB. Neither
MOVECPM nor SYSGEN mess with the O/S image that's currently in use and so they
should not interfere with the high memory map.

Also.. why was this intermittent with the emulator and does it happen on the
real system now (it apparently didn't "back in the day"??)

By comparing an instruction trace on passing and failing system and from
examination of the original XSUB and MOVCPM source codes, the mystery is
explained..

It's reading the serial number from the start of the BDOS in the created image
and expecting to find the same serial number in the running image's BDOS, but
when it thinks it's looking in the running image's BDOS it's actually looking in
the XSUB BDOS replacement, so there is no serial number there.

..that suggests it could NEVER have worked even on the original system..

(If XSUB had been a bit smarter it could have (also) have included space for the
serial number and copied it from the BDOS as it installed. OR, if MOVECPM had
been a bit smarter it could have recognised the XSUB double-jump..)

When the code fails it gets to label BADSER0. The locations at SER1 (0373h) are
loaded with 76F3h (op-code sequence DI HALT) then location at 0370h is changed
from C3h (JP) to CDh (CALL) so that:

* normal behaviour: PRINT contains a JP to BDOS and the BDOS return returns to
  the caller of PRINT
* modified behaviour: PRINT contains a CALL to BDOS and the BDOS return returns
  to the code immediately following the PRINT, which has been set up to contain
  the DI HALT sequence

As the original source code intimates, this is all deliberately obfuscated to
prevent reverse-engineering even on a development system.


## Next

1/ DONE create blank sd disk image (1MByte of $E5)
2/ DONE test cpmdefs by writing/listing disk contents
3/ DONE modify BIOS to support 2 real disks and 2 SD disks, set up the geometry in the headers
4/ DONE build it in the emulator, and test using 2 magnetic and 2 SD image
5/ DONE create new labels to fix NAC HACK in code
6/ DONE fix signon message where extra LF are present
7/ DONE extend .sub file to include the sysgen
8/ DONE debug emulator problem with N4PT123
9/ DONE change bios to actually read/write SDcard
10/ DONE create sdcard image with the disk images present
11/ support multiple disk images
12/ write SDcard boot sector loader
13/ swap disk order so it boots from SDcard
14/ test on N4 hardware
15/ create utility to allow SD disk images to be selected
16/ tidy up all the scripts and check them in

## Forming the SDcard block address

This is the conversion from track/sector/side to linear addressing.

````
2 2 2 2 1 1 1 1 1 1 1 1 1 1
3 2 1 0.9 8 7 6.5 4 3 2.1 0 9 8.7 6 5 4.3 2 1 0
                1 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 Base address $8400
                  x x x x                       4-bit disk ID (0-15)
                          x x x x x x           6-bit track (0-63)
                                      x x x x x 5-bit sector (0-31)

                ^ ^ ^ ^ ^ ^---------- this is the only place that a wrap can occur.
                                      the low byte can be formed by ORing.
````

## Build process

````
$ ./regen_build_disk

(start up CP/M using that disk)

A>sub n4pt12

A>
A>movecpm 62 *
````

.. you need to press <CR> to get the 2nd A> prompt. The system does a warm-start
between the first and second A> prompt, unloading XSUB. Without the <CR>,
movecpm will generate a SYNCHRONIZATION ERROR due to XSUB being chained through
the BDOS entry point (see long description above).

reboot, and continue (using the movecpm.com that had been generated before)

````
A>movecpm 62 *
.
.
A>sysgen

a

Wrong System/Size - Press any Key
````

.. but, reboot and the system starts up correctly, with the new BIOS. Run
MOVECPM and SYSGEN on this system and it all completes without error. I suppose
that means I need to disassemble/undestand SYSGEN next.. (actually - the DR
SYSGEN sources are in the cpm2-plm bundle, but SYSGEN is somewhat
system-specific because it encodes the disk geometry).

..that error message is not part of SYSGEN but is part of the BIOS. Is it
printed from the running image or from the new image? Would need to patch the
system to find out.. How does that come to get used/printed? It is an error
message printed by the warm start code... presumably of the running system.

-> would definitely be useful to add some tracing of BDOS and BIOS entry, and to
add the capability to break on particular locations.

-> or could just grab a trace and work backwards from the message.

..claims to be a warm start: re-reading CCP and BDOS without BIOS (presumably
that's only possible if the BIOS is the same size as it used to be?? Or, at
least the same number of sectors.




After MOVECPM has run, the relocated system is in memory at 900h - the system
track contents, including the boot sector. That allows a *small* program (eg,
SYSGEN) to be loaded and to execute without messing up the image. SYSGEN can
read a system track into memory, which is loaded at 900h.




TODO edit the "original" disk to add pip and the .com files that I created (and document them here??)
TODO clean up the number of disk files/images that I created and rationalise the names, and clean up the associated scripts and instructions




1. primary boot loader code to replace blob in MAP80VFC ROM, and a script to hack it into
the existing binary (to save the need to disassemble/reassemble the whole thing)

- my ROM and David's ROMs are different, and have the boot code at different
places. The boot code itself is different/different sizes. The new boot code
(from SDcard) is identical for both ROM versions.

-> DONE (and working)


2. boot sector code

-> DONE (and working)


3. option to put the SDcard drives first

-> DONE (and working)



## Bootstrap

* start from clean floppy image
* (boot from floppy)
* build BIOS with SDcard support and SDCARD set to F (FALSE)
* SYSGEN the new image onto floppy -- drive A
* reboot from floppy and ensure SDcard is accessible

then

* edit n4equ.mac to change SDBOOT to T (TRUE)
* update the existing boot disk with the new n4equ.mac file:

````
$ cpmrm -f nascom-pertec BIOSDEV2.DSK 0:n4equ.mac
$ cpmcp -f nascom-pertec BIOSDEV2.DSK n4equ.mac 0:n4equ.mac
````

* (boot from floppy)
* build BIOS -- has SDcard support and SDCARD set to T (TRUE)
* SYSGEN the new image onto SDcard -- drive C
* change map80vfc ROM to load bootstrap from SDcard
* reboot and ensure SDcard is accessible and that drives A, B are SDcard and C, D are floppy

Works!! Now, with map80nascom emulator, 1st floppy (file) is 1st floppy drive: drive C.



next..

how to select disks..

could store a 4-bit code for each disk, the DISK_ID

$84 for drive 0  $a4         $c4       $e4
$8c              $ac         $cc       $ec
$94              $b4         $d4       $f4
$9c              $bc         $dc       $fc for drive f


can incorporate the base address and disk ID into a single byte:  nice! but how to find the location from the SETDRV utility?

can find BDOS but want to distinguish when XRUN is in progress

.. Added 4 bytes to the BIOS workspace. Can find it at a fixed offset from the start
of the BIOS.


Next: clean up the scripts, build full set of disks, store a lump of SDimage
here that is CP/M and lump of SDimage in polydos that is polydos, with tools to
combine and split them? Add "standard" boot disk, Add the VFC ROM to the boot
menu

Problem: how to bootstrap load the new system on N4 hardware? Currently, the VFC
ROM image is baked into the FPGA and cannot be changed. I could create a
stand-alone boot loader (defeating the object of my patched ROM) and load it in
high memory, start it up and have it do all the init -- including calling the
initialisation routine in the ROM. Put it at f000 where the video memory will
eventually be located and it should be invisible and leave no footprint.


... change make_blank_sd_floppy to make all 16 and to put a unique image on each
as a "fingerprint" -> make_blank_sd_floppy_set

... want script for inserting/removing SDcard images and Polydos images

SD0.DSK .. SDF.DSK


change disks_from_image to use parameter that names the img file.

-> maybe not; use the other script instead.

-> move more scripts to tools/ and rationalise - use sdcard_editor where possible
-> create boot ROM
-> update docs
-> tidy up this README.md file
-> rework the bootstrap section and rebuild biosdev2.dsk image now I've renamed setdrv.com