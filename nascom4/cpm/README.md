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

The system track on the magnetic floppies is 2 tracks: 20*512 = 10Kbytes

With the proposed geometry, 2 tracks would be 32*512 = 16Kbytes; plenty of room
for the system track.

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
# NASCOM CP/M Pertec 35-track DS DD by Neal 18/7/21
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

# NASCOM 4 SD-card disk image by Neal 18/7/21
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

1/ copy the following files to P:

* M80.COM
* L80.COM
* N4BIOS.MAC
* N4EQU.MAC

(in the future, it would be better to do the copy (using PIP?) from the .SUB file)

2/ from A run N4CPM.SUB by issuing the command:

````
   SUB N4CPM
````


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


## Problems

1/ when the rebuild is done line-by-line it works successfully, but when done by
executing the .sub file the build fails (after the g500 step?) stopping the simulator
with the message:

Halt instructions at address 0375

(try repeating this process with instruction tracing enabled)

## Next

1/ DONE create blank sd disk image (1MByte of $E5)
2/ DONE test cpmdefs by writing/listing disk contents
3/ modify BIOS to support 2 real disks and 2 SD disks, set up the geometry in the headers
4/ build it in the emulator, and test using 2 magnetic and 2 SD image
5/ change bios to actually read/write SDcard
6/ create sdcard image with the disk images present
7/ test on N4 hardware
8/ swap disk order so it boots from SDcard
9/ create utility to allow SD disk images to be selected
