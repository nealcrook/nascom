# Nascom Keyboard

![reva_assembled_top.jpg](photos/reva_assembled_top.jpg?raw=true "Nascom Keyboard adaptor, assembled")

* doc              - user handbook, schematics and layout drawings
* photos           - the assembled board
* bin              - software binary code images to load onto the Raspberry Pi Pico
* nascom_multicard - source code

If anyone is interested in a PCB, the price is £5 including postage.

To rebuild the source code from Linux (you need the SDK installed):

   $ cd nascom_multiboard/build
   $ make

   then drag'n'drop the uf2 file to the pico.

   get debug output like this:

   $ minicom -b 115200 -o -D /dev/ttyACM0

