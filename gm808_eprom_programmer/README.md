# Gemini GM808 EPROM Programmer

Also known as the Bits & P.C.S EPROM Programmer.

This was a small board that plugged into the NASCOM PIO socket and (via a couple
of flying leads) to the -5V and +12V power supply of the NASCOM (0V and +5V were
taken from the PIO connection).

It had 2 24-pin EPROM sockets, allowing an EPROM to be programmed from a
"master" in the "Donor" socket without the need to load the EPROM contents into
memory (this seems like an extravagent design to me now, but maybe there were
systems that did not have enough spare memory for the programming code and the
EPROM image..)

The original design supported 2708 (1Kbyte x 8) and 2516/2716 (2Kbyte x 8,
single supply rail +5V) parts. I modified my board to also support the 2732
(4Kbyte x 8) part, but I cannot find any notes to describe the hardware design
changes that I made. My board is in a custom case that I made.

I also modified (patched) the original control software to support 2732 as an
additional device type.

The control software is provided in the documentation, in source form. I
disassembled my patched version, which I named "nublo" and confirmed that the
resultant source matches (apart from my patches) the listing in the
documentation.

Files here:

* two photos of my cased unit
* a scan of the original documentation (includes schematics and source code listing)
* the source code, nublo.asm
* the executable, nublo.bin (load and execute from $1000)
* a control script for the PERL CPU:Z80::Disassembler module, to disassemble the binary and insert labels to match the original source.

## Using the EPROM programmer with nascom_sdcard

Since nascom_sdcard and the gm808 both use the PIO, I wondered whether I could
use them at the same time. From examination of the schematics, PIO port A is
directly connected to the EPROM data lines and port B is input-only to the
gm808.

I created a program SDOFF to shut down nascom_sdcard
(sdcard/host_programs/sdoff.asm). I created a daisy-chain cable and connected
both the gm808 and nascom_sdcard hardware. Now, the operating procedure is
this:

* With NO EPROMs in the gm808, and the gm808 turned off, boot the system to PolyDos using nascom_sdcard
* Load the programming software into memory -- but do not execute it -- eg, "$LOAD NUBLO" (it will load at $1000)
* Load any EPROM image to be programmed into memory -- eg, "$LOAD ROM.GO 2000"
* Shut down nascom_sdcard -- eg, "$SDOFF"
* Backspace over the PolyDos "$" prompt, and execute the programmer software -- eg, "E1000"
* Follow the instructions and perform any EPROM programming.

If you have loaded data from an EPROM to memory and want to save it, do it like this:

* Turn off the EPROM programmer and remove any EPROMs from it
* Reset the NASCOM 2 (this is non-destructive)
* Boot the system to PolyDos using nascom_sdcard
* Save the memory image to a file -- eg, "$SAVE ROM1.GO 2000 2400", "$SAVE ROM2.GO 2400 2800", etc.
