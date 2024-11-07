# PolyDos

PolyDos was written for the NASCOM by Anders Hejlesberg. Anders wrote (29 April 2018):

> Hi Neal,
>
> First, absolutely feel free to share anything you have related to PolyDos or any of the other software I wrote for the NASCOM 2. I’d be delighted to see any or all of it in the public domain.
>
> I noticed that http://www.nascomhomepage.com/ already has copies of the PolyDos manuals. My, what a trip down memory lane it is to read those. Makes me long for the good old days when programming was a craft and it was all about fitting as much as possible into an impossibly small amount of memory.
>
>BTW, an interesting little historical fact is that PolyDos was heavily inspired by the operating system of the S-100 based machines from Polymorphic Systems (https://en.wikipedia.org/wiki/Polymorphic_Systems_(computers)). Our company, PolyData, for several years was the Danish distributor of their systems.
>
>Congrats on getting your old NASCOM 2 working again. I wish I had kept mine. That little machine probably taught me more about the basic principles of computers and programming than anything after it.
>
>Anders

## Versions

Polydos was available in four versions:

* GM515 PolyDos 1 for Nascom & GM805 using a WD1771 controller and 35-track disks (Pertec FD250) SD. Controller interfaced via the NASCOM's Z80-PIO.
* GM516 PolyDos 2 for Nascom & GM815 using a WD1797 controller and 35-track disks (Pertec FD250) DS; SD or DD.
* GM533 PolyDos 3 for Nascom & Lucas using a WD1793 controller and 80-track disks. SS; DD.
* GM534 PolyDos 4 for Nascom & GM809 using a WD1797 controller and 80-track disks (Micropolis 1015) SS; DD.

Each version requires a different ROM. The ROM code is slightly less than
2Kbytes, and was supplied in 2, 2708 parts assembled to be decoded at a start
address of $D000.

* The PolyDos 2 35-track double-sided single-density format used 2 sides of 35 tracks of 10 sectors of 256 bytes (175Kbytes/disk)
* The PolyDos 2 35-track double-sided double-density format used 2 sides of 35 tracks of 18 sectors of 256 bytes (315Kbytes/disk)
* The PolyDos 3 80-track single-sided double-density format used 1 side  of 80 tracks of 18 sectors of 256 bytes (360Kbytes/disk)
* The PolyDos 4 80-track single-sided double-density format used 1 side  of 80 tracks of 18 sectors of 256 bytes (360Kbytes/disk)

PolyDos uses linear block addressing, converted to tracks/sectors in the
ROM. Sectors are allocated starting from the first track and allocating both
sides before moving to the next track. The same format is used for the disk
images here.

## Material available here

* [boot-ROM (source and binary) for PolyDos 2/3/4](rom/README.md)
* [disk images for PolyDos 2/3/4](disk/README.md)
* [documentation set in PDF format](doc/README.md)
* [indexed library of software on PolyDos disk images](lib/README.md)

## Help Wanted

If you have a copy of PolyDos 1 or any other PolyDos-related
information, I'd love to see it; please get in touch.

If you have documentation for the PolyText word processing system, I'd love to
see it; please get in touch.

## Help Offered

If you want to run this code on your old NASCOM system but you need help burning
a ROM or getting it working, feel free to get in touch (raise an "Issue" through
github).


## PolyDos-related material elsewhere in this repository


In nascom/converters is a PERL program called polydos_vfs. This allows
manipulation of PolyDos disk images. It is highly capable and contains extensive
built-in help.

In nascom/converters is a PERL program called sy_extract. This can convert a
compiled symbol table file written by the PolyZap assembler so that it can be
used as an "include" file for the GNU Z80 assembler.

In nascom/sdcard is the design and control software for a NASCOM solid-state
disk. It uses an SDcard for storage and attaches to the NASCOM PIO. You can
throw away your floppy disks (and floppy disk controller) and still run PolyDos.



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


## PolyDos Gotchas

Maybe not bugs, but irritating behaviours..

You are in BASIC and developing a program, so you are saving
regularly, using the same name. Eventually, you hit the 50 files limit, and an error is reported:
directory is full. What to do?

First attempt:

Type MONITOR to get back to the $ prompt, then PURGE 0, then Z to warm-start BASIC.

This is broken in two ways:

# Although PURGE is a built-in that runs in the overlay area, it seems to use memory at 1000; at least, it corrupts the BASIC program so that Z does not warm-start BASIC
# When saving using the same name, the existing file is erased before the error message about directory entries is generated. Therefore, the PURGE deleted all copies of the program, and the inability to warm-start BASIC means that all copies are lost

Result: misery. The correct thing to do is simply to save to a different disk, and purge the first disk later.
