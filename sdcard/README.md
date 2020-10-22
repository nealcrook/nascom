# NASdsk and NAScas

This is a project to provide SDcard-based storage for a NASCOM. It has been
tested on NASCOM 1 and NASCOM 2 computers running NAS-SYS monitors.

The hardware is cheap and simple and basically consists of an Arduino and an
SDcard adaptor. A PCB is available but it's equally feasible to build a
hand-wired unit using protoype cards.

* NASdsk - Arduino sketch. This design connects to the NASCOM PIO and uses a custom EPROM
on the NASCOM. It allows the PolyDos operating system to boot and run using virtual disk images stored on SDcard.

* NAScas - Arduino sketch. This design connects to the (digital side of the) NASCOM tape
interface. It acts as a "digital tape-recorder" allowing the existing read and write commands to store data on SDcard instead of audio tape. No modifications or EPROMs are required on the NASCOM.

* sd_merged - Arduino sketch. This design superceeds NASdsk and NAScas by combining both sets of
functionality into a single image.

* setup - Arduino sketch. Run this once on the hardware to program the profile record into EEPROM.


Other stuff here:

* doc -- a full user-guide, construction notes, schematics, details of the protocols and command-sets.

* photos -- photos of the PCB and of the prototype units. Screenshots of the software running on my NASCOM 2.

* host_programs -- z80 software related to these two projects, including
software for "scraping" a floppy disk into a binary virtual disk image.

* kicad -- the kicad database for the schematic and PCB.

Relevant stuff elsewhere:

../converters has software for converting files between various formats,
including NASCOM-related audio and digital formats. It also contains a tool for
manipulating PolyDos disk images.

## EPROM programming service

If anyone is looking to build a nascom_sdcard and has an EPROM that they need
erasing and programming, I will be happy to do this on a cost-of-postage
basis. Contact me to make arrangements.
