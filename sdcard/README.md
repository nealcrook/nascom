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

## Contents

* photos/         -- photos of the assembled board sandwich
* nascom_sdcard   -- the C code for the Arduino (includes wiring instructions)
* host_programs   -- Z80 code for the NASCOM. A "library" of subroutines and some example programs for using them.
* doc/            -- description of the protocol and the command-set



## Arduino prototyping card

The boards I have are marked "Protoype Shield V.5". They have some design errors:

* The "GND" between AREF and D13 is actually connected to 5V. If you've soldered a
header pin to this position, cut the pin off before attaching the board to an
Arduino (otherwise you will short the power rails).

* The power tracks marked "GND" and "5V" are randomly wrong. Buzz each one out
  to see what it connects to before using it!

