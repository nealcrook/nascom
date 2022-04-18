# NASCOM 4

![n4_assembled.jpg](photos/n4_assembled.jpg?raw=true "NASCOM 4 assembled")

* doc - user handbook, schematics and layout drawings
* tools - for creating SDcard image
* photos - the assembled board
* [PolyDos](PolyDos/README.md) - a port of PolyDos that uses the NASCOM 4 SDcard for virtual disk storage
* [cpm](cpm/README.md) - a port of CP/M 2.2 for the MAP80 VFC that uses the NASCOM 4 SDcard for virtual disk storage
* [tools](tools/README.md) - tools for creating and manipulating SDcard images for the NASCOM 4

The FPGA VHDL code and KiCad design database is here: https://github.com/nealcrook/multicomp6809/tree/master/multicomp/NASCOM4

The pre-built files for programming the FPGA are here: https://github.com/nealcrook/multicomp6809/tree/master/multicomp/NASCOM4/output_files

Current releases:

* Rev1.0 - first release (NASCOM4_rev1p0.pof/NASCOM4_rev1p0.sof)
* Rev1.1 - revisons to video control: (1) both VGA outputs are now active simultaneously. (2) The character generator is now programmable from the Z80 (details in the Handbook) (NASCOM4_rev1p1.pof/NASCOM4_rev1p1.sof)

Here are some videos of its evolution:

* [Part 1 - Video and other signs of life](https://youtu.be/_JwadOlg9jQ)
* [Part 2 - SDcard, boot menu, external memory, space invaders](https://youtu.be/p-a7hTUv8oo)
* [Part 3 - All of the old NASCOM monitor versions, plus memory test](https://youtu.be/0gcDnrQdldA)
* [Part 4 - A dedicated PCB](https://youtu.be/sYSOiYh90dM)
* [Part 5 - Connecting to nascom_sdcard board](https://youtu.be/8UQ8GHryUmE)
* [Part 6 - Running PolyDos and NASDOS](https://youtu.be/HzWPA__F-GE)
* [Part 7 - Using the floppy disk controller and Pertec FD250 drives](https://youtu.be/_6AczylQKXc)
* [Part 8 - Video updates: 2 outputs, programmable char generator](https://www.youtube.com/watch?v=ojr-Wo8GfHs)
* [Part 9 - Running PolyDos with local SDcard as storage](https://www.youtube.com/watch?v=Y3ZjsAyj-rs)
* [Part 10 - Running CP/M with local SDcard as storage](https://www.youtube.com/watch?v=TrpH2eu6iEs)
* [Part 11 - Programmable char gen demo, running WordStar, NAS-DIS/DEBUG, screen-swapping](https://www.youtube.com/watch?v=_7C4XY207Gc)


~~If anyone is interested in a PCB (note the need for some cuts and wires - refer to the handbook) the price is £10 and includes a couple of components that I bought in bulk (the SDcard adaptor and the FPGA sockets). I priced up the total parts cost at about £70 but there are multiple build options (again, refer to the handbook). If anyone wants a more complete kit, or an assembled board, let me know and I will work out prices (but there will be a lead time on those because of various parts coming from China).~~

^-- The REV A PCBs have all been sold. If there's interest, I'll order another batch (they will be REV B and require no rework!)


