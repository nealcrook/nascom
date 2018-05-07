# nascom_sdcard

nascom_sdcard is a project to provide SDcard-based storage for a NASCOM.

My initial motivation was to provide a way to dump disk images from the machine,
and so I wanted to minimise the complexity and footprint on the NASCOM itself.

I used off-the-shelf hardware as much as possible. I used 3 circuit boards. The
baseboard is an Arduino Uno -- these are cheap, easy to develop for and run at
5V which makes them ideal for interfacing to old TTL/NMOS logic.

The second board is an Arduino prototyping card from BangGood. This is cheap but
not ideal; there are some errors on the board (see notes below).

The third and final board is a tiny daughter-card that holds the SDcard socket
and level shifters/power regulation so that it can connect to 5V; also from
BangGood.

The daughtercard is attached to the prototyping card using double-sided sticky
pads. A (shrouded, polarised) 26-way connector connects to the NASCOM PIO using
ribbon cable. The interface uses 8 data from Port A and 3 data from Port B.

Finally, there is an LED, controlled from the Arduino. The LED is used to
indicate a protocol error (command expected but data received).

## Current Status And Plans

06May2018 - using the code here, the sd_util can be used to load and save to and
from NASCOM memory, the polydos_util_rom boots PolyDos successfully and supports
4 disks (named DSK0.BIN DSK1.BIN DSK2.BIN DSK3.BIN on the SDcard). The SCRAPE
utility dumps PolyDos disk images accurately and the SDDIR/SETDRV utilities are
working.

Remaining tasks:

* Complete polydos_vfs, a PERL-based file-system manipulator
* Write SDSTDIN, to allow import of (eg BASIC) programs in ASCII format
* Write a print spooler that spools to a file on the SD card
* Write CASDSK, a utility to intercept NAS-SYS R/W calls in favour of
a disk file
* Upload PolyDos material and images
* Upload disk images


## EPROM programming service

If anyone is looking to build one of these and has an EPROM that they need
erasing and programming, I will be happy to do this on a cost-of-postage
basis. Contact me to make arrangements.


## Contents

* photos/         -- photos of the assembled board sandwich
* nascom_sdcard   -- the C code for the Arduino (includes wiring instructions)
* host_programs   -- Z80 code for the NASCOM. A "library" of subroutines and some example programs for using them.
* doc/            -- description of the protocol and the command-set

## Construction

You will need:

* Arduino uno
* Arduino prototyping card
* SDcard adaptor
* Header pins for connection the Uno to the prototyping card
* Polarised 26-way IDC connector (male pin, female shroud)
* 1 LED
* 1 270 ohm resistor
* Thin hookup wire (I use wire-wrap wire)
* Thick hookup wire (for power connection o SDcard adaptor)

The first four are easy and cheap to source from Banggood. For example:

* Arduino UNO: Arduino Compatible UNO R3 ATmega16U2 AVR USB Development Main Board, product ID 68537
* Prototyping board:Prototyping Shield PCB Board For Arduino, product ID 995386
* SD adaptor: Micro SD TF Card Memory Shield Module SPI Micro SD Adapter For Arduino, product ID 919914
* Header pins: 50 Pcs 40 Pin 2.54mm Single Row Male Pin Header Strip For Arduino Prototype Shield DIY. product ID 1033758

For the Arduino, I recommend getting one with a socketed DIL AVR chip.


Use the notes in nascom_arduino.ino and nascom_pio.pdf and the photos to guide you. There are about 20 wires to connect.


## Arduino prototyping card

The boards I have are marked "Protoype Shield V.5". They have some design errors:

* The "GND" between AREF and D13 is actually connected to 5V. If you've soldered a
header pin to this position, cut the pin off before attaching the board to an
Arduino (otherwise you will short the power rails).

* The power tracks marked "GND" and "5V" are randomly wrong. Buzz each one out
  to see what it connects to before using it!

