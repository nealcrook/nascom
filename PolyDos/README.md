# PolyDos

There is material here (ROM, disk images and documentation) for PolyDos 2 and PolyDos 3.

## Versions

Polydos was available in four versions:

* GM515 PolyDos 1 for Nascom & GM805 using a WD1771 controller and 35-track disks (Pertec FD250) SD. Controller interfaced via the NASCOM's Z80-PIO.
* GM516 PolyDos 2 for Nascom & GM815 using a WD1797 controller and 35-track disks (Pertec FD250) DS; SD or DD
* GM533 PolyDos 3 for Nascom & Lucas using a WD1793 controller and 80-track disks. SS. DD.
* GM534 PolyDos 4 for Nascom & GM825 using a ?????? controller and 80-track disks. SS or DS?; DD or QD?

Each version requires a different ROM. The ROM code is slightly less than
2Kbytes, and was supplied in 2, 2708 parts assembled to be decoded at a start
address of $D000.

* The PolyDos 2 35-track double-sided single-density format used 2 sides of 35 tracks of 10 sectors of 256 bytes (175Kbytes/disk)
* The PolyDos 2 35-track double-sided double-density format used 2 sides of 35 tracks of 18 sectors of 256 bytes (315Kbytes/disk)
* The PolyDos 3 80-track ??

PolyDos uses linear block addressing, converted to tracks/sectors in the
ROM. Sectors are allocated starting from the first track and allocating both
sides before moving to the next track. The same format is used for the disk
images here.

The disk structure (directory format, file format etc.) is documented in the
PolyDos system programmers guide, which is part of the .pdf bundle here.


## PolyDos-related material elsewhere

* 80-Bus News, Volume 1 issue 1, "BLS Pascal = NASCOM Pascal" a letter from Anders Hejlsberg, author of PolyDos (and BLS Pascal).

* 80-Bus News, Volume 1 issue 1, "Review of PolyDos disk operating system"

* 80-Bus News, Volume 1 issue 2, "PolyDos 2.0 DUMP utility" by Anders Hejlsberg - also provided as part of the PolyDos distribution disk.

* 80-Bus News, Volume 1 issue 2, MicroValue advert includes PolyDos (1 and 2)

* 80-Bus News, Volume 2 issue 2, "Lawrence and PolyDos"

* 80-Bus News, Volume 2 issue 2, Amersham Computer Centre advert includes PolyDos (all 4 versions) and Polytext Text Editor.

* 80-Bus News, Volume 2 issue 4, "Re. COMPAS Review" a letter from Anders Hejlsberg, author of PolyDos (and COMPAS).

* 80-Bus News, Volume 3 issue 2, "NASPEN for PolyDos" describes code modifications for the ROM-based NASPEN word-processor to allow it to work nicely with PolyDos. The code modifications include an overlay that acts as a file-handler for files with a .NP extension.

* 80-Bus News, Volume 3 issue 5, "System routines in PolyDos and PolyDos Disk Basic" is a cross-reference of how some of the NAS-SYS vectors are used in different operating modes.

* 80-Bus News, Volume 3 issue 5, "PolyDos File Name Listing" is a program to build a unified file index by examining the directories on a set of disks.

* 80-Bus News, Volume 3 issue 6, "Lawrence and the PolyDos User Group"




