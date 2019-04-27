# nascom_sdcard and NAScas

Here are two projects to provide SDcard-based storage for a NASCOM. Both are
based on Arduino Uno hardware and an SDcard adaptor, and should work on NASCOM 1
and NASCOM 2 computers running NAS-SYS monitors.

* nascom_sdcard - this design connects to the NASCOM PIO and uses a custom EPROM
on the NASCOM. It allows the PolyDos operating system to boot and run using virtual disk images stored on SDcard.

* NAScas - this design connects to the (digital side of the) NASCOM tape
interface. It acts as a "digital tape-recorder" allowing the existing read and write commands to store data on SDcard instead of audio tape. No modifications or EPROMs are required on the NASCOM.

There is code, documentation and photos for each of the designs in the nascom_sdcard and NAScas directories, respectively.

Also here is the directory host_programs, which contains z80 software related to
these two projects, including software for "scraping" a floppy disk into a
binary virtual disk image.

Relevant stuff elsewhere:

../converters has software for converting files between various formats,
including NASCOM-related audio and digital formats. It also contains a tool for
manipulating PolyDos disk images.

## EPROM programming service

If anyone is looking to build a nascom_sdcard and has an EPROM that they need
erasing and programming, I will be happy to do this on a cost-of-postage
basis. Contact me to make arrangements.
