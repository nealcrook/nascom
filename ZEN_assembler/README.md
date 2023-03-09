# The Zen Z80 Editor/Assembler

The original version of the Zen Z80 editor/assembler was written by John
Hawthorne and marketed by Newbear. As well as a "Standard" (port-it-yourself)
edition, there were editions for the Nascom, Video Genie, Sharp, Einstein and
TRS80 machines.

It seems that the original versions came complete with source code on tape.

Some versions included a debugger, but the Nascom version did not (presumably
because it would simply have duplicated facilities already available in the ROM
monitor).

The manual for the Sharp version includes a printout of the source code, which
includes the comments "AVALON ZEN WRITTEN BY JOHN HAWTHORNE COPYRIGHT (C) 1980
BY AVALON SOFTWARE OF ENGLAND... New parts, Copyright (C) 1983 Andrew Henson,
Apollo Software"

In http://www.fabsitesuk.com/tandy/trs8bit_year07.pdf, Laurie Shields wrote: "I
am deeply indebted to a large number of people especially John Hawthorne who
wrote the original Zen.. Zen in its original cassette only form is marketed by
Newbear for the TRS80 and other Z80 machines (Sharp, Nascom etc) and in its
upgraded enhanced format for the TRS80 Cassette, Aculab or Disc by Laurie
Shields Software."

The Centre For Computing History, Cambridge, has a number of "Zen" resources,
including a manual for the "Standard" version, marked "Copyright 1979, Avalon
Software" -- stop press: I found that I had a copy of that document (see links
below).

## Copyright

Multiple versions of this software for multiple platforms can be found using
simple web searches. My goal is to preserve the Nascom version and make it
available for study and possible repurposing on other retro/homebrew Z80
platforms.

If any copyright holder still exists and objects to this, please contact me and
I will remove any contravening material.

## Origin

The version here originated from http://www.nascomhomepage.com/asm/zen.zip and
was originally supplied to that site by Nick Webb. Nick wrote: "I modified it to
understand "SCAL" and "RCAL", plus it now handles "RETN", which the original ZEN
didn't"

That archive also includes a PDF scan of the manual from the TRS80 version.

## Versions

The version from http://www.nascomhomepage.com/asm/zen.zip loaded at 0C50H and
ran under the control of the Nascom Nasbug T4 monitor. I have successfully
rebuilt it from source and confirmed that the binary matched the source code.

Using an OCR'd version of the TRS-80 manual I created a new manual that is
correct for the Nascom version. It has minor layout and content changes from the
original and contains a new appendix on "internals".

Using the T4 version as a starting point I created a version to run under
NAS-SYS 1 or 3.

## Overview

The Zen Editor/Assembler occupies about ~3.5Kbyte of memory. Additional memory
is required for a symbol table and for the source code. It includes a simple
line-based editor. It is a 2-pass assembler that aborts on the first encountered
error. It is reputedly more that 2x the speed of ZEAP (the other classic Nascom
assembler).

In its original form, Zen is not ROM-able: it contains workspace within its
memory footprint. Examination of the source code is educational, in particular
the use of various memory-saving coding techniques.

Zen supports 3 I/O devices:

* VDU - the Nascom screen and keyboard
* Cassette
* External

The code can be patched to insert drivers for "External" (eg, a printer).

Source code must be memory-resident. The object code can be written to memory
(using the LOAD pseudo-op) or to cassette, in .NAS format (like a hex dump).

Source code can be stored to or loaded from cassette, using a Zen-specific tape
format.


### T4 Version

Files:

* ZEN.NAS - Loads and executes at 0C50H
* ZENSRC.NAS - Source that can be loaded for reassembly (requires ~20Kbytes to load)
* ZEN_t4.asm - Source
* ZEN_t4_annotated.asm - Source with comments based on Mike and Neal's code inspection
* ZEN_t4.asm - reformatted source for easy inspection (requires ~34Kbytes to load)
* ZEN_t4.lst - assembly listing

To rebuild from source:

1. Start up an emulator using the T4 monitor, load ZEN.NAS and ZENSRC.NAS and
specify an output file. For example:

    ./map80nascom roms/nasbugt4.nas ~/retro/ZEN.NAS ~/retro/ZENSRC.NAS  -o ~/retro/serout.cas


2. Edit the assembler's end-of-text pointer in memory at 0CC9H (the current
content is 2400H stored low-byte-first). Inspect ZENSRC.NAS and observe that the
last used location (containing 0DH) is 741BH. Use "MCC9" then enter "1C 74."
(the first free location. The . exits the M command) then start Zen using
"EC50". You should see the "Z>" prompt. Now read the manual (it's quite short:
11 pages).


### NAS-SYS Version

Files:

* ZENNS.NAS - Loads and executes at 1000H
* ZENNSSRC.NAS - Source that can be loaded for reassembly (requires ~20Kbytes to load)
* ZEN_nassys.asm - Source
* ZEN_nassys.lst - assembly listing

To rebuild from source:

1. Start up an emulator using the NAS-SYS monitor, load ZENNS.NAS and ZENNSSRC.NAS and
specify an output file. For example:

    ./map80nascom ~/retro/ZENNS.NAS ~/retro/ZENNSSRC.NAS  -o ~/retro/serout.cas


2. Edit the assembler's end-of-text pointer in memory at 1079H (the current
content is 2800H stored low-byte-first). Inspect ZENNSSRC.NAS and observe that
the last used location (containing 0DH) is 790FH. Use "M1079" then enter "10
79." (the first free location. The . exits the M command) then start Zen using
"E1000". You should see the "Z>" prompt. Now read the manual (it's quite short:
11 pages).


### NAS-SYS Version assembled at 8000H

This version is assembled for execution at 8000H. The Source buffer (defined by
the contents of 8079H) starts at 9800H. This code generated by changing lines 1,
2, 52, 53 of the source file.

Files:

* ZENNS8.NAS - Loads and executes at 8000H
* ZENNS8.HEX - Same file, converted to Intel Hex format
* ZENNSSRC8.NAS - Source that can be loaded for reassembly (requires ~20Kbytes to load)
* ZENNSSRC8.HEX - Same file, converted to Intel Hex format
* ZEN_nassys8.lst - assembly listing

The source ZENNSSRC8.NAS is identical to ZENNSSRC.NAS (it does not have mods. to
lines 1, 2, 52, 53) but loads to addresses 9800H - E90FH.

After loading Zen and the source code, but before starting Zen, Edit the
assembler's end-of-text pointer in memory at 8079H (the current content is 9800H
stored low-byte-first). Inspect ZENNSSRC8.NAS and observe that the last used
location (containg 0DH) is E90FH. Modify memory at 8079H to "10 E9."  (the first
free location) then start Zen by executing at 8000H. You should see the "Z>"
prompt. Now read the manual (it's quite short: 11 pages).

To patch Zen to run on another system, inspect the source code (ZEN_nassys.asm),
identify modifications and inspect the listing (ZEN_nassys8.lst) to find the
corresponding locations in memory. Once you have it up-and-running, load the
source code into Zen, and use the editor to recreate the modifications
associated with the patch. That should allow you to assemble an image that
matches your patched image. Now you can proceed with any tidy-up that you may
wish to do. The following routines will require modification:

* KI - get character from keyboard
* Code in WT3 that does a SCAL ZIN/JR C, WT4 - this is checking for keyboard input in order to pause the listing output. Initially you could NOP this out.
* VID3 - output character to VDU
* SIN - serial input for cassette load
* EXT - "printer" output for generating listings
* SOUT - serial output for cassette save
* QUIT - return to monitor

There is some space (NOPs) around KI and EXT2 to fit small fragments of code.


### Manual

* ZEN_manual.odt -- LibreOffice source of a recreated manual
* ZEN_manual.pdf -- PDF of the recreated manual
* ZEN_manual_std.pdf -- I came across this in my loft box of NASCOM goodies; it's a copy of the manual for the "Standard" version, complete with porting information (I don't think I have the associated software though).





### Tools

Some simple PERL scripts for messing with assembler source code.


* reformat_source -- expand ZEN source code to make it more readable
* crush_source -- crush ZEN source code to make it as small as possible
* src2nas -- convert assembler source code to a .NAS file so that it can be loaded into memory alongside ZEN itself. Uses nascon (nascom/converters/nascon)

### Futures

* A portable version for easy porting to retro systems
* Abstraction of the assembler core as a assemble-engine

### ZEN Elsewhere

* Phil_G ported this code to Grant Searle's "32K Simple Z80": http://www.mccrash-racing.co.uk/philg/retro/retro.htm
* Phillip Green ported Phil_G's code to RC2014: https://github.com/feilipu/NASCOM_BASIC_4.7/tree/master/rc2014_Zen


### Feedback

If you find any errors or bugs or you decode some more of ZEN's inner workings, please let me know (email me or raise a github ticket)