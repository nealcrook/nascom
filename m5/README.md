# M5 "a simple interpreter for the NASCOM 1"

Original version loads at 0x0C50 and executes at 0C60.

# Overview

M5 is a simple interpreter for the NASCOM 1 and runs under NASBUG T2 or T4. It
provides a mechanism for entering, editing and running programs. The total code
size is 671 bytes, allowing it to run on an unexpanded NASCOM 1 and still
leave room for simple programs.

# Language Features

The best analogy is to keystroke programmable calculators of the era:

* 27 variables A-Z, @, which support 16-bit unsigned integer maths.
* Special variable @ holds overflow/remainder from * and /
* Stack-based arithmetic
* Labels and conditional branches
* Literal numbers
* Program input is restricted to reading a number from the keyboard
* Program output is restricted to printing literal strings and variables (as numbers)
* Good error detection and reporting

Compared with (Palo Alto) Tiny Basic the main differences in capability are:

* Smaller (PATB is approximately 1896 bytes)
* Unsigned arithmetic (PATB has signed 16-bit)
* No subroutine support (PATB has GOSUB/RETURN)
* No array support (PATB has 1 array, named @)
* Fixed print format (PATB can control the print field width)
* Loops must be bespoke (PATB has FOR..TO..STEP/NEXT)
* No functions (PATB has ABS() and RND())

(This analysis is based on the following document: http://www.jk-quantized.com/experiments/8080Emulator/TinyBASIC-2.0.pdf)

# Saving and loading programs

There is no built-in mechanism to do this but there is no stored state so you
simply need to save/restore the memory region that the program is stored in.

# History

M5 was designed and implemented by Raymond Anderson and marketed by
Liverpool-based company Microdigital Ltd. around 1979. It had a list price of
£10 but was provided free-of-charge when purchasing a NASCOM from Microdigital.

In November 1979, Microdigital Ltd published the first edition of a magazine
titled "Liverpool software gazette". That edition contained an article about M5
and included a hex dump of the code.

I have never seen the official M5 documentation but I assume that the article
was a straight reproduction of that documentation.

The article was concise and well-written but contained many, many transcription
errors. Some, for example "A-7" when "A-Z" was intended, were easy to spot;
others less so.

Worse, the hex dump was very poorly reproduced so that there were many instances
of ambiguity for the hex digits 0 8 B E C and D.

The teenage me bought a copy of the magazine in October 1980 (probably from
Henry's Radio in Tottenham Court Road), typed in the code and disassembled it
with the goal of porting it from NASBUG T2 to NAS-SYS. I still have the
recreated assembling listing with my annotated comments. I never succeeded in
getting the code to work.

Fast-forward to 2020 and here I am, looking at the code again. Now I can run it
on NASBUG T2 (on an emulator, to decouple NAS-SYS porting problems) and have
looked at the code in more detail to understand it and unravel the ambiguous
characters to produce a working version and a commented source listing. I have
also OCRd and reworked the original documentation.

I have provided multiple versions here, starting with a 100%-accurate copy of
the original, and continuing with few mods/bug-fixes executed in versions for
both NASBUG and NAS-SYS. <-- COMING SOON.

# Documentation

* m5_lsg.pdf - Scan of article from Liverpool Software Gazette
* m5_review - Scan of review from Computing Today, May 1979.
* See also, Dr Dark's Diary #4 (INMC Issue 6)
* m5.odt, m5.pdf - my recreation of the original article (took me 11 pages when the original was only 7).

The Computing Today review comments that < and > are not available on the NASCOM
keyboard under T2, which is incorrect: they are reached using Shift-N and Shift-M.

# WANTED

If anyone has other M5-related material I would love to see it.

# Bugs

Bugs in the original version

* The stack is not initialised (eg, between runs) so a program that ends with an
  unbalanced stack can degrade the system from run to run.

* A taken branch resets the stack pointer; any user values on the stack are
  lost. This is the one instruction in the whole program that baffles me. I can
  only think that it was added in order to debug a mis-behaving program and was
  never removed.

* Using "backspace"  in the  editor Insert  command inserts  a backspace  in the
  program --  which is  invisible when  the program is  listed and  difficult to
  spot/fix. To be fair,  this behaviour is documented, but would  be worth a few
  bytes to fix!

* There is a bogus $D4 byte at the end of the program

* There is wasted space between the end of the program and the start of the user
program (see Computing Today review).

# Original Version

* m5.nas - original version, recreated hex dump. Runs under T2/T4/NASBUG. Load at 0xC50, execute at 0xC60
* m5.odt/m5.pdf/m5_lsg.pdf/mv_review.pdf - all refer to this version
* dis_rom - scripted disassembly of the binary created from m5.nas
* m5.asm - the result of running dis_rom on m5.nas
