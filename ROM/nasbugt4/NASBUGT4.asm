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
        ; Some stuff here still needs tidying up, but this
        ; does assemble to produce a match to the golden binary.
        ; foofobedoo@gmail.com Feb 2021





L_0C50: equ $0C50
L_5505: equ $5505

        org $0000


start:
        ld sp, stack
        jp L_0557

        nop
        nop
        ld sp, stack
        jp L_036D

        nop
        nop
        push hl
        pop hl
        pop hl
        inc hl
        push hl
        jp L_05B5


XL18:
        push hl
        pop hl
        pop hl
        inc hl
        push hl
        jp L_05C2


XL20:
        ex (sp), hl
        dec hl
        ex (sp), hl
        jp bpt1

        nop
        nop

prs:
        ex (sp), hl

prs1:
        ld a, (hl)
        inc hl
        or a
        jr nz, L_0044
        ex (sp), hl
        ret


rout:
        jp _crt

        nop
        nop

kdel:
        xor a

kdel1:
        push af
        pop af

L_0038:
        push af
        pop af
        dec a
        jr nz, kdel1
        ret


chin:
        call _kbd
        ret c
        jr chin


L_0044:
        rst $30
        jr prs1

        nop
        nop
        nop

flpflp:
        push af
        call flip
        pop af
        jr flip


motflp:
        ld a, $10

flip:
        push hl
        ld hl, port0
        xor (hl)
        out ($00), a
        ld (hl), a
        pop hl
        ret


srlout:
        rst $30

slrout:
        out ($01), a

l3:
        in a, ($02)
        add a, a
        ret m
        jr l3


XL66:
        jp _nmi


kbd:
        push bc
        push de
        push hl
        ld a, $02
        call flpflp
        ld hl, kmap
        in a, ($00)
        cpl
        ld (hl), a
        ld b, $08

ksc1:
        ld a, $01
        call flpflp
        inc hl
        in a, ($00)
        cpl
        ld d, a
        xor (hl)
        jr nz, ksc2

ksc1a:
        djnz ksc1

ksc8:
        or a

ksc9:
        jp L_0170

        nop

ksc2:
        call kdel
        in a, ($00)
        cpl
        ld e, a
        ld a, d
        xor (hl)
        ld c, $FF
        ld d, $00
        scf

l4:
        rl d
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
        and $10
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

l5:
        jr nz, ksc8
        ld bc, (_ktab)
        scf
        sbc hl, bc
        ld a, l
        cp $41
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


L_00F5:
        add a, $20
        bit 0, (hl)
        jr z, L_00FD
        sub $20

L_00FD:
        call L_04DD
        ld hl, _ktab0
        bit 2, (hl)
        jr z, L_0109
        xor $80

L_0109:
        scf
        bit 1, (hl)

L_010C:
        jp z, ksc9
        cp $20
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

LX124:
        or a
        jp space


LX128:
        nop
;        djnz L_018B
        djnz $18b
        nop
        nop
        nop
        call nc, L_5505
        rlca
        jp bpt1


LX135:
        jp crt


LX138:
        jp tin


crt:
        or a
        ret z
        push bc
        push de
        push hl
        push af
        cp $1E
        jr nz, l6
        ld hl, $0809
        ld (hl), $FF
        inc hl
        ld b, $30

l7:
        ld (hl), $20
        inc hl
        djnz l7
        ld b, $10

l8:
        ld (hl), $00
        inc hl
        djnz l8
        ex de, hl
        ld hl, $080A
        ld bc, lod2
        ldir
        ld a, $FF
        ld ($0BBA), a

crt0:
        ld hl, $0B8A

crt1:
        ld (hl), $5F
        ld (cursor), hl

crt2:
        pop af

L_0170:
        pop hl
        pop de
        pop bc
        ret


l6:
        ld hl, (cursor)
        ld (hl), $20
        cp $1D
        jr nz, l9

l10:
        dec hl
        ld a, (hl)
        or a
        jr z, l10
        inc a
        jr nz, crt1
        inc hl
        jr crt1


l9:
        cp $1C
        jr z, crt0

        ; Start of unknown area $018C to $018C
        defb $FE
        ; End of unknown area $018C to $018C

        rra
        jr z, crt3
        ld (hl), a

L_0191:
        inc hl
        ld a, (hl)
        or a
        jr z, L_0191
        inc a
        jr nz, crt1

crt3:
        ld de, $080A
        ld hl, $084A
        ld bc, $0370
        ldir
        ld b, $30

l12:
        dec hl
        ld (hl), $20
        djnz l12
        jr crt0


modify:
        ld hl, (arg1)

mod1:
        call tbcd3
        ld a, (hl)
        call b2hex
        call inline
        ld de, $0B52
        ld b, $00

mod2:
        push hl
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


mod3:
        pop hl
        ld a, (de)
        cp $2E
        ret z
        ld a, b
        or a
        jp L_058D

        nop
        nop

prompt:
        rst $28
        defb $3E
        defb $00

in10:
        call chin
        cp $1F
        jr z, crlf
        push af
        cp $1D
        jr nz, L_01F0
        ld de, (cursor)
        dec de
        ld a, (de)

L_01F0:
        cp $3E
        jr z, L_01F8
        pop af

L_01F5:
        rst $30
        jr in10


L_01F8:
        pop af
        xor a
        jr L_01F5


tabcde:
        call L_069B

tbcd1:
        or a
        sbc hl, de
        add hl, de
        jr c, l14
        rst $28
        defb $2E
        defb $1F
        defb $00
        ret


l14:
        ld c, $00
        rst $28
        defb $20
        defb $20
        defb $00
        call tbcd3
        ld b, $08

tbcd1a:
        ld a, (hl)
        call tbcd2
        inc hl
        call space
        djnz tbcd1a
        ld a, c
        call b2hex
        rst $28
        defb $1D
        defb $1D
        defb $1F
        defb $00
        jr tbcd1

        nop

tbcd2:
        push af
        add a, c
        ld c, a
        pop af
        jp b2hex


tbcd3:
        ld a, h
        call tbcd2
        ld a, l
        call tbcd2
        nop
        nop

space:
        ld a, $20
        jr jcrt


crlf:
        ld a, $1F
        jr jcrt


b2hex:
        push af
        rra
        rra
        rra
        rra
        call b2hex1
        pop af

b2hex1:
        and $0F
        add a, $30
        cp $3A
        jr c, jcrt
        add a, $07

jcrt:
        jp _crt


nexnum:
        ld a, (de)
        cp $20
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

nn1:
        ld a, (de)
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

nn2:
        inc de
        inc (hl)
        inc hl
        rld
        inc hl
        rld
        jr nn1


parse:
        call inline
        ld de, $0B4B
        ld bc, args
        ld a, (de)
        cp $20
        jr nz, l16
        ld a, (bc)
        cp $53
        jr nz, parse

l16:
        ld (bc), a
        inc bc
        inc de
        xor a
        ld (bc), a

ploop:
        inc bc
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
        defb $45
        defb $72
        defb $72
        defb $6F
        defb $72
        defb $1F
        defb $00
        jr parse


L_02C2:
        ld a, (args)
        ld hl, (_ctab)
        call L_0466
        ld de, parse
        push de
        jp (hl)


exec:
        ld a, $FF
        ld (conflg), a

exec1:
        ld hl, bpt1
        ld ($0C48), hl
        pop hl
        ld a, ($0C0B)
        or a
        jr z, l18
        ld hl, (arg1)
        ld (_pc), hl

l18:
        pop bc
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


step:
        xor a
        ld (conflg), a
        jr exec1


bpt1:
        push af
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


l19:
        push de
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

regs1:
        dec hl
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

strt0:
        ld hl, (brkadr)
        ld a, (brkval)
        ld (hl), a

L_0363:
        xor a
        ld (conflg), a
        call L_05A5
        jp parse


L_036D:
        ld hl, (LX128)
        ld (_sp), hl
        jr strt0


LX375:
        call crt
        jp slrout


LX37b:
        nop

lcmd:
        call motflp

lod1:
        rst $28
        defb $1C
        defb $00
        nop

L_0383:
        call chin
        cp $2E
        jr z, L_0393
        cp $1F
        jr z, lod1a
        call p, _crt
        jr L_0383


L_0393:
        rst $28
        defb $1C
        defb $2E
        defb $1F
        defb $00
        jr L_03FD


lod1a:
        ld de, $0B8A
        call nexnum
        ld a, (hl)
        or a
        jr z, l20
        ld hl, ($0C13)
        ld a, l
        add a, h
        ld c, a
        push hl
        ld hl, $0800
        ld b, h
        push hl

lod2:
        push hl
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


l20:
        call crlf
        jr lod1


dcmd:
        call motflp
        xor a
        ld b, a

L_03D6:
        rst $38
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


ccmd:
        ld hl, (arg1)
        ld de, (arg2)
        ld bc, (arg3)

L_03FA:
        ldir
        ret


L_03FD:
        jp motflp


write:
        call motflp
        xor a
        ld b, a

L_0405:
        rst $38
        djnz L_0405
        ld hl, (arg1)

w4:
        ld de, (arg2)
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

w5:
        call slrout
        ld a, $FF
        djnz w5
        xor a
        cp d
        jr nz, w6
        ld b, e
        inc b

w6:
        ld e, b
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

w9:
        call slrout
        xor a
        djnz w9
        call crlf
        jr w4


LX455:
        rra
        ld b, l
        jr nc, L_0478
        ld d, d
        rra

tx1:
        call tx2
        call Xtbcd3

Xtbcd3:
        call tbcd3
        ex de, hl
        ret


L_0466:
        push de
        ld e, a

L_0468:
        ld a, (hl)
        inc hl
        or a
        jr z, L_0474
        cp e
        jr z, L_0474
        inc hl
        inc hl
        jr L_0468


L_0474:
        ld e, (hl)
        inc hl
        ld d, (hl)
        ex de, hl

L_0478:
        pop de
        ret


xcmd:
        ld hl, LX7cf
        ld ($0C4E), hl
        ld hl, $04BA
        ld ($0C4B), hl
        ld a, (arg1)
        ld ($0C42), a
        ret


L_048D:
        jr z, L_0494
        or a
        jr z, L_0494
        set 7, (hl)

L_0494:
        pop hl
        scf
        ret


LX497:
        nop
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


LX4a9:
        rra
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


L_04CF:
        call L_07ED
        cp $0D
        ret nz
        bit 4, (hl)
        ret nz
        ld a, $0A
        jp L_07ED


L_04DD:
        ld hl, kmap
        cp $40
        jr nz, L_04EB
        bit 4, (hl)
        ret nz
        pop af
        jp ksc8


L_04EB:
        bit 5, (hl)
        jr z, L_04F1
        xor $40

L_04F1:
        ret


tin:
        call kbd
        ret c

srlin:
        in a, ($02)
        rla
        ret nc
        in a, ($01)
        scf
        ret


LX4fe:
        call tin
        ret nc

L_0502:
        push hl
        ld hl, LX4a9
        jp LX79a


LX509:
        nop
        ld hl, (arg1)
        ld (_ctab), hl
        ret


LX511:
        nop
        dec a
        nop

icmd:
        call L_0697
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


arith:
        call L_069B
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

ang:
        rst $28
        defb $3F
        defb $3F
        defb $1F
        defb $00
        ret


L_0548:
        or a
        jr nz, ang
        bit 7, l
        jr nz, ang

L_054F:
        ld a, l
        call b2hex
        jp crlf

        nop

L_0557:
        ld hl, (brkadr)
        ld a, (brkval)
        ld (hl), a
        ld hl, port0
        ld b, $18

L_0563:
        ld (hl), $00
        inc hl
        djnz L_0563
        ld hl, LX128
        ld de, _sp
        ld bc, $0013
        ldir
        rst $28
        defb $1E
        defb $4E
        defb $41
        defb $53
        defb $42
        defb $55
        defb $47
        defb $20
        defb $34
        defb $00
        jp L_0363


inline:
        push hl
        ld hl, (brkadr)
        ld a, (hl)
        ld (brkval), a
        pop hl
        jp prompt


L_058D:
        jr nz, L_0590
        inc hl

L_0590:
        ld a, (de)
        cp $3A
        jr nz, L_0597
        dec hl
        dec hl

L_0597:
        cp $2F
        jr nz, L_05A2
        inc de
        call nexnum
        ld hl, ($0C13)

L_05A2:
        jp mod1


L_05A5:
        ld hl, (cursor)
        ld de, $0B8A
        or a
        sbc hl, de
        ld hl, _ktabl
        jp nz, crlf
        ret


L_05B5:
        dec hl
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


L_05C2:
        dec hl
        dec sp
        dec sp
        push af
        push de
        ld e, (hl)
        ld d, $00
        ld hl, $0E00
        add hl, de
        add hl, de

L_05CF:
        add hl, de
        pop de
        pop af
        ex (sp), hl
        ret


        ; Start of unknown area $05D4 to $0633
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $89, $08, $88, $09, $14, $9C, $9B, $A3, $92, $C2, $BA, $B2, $AA, $A2, $98, $A0
        defb $29, $0A, $21, $19, $1A, $1C, $1B, $23, $12, $42, $3A, $32, $2A, $22, $18, $20
        defb $A9, $8A, $A1, $99, $0D, $2C, $41, $13, $3B, $33, $43, $10, $40, $2D, $38, $30
        defb $28, $31, $39, $25, $1D, $24, $15, $34, $45, $35, $11, $2B, $44, $3D, $3C, $FF
        defb $FF, $FF, $9A, $FF
        ; End of unknown area $05D4 to $0633


kcmd:
        ld a, (arg1)
        ld (_ktab0), a
        ret


bcmd:
        ld hl, (arg1)
        ld (brkadr), hl
        ret


L_0642:
        call tbcd3
        call tx2
        ld a, $1F
        jp srlout


        ; Start of unknown area $064D to $0650
        defb $00, $00, $00
        defb $00
        ; End of unknown area $064D to $0650


L_0651:
        ld c, $00

L_0653:
        call chin
        ld (hl), a
        add a, c
        ld c, a
        inc hl
        djnz L_0653
        call chin
        cp c
        jr z, L_066C

L_0662:
        rst $28
        defb $45
        defb $72
        defb $72
        defb $6F
        defb $72
        defb $1F
        defb $00
        jr L_0674


L_066C:
        call crlf
        xor a
        cp d
        jp z, motflp

L_0674:
        jp L_070F


o:
        ld bc, (arg1)
        ld a, (arg2)
        out (c), a
        jr L_0688


q:
        ld bc, (arg1)
        in a, (c)

L_0688:
        push af
        ld a, c
        call b2hex
        call space
        pop af
        call b2hex
        jp crlf


L_0697:
        ld bc, (arg3)

L_069B:
        ld de, (arg2)
        ld hl, (arg1)
        ret


g:
        ld hl, LX455
        ld b, $06
        call tx2

L_06AB:
        ld a, (hl)
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


sout:
        ld c, $00

so1:
        ld a, (hl)
        add a, c
        ld c, a
        ld a, (hl)
        call slrout
        inc hl
        djnz so1
        ret


XXcrlf:
        ld a, i
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

L_06F5:
        inc de
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

read:
        call motflp

L_070F:
        call chin

L_0712:
        cp $FF
        jr nz, L_0723
        ld b, $03

r2:
        call chin
        cp $FF
        jr nz, L_0723
        djnz r2
        jr r3


L_0723:
        cp $1E
        jr nz, L_070F
        ld b, $03

L_0729:
        call chin
        cp $1E
        jr nz, L_0712
        djnz L_0729
        jp motflp


r3:
        call chin
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


ctab:
        defb $41
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

xx:
        or a
        ld (bc), a

L_0794:
        call chin
        rst $30
        jr L_0794


LX79a:
        push af
        call L_0466
        or a
        jr z, L_07A5
        pop af
        ld a, l
        pop hl
        ret


L_07A5:
        pop af
        pop hl
        ret


LX7a8:
        call L_07AE
        jp crt


L_07AE:
        push hl
        ld hl, $04AA
        jr LX79a


LX7b4:
        ld hl, LX4fe
        ld ($0C4E), hl
        ld hl, LX7a8
        push hl
        jr L_07CA


ncmd:
        ld hl, ($0139)
        ld ($0C4E), hl

tx2:
        push hl
        ld hl, ($0136)

L_07CA:
        ld ($0C4B), hl
        pop hl
        ret


LX7cf:
        call kbd
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

L_07ED:
        or a
        ret z
        push af
        jp pe, L_07F5
        xor $80

L_07F5:
        bit 0, (hl)
        jr z, L_07FB
        xor $80

L_07FB:
        call slrout
        pop af
        ret


        org $0C00


port0:
        defb $00

kmap:
        defb $00, $00, $00, $00, $00, $00, $00, $00, $00

args:
        defb $00, $00

arg1:
        defb $00, $00

arg2:
        defb $00, $00

arg3:
        defb $00, $00

num:
        defb $00, $00, $00

brkadr:
        defb $00, $00

brkval:
        defb $00

cursor:
        defb $00, $00

conflg:
        defb $00

        ; Start of unknown area $0C1B to $0C32
        defb $00, $00, $00, $00, $00
        defb $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
        defb $00, $00, $00
        ; End of unknown area $0C1B to $0C32


stack:
        defb $00, $00

        ; Start of unknown area $0C35 to $0C36
        defb $00, $00
        ; End of unknown area $0C35 to $0C36


_hl:
        defb $00, $00

_af:
        defb $00, $00

_pc:
        defb $00, $00

_sp:
        defb $00, $00

_ktabl:
        defb $00, $00

_ktab0:
        defb $00, $00

_ktab:
        defb $00, $00

_ctab:
        defb $00, $00

_nmi:
        nop
        nop
        nop

_crt:
        nop
        nop
        nop

_kbd:
        nop
        nop
        nop


; $0000 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $0050 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $00A0 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $00F0 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $0140 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $0190 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCBBCC
; $01E0 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCBBBCCCCBBBCCCCCCCCCCCCCCCCCCCCBBBBCCCCCCCC
; $0230 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $0280 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCBBBBBBBCCCCCCCCCCCCCCCC
; $02D0 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $0320 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $0370 CCCCCCCCCCCCCCCCBBCCCCCCCCCCCCCCCCCCBBBBCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $03C0 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $0410 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $0460 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $04B0 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $0500 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCBBBBCCCCCCCCC
; $0550 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCBBBBBBBBBBCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $05A0 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC----------------------------
; $05F0 --------------------------------------------------------------------CCCCCCCCCCCC
; $0640 CCCCCCCCCCCCC----CCCCCCCCCCCCCCCCCCBBBBBBBCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $0690 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $06E0 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $0730 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCBWWBWWBWWBWWBWWBWWBWWBWWBWWBWWBWWBWWBWWBWWB
; $0780 WWBWWBWWBWWBWWBWWBCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $07D0 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC

; $0C00 BBBBBBBBBBBBBBBBBBBBBBBBBBB---------------------
; $0C30 ---BB--BBBBBBBBBBBBBBBBCCCCCCCC

; Labels
;
; $0000 => start         _af    => $0C39
; $0018 => XL18          _crt   => $0C4A
; $0020 => XL20          _ctab  => $0C45
; $0028 => prs           _hl    => $0C37
; $0029 => prs1          _kbd   => $0C4D
; $0030 => rout          _ktab  => $0C43
; $0035 => kdel          _ktab0 => $0C41
; $0036 => kdel1         _ktabl => $0C3F
; $0038 => L_0038        _nmi   => $0C47
; $003E => chin          _pc    => $0C3B
; $0044 => L_0044        _sp    => $0C3D
; $004A => flpflp        ang    => $0542
; $0051 => motflp        arg1   => $0C0C
; $0053 => flip          arg2   => $0C0E
; $005D => srlout        arg3   => $0C10
; $005E => slrout        args   => $0C0A
; $0060 => l3            arith  => $0527
; $0066 => XL66          b2hex  => $0244
; $0069 => kbd           b2hex1 => $024D
; $007A => ksc1          bcmd   => $063B
; $0087 => ksc1a         bpt1   => $0305
; $0089 => ksc8          brkadr => $0C15
; $008A => ksc9          brkval => $0C17
; $008E => ksc2          ccmd   => $03EF
; $009C => l4            chin   => $003E
; $00D1 => l5            conflg => $0C1A
; $00F5 => L_00F5        crlf   => $0240
; $00FD => L_00FD        crt    => $013B
; $0109 => L_0109        crt0   => $0167
; $010C => L_010C        crt1   => $016A
; $0124 => LX124         crt2   => $016F
; $0128 => LX128         crt3   => $0199
; $0135 => LX135         ctab   => $0755
; $0138 => LX138         cursor => $0C18
; $013B => crt           dcmd   => $03D1
; $014D => l7            exec   => $02D0
; $0154 => l8            exec1  => $02D5
; $0167 => crt0          flip   => $0053
; $016A => crt1          flpflp => $004A
; $016F => crt2          g      => $06A3
; $0170 => L_0170        icmd   => $0514
; $0174 => l6            in10   => $01DE
; $017D => l10           inline => $0581
; $0188 => l9            jcrt   => $0257
; $018B => L_018B        kbd    => $0069
; $0191 => L_0191        kcmd   => $0634
; $0199 => crt3          kdel   => $0035
; $01A6 => l12           kdel1  => $0036
; $01AD => modify        kmap   => $0C01
; $01B0 => mod1          ksc1   => $007A
; $01BF => mod2          ksc1a  => $0087
; $01CF => mod3          ksc2   => $008E
; $01DB => prompt        ksc8   => $0089
; $01DE => in10          ksc9   => $008A
; $01F0 => L_01F0        l10    => $017D
; $01F5 => L_01F5        l12    => $01A6
; $01F8 => L_01F8        l14    => $020A
; $01FC => tabcde        l16    => $0299
; $01FF => tbcd1         l18    => $02E8
; $020A => l14           l19    => $0325
; $0215 => tbcd1a        l20    => $03CC
; $022B => tbcd2         l3     => $0060
; $0232 => tbcd3         l4     => $009C
; $023C => space         l5     => $00D1
; $0240 => crlf          l6     => $0174
; $0244 => b2hex         l7     => $014D
; $024D => b2hex1        l8     => $0154
; $0257 => jcrt          l9     => $0188
; $025A => nexnum        L_0038 => $0038
; $026A => nn1           L_0044 => $0044
; $027C => nn2           L_00F5 => $00F5
; $0286 => parse         L_00FD => $00FD
; $0299 => l16           L_0109 => $0109
; $029E => ploop         L_010C => $010C
; $02C2 => L_02C2        L_0170 => $0170
; $02D0 => exec          L_018B => $018B
; $02D5 => exec1         L_0191 => $0191
; $02E8 => l18           L_01F0 => $01F0
; $02FF => step          L_01F5 => $01F5
; $0305 => bpt1          L_01F8 => $01F8
; $0325 => l19           L_02C2 => $02C2
; $0347 => regs1         L_0363 => $0363
; $035C => strt0         L_036D => $036D
; $0363 => L_0363        L_0383 => $0383
; $036D => L_036D        L_0393 => $0393
; $0375 => LX375         L_03D6 => $03D6
; $037B => LX37b         L_03FA => $03FA
; $037C => lcmd          L_03FD => $03FD
; $037F => lod1          L_0405 => $0405
; $0383 => L_0383        L_0466 => $0466
; $0393 => L_0393        L_0468 => $0468
; $039A => lod1a         L_0474 => $0474
; $03B0 => lod2          L_0478 => $0478
; $03CC => l20           L_048D => $048D
; $03D1 => dcmd          L_0494 => $0494
; $03D6 => L_03D6        L_049B => $049B
; $03EF => ccmd          L_04CF => $04CF
; $03FA => L_03FA        L_04DD => $04DD
; $03FD => L_03FD        L_04EB => $04EB
; $0400 => write         L_04F1 => $04F1
; $0405 => L_0405        L_0502 => $0502
; $040B => w4            L_0548 => $0548
; $041D => w5            L_054F => $054F
; $042A => w6            L_0557 => $0557
; $044A => w9            L_0563 => $0563
; $0455 => LX455         L_058D => $058D
; $045B => tx1           L_0590 => $0590
; $0461 => Xtbcd3        L_0597 => $0597
; $0466 => L_0466        L_05A2 => $05A2
; $0468 => L_0468        L_05A5 => $05A5
; $0474 => L_0474        L_05B5 => $05B5
; $0478 => L_0478        L_05C2 => $05C2
; $047A => xcmd          L_05CF => $05CF
; $048D => L_048D        L_0642 => $0642
; $0494 => L_0494        L_0651 => $0651
; $0497 => LX497         L_0653 => $0653
; $049B => L_049B        L_0662 => $0662
; $04A9 => LX4a9         L_066C => $066C
; $04CF => L_04CF        L_0674 => $0674
; $04DD => L_04DD        L_0688 => $0688
; $04EB => L_04EB        L_0697 => $0697
; $04F1 => L_04F1        L_069B => $069B
; $04F2 => tin           L_06AB => $06AB
; $04F6 => srlin         L_06F5 => $06F5
; $04FE => LX4fe         L_070F => $070F
; $0502 => L_0502        L_0712 => $0712
; $0509 => LX509         L_0723 => $0723
; $0511 => LX511         L_0729 => $0729
; $0514 => icmd          L_0794 => $0794
; $0527 => arith         L_07A5 => $07A5
; $0542 => ang           L_07AE => $07AE
; $0548 => L_0548        L_07CA => $07CA
; $054F => L_054F        L_07ED => $07ED
; $0557 => L_0557        L_07F5 => $07F5
; $0563 => L_0563        L_07FB => $07FB
; $0581 => inline        L_0C50 => $0C50
; $058D => L_058D        L_5505 => $5505
; $0590 => L_0590        lcmd   => $037C
; $0597 => L_0597        lod1   => $037F
; $05A2 => L_05A2        lod1a  => $039A
; $05A5 => L_05A5        lod2   => $03B0
; $05B5 => L_05B5        LX124  => $0124
; $05C2 => L_05C2        LX128  => $0128
; $05CF => L_05CF        LX135  => $0135
; $0634 => kcmd          LX138  => $0138
; $063B => bcmd          LX375  => $0375
; $0642 => L_0642        LX37b  => $037B
; $0651 => L_0651        LX455  => $0455
; $0653 => L_0653        LX497  => $0497
; $0662 => L_0662        LX4a9  => $04A9
; $066C => L_066C        LX4fe  => $04FE
; $0674 => L_0674        LX509  => $0509
; $0677 => o             LX511  => $0511
; $0682 => q             LX79a  => $079A
; $0688 => L_0688        LX7a8  => $07A8
; $0697 => L_0697        LX7b4  => $07B4
; $069B => L_069B        LX7cf  => $07CF
; $06A3 => g             mod1   => $01B0
; $06AB => L_06AB        mod2   => $01BF
; $06CC => sout          mod3   => $01CF
; $06CE => so1           modify => $01AD
; $06D9 => XXcrlf        motflp => $0051
; $06F5 => L_06F5        ncmd   => $07C0
; $070C => read          nexnum => $025A
; $070F => L_070F        nn1    => $026A
; $0712 => L_0712        nn2    => $027C
; $0718 => r2            num    => $0C12
; $0723 => L_0723        o      => $0677
; $0729 => L_0729        parse  => $0286
; $0735 => r3            ploop  => $029E
; $0755 => ctab          port0  => $0C00
; $0792 => xx            prompt => $01DB
; $0794 => L_0794        prs    => $0028
; $079A => LX79a         prs1   => $0029
; $07A5 => L_07A5        q      => $0682
; $07A8 => LX7a8         r2     => $0718
; $07AE => L_07AE        r3     => $0735
; $07B4 => LX7b4         read   => $070C
; $07C0 => ncmd          regs1  => $0347
; $07C6 => tx2           rout   => $0030
; $07CA => L_07CA        slrout => $005E
; $07CF => LX7cf         so1    => $06CE
; $07ED => L_07ED        sout   => $06CC
; $07F5 => L_07F5        space  => $023C
; $07FB => L_07FB        srlin  => $04F6
; $0C00 => port0         srlout => $005D
; $0C01 => kmap          stack  => $0C33
; $0C0A => args          start  => $0000
; $0C0C => arg1          step   => $02FF
; $0C0E => arg2          strt0  => $035C
; $0C10 => arg3          tabcde => $01FC
; $0C12 => num           tbcd1  => $01FF
; $0C15 => brkadr        tbcd1a => $0215
; $0C17 => brkval        tbcd2  => $022B
; $0C18 => cursor        tbcd3  => $0232
; $0C1A => conflg        tin    => $04F2
; $0C33 => stack         tx1    => $045B
; $0C37 => _hl           tx2    => $07C6
; $0C39 => _af           w4     => $040B
; $0C3B => _pc           w5     => $041D
; $0C3D => _sp           w6     => $042A
; $0C3F => _ktabl        w9     => $044A
; $0C41 => _ktab0        write  => $0400
; $0C43 => _ktab         xcmd   => $047A
; $0C45 => _ctab         XL18   => $0018
; $0C47 => _nmi          XL20   => $0020
; $0C4A => _crt          XL66   => $0066
; $0C4D => _kbd          Xtbcd3 => $0461
; $0C50 => L_0C50        xx     => $0792
; $5505 => L_5505        XXcrlf => $06D9
