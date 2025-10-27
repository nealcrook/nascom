# Nascom Keyboard

Using a raspberry pi pico and a PS/2 keyboard to mimic the software-scanned
keyboard of the NASCOM. For additional joy, the PS/2 keyboard supplies RESET and
(on the NASCOM 2) NMI and also a hex numeric pad.

![reva_assembled_top.jpg](photos/reva_assembled_top.jpg?raw=true "Nascom Keyboard adaptor, assembled")

* doc              - user handbook, schematics and layout drawings
* photos           - the assembled board
* bin              - software binary code images to load onto the Raspberry Pi Pico
* nascom_multicard - source code

See also nascom/doc/NASCOM_keyboard.pdf

If anyone is interested in a PCB, the price is £5 including postage.

To rebuild the source code from Linux (you need the SDK installed):

   $ cd nascom_multiboard/build
   $ cmake ..
   $ make

   then drag'n'drop the uf2 file to the pico.

   you can get debug output like this:

   $ minicom -b 115200 -o -D /dev/ttyACM0

