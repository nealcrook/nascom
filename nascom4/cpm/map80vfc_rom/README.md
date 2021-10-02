# MAP80VFC ROM CP/M boot code modification

The MAP80VFC card provides a pageable ROM that contains a floppy bootstrap
loader along with control software for the video functionality.

When the card is decoded at address 0 after reset, the floppy bootstrap loader
executes. Its function is to load track 0 sector 0 into RAM at 0C00H, check that
the first two bytes of the loaded code contain the "magic value" 3038H and, if
so, to jump to address 0C02H. Usually, this is used to load CP/M.

In order to load CP/M from the SDcard, an alternative bootstrap loader is
required.

I considered a couple of implementation options, but chose to modify the
original ROM. Rather than disassembling the whole ROM I followed the code
execution from address 0, extracted the fragment of code associated with the
boot loader, disassembled it, wrote a new version and patched it into the same
locations in the ROM (the new code is smaller but padded to match the size of
the original)

I know of 2 versions of the MAP80VFC ROM:

* [map80vfc_boot_rom.bin](../../../ROM/map80vfc/map80vfc_boot_rom.bin) -- version AW1.11
* [map80vfc_boot_rom_newver.bin](../../../ROM/map80vfc/map80vfc_boot_rom_newver.bin) -- version ASW2.01

The boot code starts at different places in each of them and is slightly
different in each case, but the overall functionality is the same and the
replacement code is identical (just assembled for different start addresses and
padded to different sizes.

The script manipulate_vfc_rom is used to semi-automate the modification. Refer to the
comments in that script.

The end result is the 2 ROM images here:

* [map80vfc_boot_rom_sd.bin](map80vfc_boot_rom_sd.bin)
* [map80vfc_boot_rom_newver_sd.bin](map80vfc_boot_rom_newver_sd.bin)

These can be used in David's map80nascom emulator or in the boot menu of a real
NASCOM4.

An alternative to modifying the ROM (which is part of the FPGA image) is to use
a stand-alone boot-loader to start up from SDcard, leaving the MAP80VFC ROM
unchanged which means the FPGA does not need to be reprogrammed and the NASCOM4
boot menu can include options to boot either from a floppy (start MAP80VFC ROM)
or from SDcard (start stand-alone boot-loader). The stand-alone boot-loader is here:

* [boot_code_standalone_sd.bin](oot_code_standalone_sd.bin)
