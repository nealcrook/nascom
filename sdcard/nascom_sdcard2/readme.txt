18Nov2018 -- this project is a work-in-progress. Use nascom_sdcard if you want something
finished and documented and working.


Overview
========

A small external unit, "NASCAS" comprising an Arduino and SDcard, is connected to the NASCOM cassette interface as follows:

NASCOM 1: TBD

NASCOM 2: TXD, RXD, CLK, DRIVE

There is no additional software on the NASCOM. At reset, the NASCOM must run NAS-SYS (1 or 3 should both work).

The serial interface can run at any true NASCOM baud rate (for authenticity) or you can use the serial clock output to run the UART as fast as it and NAS-SYS can go.

CAS Format
==========

I use the term "CAS format" to refer to the block-based binary format that NAS-SYS uses to store and load data. Data in this format
has an implicit load address (NAS-SYS knows where to put it).

Files can be saved in "G" format, in which case there is appended an execution address.

Bootstrap
=========

After reset, you use the NAS-SYS "R" command. NASCAS detects the read command like this:

1/ the DRIVE signal has asserted
2/ wait to see if data is received from the NASCOM
3/ time-out: no data received, therefore must be expecting a READ

At this point, NASCAS sends a bytestream to the NASCOM, in cassette R format. The NASCOM loads it into memory. After the DRIVE signal negates, NASCAS sends the text string "EC80 <CR>". The NAS-SYS command loop always polls the serial/cassette interface at the same time as the keyboard, so it will receive and process this command, starting the bootstrap program.

(the code of the bootstrap program is here: https://github.com/nealcrook/nascom/sdcard/host_programs/serboot.asm)

The bootstrap program is tiny (~103 bytes). It provides a prompt and command loop. Its function is to relay commands to NASCAS and to report responses. The prompt looks like this:

SDcard>

You can issue a command, followed by <ENTER>. There are 2 ways to exit the command loop and return to NAS-SYS:

1/ terminate a command with a period, "." (followed by <ENTER>)
2/ enter a period, "." by itself on a line (followed by <ENTER>)


Usage Paradigm
==============

Tape is a sequential access device so we need a paradigm that accommodates that, and that will work with all existing software.
Unlike tape, which is a linear device, NASCAS uses files.

Tape paradigm                                         NASCAS paradigm
-----------------------------------------------------+------------------------------------
wind tape to specific place, press PLAY               Use CLI to specify filename for upcoming read operation

rewind tape and press PLAY a second time              Previously specified filename is reused

press PLAY a second time to load the next program     Use CLI to specify filename for upcoming read operation

                                                      (or) specify auto-increment filename

wind tape to specific place, press RECORD             Use CLI to specify filename for upcoming write operation

rewind tape to same  place, press RECORD              Previously specified filename is reused

press RECORD a second time to save a second           Use CLI to specify filename for upcoming write operation
(maybe modified) copy
                                                      (or) specify auto-increment filename

The basic idea is that the CLI is used to "wind" the (virtual) tape to the "right place" (file name). Unlike a tape, you can have separate/different names/files ("places on the tape") for read and for write.


Reloading/Relocating the bootstrap
==================================

Usually the bootstrap code will stay in memory forever. You can always re-run it from NAS-SYS (EC80 <ENTER>). If it gets lost or
corrupted you need to reset NASCAS and issue the R command again from NAS-SYS.

The bootstrap always loads and starts at C80 but the code itself is relocatable and there is a command to move it to a new location

SDcard> TO 1000<ENTER>
SDcard>

relocates the code to address 1000. When the second prompt appears, the code is executing at the new address.


Capability
==========

NASCAS can act as a cassette recorder, a target for the NAS-SYS R/W/V/G commands. There are 3 ways to store files on NASCAS:

1/ in the Arduino internal FLASH memory. These are configured when the NASCAS firmware is built, and are read-only. These files include the bootstrap loader itself and (by default) some NASCOM classics like lollipop lady trainer. Internally these are stored as binary blobs along with meta-data (name, load address, execution address) and are converted to "R" format on-the-fly when loaded.

-> are they named or what?

2/ on the SDcard FAT Filesystem. These have DOS 8.3 format names. Various file formats are supported. Files can be read and written.

3/ in a virtual floppy disk image, which is itself stored as a binary blob on the SDcard FAT Filesystem. The floppy disk image has a DOS 8.3 format name. The virtual floppy is in POLYDOS format. Files adhere to POLYDOS file-naming (8.2). Such files have meta-data (name, load address, execution address). Various file formats are supported. Files can be read and written. My polydos_vfs utility can be used to create and manage these virtual disk images.

As well as file read/write, NASCAS provides two other capabilities:

1/ auto-typewriter. An ASCII text file stored on the SDcard (either directly or within a virtual floppy disk image) can be sent to the serial port and will be treated, by the NASCOM, as though it has been typed in directly. One use for this is for loading BASIC programs: if you have a program in plain text you cannot load it directly into memory because programs are stored in tokenised format. By importing it in this way it will be processed by BASIC and tokenised and you can then save it using the usual BASIC
commands.

2/ print spool. As if you had a serial printer, you can "spool" listings to the serial port to be saved in literal format on a file on the SDcard (either directly or within a virtual floppy disk image).

There are a couple of special things to worry about:

1/ BASIC save programs as a short "header" with a single-letter "filename" followed by a sequence of blocks in CAS format. On load, it will not load a program until it has seen that "header".

2/ HiSoft PASCAL uses its own file format (I think).


Formats
=======

Files stored in Arduino internal FLASH memory use a PolyDOS-like directory structure with an 8.2 name structure. Files are stored in binary form and converted to CAS format on-the-fly.

Files stored on the SDcard FAT Filesystem have DOS 8.3 format names. They can be .BIN files (in which case they are converted to/from "R" format on-the-fly). Such files have no load information and no execute information so this must be provided as part of the command. Since that is clumsy this format is only recommended for special purposes like importing or exporting a binary ROM image. Files can be read or written in this format.


Commands
========

At boot or after a NEW command, check for SDcard. If found, check for NASCOM directory. If NASCOM directory is found all accesses use that directory. Otherwise, all accesses use the root directory.

Commands (only the first 2 characters are significant)

HELP - report help for all commands

INFO - report fw version and any other useful state info

. - quit the CLI (this is handled directly by serboot with no communication with the Arduino)

TO xxxx - relocate program to specified address.

DF - directory of Flash
DV - directory of virtual disk. Error if !vdisk_mounted.
DS - directory of SD card. Error if !sdcard_present.

NEW - re-check SDcard
- automatically performed at reset. Updates sdcard_present, nascom_directory

MO FILE.XXX - mount file as virtual disk. File can have any legal DOS 8.3 name. A basic check is done that the file looks the right size and format to be a PolyDOS disk. ?Report disk name?
- Error if !sdcard_present, update vdisk_mounted
- Error if illegal file name or file not found or file format looks dodgy

RF FILE.GO - cue file FILE.GO from Flash for reading. File can have any legal PolyDOS 8.2 name but all files in the Flash filesystem have the .GO extension.
- Error if illegal file name or file not found
- update rd_src to Flash and directory entry to the entry number of the specified file
- boot works by setting rd_src to Flash, directory entry to 0 (serboot) and ld_type to bin2cas and auto_go to 1

RV FILE.XX - cue file FILE.XX from virtual disk for reading. File can have any legal PolyDOS 8.2 name
- Error if illegal file name or file not found or !vdisk_mounted
- update rd_src to vdisk and directory entry to the entry number of the specified file

RS FILE.XXX - cue file FILE.XXX from SDcard for reading. File can have any legal DOS 8.3 name
- Error if illegal file name or file not found or !sdcard_present
- update rd_src to sdcard and directory entry to the entry number of the specified file - or leave the handle open and seeked to the right place?

RS FILE.XXX LLLL EEEE
- LLLL is optional load address
- EEEE is optional execution address
Both are ignored if the file format doesn't need them.

AUTOGO - after reset, any file that is read and has a known execution address will be executed after loading (BASIC programs will be RUN)
AUTOGO - toggle and report flag
AUTOGO 0 - clear flag
AUTOGO 1 - set flag

PAUSE n - after issuing a R of a .TX or TXT file the data stream will start straight away (will not wait for drive light). This is the number of seconds to pause before the data stream starts (default 2).

NULLS n - when sending a .TX or TXT file this is the amount of time to wait after a line-end, to give BASIC time to catch up. Will it actually be NULS or a short time delay in ms??

File conversions on READ

.GO -> PolyDos binary file with metadata. bin2cas conversion on-the-fly
.BIN -> binary file on SD. Additional data needs to be explicitly provided. bin2cas conversion on-the-fly
.BS -> PolyDos BASIC file with metadata. Generate BASIC header with null file name or file name "A"?? followed by bin2cas conversion on-the-fly
.BAS -> binary file on SD. Implicitly a binary BASIC program; no additional data is needed. Generate BASIC header with null file name or file name "A"?? followed by bin2cas conversion on-the-fly
.TX, .TXT -> PolyDos or SD file. Data stream will start straight away (see PAUSE, NULLS above).
.CA, .CAS -> PolyDos or SD file. Encoded CAS format, delivered literally. No attempt at "auto" or anything else.


? Other extensions that are loaded but not auto-executed? Zeap source, NASPEN etc..

WV FILE.XX - cue file FILE.XX for writing to virtual disk. File can have any legal PolyDOS 8.2 name
- Error if illegal file name or !vdisk_mounted or no space on disk/no directory entry
- update wr_src to vdisk and directory entry to the entry number of the specified file??

WS FILE.XXX - cue file FILE.XXX for writing to SDcard. File can have any legal DOS 8.3 name
- Error if illegal file name or !sdcard_present or no space on disk/no directory entry??
- update wr_src to sdcard and directory entry to the entry number of the specified file - or leave the handle open and seeked to the right place?


File conversions on WRITE

.GO -> PolyDos binary file with metadata. cas2bin conversion on-the-fly, including final Exxxx if present.
.BS -> cas2bin conversion on-the-fly
.BAS -> binary file on SD. cas2bin conversion on-the-fly
.TX, .TXT -> PolyDos or SD file. Data stream will start straight away (see PAUSE, NULLS above).
.CA, .CAS -> PolyDos or SD file. Encoded CAS format, saved literally, until DRIVE goes off


? Any (??) command can also have optional AI to auto-increment file name (last 2 positions in file name)

TODO: PRN file for print spooling?

Flags
=====

sdcard_present
nascom_directory
vdisk_mounted
auto_go




The file on the SDcard is a byte-stream and so can accommodate both CAS format and the extra pieces added by G (generate) or BASIC load/save. It should work transparently with anything that uses the cassette interface. The SDcard can be plugged into a PC for trandferring files on and off (.CAS files can be created using a PERL script in my github repository)




should get the framework working with the softserial library then switch to the hardware pins - allow debug

nail down the commands

get as much commonality with the pio as possible

double-assign pins in the mean-time as long as they do not interfere if one interface is idle

write the control program and make sure it's small.

use MFLP to turn the drive LED on and off - no, I never need to do that!
use SOUT to send characters to the serial port

I think input characters are detected with normal RST IN

cannot simply do this:

E1000 hello this is a command

..because NAS-SYS will generate an error; expects ONLY hex stuff. Instead, it must be:

EC800
SDcard> hello this is a command
SDcard> .


- dot at the end of a command or on a blank line will terminate
- R after reset will implicitly read the boot program
- load from .cas (binary literal, start on DRIVE) or from extracting from PolyDos disk image or from .txt file
  (stream in as though typed)

commands:

help
rc temp.cas -- read CAS file
rd temp.zzz -- read from DISK image, file temp.zzz
               if it has .BS extension and start address of 10D6, prepend BASIC header
rb temp.cas -- read CAS file with BASIC header
ma fooby    -- magic word for ra
ra temp.txt -- read ASCII -- fooby is the magic word to start the supply of text.
sd DISK.BIN -- set disk image to use for rd command
ag          -- toggle auto-go flag. When true, files read from disk image (where execution
               address is Known) are followed by an "Exxx <RETURN>" string
to xxxx     -- relocate this code to somewhere else, xxxx

similarly for write. Also, auto-increment names.


Help screen:

v                                              v
012345678901234567890123456789012345678901234567

RI WI        -- read increment/write increment        just set flags
                (last 2 digits of filename)
RV WV <file> -- read/write from virtual disk          rv gets name, no search done. wv gets name.. then what?
RF <file>    -- read from FLASH storage               rf get name, no search done. No names saved yet
RC WC <file> -- read/write cas from SD                rc done, untested. wc done, untested. Messy code.
VD <file>    -- select virtual disk                   done, untested
AE           -- auto-execute on reset                 just sets flags
AG           -- auto-go after reading file            just sets flags
BH           -- prepend BASIC header                  just sets flags
INFO HELP    -- what they say                         sorta-done
.            -- exit CLI                              done
EC80         -- restart CLI                           done
TO xxxx      -- relocate CLI to xxxx                  done, needs tidy-up on error and to handle lower case
SP n         -- set speed

others:

MA FOOBY     -- set magic word of FOOBY for RA command
RA FOO.TXT   -- read ASCII -- FOOBY is the magic
                word to start the supply of text
DIR
DEL
?? print spooler


ALSO:

DS                                                    dir SD. Coded but commented out
NE                                                    next flash file - cos names/search not implemented


-> auto-increment
-> write commands


The RI WI AE AG BH commands all set/clear/toggle flags

RI 0          - clear flag
RI 1          - set flag
RI            - toggle flag
RI blah       - flag unchanged



Next:


- can write to SD card OK but need to minimise RAM usage first
- for write, need to see if the file exists and if so remove it.

-> BUG: write appears to succeed even when no SD card is present

- the print statements are using RAM!! Change the HELP to read from ROM
- and reduce the amount of printing!!
- formalise the command set and arguments, code them
- Write proper help screen
- DONE Implement TO
- DONE Implement rules for telling read from write
- Implement read cas
- Implement write cas
- Implement implement auto-increment of file names
- Implement read from disk image
- Implement auto-go flag
- Implement write to disk image
- Implement external clock and see how fast it can go
- DONE Tidy up code structure
- DONE Change boot code to be stored in EPROM.
- Choose pins, migrate other board/code to use them and itegrate the two lumps of code.. cannot use current cassette code
  with SDcard until I migrate to a board with an SDcard..
- should always try to check a read file when it's mentioned, becasue that is the
  best/only time to report an error.
- maybe add SAVE command to save everything to EEPROM. Don't want to do that
  automatically as it might happen too often.


- for RI/WI commands require the filename to be of the correct format: to have at least 3 char of prefix
  and for the last 2 char of prefix to be numeric. Therefore:
1/ when a filename is given and the associated "I" flag is set, check the filename
2/ when the I flag is set check the existing filename to make sure it's legal
so, expected use-case is to set the filename before setting the "I" flag.
What to do in case of error? Ignore/clear the I flag??


TODO implement "pager" in serboot: allow RSMSG to terminate with PAUSE (wait for serboot to send something) rather
than NUL. Issue the "press ENTER to continue" text from the NASCAS unit.
