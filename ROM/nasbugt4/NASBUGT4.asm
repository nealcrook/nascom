        ; NASBUG T4
        ; WRITTEN BY RICHARD BEAL

	; source code re-created from NASBUG T4 binary.
        ; It seems that the source code was never published
        ; even though source was published for earlier (T2)
        ; and later (NAS-SYS) monitors. Much of the first
        ; 1Kbytes is very similar to T2 and so label names
        ; and comments have been pasted from that code. T4
        ; was the first sight of the R/W/G commands and some
        ; label names and comments for these have been pasted
        ; the NAS-SYS1 source.
        ; There was clearly a deliberate attempt to make the
        ; start addresses for many routines match those of T2,
        ; and this explains the sequences of nop instructions
        ; in various places.
        ; Some stuff here still needs tidying up, but this
        ; does assemble to produce a match to the golden binary.
        ; foofobedoo@gmail.com Feb 2021


L_0C50: equ $0C50
L_5505: equ $5505

        org 0
crtram: equ	0800h	; start of video ram
bs:	equ	1dh
ff:	equ	1eh
cr:	equ	1fh
cur:	equ	5fh
line:	equ	0b4ah
curlin: equ	0b8ah

; RST $0
; initialise stack pointer and RAM
start:  ld sp, stack
        jp L_0557
        nop
        nop

; RST $8
        ld sp, stack
        jp L_036D
        nop
        nop

; RST $10
        push hl
        pop hl
        pop hl
        inc hl
        push hl
        jp L_05B5

; RST $18
XL18:   push hl
        pop hl
        pop hl
        inc hl
        push hl
        jp L_05C2

; RST $20
XL20:   ex (sp), hl
        dec hl
        ex (sp), hl
        jp bpt1

        nop
        nop

; RST $28 = print following string, terminated by 00
prs:    ex (sp), hl
prs1:   ld a, (hl)
        inc hl
        or a
        jr nz, L_0044
        ex (sp), hl
        ret

; RST $30
rout:   jp _crt
        nop
        nop

; keyboard debounce delay routine
kdel:   xor a
kdel1:  push af
        pop af

; RST $38
L_0038: push af
        pop af
        dec a
        jr nz, kdel1
        ret

; read a char from keyboard or uart (first come first served)
chin:   call _kbd
        ret c
        jr chin

L_0044: rst $30
        jr prs1
        nop
        nop
        nop

; set & reset a bit in I/O port 0
flpflp: push af
        call flip
        pop af
        jr flip

; start or stop motor
motflp: ld a, $10       ; bit 4

; flip a bit in port 0
flip:   push hl
        ld hl, port0
        xor (hl)
        out ($00), a
        ld (hl), a
        pop hl
        ret

; put character out thru UART, and wait till sent
srlout: rst $30
slrout: out ($01), a
l3:     in a, ($02)
        add a, a
        ret m
        jr l3

; NMI
XL66:   jp _nmi

; routine to read from keyboard
;	carry is set if a char. is available
;	the standard ASCII code for the char is returned in A
;	EXCEPT for the following chars
;		BS= 1DH	 backspace
;		CR= 1EH	 carriage return (=newline)
;		FF= 1FH	 form feed =clear screen
kbd:    push bc
        push de
        push hl
        ld a, $02       ; bit 1
        call flpflp
        ld hl, kmap
        in a, ($00)
        cpl
        ld (hl), a
        ld b, $08

ksc1:   ld a, $01       ; bit 0
        call flpflp
        inc hl
        in a, ($00)
        cpl
        ld d, a
        xor (hl)
        jr nz, ksc2
ksc1a:  djnz ksc1
ksc8:   or a
ksc9:   jp L_0170
        nop
ksc2:   call kdel
        in a, ($00)
        cpl
        ld e, a
        ld a, d
        xor (hl)
        ld c, $FF
        ld d, $00
        scf
l4:     rl d
        inc c
        rra
        jr nc, l4
        ld a, d
        and e
        ld e, a
        ld a, (hl)
        and d
        cp e
        jr z, ksc1a
        ld a, (hl)
        xor d
        ld (hl), a
        ld a, e
        or a
        jr z, ksc1a
        ld a, (kmap)
        and $10 ; bit 4
        or b
        add a, a
        add a, a
        add a, a
        or c
        ld bc, (_ktabl)
        ld hl, (_ktab)
        cpir
        jr z, l5
        ld hl, (_ktab)
        ld bc, (_ktabl)
        and $7F
        cpir

; check again for unshifted character
l5:     jr nz, ksc8
        ld bc, (_ktab)
        scf
        sbc hl, bc
        ld a, l
        cp 'A'
        jr c, L_00FD
        cp $5B
        jr nc, L_00FD
        ld hl, kmap
        bit 4, (hl)
        ld hl, _ktab0
        jr nz, L_00F5
        bit 0, (hl)
        jr z, L_00FD
        add a, $20
        jr L_00FD

L_00F5: add a, $20
        bit 0, (hl)
        jr z, L_00FD
        sub ' '
L_00FD: call L_04DD
        ld hl, _ktab0
        bit 2, (hl)
        jr z, L_0109
        xor $80
L_0109: scf
        bit 1, (hl)
L_010C: jp z, ksc9
        cp ' '
        scf
        jr z, L_010C
        ld hl, $0C08
        bit 4, (hl)
        jr z, L_010C
        pop hl
        pop de
        pop bc
        call tx2
        call b2hex
LX124:  or a
        jp space

LX128:  nop
;        djnz L_018B
        djnz $18b
        nop
        nop
        nop
        call nc, L_5505
        rlca
        jp bpt1

LX135:  jp crt

LX138:  jp tin

crt:    or a
        ret z
        push bc
        push de
        push hl
        push af
        cp ff
        jr nz, l6
        ld hl, $0809
        ld (hl), $FF
        inc hl
        ld b, $30

l7:     ld (hl), $20
        inc hl
        djnz l7
        ld b, $10

l8:     ld (hl), $00
        inc hl
        djnz l8
        ex de, hl
        ld hl, $080A
        ld bc, lod2
        ldir
        ld a, $FF
        ld ($0BBA), a

crt0:   ld hl, curlin
crt1:   ld (hl), $5F
        ld (cursor), hl
crt2:   pop af
L_0170: pop hl
        pop de
        pop bc
        ret

l6:     ld hl, (cursor)
        ld (hl), $20
        cp bs
        jr nz, l9

l10:    dec hl
        ld a, (hl)
        or a
        jr z, l10
        inc a
        jr nz, crt1
        inc hl
        jr crt1

l9:     cp $1C
        jr z, crt0

        cp cr
        jr z, crt3
        ld (hl), a

L_0191: inc hl
        ld a, (hl)
        or a
        jr z, L_0191
        inc a
        jr nz, crt1

crt3:   ld de, $080A
        ld hl, $084A
        ld bc, $0370
        ldir
        ld b, $30

l12:    dec hl
        ld (hl), $20
        djnz l12
        jr crt0


modify: ld hl, (arg1)
mod1:   call tbcd3
        ld a, (hl)
        call b2hex
        call inline
        ld de, $0B52
        ld b, $00
mod2:   push hl
        call nexnum
        ld a, (hl)
        or a
        jr z, mod3
        inc hl
        ld a, (hl)
        pop hl
        ld (hl), a
        inc b
        inc hl
        jr mod2
mod3:   pop hl
        ld a, (de)
        cp '.'
        ret z
        ld a, b
        or a
        jp L_058D
        nop
        nop

prompt: rst $28
        defb '>',0
in10:   call chin
        cp cr
        jr z, crlf
        push af
        cp bs
        jr nz, L_01F0
        ld de, (cursor)
        dec de
        ld a, (de)

L_01F0: cp '>'
        jr z, L_01F8
        pop af

L_01F5: rst $30
        jr in10

L_01F8: pop af
        xor a
        jr L_01F5

tabcde: call L_069B

tbcd1:  or a
        sbc hl, de
        add hl, de
        jr c, l14
        rst $28
        defb '.',cr,0
        ret

l14:    ld c, $00
        rst $28
        defb ' ',' ',0
        call tbcd3
        ld b, $08

tbcd1a: ld a, (hl)
        call tbcd2
        inc hl
        call space
        djnz tbcd1a
        ld a, c
        call b2hex
        rst $28
        defb bs,bs,cr,0
        jr tbcd1
        nop

tbcd2:  push af
        add a, c
        ld c, a
        pop af
        jp b2hex

tbcd3:  ld a, h
        call tbcd2
        ld a, l
        call tbcd2
        nop
        nop

space:  ld a, $20
        jr jcrt

crlf:   ld a, cr
        jr jcrt

b2hex:  push af
        rra
        rra
        rra
        rra
        call b2hex1
        pop af

b2hex1: and $0F
        add a, $30
        cp ':'
        jr c, jcrt
        add a, $07

jcrt:   jp _crt

nexnum: ld a, (de)
        cp ' '
        inc de
        jr z, nexnum
        dec de
        xor a
        ld hl, num
        ld (hl), a
        inc hl
        ld (hl), a
        inc hl
        ld (hl), a

nn1:    ld a, (de)
        dec hl
        dec hl
        sub $30
        ret m
        cp $0A
        jr c, nn2
        sub $07
        cp $0A
        ret m
        cp $10
        ret p

nn2:    inc de
        inc (hl)
        inc hl
        rld
        inc hl
        rld
        jr nn1

parse:  call inline
        ld de, $0B4B
        ld bc, args
        ld a, (de)
        cp ' '
        jr nz, l16
        ld a, (bc)
        cp $53
        jr nz, parse

l16:    ld (bc), a
        inc bc
        inc de
        xor a
        ld (bc), a

ploop:  inc bc
        call nexnum
        ld a, (hl)
        or a
        jr z, L_02C2
        inc hl
        ld a, (hl)
        ld (bc), a
        inc hl
        inc bc
        ld a, (hl)
        ld (bc), a
        ld hl, $0C0B
        inc (hl)
        ld a, (hl)
        cp $04
        jr c, ploop
        push af
        pop af
        rst $28
errm:   defb 'E','r','r','o','r',cr,0
        jr parse


L_02C2: ld a, (args)
        ld hl, (_ctab)
        call L_0466
        ld de, parse
        push de
        jp (hl)

exec:   ld a, $FF
        ld (conflg), a

exec1:  ld hl, bpt1
        ld ($0C48), hl
        pop hl
        ld a, ($0C0B)
        or a
        jr z, l18
        ld hl, (arg1)
        ld (_pc), hl
l18:    pop bc
        pop de
        pop af
        pop af
        ld hl, (_sp)
        ld sp, hl
        ld hl, (_pc)
        push hl
        ld hl, (_hl)
        push af
        ld a, $08
        out ($00), a
        pop af
        retn

step:   xor a
        ld (conflg), a
        jr exec1

bpt1:   push af
        push hl
        ld a, (port0)
        out ($00), a
        ld a, (conflg)
        or a
        jr z, l19
        ld hl, (brkadr)
        ld a, (hl)
        ld (brkval), a
        ld (hl), $E7
        xor a
        ld (conflg), a
        nop
        nop
        pop hl
        pop af
        retn

l19:    push de
        push bc
        ld hl, start
        add hl, sp
        ld de, stack
        ld sp, stack
        ld bc, $0008
        ldir
        ld e, (hl)
        inc hl
        ld d, (hl)
        inc hl
        nop
        ld (_pc), de
        ld (_sp), hl
        call L_05A5
        ld b, $06

regs1:  dec hl
        ld a, (hl)
        call b2hex
        dec hl
        ld a, (hl)
        call b2hex
        call space
        djnz regs1
        call XXcrlf
        nop
        nop
        nop

strt0:  ld hl, (brkadr)
        ld a, (brkval)
        ld (hl), a

L_0363: xor a
        ld (conflg), a
        call L_05A5
        jp parse

L_036D: ld hl, (LX128)
        ld (_sp), hl
        jr strt0

LX375:  call crt
        jp slrout

LX37b:  nop

lcmd:   call motflp

lod1:   rst $28
        defb $1C,0
        nop

L_0383: call chin
        cp $2E
        jr z, L_0393
        cp cr
        jr z, lod1a
        call p, _crt
        jr L_0383

L_0393: rst $28
        defb $1C,'.',cr,0
        jr L_03FD

lod1a:  ld de, curlin
        call nexnum
        ld a, (hl)
        or a
        jr z, l20
        ld hl, ($0C13)
        ld a, l
        add a, h
        ld c, a
        push hl
        ld hl, crtram
        ld b, h
        push hl

lod2:   push hl
        call nexnum
        inc hl
        ld a, (hl)
        pop hl
        ld (hl), a
        inc hl
        add a, c
        ld c, a
        djnz lod2
        call nexnum
        inc hl
        ld a, (hl)
        cp c
        pop hl
        pop de
        jr nz, l20
        ld c, h
        ldir
        jr lod1

l20:    call crlf
        jr lod1


dcmd:   call motflp
        xor a
        ld b, a

L_03D6: rst $38
        djnz L_03D6
        ld hl, ($0C4B)
        push hl
        ld hl, LX375
        ld ($0C4B), hl
        call crlf
        call tabcde
        pop hl
        ld ($0C4B), hl
        jr L_03FD

ccmd:   ld hl, (arg1)
        ld de, (arg2)
        ld bc, (arg3)

L_03FA: ldir
        ret

L_03FD: jp motflp

write:  call motflp
        xor a
        ld b, a

L_0405: rst $38
        djnz L_0405
        ld hl, (arg1)
w4:     ld de, (arg2)
        ex de, hl
        scf
        sbc hl, de
        jp c, motflp
        ex de, hl
        xor a
        rst $38
        nop
        ld b, $05
        xor a
w5:     call slrout
        ld a, $FF
        djnz w5
        xor a
        cp d
        jr nz, w6
        ld b, e
        inc b
w6:     ld e, b
        ld a, l
        call slrout
        ld a, h
        call slrout
        ld a, e
        call slrout
        ld a, d
        call slrout
        ld c, $00
        call tx1
        ld a, c
        call slrout
        call sout
        ld b, $0B
        ld a, c
w9:     call slrout
        xor a
        djnz w9
        call crlf
        jr w4

LX455:  rra
        ld b, l
        jr nc, L_0478
        ld d, d
        rra

tx1:    call tx2
        call Xtbcd3

Xtbcd3: call tbcd3
        ex de, hl
        ret

L_0466: push de
        ld e, a

L_0468: ld a, (hl)
        inc hl
        or a
        jr z, L_0474
        cp e
        jr z, L_0474
        inc hl
        inc hl
        jr L_0468

L_0474: ld e, (hl)
        inc hl
        ld d, (hl)
        ex de, hl

L_0478: pop de
        ret

xcmd:   ld hl, LX7cf
        ld ($0C4E), hl
        ld hl, $04BA
        ld ($0C4B), hl
        ld a, (arg1)
        ld ($0C42), a
        ret

L_048D: jr z, L_0494
        or a
        jr z, L_0494
        set 7, (hl)

L_0494: pop hl
        scf
        ret

LX497:  nop
        ld hl, (_ctab)

L_049B:
        ld a, (hl)
        or a
        jp z, crlf
        rst $30
        call space
        inc hl
        inc hl
        inc hl
        jr L_049B

LX4a9:  rra
        dec c
        rra
        ld e, $1B
        ld e, $1D
        ex af, af'
        dec e
        inc e
        ld a, (bc)
        nop
        ld a, a
        ld a, a
        nop
        nop
        nop
        call crt
        push af
        call L_0502
        push hl
        ld hl, $0C42
        bit 7, (hl)
        call z, L_04CF
        res 7, (hl)
        pop hl
        pop af
        ret

L_04CF: call L_07ED
        cp $0D
        ret nz
        bit 4, (hl)
        ret nz
        ld a, $0A
        jp L_07ED

L_04DD: ld hl, kmap
        cp $40
        jr nz, L_04EB
        bit 4, (hl)
        ret nz
        pop af
        jp ksc8


L_04EB: bit 5, (hl)
        jr z, L_04F1
        xor $40

L_04F1: ret

tin:    call kbd
        ret c

srlin:  in a, ($02)
        rla
        ret nc
        in a, ($01)
        scf
        ret

LX4fe:  call tin
        ret nc

L_0502: push hl
        ld hl, LX4a9
        jp LX79a

LX509:  nop
        ld hl, (arg1)
        ld (_ctab), hl
        ret

LX511:  nop
        dec a
        nop

icmd:   call L_0697
        or a
        sbc hl, de
        add hl, de
        jp nc, L_03FA
        dec bc
        ex de, hl
        add hl, bc
        ex de, hl
        add hl, bc
        inc bc
        lddr
        ret

arith:  call L_069B
        ex de, hl
        push hl
        add hl, de
        call tbcd3
        pop hl
        or a
        sbc hl, de
        call tbcd3
        dec hl
        dec hl
        ld a, h
        cp $FF
        jr nz, L_0548
        bit 7, l
        jr nz, L_054F

ang:    rst $28
        defb '?','?',cr,0
        ret

L_0548: or a
        jr nz, ang
        bit 7, l
        jr nz, ang

L_054F: ld a, l
        call b2hex
        jp crlf
        nop

L_0557: ld hl, (brkadr)
        ld a, (brkval)
        ld (hl), a
        ld hl, port0
        ld b, $18

L_0563: ld (hl), $00
        inc hl
        djnz L_0563
        ld hl, LX128
        ld de, _sp
        ld bc, $0013
        ldir
        rst $28
        defb $1E,'N','A','S','B','U','G',' ','4',0
        jp L_0363

inline: push hl
        ld hl, (brkadr)
        ld a, (hl)
        ld (brkval), a
        pop hl
        jp prompt

L_058D: jr nz, L_0590
        inc hl

L_0590: ld a, (de)
        cp ':'
        jr nz, L_0597
        dec hl
        dec hl

L_0597: cp '/'
        jr nz, L_05A2
        inc de
        call nexnum
        ld hl, ($0C13)

L_05A2: jp mod1

L_05A5: ld hl, (cursor)
        ld de, curlin
        or a
        sbc hl, de
        ld hl, _ktabl
        jp nz, crlf
        ret

L_05B5: dec hl
        dec sp
        dec sp
        push af
        push de
        ld e, (hl)
        ld a, e
        rla
        sbc a, a
        ld d, a
        inc hl
        jr L_05CF

L_05C2: dec hl
        dec sp
        dec sp
        push af
        push de
        ld e, (hl)
        ld d, $00
        ld hl, $0E00
        add hl, de
        add hl, de

L_05CF: add hl, de
        pop de
        pop af
        ex (sp), hl
        ret

        ; Start of unknown area $05D4 to $0633
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF
        defb $89

; table entries represent key number for each ASCII code
;	appearing in ASCII order starting at code 1DH
;	Each entry is in the format SRRRRCCC
;	where S=1 implies that shift key must be down
;	RRRR=8-row number (number in counter)
;	CCC=column number (bit number)
; Setting all ones (0FFH) implies that there is no key
;	for this code
; If the shift key is down and no code is found
;	then the table is searched again if
;	the shift key were uo.
ktab:   defb $08, $88, $09                          ;1d-1f
        defb $14, $9C, $9B, $A3, $92, $C2, $BA, $B2 ;20-27
        defb $AA, $A2, $98, $A0, $29, $0A, $21, $19 ;28-2f
        defb $1A, $1C, $1B, $23, $12, $42, $3A, $32 ;30-37
        defb $2A, $22, $18, $20, $A9, $8A, $A1, $99 ;38-3f
        defb $0D, $2C, $41, $13, $3B, $33, $43, $10 ;40-47
        defb $40, $2D, $38, $30, $28, $31, $39, $25 ;48-4f
        defb $1D, $24, $15, $34, $45, $35, $11, $2B ;50-57
        defb $44, $3D, $3C                          ;58-5a

        defb $FF, $FF, $FF, $9A, $FF
        ; End of unknown area $05D4 to $0633

kcmd:   ld a, (arg1)
        ld (_ktab0), a
        ret

bcmd:   ld hl, (arg1)
        ld (brkadr), hl
        ret

L_0642: call tbcd3
        call tx2
        ld a, cr
        jp srlout
        nop
        nop
        nop
        nop

L_0651: ld c, $00
L_0653: call chin
        ld (hl), a
        add a, c
        ld c, a
        inc hl
        djnz L_0653
        call chin
        cp c
        jr z, L_066C

L_0662: rst $28
        defb 'E','r','r','o','r',cr,0
        jr L_0674

L_066C: call crlf
        xor a
        cp d
        jp z, motflp

L_0674: jp L_070F

o:      ld bc, (arg1)
        ld a, (arg2)
        out (c), a
        jr L_0688

q:      ld bc, (arg1)
        in a, (c)

L_0688: push af
        ld a, c
        call b2hex
        call space
        pop af
        call b2hex
        jp crlf


L_0697: ld bc, (arg3)

L_069B: ld de, (arg2)
        ld hl, (arg1)
        ret

g:      ld hl, LX455
        ld b, $06
        call tx2

L_06AB: ld a, (hl)
        call srlout
        xor a
        rst $38
        rst $38
        rst $38
        inc hl
        djnz L_06AB
        call write
        xor a
        rst $38
        ld a, $45
        call srlout
        ld hl, LX375
        ld ($0C4B), hl
        ld hl, (arg3)
        jp L_0642

sout:   ld c, $00
so1:    ld a, (hl)
        add a, c
        ld c, a
        ld a, (hl)
        call slrout
        inc hl
        djnz so1
        ret

XXcrlf: ld a, i
        call b2hex
        call space
        push ix
        pop hl
        call tbcd3
        push iy
        pop hl
        call tbcd3
        ld a, (_af)
        ld de, $06FF
        ld b, $08

L_06F5: inc de
        rla
        push af
        ld a, (de)
        call c, _crt
        pop af
        djnz L_06F5
        ret

        ld d, e
        ld e, d
        nop
        ld c, b
        nop
        ld d, b
        ld c, (hl)
        ld b, e
        nop
        nop
        nop
        nop

read:   call motflp
L_070F: call chin
L_0712: cp $FF
        jr nz, L_0723
        ld b, $03
r2:     call chin
        cp $FF
        jr nz, L_0723
        djnz r2
        jr r3

L_0723: cp $1E
        jr nz, L_070F
        ld b, $03

L_0729: call chin
        cp $1E
        jr nz, L_0712
        djnz L_0729
        jp motflp

r3:     call chin
        ld l, a
        call chin
        ld h, a
        call chin
        ld e, a
        call chin
        ld d, a
        ld c, $00
        call tx1
        call chin
        cp c
        jp nz, L_0662
        ld b, e
        jp L_0651

ctab:   defb $41
        defw arith
        defb $42
        defw bcmd
        defb $43
        defw ccmd
        defb $44
        defw dcmd
        defb $45
        defw exec
        defb $47
        defw g
        defb $49
        defw icmd
        defb $4B
        defw kcmd
        defb $4C
        defw lcmd
        defb $4D
        defw modify
        defb $4E
        defw ncmd
        defb $4F
        defw o
        defb $51
        defw q
        defb $52
        defw read
        defb $53
        defw step
        defb $54
        defw tabcde
        defb $57
        defw write
        defb $58
        defw xcmd
        defb $5A
        defw $050A
        defb $3F
        defw $0498
        defb $00

xx:     or a
        ld (bc), a

L_0794: call chin
        rst $30
        jr L_0794

LX79a:  push af
        call L_0466
        or a
        jr z, L_07A5
        pop af
        ld a, l
        pop hl
        ret

L_07A5: pop af
        pop hl
        ret

LX7a8:  call L_07AE
        jp crt


L_07AE: push hl
        ld hl, $04AA
        jr LX79a

; after calling this the monitor will convert non-standard control codes to ASCII format
tasc:   ld hl, LX4fe
        ld ($0C4E), hl
        ld hl, LX7a8
        push hl
        jr L_07CA

; after calling this the monitor will resume use of non-standard control codes
ncmd:   ld hl, ($0139)
        ld ($0C4E), hl

tx2:    push hl
        ld hl, ($0136)

L_07CA: ld ($0C4B), hl
        pop hl
        ret

LX7cf:  call kbd
        ret c
        call srlin
        ret nc
        and $7F
        push hl
        push af
        ld hl, $0C42
        bit 5, (hl)
        call z, L_04CF
        pop af
        call L_07AE
        cp $1E
        jp L_048D
        nop

L_07ED: or a
        ret z
        push af
        jp pe, L_07F5
        xor $80

L_07F5: bit 0, (hl)
        jr z, L_07FB
        xor $80

L_07FB: call slrout
        pop af
        ret

        org $0C00
port0:  defb $00
kmap:   defb $00, $00, $00, $00, $00, $00, $00, $00, $00
args:   defb $00, $00
arg1:   defb $00, $00
arg2:   defb $00, $00
arg3:   defb $00, $00
num:    defb $00, $00, $00
brkadr: defb $00, $00
brkval: defb $00
cursor: defb $00, $00
conflg: defb $00

        ; Start of unknown area $0C1B to $0C32
        defb $00, $00, $00, $00, $00
        defb $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
        defb $00, $00, $00
        ; End of unknown area $0C1B to $0C32


stack:  defb $00, $00

        ; Start of unknown area $0C35 to $0C36
        defb $00, $00
        ; End of unknown area $0C35 to $0C36

_hl:    defb $00, $00
_af:    defb $00, $00
_pc:    defb $00, $00
_sp:    defb $00, $00

_ktabl: defb $00, $00
_ktab0: defb $00, $00
_ktab:  defb $00, $00
_ctab:  defb $00, $00
_nmi:   nop
        nop
        nop
_crt:   nop
        nop
        nop
_kbd:   nop
        nop
        nop
;End
