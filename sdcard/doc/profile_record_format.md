# Profile record format

The profile record is stored in the Arduino EEPROM, which means that it is
non-volatile but can be modified easily.

## Overview

The profile record contains 4 profiles along with a checksum, default boot
selection and other configuration data.

Each profile is associated with an operating system/environment as follows:

* Profile 0: PolyDos
* Profile 1: NAS-DOS
* Profile 2: CP/M
* Profile 3: Stand-alone boot environment

There is a 5th profile, the "default profile" which is used if the profile
record is corrupt or missing.

Each profile defines file names for 4 disks and defines the geometry used by the
disk. The geometry is used by the NASdsk TS_SEEK and PBOOT commands (see
[Parallel interface command set](parallel_interface_command_set.md)).


## Format

Profile record:

````
Byte Offset   Name     Value   Description
    0         MAGIC0    'N'    Magic to suggest a valid record
    1         MAGIC1    'A'
    2         MAGIC2    'S'    On format change this letter will change..
    3         PUPPROF    0     Profile selected automatically at powerup/reset
    4         CHECKSUM   ?     Set such that the mod-256 sum of all bytes of the profile
                               record is 0
    5-60      PROFILE0         Profile 0. 56 bytes. See below.
    61-116    PROFILE1         Profile 1. 56 bytes. See below.
    117-172   PROFILE2         Profile 2. 56 bytes. See below.
    173-228   PROFILE3         Profile 3. 56 bytes. See below.
    229                        total: 5 + 4*56 = 229
````

Profile:

````
#define SECTOR_CHUNK (128)
typedef struct PROFILE {
    char fnam_fext[4][8+1+3+1]; // Null-terminated MSDOS 8.3 names including dot
    uint8_t nsect_per_track;    // sectors per track
    uint8_t ntrack;             // tracks TODO not used.. could be used to detect illegal seek.
    uint8_t first_sect;         // number associated with first sector
    uint8_t sect_chunks;        // number of SECTOR_CHUNKs per sector
} PROFILE;
````

## Default values for profiles

Default profile:

````
fnam_fext[0]    = DSK0.BIN
fnam_fext[1]    = DSK1.BIN
fnam_fext[2]    = DSK2.BIN
fnam_fext[3]    = DSK3.BIN
nsect_per_track = 36
ntrack          = 35
first_sect      = 0
sect_chunks     = 2 (ie, 256 bytes per sector)
````

Profile 0:

````
fnam_fext[0]    = POLYDOS0.DSK
fnam_fext[1]    = POLYDOS1.DSK
fnam_fext[2]    = POLYDOS2.DSK
fnam_fext[3]    = POLYDOS3.DSK
nsect_per_track = 36 (18 sectors per track per side, 2 sides)
ntrack          = 35 (35 tracks)
first_sect      = 0 (first sector is sector 0)
sect_chunks     = 2 (ie, 256 bytes per sector)
````

Profile 1:

````
fnam_fext[0]    = NASDOS0.DSK
fnam_fext[1]    = NASDOS1.DSK
fnam_fext[2]    = NASDOS2.DSK
fnam_fext[3]    = NASDOS3.DSK
nsect_per_track = 32
ntrack          = 80
first_sect      = 1
sect_chunks     = 2 (ie, 256 bytes per sector)
````

Profile 2 (this reflects the format for the Lucas/NASCOM implementation of CP/M):

````
fnam_fext
[0]    = CPM0.DSK
fnam_fext[1]    = CPM1.DSK
fnam_fext[2]    = CPM2.DSK
fnam_fext[3]    = CPM3.DSK
nsect_per_track = 10
ntrack          = 77
first_sect      = 1
sect_chunks     = 4 (ie, 512 bytes per sector)
````

Profile 3:

````
fnam_fext[0]    = SDBOOT0.DSK
fnam_fext[1]    = SDBOOT1.DSK
fnam_fext[2]    = SDBOOT2.DSK
fnam_fext[3]    = SDBOOT3.DSK
nsect_per_track = 36
ntrack          = 35
first_sect      = 0
sect_chunks     = 4 (ie, 512 bytes per sector)
````

## Writing and editing the profile record

The profile record is not part of the nascom_sdcard sketch. Therefore, when the
Arduino is first programmed, no profile record will be present and the default
profile will be used.

Currently:

* The only way to program the profile record is to use the PROFILE command in [NASconsole](../host_programs/NASconsole).
* There is no way to modify the profile record (except by editing the source code of [NASconsole](../host_programs/NASconsole)).

In the future there may be:

* A stand-alone tool to program the profile record, or a way to program it through a simple terminal emulator.
* Extensions to [NASconsole](../host_programs/NASconsole) to allow editing of the profile record.


## Internals: use of geometry information

A floppy disk contains sector number and track number information recorded as
part of the formatting operation. The format is OS-specific (and based on
history and somewhat arbitrary decisions). Some OS number the sectors from 0 and
some number the sectors from 1. The formula for translating from a track/sector
to a linear address needs to know both the sector size and the number associated
with the first sector.

The NASdsk SEEK_TS command uses the disk geometry information of the selected
profile.

The NASdsk PBOOT command loads data from the first sector of a disk image, and
the sector size is determined by the disk geometry information of the selected
profile.


## Internals: use of the profile record

When the nascom_sdcard hardware is reset, it performs an integrity check of the
profile record. If the checksum is bad, the default profile is used. If the
checksum is good, the profile identified by PUPPROF is used.

A well-behaved boot ROM will not rely on the correct profile being selected,
instead, it will use the NASdsk PRESTORE(pid) command to select the appropriate
profile.

Historical note: the original PolyDos NASdsk ROM pre-dates the concept of the
profile record and performs a RESTORE_STATE command, which is equivalent to a
PRESTORE(0).

## Internals: Profile 3

Profile 3 is intended for use by the [boot loader](boot_loader.md) function,
specifically by a program called [dskboot](../host_programs/dskboot.asm):
