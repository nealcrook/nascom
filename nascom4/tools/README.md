# Tools for NASCOM 4

Tools for creating and manipulating SDcard image.

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
