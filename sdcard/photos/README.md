# PCB

Photos of the assembled PCB, using an Arduino NANO and an SDcard adaptor. The two black connectors connect directly to a  NASCOM 2 "serial" and "pio" ports using ribbon cable. Connections to a NASCOM 1 use J2, J4 and J7.

![pcb_top.jpg](pcb_top.jpg?raw=true "Top view of assembled REV-A PCB")
![pcb_bottom_eco.jpg](pcb_bottom_eco.jpg?raw=true "Bottom view of assembled REV-A PCB, showing ECO wires")


# Software running (NAScas)

The "serboot" program loads and starts automatically at powerup, resulting in the NAScas> prompt:
![nascas_boot.jpg](nascas_boot.jpg?raw=true "serboot loading to the NAScas prompt")

Using NAScas:
* "DF" gives a directory listing of the Flash filesystem within the Arduino.
* "RF LOLLIPOP.GO" cues up this file to be loaded across the serial (cassette) interface
* "." exits NAScas and returns to the NAS-SYS prompt
* "R" is the normal NAS-SYS command to read from cassette; the normal block-loading messages are printed.

![nascas_read_flash.jpg](nascas_read_flash.jpg?raw=true "Reading a file from Flash")

Using NAScas: the "HELP" command:
![nascas_help.jpg](nascas_help.jpg?raw=true "Output from NAScas help command")

Using NAScas: "DS" gives a directory of the SDcard filesystem:
![nascas_directory_sd.jpg](nascas_directory_sd.jpg?raw=true "Output from the NAScas DF (directory flash) command")



# Software running (PolyDos)

PolyDos booting from SDcard using prototype hardware (Arduino Uno):
![system.jpg](system.jpg?raw=true "PolyDos booting")

PolyDos directory listing of virtual disk image:
![boot.jpg](boot.jpg?raw=true "PolyDos directory listing")

PolyEdit running:
![polyedit.jpg](polyedit.jpg?raw=true "PolyEdit running")

PolyZap assembler running:
![polyzap.jpg](polyzap.jpg?raw=true "PolyZap running")



# Prototype boards

Assembled NAScas (serial connection) prototype using Arduino Uno:
![nascas_assembled.jpg](nascas_assembled.jpg?raw=true "NAScas prototype")

Modified PolyDos boot EPROM installed in my NASCOM 2:
![eprom.jpg](eprom.jpg?raw=true "PolyDos boot EPROM")

Assembled parallel-interface prototype using Arduino Uno:
![assembled.jpg](assembled.jpg?raw=true "Assembled parallel-interface adaptor")


Top view of prototype shield for parallel-interface using Arduino Uno:
![top.jpg](top.jpg?raw=true "Top view of prototype shield")

Bottom view of protoype shield for parallel-interface using Arduino Uno:
![bottom.jpg](bottom.jpg?raw=true "Bottom view of prototype shield")




