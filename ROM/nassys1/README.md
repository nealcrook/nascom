# Sources

The monitor source code:

    NASSYS1.asm

was recreated by disassembly of the binary (see below). NASSYS1 was a 2Kbyte
monitor that shared much code with its successor, NASSYS3. The source code
was published as part of the documentation, but no electronic copy existed.
Therefore, I used the electronic copy of NASSYS3 together with a guided
disassembly of the binary to recreate an accurate commented source.

The binary file:

    NASSYS1.bin_golden

is 2048 bytes in size. This was created as a binary dump from a ROM (not EPROM)
that was supplied with my NASCOM2 when I bought it from new as a kit.

The documentation:

    NASSYS1_manual.pdf

is a scan from the documentation set that was supplied with my NASCOM2. It was
supplemented by an index page which teenaged-me typed, and includes a complete
assembly listing and Dave Hunt's article "Simple Demonstration Programs using
NAS-SYS 1" which broke down the door to Z80 assembly language programming for
me.

# Disassembly

(This is just to explain how I did it; there is no need to repeat this step)

This was done iteratively as a 2-stage process. The first stage is to use the
PERL script "dis_ns1" which uses the a disassembler module and uses the
NASSYS1.bin_golden file to generate NASSYS1_dis.txt (a straight disassembly
considering everything as code) and NASSYS1_dis.asm (a disassembly guided by
definitions in dis_bbug. By running dis_ns1, inspecting NASSYS1_dis.asm file,
adding more definitions to dis_debug and running again, the source file can
be made more and more complete.

Unlike BBUG where I put a lot of effort into the dis_bbug file, dis_ns1 is
pretty minimal. Once the bulk of the code was exposed I moved onto the second
stage, which was to use a diff tool (ediff in emacs) to compare the code against
the NASSYS3.asm source. Since there are very significant similarities, the
NASSYS1.asm code was patched with the formatting, comments and labels from
NASSYS3.asm supplemented by consulting the NASSYS1 assembly listing from the
manual.

During this process, the second script "check_rebuild" was run regularly. This
does an assembly of the source and compares the binary against the
NASSYS1.bin_golden. Since the process is near-instantaneous, it's easy to make
tidy-up edits and continually check that the integrity of the source code has
not been compromised.

# Rebuild From Source

To assemble it, I use the GNU Z80 assembler (which is somewhat crude, but effective)
invoked using this script, named "build":


    #!/bin/sh
    #
    # $1 is the program base-name
    #
    # expect to find z80asm (from https://www.nongnu.org/z80asm/index.html) on $PATH
    z80asm ${1}.asm -l${1}.lst -o${1}.bin


so:

    $ ./build NASSYS1

creates:

    NASSYS1.bin
    NASSYS1.lst

The .bin is 2176 in size because of the way that the assembler handles the workspace
declarations.

Split the workspace off the end:

    $ split -b 2048 NASSYS1.bin && rm xab && mv xaa NASSYS1.bin_trim

Now:

    $ diff NASSYS1.bin_golden NASSYS1.bin_trim
    (no output => files match)
    $ diff NASSYS1.bin_golden NASSYS1.bin
    Binary files NASSYS1.bin_golden and NASSYS1.bin differ

This shows that the original binary can be faithfully reproduced.

You can use nascon (https://github.com/nealcrook/nascom/blob/master/converters/nascon)
to convert to .NAS format

    $ ../../converters/nascon NASSYS1.bin_golden NASSYS1.NAS_golden       -in bin -out nas -org 0 -csum
    $ ../../converters/nascon NASSYS1.bin_trim   NASSYS1.NAS_trim_rebuilt -in bin -out nas -org 0 -csum
    $ ../../converters/nascon NASSYS1.bin        NASSYS1.NAS_rebuilt              -out nas -org 0 -csum
    $ diff NASSYS1.NAS_golden NASSYS1.NAS_trim_rebuilt
    (no output => files match)
    $ diff NASSYS1.NAS_golden NASSYS1.NAS_rebuilt
    256a257,272
    > 0800 00 00 00 00 00 00 00 00 08
    > 0808 00 00 00 00 00 00 00 00 10
    > 0810 00 00 00 00 00 00 00 00 18
    > 0818 00 00 00 00 00 00 00 00 20
    > 0820 00 00 00 00 00 00 00 00 28
    > 0828 00 00 00 00 00 00 00 00 30
    > 0830 00 00 00 00 00 00 00 00 38
    > 0838 00 00 00 00 00 00 00 00 40
    > 0840 00 00 00 00 00 00 00 00 48
    > 0848 00 00 00 00 00 00 00 00 50
    > 0850 00 00 00 00 00 00 00 00 58
    > 0858 00 00 00 00 00 00 00 00 60
    > 0860 00 00 00 00 00 00 00 00 68
    > 0868 00 00 00 00 00 00 00 00 70
    > 0870 00 00 00 00 00 00 00 00 78
    > 0878 00 00 00 00 00 00 00 00 80
