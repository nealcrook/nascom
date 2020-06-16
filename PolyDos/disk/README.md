# PolyDos system disks

* PolyDos2.dsk is a system disk for a PolyDos 2 system.
* PolyDos3.dsk is a system disk for a PolyDos 3 system.

## Disk capacities

PolyDos2 supports 35-track double-sided single or double-density 5 1/4" floppy
drives with a sector size of 256 bytes. Single-density disks have 10 sectors
(per side) per track. Double-density disks have 18 sectors (per side) per track.

Therefore the storage capacity of a single-density disk is 35*2*10*256=179,200
bytes (175Kbytes) and the storage capacity of a double-density disk is
35*2*18*256=322,560 bytes (315Kbytes).

PolyDos3 supports 80-track single-sided double-density 5 1/4" floppy drives with
a sector size of 256 bytes and 18 sectors per track. Therefore the storage
capacity of a disk is 80*1*18*256=368,640 bytes (360Kbytes).

(This information can be found in the USERS GUIDE or by inspecting comments in
the source code for the PolyDos ROMs, in particular the routine DSIZE).

## Disk Format

PolyDos treats a disk as a linear sequence of sectors, starting at address 0 and
continuing until the final sector of the disk. The disk size is hard-coded in
the PolyDos boot ROM and provided on demand through a SCAL, SCAL ZDSIZE.

The directory structure (sectors 0-3 on the disk) uses the same linear
addressing for sectors of the disk. The translation from linear addressing to
the disk's actual geometry (track/sector/side) is done by routines in the ROM.

As a result, the disk images here are effectively "geometry-free" -- the Nth
256-byte block (numbering from 0) of the image is the block that PolyDos
considers to be block N.

The disk images (at least, the PolyDos2.dsk image) was created by using PolyDos
routines to read each sector in turn. Therefore, the disk geometry was hidden
even from the disk image creation process.

However, based on the the documentation and some code inspection, it appears that:

* Tracks are numbered from 0
* Sectors are numbered from 0
* For double-sided drives, a track is considered to have 2x the number of sectors on each side with the low half of the sectors on side 0 of the disk and the high half of the sectors on side 1 of the disk.

These conclusions can be validated by inspecting the routine CNVSAD in the
source code for the PolyDos ROMs.

## File List

Here is a list of files present on each image. Most of the files are identical
between PolyDos 2 and PolyDos 3. The ROM source code and format program are
different, to accommodate the different disk controller/disk drive hardware.

 PolyDos2       |   PolyDos3     | Comparison
----------------|----------------|-----------
BACKUP.GO       |   BACKUP.GO    |    match
BSdr.BR         |   BSDR.BR      |    match
BSfh.OV         |   BSFH.OV      |    match
Dfun.OV         |   DFUN.OV      |    match
DUMP.GO         |   DUMP.GO      |    match
DUMPS.TX        |   DUMPS.TX     |    match
Ecmd.OV         |   ECMD.OV      |    match
Edit.OV         |   EDIT.OV      |    differ
Emsg.OV         |   EMSG.OV      |    match
Exec.OV         |   EXEC.OV      |    differ
FORMAT.GO       |   FORMAT.GO    |    differ
Info.IN         |   INFO.IN      |    match
PD2S.TX         |   PD3S.TX      |    differ
PTXT.GO         |                |
PZAP.GO         |   PZAP.GO      |    match
SYSEQU.SY       |   SYSEQU.SY    |    match
SZAP.GO         |   SZAP.GO      |    match

The PolyDos2_files/ and PolyDos3_files/ directories contain set of unmodified
files extracted from each disk image. In particular, "unmodified" means .TX
files retain the original Ctrl-M line endings.

The PolyDos disk structure (directory format, file format etc.) is documented in
the PolyDos system programmers guide, which is part of the .pdf bundle in ../doc
