# NAScas

NAScas is a project to provide SDcard-based storage for a NASCOM by interfacing
to the (digital side of the) cassette interface.

My initial motivation was to provide a mechanism that would work without the
need for any expansion on the NASCOM or any on-board software, and which would
work for all existing software.

The serial interface can run at any true NASCOM baud rate (for authenticity) but
the default setup is to generate a bit clock from the NAScas hardware in order
to run the UART as fast as it and NAS-SYS can go. The current design runs at
2400bd.

## CAS format

I use the term "CAS format" to refer to the block-based binary format that
NAS-SYS uses to store and load data. Data in this format has an implicit load
address (NAS-SYS knows where to put it).

Files can be saved in "G" format, in which case there is appended an execution address.


## Bootstrap and SERBOOT

When you power-up or reset the NAScas hardware, it sends "R<CR>" across the serial
interface, which causes NAS-SYS to issue the "R" (read) command as though it had been
entered at the keyboard. NAScas detects the read command like this:

* the DRIVE signal has asserted
* wait to see if data is received from the NASCOM
* time-out: no data received, therefore must be expecting a READ

At this point, NAScas sends a byte stream to the NASCOM, in cassette R
format. This byte stream is a bootstrap program called SERBOOT. The NASCOM loads
it into memory. After the DRIVE signal negates, NAScas sends the text string
"EC80<CR>". The NAS-SYS command loop always polls the serial/cassette interface
at the same time as the keyboard, so it will receive and process this command,
starting the bootstrap program.

(the source code is here: https://github.com/nealcrook/nascom/sdcard/host_programs/serboot.asm)

SERBOOT is tiny (~103 bytes). It provides a prompt and command loop. Its
function is to relay commands to NAScas and to report responses. The prompt
looks like this:

````
NAScas>
````

You can issue a command, followed by <ENTER>. There are 2 ways to exit the command loop and return to NAS-SYS:

1/ terminate a command with a period, "." (followed by <ENTER>)
2/ enter a period, "." by itself on a line (followed by <ENTER>)


## Usage Paradigm

Tape is a sequential access device so we need a paradigm that accommodates that, and that will work with all existing software.
Unlike tape, which is a linear device, NAScas uses files. The basic usage model is this:

* Use the NAScas command to specify files that will be used for future "R"ead or "W"rite commands
* Exit NAScas
* (at some time in the future) issue "R" or "W" commands (or CLOAD/CSAVE from BASIC)

This idea of specifying file names in advance is analagous to "cueing" the tape by winding forward or back to the correct position.

There is some additional capability, which will be described along with the command-set.


## Reloading/Relocating SERBOOT

Usually the bootstrap code will stay in memory forever. You can always re-run it
from NAS-SYS (EC80<ENTER>). If it gets lost or corrupted you need to reset
NAScas and issue the R command again from NAS-SYS.

The bootstrap always loads and starts at 0C80 but the code itself is relocatable
and there is a command to move it to a new location

````
NAScas> TO 1000<ENTER>
NAScas>
````

relocates the code to address 1000. When the second prompt appears, the code is executing at the new address.

## Formats and file-systems

TODO

## Commands

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

ES FILE.XXX - erase file from SDcard.

TS FILE.XXX - send file from SDcard as text.


AUTOGO - after reset, any file that is read and has a known execution address will be executed after loading (BASIC programs will be RUN)
AUTOGO - toggle flag
AUTOGO 0 - clear flag
AUTOGO 1 - set flag

PAUSE n - after issuing a TS command the data stream will start straight away (will not wait for drive light). This is the number of seconds to pause before the data stream starts (default 2).

NULLS n - after issuing a TS command this is the amount of time to wait after a line-end, to give BASIC time to catch up. Will it actually be NULS or a short time delay in ms??


## Hardware

As for nascom_sdcard, I used off-the-shelf hardware as much as possible. I used
3 circuit boards. The baseboard is an Arduino Uno -- these are cheap, easy to
develop for and run at 5V which makes them ideal for interfacing to old TTL/NMOS
logic.

The second board is an Arduino prototyping card from BangGood. This is cheap but
not ideal; there are some errors on the board (see notes below).

The third and final board is a tiny daughter-card that holds the SDcard socket
and level shifters/power regulation so that it can connect to 5V; also from
BangGood.

The daughtercard is attached to the prototyping card using double-sided sticky
pads. A (shrouded, polarised) 16-way connector connects to the NASCOM Serial connector using
ribbon cable. The interface connects to:

* Transmit clock
* Receive clock
* Transmit data
* Receive data
* Drive
* Ground
* (+5V)


## Current Status And Plans

27Apr2019 - using the code here, all functions are working.


Remaining tasks:

* Make a smaller version
* Create conenction diagrams for NASCOM1 and NASCOM2
* Take some photos
* Youtube video?


## Contents

* photos/         -- not yet done
* doc/            -- not yet done
* NAScas.ino      -- the C code for the Arduino (includes wiring instructions)
* messages.h      -- "
* roms.h          -- "
* parser.ino      -- "

See also:

* nascom/host_programs/ which contains associated Z80 code for the NASCOM. A "library" of subroutines and some example programs for using them.


## Construction

You will need:

* Arduino uno
* Arduino prototyping card
* SDcard adaptor
* Header pins for connecting the Uno to the prototyping card
* Polarised 16-way IDC connector (male pin, female shroud)
* 1 270 ohm resistor
* Thin hookup wire (I use wire-wrap wire)
* Thick hookup wire (for power connection on SDcard adaptor)

The first four are easy and cheap to source from Banggood or Aliexpress For example (Banggood product IDs):

* Arduino UNO: Arduino Compatible UNO R3 ATmega16U2 AVR USB Development Main Board, product ID 68537
* Prototyping board:Prototyping Shield PCB Board For Arduino, product ID 995386
* SD adaptor: Micro SD TF Card Memory Shield Module SPI Micro SD Adapter For Arduino, product ID 919914
* Header pins: 50 Pcs 40 Pin 2.54mm Single Row Male Pin Header Strip For Arduino Prototype Shield DIY. product ID 1033758

For the Arduino, I recommend getting one with a socketed DIL AVR chip.


Use the notes in nascom_arduino.ino and nascom_pio.pdf and the photos to guide you. There are about 20 wires to connect.

## Powering the Arduino

During development, I powered the Arduino though the USB connection - either from a wall power supply or from a laptop where I was running the Arduino IDE for code development. With the finished system, it's preferable to power it directly from the NASCOM.

There are 2 options:

* The Polite option is to use the DC input jack of the Arduino. This is polite because it can co-exist with the USB input (there is comparator and FET which switches the DC source out when there is power on the USB). This input is regulated on-board and so requires an input of at least 7V. You could wire a barrel connector to the 12V output of the NASCOM PSU and connect it.
* The Impolite option (which I used) is to pick up +5V from the PIO IDC connector. This needs to be wired into the same power rail as the USB would supply -- so you can NO LONGER ATTACH THE USB (I put some tape over the connector to remind me!). Close to the USB connector on the Arduino is a 2-pin device that looks like a big yellow resistor but which is actually a fuse. Solder the +5V connection to this point (the end down-stream of the fuse, but it doesn't really matter).

## Arduino prototyping card

The boards I have are marked "Protoype Shield V.5". They have some design errors:

* The "GND" between AREF and D13 is actually connected to 5V. If you've soldered a
header pin to this position, cut the pin off before attaching the board to an
Arduino (otherwise you will short the power rails).

* The power tracks marked "GND" and "5V" are randomly wrong. Buzz each one out
  to see what it connects to before using it!

