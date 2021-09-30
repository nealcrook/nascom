# Tools for NASCOM 4

Tools for creating and manipulating SDcard image.

* make_rom_menu - creates the part of the SDcard image used by the Special Boot
  ROM (SBR), which includes the boot menu, profiles and ROM images. This script
  is not interactive; to change its behaviour you must edit the code
  directly. Refer to the [nascom4_handbook.pdf](../docs/nascom4_handbook.pdf)
  for details.
* sdcard_editor - script for manipulating the SDcard image. Can be used to
  create the image and to insert or remove PolyDos and CP/M disk images from
  the SDcard image. Can be used as a command-line tool or through its command-line
  interface, which provides detailed help.


TODO move some of the other scripts here and rationalise them, using sdcard_editor where possible.
