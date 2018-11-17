18Nov2018 -- this project is a work-in-progress. Use nascom_sdcard if you want something
finished and documented and working.



should get the framework working with the softserial library then switch to the hardware pins - allow debug

nail down the commands

get as much commonality with the pio as possible

double-assign pins in the mean-time as long as they do not interfere if one interface is idle

write the control program and make sure it's small.

use MFLP to turn the drive LED on and off - no, I never need to do that!
use SOUT to send characters to the serial port

I think input characters are detected with normal RST IN

cannot simply do this:

E1000 hello this is a command

..because NAS-SYS will generate an error; expects ONLY hex stuff. Instead, it must be:

EC800
SDcard> hello this is a command
SDcard> .


- dot at the end of a command or on a blank line will terminate
- R after reset will implicitly read the boot program
- load from .cas (binary literal, start on DRIVE) or from extracting from PolyDos disk image or from .txt file
  (stream in as though typed)

commands:

help
rc temp.cas -- read CAS file
rd temp.zzz -- read from DISK image, file temp.zzz
               if it has .BS extension and start address of 10D6, prepend BASIC header
rb temp.cas -- read CAS file with BASIC header
ma fooby    -- magic word for ra
ra temp.txt -- read ASCII -- fooby is the magic word to start the supply of text.
sd DISK.BIN -- set disk image to use for rd command
ag          -- toggle auto-go flag. When true, files read from disk image (where execution
               address is Known) are followed by an "Exxx <RETURN>" string
to xxxx     -- relocate this code to somewhere else, xxxx

similarly for write. Also, auto-increment names.


Help screen:

v                                              v
012345678901234567890123456789012345678901234567

RI WI        -- read increment/write increment
                (last 2 digits of filename)
RV WV <file> -- read/write from virtual disk
RF <file>    -- read from FLASH storage
RC WC <file> -- read/write cas from SD
VD <file>    -- select virtual disk
AE           -- auto-execute on reset
AG           -- auto-go after reading file
BH           -- prepend BASIC header
INFO HELP    -- what they say
.            -- exit CLI
EC80         -- restart CLI
TO xxxx      -- relocate CLI to xxxx
SP n         -- set speed

others:

MA FOOBY     -- set magic word of FOOBY for RA command
RA FOO.TXT   -- read ASCII -- FOOBY is the magic
                word to start the supply of text
DIR
DEL
?? print spooler



-> auto-increment
-> write commands


The RI WI AE AG BH commands all set/clear/toggle flags

RI 0          - clear flag
RI 1          - set flag
RI            - toggle flag
RI blah       - flag unchanged





1/ DONE assign pins
2/ DONE get loopback working from NASCOM out/in
3/ DONE write bootstrap
4/ DONE source bootstrap as CAS file on-the-fly, and start it up like a GENERATE
5/ DONE add ability in bootstrap to relocate itself
6/ DONE get command loop going, including help and to commands
7/ set up external clock
8/ source a couple of big files including BASIC files and see how fast NASCOM can go
9/ rewire SD board, rework that code, add new read- command, and revamp ROM

Next:

- formalise the command set and arguments, code them
- Write proper help screen
- Implement TO
- DONE Implement rules for telling read from write
- Implement read cas
- Implement write cas
- Implement implement auto-increment of file names
- Implement read from disk image
- Implement auto-go flag
- Implement write to disk image
- Implement external clock and see how fast it can go
- DONE Tidy up code structure
- Change boot code to be stored in EPROM.
- Choose pins, migrate other board/code to use them and itegrate the two lumps of code.. cannot use current cassette code
  with SDcard until I migrate to a board with an SDcard..
