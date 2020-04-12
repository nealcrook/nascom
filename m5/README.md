# M5 "a simple interpreter for the NASCOM 1"

Execute from 0C60

# Overview

M5 is a simple interpreter for the NASCOM 1 and runs under NASBUG T2 or T4. It
provides a mechanism for entering, editing and running programs. The total code
size is about 670 bytes, allowing it to run on an unexpanded NASCOM 1 and still
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

The article was concse and well-written but contained many, many transcription
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

- Article from Liverpool Software Gazette
- Review from Computing Today, May 1979.
- Dr Dark's Diary #4 (INMC Issue 6)

<-- COMING SOON

# WANTED

If anyone has other M5-related material I would love to see it.

# Versions

<-- COMING SOON
