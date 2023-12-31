# Sources

These are ROMs for the Movement Computer Systems MCS-II NASCOM2-based drum machine.

* MCS-II_MON_V3.bin_golden     -- 2Kbyte Z80 code, origin 0x0000 (replaces NAS-SYS ROM)
* MCS-II_MIDI_1.bin_golden     -- 4Kbyte Z80 code, origin 0xc000
* MCS-II_MIDI_2.bin_golden     -- 4Kbyte Z80 code, origin 0xd000
* MCS-II_Graphics.bin_golden   -- 2Kbyte character generator for ASCII codes 0x80-0xff (instead of the regular NAS-GRA ROM)
* N2MD-2__AM27S19.bin_golden   -- Memory decode PROM image for NASCOM2

It looks as though the memory map of NASCOM ROMs was modified to allow 4K EPROMs
to be fitted.

The MON image is a heavily-modified version of NAS-SYS 3. It provides the same
RST calls (including most of the same RST SCAL calls). Modifications include a
text menu as a more user-friendly way of starting up the "Drum computer" code.


# Hardware

From the photos of the Mk1, the digital hardware consisted of:

* A 2-slot backplane (possibly Veroboard, but not clear)
* NASCOM2 main board and keyboard
* Gemini G802 64K DRAM card, without the paging logic and with 32Kbytes of RAM fitted.
* There is a ribbon connection to the PIO (and to the serial/tape and kbd connectors)
* There are some wire mods. around the WRAM socket of the NASCOM2 (IC48) which could be
  related to memory map mods. to accommodate the 4Kbyte MIDI ROMs.

The photo only shows the 2 boards as a stack so it's not possible to see any details
of other mods. to the NASCOM2.

The photos of the Mk2 includes a perspective view of the NASCOM2 board. From this it's
possible to see:

* The custom character generator EPROM
* The monitor EPROM
* A hacked up link block for memory decode
* One additional EPROM, fitted in socket A1. I expected to see a second EPROM in socket B1 but that is unpopulated. Perhaps it had been removed to perform the dump?

It looks as though all of the analogue electronics was controlled from the
PIO. The NASCOM UART was used to provide some degree of MIDI control and as a
way to save/retrieve drum settings via the cassette interface.

The designer explained that there is a timer tick that is used by the code, and
that there is no real-time control by the code of the analogue stuff: a sample
gets kicked (through a PIO output pin?) and then continues to completion without
further involvement from the code.

There is no sign in the code of any use of interrupts: no EI/DI/RETI/IMM
instructions, or any evident ISR code.

# Rebuilding from source

(no scripted way to do this at the moment; made tricky by my approach of disassembling all 3 ROMS into one source file)


# Guided disassembly

The script dis_all operates on MCS-II_MON_V3.bin_golden,
MCS-II_MIDI_1.bin_golden and MCS-II_MIDI_2.bin_golden to create mcs_dis.txt and
mcs_dis.asm. mcs_dis.asm was the starting-point for mcs_dis_edit.asm but the
latter has been hand-edited to add more comments and to change the formatting.


# WANTED

If you have any original documentation or other versions, please get in
touch.

I've seen a photo with a different monitor boot menu, which includes cold-start
and warm-start options for a word-processor (probably naspen?)
