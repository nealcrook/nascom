# Files pertinent to the MAP80 Video/Floppy Controller

* map80_vfc_boot_rom.bin -- 2kbyte image for the on-board boot EPROM (version AW1.11)
* map80_vfc_boot_rom_newver.bin -- 2kbyte image for the on-board boot EPROM (version ASW2.01)
* map80_vfc_chargen_rom.bin -- 4kbyte image for the character generator EPROM.
* NAS051.BIN -- CP/M boot disk supporting MAP80 VFC and RAM boards with NASCOM CPU
* NAS053.BIN -- CP/M boot disk supporting MAP80 VFC and RAM boards with NASCOM CPU

Each disk is 35 tracks * 10 sectors * 2 sides * 512 bytes = 350Kb (358400bytes)


# Boot process on NASCOM with MAP80 VFC

## Files supplied by MAP80 Systems

* BIOSMAN.TXT -- original manual from MAP80
* MOVCPM.COM  -- original master from DRI - do not use; not configured for the MAP80 system.
* CPM.SYS -- configured by MAP80; bare CP/M with relocating bit-map and movecpm configuration routine but NO BIOS.
* MOVECPM.COM -- configured by MAP80 (generated from cpm.sys)
* CPM.SUB -- script to rebuild BIOS from source (see section below)
* MU.COM -- "map80 utilities" for format/copy/verify. Will do disk-disk copy on single-disk systems.
* SYSGEN.COM  -- from DRI. Used to make a disk bootable, by writing the system track.
  The write data can come from memory (after MOVECPM) or by reading the system track from another disk.
  No files are copied/changed. Space is always reserved for a system track, whether or not the disk
  actually contains valid data there.

VFC-based system leaves the video RAM enabled at F800 and so the maximum
system size is 62K. Notes in biosman.txt describe how to create a 64K system.

## ROM Bootstrap

When appropriately configured, the VFC ROM appears at address 0 and provides a
bootstrap loader for CP/M. This is the only part of the ROM that is not
relocatable code.

The function of the bootstrap loader is to load track 0 sector 0 from drive A
into memory at 0C00H using the 2797 FDC, then to jump to 0C02H.

The first 2 bytes of the image are expected to be the "magic number" 3038H.
Without these, it's assumed not to contain a system track and the message
"SYSTEM?" is displayed. These are the messages that can be displayed:

BOOTING          - initial message
DISK ??          - error: no disk
SYSTEM?          - error: not a system disk
ERROR ?          - error: read error

## Boot sector (track 0 sector 0)

The source code for the boot sector is in the bios.mac file, and it is built in
the dseg (more below). Conditional assembly controlled by the BIOS configuration
creates boot code specific to the system hardware/disks. In this case it is
coded for a disk that is 35 tracks * 10 sectors * 2 sides * 512 bytes = 350Kb.

The boot sector is 512 bytes so the code is restricted to this size, but is tiny
(75 bytes) and padded to the sector size with 0.

The boot sector loads the CP/M image from the system track(s) and then executes
it at an offset of an offset of 1600H from its load address -- ie, D200H + 1600H
= E800H which corresponds to the start of the BIOS and is the "JMP BOOT"
cold-start vector.

CP/M reserves a whole numbers of tracks as system tracks (and this must be known
to the format program). This configuration reserves 1 track (20 sectors) of
which 1 is reserved for the boot sector.

A rebuild of the BIOS leads to the creation of a custom MOVECPM.COM program
which can be used to create images for systems of different memory
sizes. Execution of MOVECPM patches the boot sector code to change the load
address from D200H depending upon the system memory map (MOVECPM also patches
the CCP/BDOS/BIOS code).

The size of the CP/M image (CCP + BDOS + BIOS) is dependent upon the BIOS
configuration options. The total size is known at the time that the BIOS/boot
sector is built, and so the number of sectors that the boot sector must load it
coded into the boot sector code. In this example, it loads 18 sectors (of a
possible maximum of 19).

## DRI CP/M 2.2 distribution image

The system tracks of the distribution are:

BSECT 1 sector  of 128 bytes = 0080H 128 bytes
CCP  16 sectors of 128 bytes = 0800H 2048 bytes (2Kbytes)
BDOS 28 sectors of 128 bytes = 0E00H 3584 bytes (3.5Kbytes)
BIOS  7 sectors of 128 bytes =  896 bytes
-------
     52 sectors

For the MAP80 system, the sector size is 512 bytes. The size of the CCP and BDOS
is unchanged; the BIOS is bigger (approximately 3.5Kbytes)

The system track is therefore: 512 + 2048 + 3584 + 3560 = 18.9 sectors (17.9
excluding the boot sector)


## The system track (contents)

map80_cpm22_sys.bin/.txt/.asm is the system track - with the boot sector
removed, so it is 512*18 = 9216bytes. In memory (loaded at D200H) it looks like
this:

````
F800H Start of VFC RAM
F600H Start of 512byte space ?disk buffer?
F5FFH last location in system track           } system
E800H BIOS (starts with 17-entry jump table)  } track
DA00H BDOS (starts "ret z")                   } in
D200H CCP                                     } memory
D1FFH end of TPA
0100H start of TPA
0000H start of workspace
````

CPM.SYS should contain a relocator program, a bitmap of relocations
and golden CCP and BDOS images.

The build process below seems to *create* MOVECPM.COM?? My MOVECPM.COM image
seems to start like CPM.SYS and include the system track including BIOS, with
more stuff on the end (though it's possibly junk) That name is really
confusing..

MOVCPM.COM (not MOVECPM.COM) is the system relocator. Used for??


# Notes on MOVCPM

(from https://www.vcfed.org/forum/forum/genres/cp-m-and-mp-m/49136-how-does-movcpm-com-work)

Mike wrote:

MOVCPM.COM contains three primary sections:

* executable code for the program,
* an image of CP/M
* a relocation bitmap.

For example, the table below documents how MOVCPM.COM for Altair CP/M 2.2 is
laid out. Note that CP/M for a different machine may have a different bootloader
size and/or BIOS size, and therefore, a slightly different layout within the
file.

Offset in File 	In Memory 	Content
========================================
0000h           0100h           CPMOVE (code that “does” MOVCPM)
0701h-0702h     0801h-0802h     Length of “MODULE” (Bootloader + CCP + BDOS + BIOS)
0800h-087fh     0900h-097fh     Bootloader (1st 128 bytes)
0900h-097fh     0a00h-0a7fh     Bootloader (2nd 128 bytes)
0980h           0a80h           Start of CCP
1180h           1280h           Start of BDOS
1f80h           2080h           Start of BIOS
2580h           2680h           Start of relocation bitmap


MAP80 provided an original MOVCPM.COM and a customised version, MOVECPM.COM
along with a created by the BIOS build process (not MOVCPM) looks like this:

Offset in File 	In Memory 	Content
========================================
0000h           0100h           CPMOVE (code that “does” MOVCPM)
07feh-07ffh                     1eebh Length of “MODULE” (Bootloader + CCP + BDOS + BIOS)
0800h-09ffh                     Bootloader (512 bytes)
0a00h           0a80h           Start of CCP - matches start of map80_cpm22_sys.bin
                                and offset a00 of CPM.SYS
1200h                           Start of BDOS (looks correct)
2000h                           Start of BIOS (looks correct; but CPM.SYS does not match; it does not
                                contain a BIOS?)
26ebh                           Start of relocation bitmap?? Doesn't seem correct; looks like that
                                starts at 2e50?


The "Module" portion of MOVCPM (when MOVCPM is in memory) is the CP/M image
written by SYSGEN to the boot tracks of the disk. In this case, the module runs
from 900h to 267Fh. This puts the CP/M image in the same location and format as
the SYSGEN program expects. Again, the starting address may vary slightly (e.g.,
980h - A80h) and the length will vary based on the size of the BIOS for your
particular CP/M.

The relocation bitmap has one bit corresponding to each byte in the module. If a
bit is set, the corresponding byte must be updated based on where in memory CP/M
is placed

In order to work with this relocation scheme, the CP/M image must be assembled
so that the CCP starts at address 0000h. This leaves the BDOS starting at
address 0800h and the BIOS starting at address 1600h. The bootloader is always
assembled at address zero, however, relocation of the bootloader is still
required as it references addresses corresponding to the final location of CP/M
in memory. This CP/M image (the one assembled with the CCP starting at address
zero) is the image in the module section of the file.

The bytes that must be relocated can be determined by assembling CP/M at two
different addresses. The bytes that differ between the two object files are
those bytes that must be updated for relocation. I have written a utility that
runs on a PC and generates the bitmap for me. I then use a hex editor to patch
the bitmap into the MOVCPM.COM file.


# Notes on CP/M rebuild

The MAP80 script "cpm.sub" to rebuild the BIOS and system:

XSUB                                           -- XSUB loads and relocates directly below CCP. When it is present
                                               -- in a submit file, it allows programs referenced by the file
                                               -- to accept input from the file -- in this case, the sysgen
                                               -- program accepts input from the submit file.
ERA P:*.BAK                                    -- clean up/make space on RAM-disk P
P:M80 =P:NBIOS                                 -- assemble the BIOS source
ERA P:M80.COM                                  -- make space on P by deleting the assembler
P:L80 /D:13F8,/P:1600,P:H1/N/X,P:NBIOS/E       -- link to make H1.HEX program origin 1600, data origin 13F8
P:L80 /D:33F8,/P:3600,P:H2/N/X,P:NBIOS/E       -- link to make H2.HEX program origin 3600, data origin 33F8
                                               -- the data area is 8 bytes + 512 of boot sector code so the
                                               -- code follows on straight after the data.
                                               -- L80 is used to link the two .HEX files for execution at two
                                               -- different addresses a multiple of 256 bytes apart. These are
                                               -- then loaded and the program executed by G500
                                               -- compares the two images and generates the relocation information.
                                               -- Thus movcpm can relocate cpm and the bios to the required address.
ZSID CPM.SYS                                   -- CPM.SYS is the golden version? on drive A?
IP:H1.HEX                                      -- set up code/symbol file for reading H1.HEX from P:
R3C00                                          -- read in file at offset $3C00
IP:H2.HEX                                      -- set up code/symbol file for reading H1.HEX from P:
R3C00                                          -- read in file at offset $3C00
                                               -- because they were linked at different addresses the same
                                               -- offset means they are loaded at different addresses
G500                                           -- execute at $500 (code in CPM.SYS) and exit ZSID
SAVE 54 MOVECPM.COM                            -- (now back at the prompt) Save new memory image as MOVECPM.COM
                                               -- not to be confused with utility program MOVCPM.COM
ERA P:*.?E?                                    -- clean up/make space on P
MOVECPM 62 *                                   -- put it in place as a 62Kbyte CP/M system, do not execute it
SYSGEN                                         -- copy it to the system track
                                               -- CR => take it from memory
A                                              -- A => write it to drive A
                                               -- CR => ??
                                               -- CR => ??


Q: How do M80 and L80 get onto P in the first place?

The BIOS itself starts with the sector0 code that is the secondary bootstrap loader
(the primary boostrap loader is in the VFC ROM).

The image map80_cpm22_sys.bin is the code (excluding that boostrap loader) from
track 0 of the disk. The bootstrap loader loads that code at $D200 and enters it
at $E800.

Image contains CCP, BDOS, BIOS bolted together in that order

TODO: dissect that build script and document it, including descriptions of
CPM.SYS MOVCPM.COM SYSGEN etc.


# Output from build process

using NAS051.img

copy all the files to P:

nswp
press 't' repeatedly to tag all the files
press 'm' for mass copy
p: <return>
x

change to P and run the commands from cpm.sub one by one..

P>m80 =nbios

"Initialised size 0DE6 Uninitialised size 0F8E USER 0"

No Fatal error(s)

P>l80 /d:...

Data    13F8 1600   <  520>
Program 1600 23E8   < 3560>

40469 bytes free
[0000   1600   35]

P>l80 /d...

Data    33F8 3600   <  520>
Program 3600 43E8   < 3560>

40469 bytes free
[0000   1600   35]

zsid.. after invocation

NEXT  PC  END
2400 0100 B7FF

zsid.. after first read

NEXT  PC  END
5FE7 0100 B7FF

after second read

NEXT  PC  END
7FE7 0100 B7FF


in zsid..

l5200 shows that BIOS is in memory at 5200:

JP 2188
JP 16DD

l7200 shows another copy of the BIOS in memory at 7200:

JP 4188
JP 36DD

d4ff8

 00 10 00 0e 00 00 e6 0d

d6ff8

 00 10 00 0e 00 00 e6 0d

after g500 and re-entering zsid:


??

The two .hex files are intel hex format, converted to h1.dmp, h2.dmp

h1.dmp files has a chunk of stuff at 13f8 and a chunk of stuff at 1600.

The 13f8 stuff is dseg and starts with the 8 bytes defined at the start of DSEG
in the BIOS source. The rest of it is the boot sector code, for which the source
code is also in the BIOS, located in DSEG.

the 13f8 stuff is 32*16 + 7 = 519. Without the initial 8 bytes it's 511.. 1 byte
smaller than the boot sector..
but L80 reported it was 520 bytes.. but the .hex file is definitely 519 and not
520 bytes of data

But when L80 reports:

Data    33F8 3600   <  520>
Program 3600 43E8   < 3560>

that suggests that address 3600 is both data and program?! But the computation for
the ds statement looks correct so I don't understand where the missing bytes have
gone. Try getting a listing or some other output format from L80?




# Building a new BIOS

I want to add support for SD-card based virtual floppy drives. Want these to co-exist with real floppies

A, B double-density floppies
C, D single-density logical drives mapping to physical drives A, B
E, F SDcard drives
P    RAM drive

E, F will map to 2 particular SDcard regions by default/at boot but a utility will allow different SDcard regions (virtual
floppy disks) to be mapped in.

Initially, will continue to boot from A. Eventually, will swap them around (eg as boot option) to boot from SDcard.

SDcard will either use exactly the same geometry as the floppies but preferably will use a different format in which there are 16 sectors per track (or 32?) and 128 tracks (or 256)

Don't want to make the disk too big else it becomes unwieldy - remember, there are no directories.



## Disk information

from DU (£ command)

35 tracks
80 sectors/track (20 sectors * 4 128-byte logical sectors per 512-byte physical sectors)
16 sectors/group
169 groups
128 directory entries
1 system track


listing on disk 49

