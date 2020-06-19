# Miscellaneous programs for the NASCOM

These are programs in z80 assembler intended to run on the NASCOM.

They are in various states of development/evolution

## Stuff that's more-or-less finished/usable

## Other Stuff

For anything not listed above, consult the code to see what it does (which may or may not be in any way useful).

## Tools

I use the gnu z80 assembler, z80asm, version 1.8

This is a simple assembler that generates binaries directly (no linker step) in
the same way as the old-style NASCOM assemblers like ZEAP.

* build - a trivial script "./build foo" assume foo.asm and creates a .lst and .bin
