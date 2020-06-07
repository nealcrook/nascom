# sd_merged

This is an experimental merge of NAScas and nascom_sdcard with the functionality
of both. All three interfaces are available, but only one can process a command
at any time; you are expected to use them in a "polite" way!

At reset, the serial interface loads and starts the "NAScas" command-line code
on the NASCOM. If you want to use the console interface start this up ASAP, because
it resets the Arduino. Finally, type a . to quit NAScas and type ED800 (or whatever)
to start PolyDos.

Now, all 3 interfaces are live!


## Migration

The first is REQUIRED, the second is RECOMMENDED

1. Previously, NAScas looked for and used a directory named NASCOM if it
existed. The nascom_sdcard code simply looked in the SDcard root directory. Now,
both pieces of functionality look for and use a directory named NASCOM, if it
exists. Therefore, if you have PolyDos disk images in the SDcard root, move them
to the NASCOM directory.

2. the nascom_sdcard code now has the ability to support multiple disk
formats. This is a stepping-stone to running NASDOS. This is achieved by a data
record programmed in EEPROM. To set this up, start up the console and issue the
command "PROFILE". Now, on your SDcard, rename the 4 PolyDos images thus:
POLYDOS0.DSK POLYDOS1.DSK POLYDOS2.DSK POLYDOS3.DSK (were DSK0.BIN etc.)

## Known bugs

1. If you exit the console, PolyDos issues an "Error 31" and returns to
NAS-SYS. You can re-start it and it reboots OK.

