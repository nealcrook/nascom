# NASdsk

NASdsk is a project to provide PIO-attached SDcard-based storage for a NASCOM.

My initial motivation was to provide a way to dump disk images from the machine,
and so I wanted to minimise the complexity and footprint on the NASCOM itself.

The final design connects to the NASCOM Z80-PIO and acts as a virtual floppy
disk drive, running the PolyDos operating system.

As of July 2020, this code is obsolete; use the code in sd_merged instead; it
combines the NASdsk and NAScas functionality.

## Contents

* NASdsk.ino -- the C code for the Arduino (includes wiring instructions)

See also:

* nascom/sdcard/host_programs/ -- associated Z80 code for the NASCOM. A "library" of subroutines and some example programs for using them.
* nascom/sdcard/photos/ -- photos of the assembled PCB and the prototype board sandwich
* nascom/sdcard/doc/ -- description of the protocol and the command-set, a full manual, schematics

* nascom/PolyDos/ -- PolyDos disk images and documentation


## Hardware

The easiest way to build this is to use the PCB that I designed (contact me to
see if I still have spares). The PCB is common between the NAScas design and the
NASdsk design. The PCB uses an Arduino nano and a tiny daughter-card that
holds the SDcard socket and level shifters/power regulation so that it can
connect to 5V; both of these are available from EBay/Banggood/Aliexpress.
BangGood.

My prototype used 3 circuit boards. The baseboard is an Arduino Uno -- these are
cheap, easy to develop for and run at 5V which makes them ideal for interfacing
to old TTL/NMOS logic.

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

07Sep2018 - polydos_vfs is quite functional, with just a couple more commands needed.
The CASDSK utility is complete. Multiple application disk images are present in the
PolyDos/libs area. Construction details updated to show how to power the Arduino from
the NASCOM.

20May2020 - polydos_vfs is complete.

Remaining tasks:

* Write SDSTDIN, to allow import of (eg BASIC) programs in ASCII format
* Write a print spooler that spools to a file on the SD card

## Construction

You will need:

* Arduino uno
* Arduino prototyping card
* SDcard adaptor
* Header pins for connecting the Uno to the prototyping card
* Polarised 26-way IDC connector (male pin, female shroud)
* 1 LED
* 1 270 ohm resistor
* Thin hookup wire (I use wire-wrap wire)
* Thick hookup wire (for power connection on SDcard adaptor)

The first four are easy and cheap to source from Banggood or Aliexpress. For example (Banggood product IDs):

* Arduino UNO: Arduino Compatible UNO R3 ATmega16U2 AVR USB Development Main Board, product ID 68537
* Prototyping board:Prototyping Shield PCB Board For Arduino, product ID 995386
* SD adaptor: Micro SD TF Card Memory Shield Module SPI Micro SD Adapter For Arduino, product ID 919914
* Header pins: 50 Pcs 40 Pin 2.54mm Single Row Male Pin Header Strip For Arduino Prototype Shield DIY. product ID 1033758

For the Arduino, I recommend getting one with a socketed DIL AVR chip.


Use the notes in NASdsk.ino and doc/nascom_pio.pdf and the photos to guide you. There are about 20 wires to connect.

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

## First Boot

You need an EPROM on the NASCOM. The code is in
nascom/sdcard/host_programs/polydos_util_rom.asm and suitable base addresses are
0xd000 and 0xd800 -- there are pre-built binaries at each of those start
addresses and you can use nascom/converters/nascon to convert the binary to
other formats (eg, .hex .nas) to suit your programmer.

Next, you need an FAT-formatted SDcard. The code expects to find disk images
named DSK0.BIN, DSK1.BIN, DSK2.BIN, DSK3.BIN, which will be drives 0-3
respectively. At least one of them must be bootable. I recommend that you copy
all of the images from nascom/PolyDos/lib onto your SDcard, then make a copy of
PD000.BIN as DSK0.BIN and copy three other images for the other disks. From
PolyDos, use the SDDIR and SETDRV utilities to inspect the SDcard and mount
different disk images.

All the files should be copied to the root directory of the SDcard.


### EPROM programming service

If you want an EPROM erased and programmed with this code, I will be happy to do
this on a cost-of-postage basis. Contact me to make arrangements.

