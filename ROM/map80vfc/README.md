Files pertinent to the MAP80 Video/Floppy Controller

map80_vfc_boot_rom.bin     -- 2kbyte image for the on-board boot EPROM
map80_vfc_chargen_rom.bin  -- 4kbyte image for the character generator
                              EPROM.

NAS051.BIN -- CP/M boot disk supporting MAP80 VFC and RAM boards with NASCOM CPU
NAS053.BIN -- CP/M boot disk supporting MAP80 VFC and RAM boards with NASCOM CPU

Each disk is 35 tracks * 10 sectors * 2 sides * 512 bytes = 350Kb (358400bytes)


# Boot process on NASCOM with MAP80 VFC

## ROM Bootstrap

When appropriately configured, the VFC ROM appears at address 0 and provides a
bootstrap loader for CP/M. This is the only part of the ROM that is not
relocatable code.

The function of the bootstrap loader is to load track 0 sector 0 from drive A
into memory at 0C00H using the 2797 FDC, then to jump to 0C02H.

The first 2 bytes of the image are expected to be the "magic number" 3038H.
If not, it's assumed not to contain a system track and the message "SYSTEM?"
is displayed. These are the messages that can be displayed:

BOOTING          - initial message
DISK ??          - error: no disk
SYSTEM?          - error: not a system disk
ERROR ?          - error: read error

## Boot sector (track 0 sector 0)

This code is restricted to/padded to 1 sector (512 bytes). The boot sector is
coded for a disk that is 35 tracks * 10 sectors * 2 sides * 512 bytes =
350Kb. The boot sector code is tiny (75 bytes) and padded to the sector size
with 0.

CP/M system reserves whole numbers of tracks. This configuration seems to
reserve 1 track (20 sectors) but only loads 18 sectors of the 19 available
(the 20th is the boot sector). 18 sectors = 9Kbytes, loaded at D200H-F600H.

After loading, the image is executed at an offset of 1600H from its load address
-- ie, D200H + 1600H = E800H which corresponds to the start of the BIOS and is
the "JMP BOOT" cold-start vector.

Somehow?? movcpm/build process (??) patches the value D200H in the boot sector
to change the load address depending upon the system memory map.

According to the alteration guide, the 2.2 distribution image is:

BSECT 1 sector  of 128 bytes
CCP  16 sectors of 128 bytes
BDOS 28 sectors of 128 bytes
BIOS  7 sectors of 128 bytes
-------
     52 sectors


## The system track (contents)

Looking at map80_cpm22_sys.txt/.asm:

* Expect CCP to start at D200H
* The jump table (17 entries) is at E800H
* According to alteration guide, expect jump vector table at 4A00H + b, implying b = 9E00H

(3400H start corresponds to memory size of 20Kbytes, so D200H start corresponds to (D200H - 3400H)/1024 + 20 = 59.5Kbyte

But.. the BIOS build script below indicates a 62Kbyte CP/M system ??
..and I think the system size might somehow include the 512byte boot sector?

* Expect BDOS to start at D200H + 16*128 = DA00H - seems credible; instruction there after run of NOPs
* Expect BIOS to start at D200H + 44*128 = E800H - seems credible; start of vector jump table after run of NOPs.
* Expect BIOS to end at   E800H +  7*128 = EB80H - but it ends at F5FF

.. so the BIOS is bigger (by about 2.5K) than the DR distribution and I suppose
that explains why all of the memory sizes are out.

CPM.SYS should contain the assembled "golden" CCP and BDOS but does not seem to
match the start of map80_cpm22_sys.bin as I would expect it to.. because it
actually contains some other stuff, too (the relocator program, for example?)

The build process below seems to *create* MOVECPM.COM??

SYSGEN is used to make a disk bootable, by writing the system track. The write
data can come from memory (after MOVECPM) or by reading the system track from
another disk. No files are copied/changed. Space is always reserved for a system
track, whether or not the disk actually contains valid data there.


# Notes on CP/M rebuild

The script to rebuild the BIOS and system:

XSUB                                           -- XSUB loads and relocates directly below CCP. When it is present
                                               -- in a submit file, it allows programs referenced by the file
                                               -- to accept input from the file -- in this case, the sysgen
                                               -- program accepts input from the submit file.
ERA P:*.BAK                                    -- clean up/make space on RAM-disk P
P:M80 =P:NBIOS                                 -- assemble the BIOS source
ERA P:M80.COM                                  -- make space on P by deleting the assembler
P:L80 /D:13F8,/P:1600,P:H1/N/X,P:NBIOS/E       -- link to make H1.HEX
P:L80 /D:33F8,/P:3600,P:H2/N/X,P:NBIOS/E       -- link to make H2.HEX
                                               -- L80 is used to link the two .HEX files for execution at two
                                               -- different addresses a multiple of 256 bytes apart. These are
                                               -- then loaded and the program executed by G500
                                               -- compares the two images and generates the relocation information.
                                               -- Thus movcpm can relocate cpm and the bios to the required address.
ZSID CPM.SYS                                   -- CPM.SYS is the golden version? on drive A?
IP:H1.HEX                                      -- set up code/symbol file for reading H1.HEX from P:
R3C00                                          -- read in file at offset $3C00
IP:H2.HEX                                      -- set up code/symbol file for reading H1.HEX from P:
R3C00                                          -- read in file at offset $3C00
                                               -- because they were linked at different addresses the same
                                               -- offset means they are loaded at different addresses
G500                                           -- execute at $500 (code in CPM.SYS) and exit ZSID
SAVE 54 MOVECPM.COM                            -- ? is this now back at the prompt? Save new memory image as MOVECPM.COM
ERA P:*.?E?                                    -- clean up/make space on P
MOVECPM 62 *                                   -- put it in place as a 62Kbyte CP/M system, do not execute it
SYSGEN                                         -- copy it to the system track
                                               -- CR => take it from memory
A                                              -- A => write it to drive A
                                               -- CR => ??
                                               -- CR => ??


Q: How do M80 and L80 get onto P in the first place?

The BIOS itself starts with the sector0 code that is the secondary bootstrap loader
(the primary boostrap loader is in the VFC ROM).

The image map80_cpm22_sys.bin is the code (excluding that boostrap loader) from
track 0 of the disk. The bootstrap loader loads that code at $D200 and enters it
at $E800.

Image contains CCP, BDOS, BIOS bolted together in that order

TODO: dissect that build script and document it, including descriptions of
CPM.SYS MOVCPM.COM SYSGEN etc.

