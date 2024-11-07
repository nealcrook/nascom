# PolyDos system disks

* PolyDos2.dsk is a system disk for a PolyDos 2 system.
* PolyDos3.dsk is a system disk for a PolyDos 3 system.
* PolyDos4.dsk is a system disk for a PolyDos 4 system.

## Disk capacities

PolyDos2 supports Gemini G809 (WD1797 FDC) 35-track double-sided single or
double-density 5 1/4" floppy drives with a sector size of 256 bytes, on Pertec
FD250 drives or equivalent. Single-density disks have 10 sectors (per side) per
track. Double-density disks have 18 sectors (per side) per track.

Therefore the storage capacity of a single-density disk is 35*2*10*256=179,200
bytes (175Kbytes) and the storage capacity of a double-density disk is
35*2*18*256=322,560 bytes (315Kbytes).

PolyDos3 supports NASCOM FDC (WD1793 FDC) 80-track single-sided double-density 5
1/4" floppy drives with a sector size of 256 bytes and 18 sectors per track, on
TEAC FD-50E drives or equivalent. Therefore the storage capacity of a disk is
80*1*18*256=368,640 bytes (360Kbytes).

PolyDos4 supports Gemini G809 (WD1797 FDC) with upto 4, 80-track single-sided
double-density 5 1/4" floppy drives with a sector size of 256 bytes and 18
sectors per track, on Micropolis 1015 drives or equivalent. Therefore the
storage capacity of a disk is 80*1*18*256=368,640 bytes (360Kbytes).


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

 PolyDos2       |   PolyDos3     |    PolyDos4      Comparison
----------------|----------------|----------------|-----------
BACKUP.GO       |   BACKUP.GO    |   BACKUP.GO    |    match
BSdr.BR         |   BSDR.BR      |   BSdr.BR      |    match
BSfh.OV         |   BSFH.OV      |   BSfh.OV      |    match
Dfun.OV         |   DFUN.OV      |   Dfun.OV      |    match
DUMP.GO         |   DUMP.GO      |   DUMP.GO      |    match
DUMPS.TX        |   DUMPS.TX     |   DUMPS.TX     |    match
Ecmd.OV         |   ECMD.OV      |   Ecmd.OV      |    match
Edit.OV         |   EDIT.OV      |   Edit.OV      |    differ 2!=3, 3==4
Emsg.OV         |   EMSG.OV      |   Emsg.OV      |    match
Exec.OV         |   EXEC.OV      |   Exec.OV      |    differ 2!=3!=4
FORMAT.GO       |   FORMAT.GO    |   FORMAT.GO    |    differ 2!=3!=4
Info.IN         |   INFO.IN      |   Info.IN      |    match
PD2S.TX         |   PD3S.TX      |   PD4S.TX      |    differ 2!=3!=4
PTXT.GO         |                |                |
PZAP.GO         |   PZAP.GO      |   PZAP.GO      |    match
SYSEQU.SY       |   SYSEQU.SY    |   SYSEQU.SY    |    match
SZAP.GO         |   SZAP.GO      |   SZAP.GO      |    match

The PolyDos2_files/, PolyDos3_files/ and PolyDos4_files directories each contain
files extracted from the associated disk image. The files are unmodified except
that the .TX files have been modified from the original Ctrl-M line endings to
have Ctrl-M/Ctrl-J (DOS-format) line endings.

The PolyDos disk structure (directory format, file format etc.) is documented in
the PolyDos system programmers guide, which is part of the .pdf bundle in ../doc


TODO why does polydos3 disk image not list correctly in polydos_vfs.. surely it used to??
also, inspecting that image suggests it has no PD3S.TX file but one is in the extracted
area.. how come? Inspecting the disk binary suggests it DOES have that image. Inspecting
the git history shows that I repaired the disk image at some point.. I may have actually
corrupted it further?!