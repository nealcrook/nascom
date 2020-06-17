# Parallel interface programming

These notes give some guidance on how to write a program that runs on the NASCOM
and uses the NASCOM PIO to access files stored on the SDcard plugged into the
nascom_sdcard hardware.

In these notes, the NASCOM is sometimes referred to as the Host and the
nascom_sdcard is generally referred to as the Target.

Programs can be divided into two groups:

* Self-contained/stand-alone programs. The function of such programs must
  include the initialisation of the hardware.

* Utilities that run from, for example, PolyDos. In this case, the hardware has
  already been initialised and the program can start issuing commands straight
  away.

It is pretty-much essential to write programs in z80 assembler. This can be done
either on the NASCOM directly or on some other machine; I tend to develop on a
PC running Linux, using the nongnu z80 assembler.

The program [sd_util.asm](../host_programs/sd_util.asm) is an example of a self-contained/stand-alone program.

The program [sddir.asm](../host_programs/sddir.asm) is an example of a PolyDos utility.

Both of these programs start with some defines for command names and then
include the file [sd_sub1.asm](../host_programs/sd_sub1.asm) -- that file
contains a set of low-level subroutines for implementing the protocol:

* putcmd -- send an 8-bit command
* putval -- send an 8-bit data value
* gorx -- change direction to receive
* gotx -- change direction to transmit
* getval -- read an 8-bit data value

After initialisation, the interface is set to transmit (ie, to send data from
the NASCOM to the Target). At the completions of every command, the interface
should be set back to transmit, ready for the next command.

The [Parallel interface command set](parallel_interface_command_set.md)
describes all of the commands supported by the Target. For example, the command
LOOP accepts 1 byte argument and sends 1 byte response.

Therefore, the command sequence would look like this:

* load the command code into A
* call putcmd
* load the argument into A
* call putval
* call gorx
* call getval
* call gotx

The response byte is in A (gotx has been deliberately designed to preserve
AF). Really, it's as simple as that.

Once you understand that simple example, you are ready to examine
[sddir.asm](../host_programs/sddir.asm), and once you understand that you can
delve into [sd_util.asm](../host_programs/sd_util.asm).

Each of the stand-alone programs in [sd_util.asm](../host_programs/sd_util.asm)
starts with a call to the subroutine hwinit (which is defined in
[sd_util.asm](../host_programs/sd_util.asm)).

````
;;; setup: initialise the PIO and the interface.
;;; By experiment, the output word has to be the next thing
;;; written, not simply the next thing written to that port.
hwinit: call    a2out           ;port A to outputs
        ld      a, $cf          ;"control" mode
        out     (PIOBC), a
        ld	a,1
        out     (PIOBC), a      ;port B LSB is input
        out     (PIOBD), a      ;init outputs H2T=0, CMD=0

;;; train the interface
        ld      b, 8            ;number of times to do it
train:	ld      a, CNOP
	call    putcmd
        djnz    train
        ret
````

"training" the interface toggles the protocol signals to ensure that the Target
is in-sync and is responding. The Target needs to cope with the situation where
the nascom_sdcard is attached to the serial connector but not to the PIO; once
it sees sufficient well-behaved toggles on the protocol signals it considers the
interface to be enabled and will respond to commands.
