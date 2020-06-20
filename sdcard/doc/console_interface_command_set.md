# Console interface command set

The Arduino on the nascom_sdcard hardware provides a USB connection that
implements a virtual UART. When linked to a terminal emulator on a PC it reports
status and debug messages. If the code is built with "#define CONSOLE" this
interface also provides a restricted command interface called the "console".

The following commands are supported:

* Directory of SDcard
* Write: transfer file from host filesystem to SDcard
* Read: transfer file from SDcard to host filesystem
* Erase file on SDcard
* Read byte from Arduino EEPROM
* Write byte to Arduino EEPROM

The use-case is to allow cross-hosted development of NASCOM code on a PC without
need to keep swapping the SDcard back and forth.

The console interface protocol uses ASCII so that it can be mingled with
status/debug messages. However, it is designed to be accessed though a special
program on the PC, not simply a terminal emulator. For that reason there is
almost zero error/sanity checking on arguments within the Arduino code: the
implementation was focussed on small code size through the reuse of existing
code.

On a PC, the PERL program called [NASconsole](../host_programs/NASconsole) is
used to communicate across this interface.

[NASconsole](../host_programs/NASconsole) has a built-in "help" command that
describes its command-set. The descriptions here document the low-level protocol
between [NASconsole](../host_programs/NASconsole) and the Arduino code.

## Directory

````D<cr>````

Only the D is significant. Any characters between D and <cr> are ignored.

Response (success):
````Ack 0<cr><lf>multiple lines of crlf-delimited text````

Error response:
````Ack 1<cr><lf>```` - no SDcard present.

The responses are ASCII, so "Ack 1" is the 5 bytes 0x41, 0x63, 0x6b, 0x20, 0x31.
Even Ack codes signal success, odd Ack codes signal errors.

## Erase

````E filename <cr>````

Only the E is significant. Any additional characters before the first
space are ignored. filename is an 8.3 MSDOS filename (format is
checked). Note the extra space at the end of the line, before the <cr>.

Response (success):
````Ack 2<cr><lf>````

Error responses:
````Ack 1<cr><lf>```` - no SDcard present.
````Ack 3<cr><lf>```` - bad filename or file not found.

## Write

````W filename length <cr>````

Only the W is significant. Any additional characters before the first
space are ignored. filename is an 8.3 MSDOS filename (format is
checked). Length is the number of bytes in the file (decimal number
in ASCII). Note the extra space at the end of the line, before the <cr>.

Response (success):
````Ack 4<cr><lf>.```` - the "." indicates that the console should send the first chunk of
the file (512 or the runt/remaining bytes). An additional "." is
sent as a request for each successive chunk of data. When all the data bytes have been transferred there is a final response
of ````Ack 8<cr><lf>````.

Error responses:
````Ack 1<cr><lf>```` - no SDcard present.
````Ack 5<cr><lf>```` - bad filename or file not found.

## Read

````R filename <cr>````

Only the R is significant. Any additional characters before the first
space are ignored. filename is an 8.3 MSDOS filename (format is
checked). Note the extra space at the end of the line, before the <cr>.

Response (success):
````Ack 6<cr><lf>length<cr><lf>bytestream```` - Length is the number of bytes in the file (decimal number
in ASCII).

Error responses:
````Ack 1<cr><lf>```` - no SDcard present.
````Ack 7<cr><lf>```` - bad filename or file not found.

## Put byte to EEPROM

````P address data <cr>````

Only the P is significant. Any additional characters before the first
space are ignored. Address is in hex, data is in hex. No range check
is done; if the command is incorrectly formatted it will return
success but not actually perform a write.

Response (success):
````Ack 10<cr><lf>````

Error response:
````Ack 1<cr><lf>```` - no SDcard present.

## Get byte from EEPROM

````G address <cr>````

Only the G is significant. Any additional characters before the first
space are ignored. Address is in hex. No range check is done.

Response (success):
````Ack 12<cr><lf>byte````

Error response:
````Ack 1<cr><lf>```` - no SDcard present.

## Unrecognised commands

For any other "command"

Error responses:
````Ack 9<cr><lf>```` - command not recognised.
````Ack 1<cr><lf>```` - no SDcard present.

The SDcard check is always done; that's why the error response can occur even
for commands that do not require SDcard.
