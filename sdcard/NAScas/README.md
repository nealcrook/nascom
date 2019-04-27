# NAScas

NAScas is a project to provide SDcard-based storage for a NASCOM by interfacing
to the (digital side of the) cassette interface.

My initial motivation was to provide a mechanism that would work without the
need for any expansion on the NASCOM or any on-board software, and which would
work for all existing software.

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

