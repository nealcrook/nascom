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

## Contents

* photos/         -- photos of the hardware and of SERBOOT in operation
* NAScas.ino      -- the C code for the Arduino (includes wiring instructions)
* messages.h      -- "
* parser.ino      -- "
* roms.h          -- "

See also:

* nascom/host_programs/ which contains associated Z80 code for the NASCOM.
* nascom/sdcard/nascom_sdcard/docs which contains a full manual, schematics and other documentation


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

SERBOOT is tiny (~110 bytes). It provides a prompt and command loop. Its
function is to relay commands to NAScas and to report responses. The prompt
looks like this:

````
NAScas>
````

You can issue a command, followed by <ENTER>. There are 2 ways to exit the command loop and return to NAS-SYS:

* Terminate a command with a period, "." (followed by \<ENTER\>)
* Enter a period, "." by itself on a line (followed by \<ENTER\>)


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

NAScas supports 3 file-systems:

* Vdisk  - A read-only file-system implemented in a binary blob that is stored on the SDcard. The binary blob is a PolyDos disk image; the format is documented in the PolyDos System Programmers Guide. File names use an 8.2 format: 1-8 characters before the dot, exactly 2 characters after the dot.
* Flash - A read-only file-system that uses the Flash memory on the Atmel processor of the Arduino. This stores the SERBOOT code and a few other programs (including ZEAP and Lollipop Lady Trainer). File names use PolyDos format (see above).
* SDcard - A read/write filesystem implemented on the SD card. File names use MSDOS 8.3 format: 1-8 characters before the dot, 1-3 characters after the dot.

NAScas supports these file formats:

* Files stored on the Vdisk and Flash file-systems are binary blobs with additional meta-data (load address, execution address) that is stored in the associated directory structure. When read, a file is converted to CAS format on-the-fly.

* Files stored on the SDcard FAT file-system can be text files (See the description of the TS command) or byte streams in CAS format. When NAScas writes to a file on the SDcard, it stores the exact byte stream from the NASCOM UART. When the file is subsequently read, it delivers that exact byte stream. Files that have been created elsewhere (e.g. for NASCOM emulators) in .CAS format can be loaded onto an SDcard and read as though they had been generated by the NASCOM.

Additional utilities exist (in nascom/converters) for creating/maintainng PolyDos disk images and for converting between CAS and other formats.

## Commands

Commands (only the first 2 characters are significant)

````
HELP - report help for all commands
`````

````
INFO - report fw version and any other useful state info
````

````
. - quit the CLI (this is handled directly by SERBOOT with no communication with the NAScas hardware)
````

````
TO xxxx - relocate program to specified address.
````

````
DF - directory of Flash
DV - directory of virtual disk (with pager). Error if no virtual disk mounted.
DS - directory of SDcard (with pager). Error if no SDcard present.
````

````
NEW - check for presence of SDcard and set working directory. Automatically performed at reset. Use this
when you change the SDcard. If a directory named NASCOM exists, all file operations use this directory.
Otherwise, all file operations use the root directory of the SDcard.
````

````
MO <file.xxx> - mount file as virtual disk. File can have any legal DOS 8.3 name. Error if no SDcard
present. Error if illegal file name. Error if file not found.
````

````
RF <file.go> - cue file for reading from Flash. File can have any legal PolyDOS 8.2 name but all files
in the Flash file-system have the .GO extension. Error if illegal file name. Error if file not found.
RV <file.xx> - cue file for reading from virtual disk. File can have any legal PolyDOS 8.2 name. Error
if illegal file name. Error if no SDcard present. Error if no virtual disk mounted. Error if file not found.
RS <file.xxx> - cue file for reading from SDcard. File can have any legal DOS 8.3 name. Error if illegal
file name. Error if no SDcard present. Error if file not found.
````

````
ES <file.xxxx> - erase file from SDcard. Error if illegal file name. Error if no SDcard present.
Error if file not found.
````

````
TS <file.xxx> - send file from SDcard as text. See notes below.
````

````
AUTOGO - after reset, any file that is read from Flash or Vdisk and has a known execution address
is executed after loading  (for files saved to SDcard use the NAS-SYS "G"enerate command to make
them execute automaticaly after loading).
AUTOGO - toggle flag
AUTOGO 0 - clear flag
AUTOGO 1 - set flag
````

````
PAUSE n - after issuing a TS command the data stream will start straight away (will not wait for
DRIVE light). This is the number of seconds to pause before the data stream starts (default 10).
````
````
NULLS n - after issuing a TS command this is the number of milli-seconds to wait after a line-end,
to give BASIC time to catch up. It is not actually implemented by issuing NUL characters; it just
uses a time delay (default 100).
````

### The AI argument

The RS and WS commands allow an optional AI argument after the file name. This argument causes the last 2 digits of the file name to increment numerically after each read or write operation. INFO will show the next file names to be used.

Usually, if you issue RS repeatedly, you will always read the same file. Usually, if you issue WS repeatedly, you will always overwrite any existing file. Using AI allows multiple versions to be kept, which can be useful during program development.

### The TS Command

Use this to send a text file to the NASCOM exactly as though you had typed it in by hand. For example, you could grab a BASIC program from somewhere on the 'net and then deliver it to BASIC (which will tokenize it line by line and store it in memory) and then save it using CLOAD. The session to do this would be something like this:

````
NAScas> WS HANGMAN.CAS                       -- encoded file will be save here
NAScas> TS HANGMAN.BAS                       -- text file to be read into BASIC
NAScas> .                                    -- leave the CLI

-- NAS-SYS 3 --
X0                                           -- allow long lines in BASIC
J                                            -- cold-start BASIC

Memory Size? 

Microsoft BASIC

<program scrolls by line by line>            -- you have 10s from issuing the TS command to now

MONITOR                                      -- back to NAS-SYS
N                                            -- back to normal command handling
Z                                            -- back to BASIC
CSAVE "A"                                    -- save encoded file as HANGMAN.CAS
````


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

* 27Apr2019 - using the code here, all functions are working.
* 20Sep2019 - I have designed a PCB and am awaiting its arrival from manufacture
* 01Oct2019 - The PCB is up and running! I created a user guide.
* 16Nov2019 - I reworked the serboot code to add a pager so (it grew from 103 to 110 bytes) and reworked the NAScas.ino to page directory listings for SDcard and Virtual Disk. Bumped revision number from 1.0 to 1.1


Remaining tasks:

* More photos
* Youtube video?



## Construction

You will need:

* Arduino Uno and Arduino prototyping card
* or, Arduino Nano and Veroboard
* or, Arduino Nano and my PCB
* SDcard adaptor
* Header pins for connecting the Uno to the prototyping card
* NASCOM2: Polarised 16-way IDC connector (male pin, female shroud)
* 1 270 ohm resistor
* Thin hookup wire (I use wire-wrap wire)
* Thick hookup wire (for power connection on SDcard adaptor)

The first four are easy and cheap to source from Banggood or Aliexpress For example (Banggood product IDs):

* Arduino UNO: Arduino Compatible UNO R3 ATmega16U2 AVR USB Development Main Board, product ID 68537
* Prototyping board:Prototyping Shield PCB Board For Arduino, product ID 995386
* SD adaptor: Micro SD TF Card Memory Shield Module SPI Micro SD Adapter For Arduino, product ID 919914
* Header pins: 50 Pcs 40 Pin 2.54mm Single Row Male Pin Header Strip For Arduino Prototype Shield DIY. product ID 1033758

For the Arduino, I recommend getting one with a socketed DIL AVR chip.


Use the notes in NAScas.ino and the photos to guide you. There are about 15 wires to connect.

## Powering the Arduino

If you use an Arduino Nano, it contains circuitry to allow it to automatically
draw 5V power either from the USB or from the connected system (the NASCOM in
this case).

The Arduino Uno is not so flexible. During development, I powered the Arduino
Uno though the USB connection - either from a wall power supply or from a laptop
where I was running the Arduino IDE for code development. With the finished
system, it's preferable to power it directly from the NASCOM.

There are 2 options:

* The Polite option is to use the DC input jack of the Arduino. This is polite because it can co-exist with the USB input (there is comparator and FET which switches the DC source out when there is power on the USB). This input is regulated on-board and so requires an input of at least 7V. You could wire a barrel connector to the 12V output of the NASCOM PSU and connect it.
* The Impolite option (which I used) is to pick up +5V from the NASCOM Serial connector and wire it into the same power rail as the USB would supply -- so you can NO LONGER ATTACH THE USB (I put some tape over the connector to remind me!). Close to the USB connector on the Arduino is a 2-pin device that looks like a big yellow resistor but which is actually a fuse. Solder the +5V connection to this point (preferably the end down-stream of the fuse, but it doesn't really matter).

## Arduino prototyping card

The boards I have are marked "Protoype Shield V.5". They have some design errors:

* The "GND" between AREF and D13 is actually connected to 5V. If you've soldered a
header pin to this position, cut the pin off before attaching the board to an
Arduino (otherwise you will short the power rails).

* The power tracks marked "GND" and "5V" are randomly wrong. Buzz each one out
  to see what it connects to before using it!

## Connecting to a NASCOM1

The tidiest way to connect is to add 4 wires to the back of the N1, connecting
the required signals to unused pins of the 16-way Serial Data Socket (SK2). The
modified pinout of this connector is as follows (In/Out are shown with respect
to the NASCOM):

````
                               1   U   16 +5V
                    RS232  In  2       15
                               3       14 Out RS232 Out
                     KBD-  In  4       13
                     KBD+  In  5       12 Out PTR+
 NEW Tape DRIVE (IC41/12) Out  6       11 Out PTR-
 NEW      Uart In (LK3/In) In  7       10 Out Uart Out (IC29/25) NEW
                RS232 COM GND  8       9  In  Ext Cl P1 (LK4/P1) NEW
````

With these wires added, configure the links as follows:

* LK3: disconnect (so that the new pin 7 connection can drive serial data into the NASCOM)
* LK4: set to "Ext Cl" position (so that the new pin 9 connection can drive a serial clock into the NASCOM)
* LK2: fitted (single stop bit)

Now connect NASCAS using a flying lead connected to SK2. 6 Connections are required:

* Drive (out from NASCOM)
* Serial clock (in to NASCOM)
* TxD (out from NASCOM)
* RxD (in to NASCOM)
* +5V (power from NASCOM)
* Gnd (common ground)

## Connecting to a NASCOM2

All of the connections required are available on the 16-way Serial connector
(PL2). The connection can be made using a 16-way IDC ribbon cable.

Configure the NASCOM jumpers as follows: LSW1/5: Up (1 stop bit), LSW2: all
switches to Up/On.

## Programming the Arduino/Nano

Edit the source file to set the appropriate #define to select NASCOM 1 or
NASCOM2. This sets the serial data rate and controls whether the serial data is
inverted.




