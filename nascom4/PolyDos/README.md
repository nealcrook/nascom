# PolyDos for NASCOM 4

The original versions of PolyDos will run on NASCOM 4 without modification,
using the FDC and either real floppy disk drives or GOTEK drives.

The nascom_sdcard version of PolyDos will run on NASCOM 4, with the
nascom_sdcard connected to the PIO.

This code is (yet another) version of PolyDos; this time, to use the SDcard on
the NASCOM 4. Therefore, it will run on a "Stage 2" build of NASCOM 4, without
the need for PIO or FDC.

All of the customisation of PolyDos takes place within its boot ROM. Boot ROMs
are loaded using the NASCOM 4 menu system.

TODO:

* New utilities


## Getting Started


## How this version differs from one using floppy disks


## Adding disk images to the SDcard

Create a 2048-sector disk image using polydos_vfs:

$ ../../converters/polydos_vfs
polydos_vfs: new pd0.dsk s=2048
polydos_vfs: mount 0 pd0.dsk
polydos_vfs: name 0 PD0 System for N4
polydos_vfs: mount 1 ../../PolyDos/lib/PD000.BIN
polydos_vfs: copy *.*:1 0
polydos_vfs: exit

Pad each sector to 512 bytes:

$ ../../converters/pad256to512 pd0.dsk pd0.dsk_padded

Later might want to convert back:

$ ../../converters/unpad512to256 pad0.dsk_padded pd0.dsk_back

Pad the menu part of the SDcard image to 0x800 blocks and add this new image on the end:

$ cp ../tools/nascom4_sdcard.img xx.img
$ dd if=pd0.dsk_padded of=xx.img bs=512K seek=1

now xx.img is 1572864bytes (3072 sectors = 0xc00 sectors; 0x400 sectors for the
menu system and 0x800 sectors for the disk image).

## Utilities

SETDRV utility to map drives to drive slots (new version)
CASDSK to intercept tape read/write commands (same version as for nascom_sdcard)
SCRAPE (new version that stores to internal SDcard)


## Working with PolyDos disk images

Overview:

* Use ../../converters/polydos_vfs to create/manipulate 16 disk images, pd0.dsk..pdf.dsk
* Use make_full_sdcard_image to create a disk image for the NASCOM4 sdcard
* Later, use image_from_sdcard to pull a modified image off the card, and dsks_from_image to extract pd0_from.dsk..pdf_from.dsk from the image
* Copy some/all of pdX_from.dsk to pdX.dsk and re-run make_full_sdcard_image to create a revised disk image for the NASCOM4 sdcard

### Script: mkdsk.scr

Script for polydos_vfs to create a set of empty disk images. Probably never need to run this again.

### Script: make_full_sdcard_image

Creates an image, nascom4_sdcard_bp.img, containing the nascom4 boot menu (built in ../tools by
running make_sdcard_image to create nascom4_sdcard.img and including the PolyDos
ROM which is built here, first) and a set of 16 disk images which start out as
the files pd0.dsk..pdf.dsk here.

(_bp stands for: boot, polydos)

The image is suitable to be dd'd onto an SDcard.

### Script: image_from_sdcard

Reads a sdcard to extract the file nascom4_sdcard_bp_from.img which should be
exactly the same size as nascom4_sdcard_bp.img and contain all the same stuff
but will have been changed by any PolyDos write/delete operations to the disk
images.

### Script: dsks_from_img

Given an image file, typically nascom4_sdcard_bp.img, extract 16 files representing the PolyDos disk images and unpack them
as pd0_from.dsk.. pdf_from.dsk

Each disk image is 2048 blocks (1024Kbytes) before unpacking, 1024 (512Kbytes) after.


## Other PolyDos resources


## Appendix: Design Decisions

16 disk slots, each 512Kbytes

sdcard image for the menu system is 79360 bytes = 0x13600 = 0x9b blocks

Polydos uses linear block addressing and uses 16-bit values for sector address
and number of sectors.

Each PolyDos sector is 256 bytes so the maximum disk size is 2^16 * 256 =
16Mbytes but the directory size limits the number of files on a disk so there is
no point making the disk over-large.

I'm going to set the disk size to 512Kbytes ie 2048 sectors.

To avoid having to pack 256-byte PolyDos sectors into 512byte SDcard sectors
(read/modify/write cycles) each Polydos sector uses the first half of an SDcard
sector. The remainder of the SDcard sector is filled with 0. This makes the
implementation simpler. Each disk image (512Kbytes of space from within PolyDos)
occupies 1Mbyte on the SDcard (2028 sectors, at offsets 0-0x7ff from some start
address).

The SDcard uses 24-bit addressing but PolyDos sets the top 8 bits to 0 and so
restricts itself to accessing the first 2^16 * 512 = 32MBytes: all of the disk
images have to fit within the first 32MBytes of the SDcard image.

Say I allow 16 images and allow 4 to be assigned to drives 0-3. Start
with the first 4 assigned and allow that to be changed using the SETDRV
utility.

If the images are stored contiguously, the ROM needs to know the start block of
the first image, and need workspace in which to store the start block of
each of the currently-selected images.

If the images are aligned, so that they start at block 0x0800, 0x1000, 0x1800
etc. only need 4 bits for each image; 2 bytes in total.. or store a
start block (16 bits) and 4x4 bits (32 bits)

The ROM needs to know the start block else the system can't boot. Put it in the
ROM (in a location that won't change, so that it can be patched) or in in a
well-known immovable location elsewhere in the SDcard - eg, with the menus;
there is space there.

The 4x4 bits needs to be stored in the running system. Where can I steal 16 bits
of workspace? There are 6 bytes of DSKWSP assigned - used as a data buffer for
the "read address" command: track, side, sector, length, crc1, crc2. This is
used to check that a disk is present after selecting a drive; we don't need
it so can happily use this space without conflict. There are a further 64 bytes
of unused workspace.

translation from drive to start address:

disk images start at $400, each disk image is $800 in size


$0400 + $0000 drive 0
$0400 + $0800       1
$0400 + $1000 2
$0400 + $1800 3
$0400 + $2000 4
$0400 + $2800 5
$0400 + $3000 6
$0400 + $3800 7
$0400 + $4000 8
$0400 + $4800 9
$0400 + $5000 a
$0400 + $5800 b
$0400 + $6000 c
$0400 + $6800 d
$0400 + $7000 e
$0400 + $7800 f

so, just store the high byte in first 4 bytes of DSKWSP, then can have a utility to report it and change it (which will need to go from offset to slot)

or, more portable to store values 0-f in DSKWSP and convert to block number:

* left-shift by 3
* add the base

sla a
sla a
sla a
