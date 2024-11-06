# Tools for NASCOM 4

Tools for creating and manipulating SDcard image for NASCOM 4.

* make_rom_menu - creates the part of the SDcard image used by the Special Boot
  ROM (SBR), which includes the boot menu, profiles and ROM images. This script
  is not interactive; to change its behaviour you must edit the code
  directly. Refer to the [nascom4_handbook.pdf](../docs/nascom4_handbook.pdf)
  for details.
* make_polydos_floppy_set - creates the part of the SDcard image used by PolyDos
* make_cpm_floppy_set - creates the part of the SDcard image used by CP/M
* sdcard_editor - script for manipulating the SDcard image. Can be used to
  create the image and to insert or remove PolyDos and CP/M disk images from
  the SDcard image. Can be used as a command-line tool or through its command-line
  interface, which provides detailed help.
* nascom4_sdcard.img - default SDcard image for NASCOM 4 (details below)

Example usage:

````
$ ./make_rom_menu
$ ./make_polydos_floppy_set
$ ./make_cpm_floppy_set
$ ./sdcard_editor nascom4_sdcard.img ins-poly=polydos_floppy_set.img ins-cpm=cpm_floppy_set.img
$ rm polydos_floppy_set.img cpm_floppy_set.img
````

The result is "nascom4_sdcard.img" which should be 34,078,720 bytes in size, made up of:

````
      512 * 1024 =    524,288 bytes menu and ROM images
16 * 1024 * 1024 = 16,777,216 bytes PolyDos disk images
16 * 1024 * 1024 = 16,777,216 bytes CP/M disk images
                   ----------
                   34,078,720
````

Later, you could change the menu (by editing make_rom_menu) and rebuild the image like this:

````
$ ./make_rom_menu new.img
$ ./sdcard_editor nascom4_sdcard.img ins-menu=new.img
$ rm new.img
````


== nascom4_sdcard.img ==

This image contains boot ROMs, a set of PolyDos disk images and a set of CP/M
disk images. From PolyDos the first 4 images are available as drives A..D and
the other images can be "mounted" using the PolDos "setdrv" utility.

From CP/M the first 2 images are available as drives A..B (drives C..D are
expected to be physical 48tpi PERTEC drives, or a suitably configured gotek
device).

PolyDos images
````
0: PD0 System for N4: system disk also with pascal overlay and nascom4 graphics demos
1: PD1 for N4:        BASIC games
2: PD2 for N4
3: PD3 System for N4: Bob Edwards Modified Pascal and N4 hires graphics
4:
5:
6:
7:
8:
9:
A:
B:
C:
D:
E:
F:
````
CP/M images
````
0: boot/M80/L80 Bios sources, PIP, utilities
1: wordstar
2: turbo Pascal
3: turbo Modula 2
4: MBASIC + Creative Computing BASIC programs 1 of 2 ("MBASIC MENU" to start)
5: MBASIC + Creative Computing BASIC programs 2 of 2 ("MBASIC MENU" to start)
6: Adventure
7: Chess
8: MBASIC + games
9: MBASIC + games
A: MBASIC + games
B: Zork
C:
D:
E:
F:
````
