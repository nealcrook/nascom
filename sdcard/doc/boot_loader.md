# Boot loader

The NASdsk PBOOT(pid) command is designed for use in the primary boot loader of
a CP/M system. For example, the MAP80 VFC board includes a pageable ROM that
includes a primary boot loader for CP/M. That boot loader is tiny (193 bytes)
and its function is to read the first sector from a floppy into memory at a
pre-defined address and jump to it. When I tried to code the equivalent for
nascom_sdcard I could not fit it in the size available, and so I designed the
PBOOT(pid) command as a way to perform that boot function in a single command.

A future project is to create a new MAP80 VFC ROM which boots using
nascom_sdcard. Contact me if interested.

Another use of the PBOOT(pid) command is in conjunction with a program
called [dskboot](../host_programs/dskboot.asm):

* dskboot (129 bytes in size) is stored in the Arduino FLASH filesystem

* dskboot can be loaded and executed by NAScas -- ie, it is loaded through the
  serial/cassette interface.

* when dskboot executes, it initialises NASdsk and issues a PBOOT(3) command.

* the effect of the PBOOT(3) command is to return 512 bytes of data from SDcard
  file SDBOOT0.DSK; dskboot loads that into memory at $1000 and then jumps to
  $1000.

The code in SDBOOT can do anything. There is a sample/test program in
[SDBOOT0.asm](../host_programs/SDBOOT0.asm) which just displays a message and
terminates.

SDBOOT0 could support a soft NASCOM in which a multiple ROM images (part of
SDBOOT0 code) are loaded into memory though a menu system.

The advantage of using NAScas to bootstrap load dskboot is that files can be
loaded much more quickly through the NASdsk interface than through the NAScas
interface.
