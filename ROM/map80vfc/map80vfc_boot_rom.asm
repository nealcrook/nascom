K_0948  equ $0948
K_0B1D  equ $0B1D
L_0C02  equ $0C02
K_0F00  equ $0F00
K_5A50  equ $5A50

        org $0000

;;; ROM entry point
;;; IO ports:
;;; E0 rd FDC status
;;; E0 wr FDC command
;;; E1 rw FDC track
;;; E2 rw FDC sector
;;; E3 rw FDC data
;;; E4 rd FDC pins DRQ, INTRQ, READY
;;; E4 wr FDC select drive
;;;
;;; E6 rd KBD
;;; E8 wr Alarm trigger
;;; EA wr VDU register select
;;; EB rw VDU data port
;;; EC wr Video control port
;;; EE rw Select video 1
;;; EF rw Select video 2

BOOT:
        jp BOOT1


VINIT:
        jr VINIT1


KBDST:
        jr KBDST1


KBDIN:
        ld hl, L_00F8
        jr L_000F


VIDEO:
        ld hl, X_019A

L_000F:
        push de
        exx
        ex (sp), hl
        push de
        ex de, hl
        push bc
        ld hl, X_001D
        add hl, de
        push hl
        exx

K_001B:
        add hl, de
        jp (hl)


X_001D:
        exx
        pop bc
        pop de
        pop hl
        exx
        ret

;;; ========================================================
;;; IX points to a 23-byte region of workspace, described
;;; like this in the VFC manual:
;;; VFCST  DEFB 0 ; offset 0  status of VFC
;;; LASVR  DEFW 0 ; offset 1  last screen address
;;; CURSOR DEFW 0 ; offset 3  cursor address
;;; MLOCK  DEFW 0 ; offset 5  current top of screen
;;; KPOS   DEFW 0 ; offset 7  current send position
;;; PRGKEY DEFW 0 ; offset 9  address of prog key table
;;; CURTYP DEFW 0 ; offset 11 normal cursor
;;; STATE1 DEFB 0 ; offset 13 option bits
;;; KCHR   DEFB 0 ; offset 14 key character store
;;; SEND   DEFB 0 ; offset 15 number of characters during send
;;; KCOUNT DEFW 0 ; offset 16 key repeat counter
;;; ESCST  DEFB 0 ; offset 18 ESC status
;;; ESCTYP DEFB 0 ; offset 19 ESC type
;;; EDCHR  DEFB 0 ; offset 20 editing character
;;; ROW    DEFB 0 ; offset 21 row store
;;; PIXEL  DEFB 0 ; offset 22 pixel for set/reset/test
;;;

VINIT1:
        push ix
        pop hl
        ld b, $17

L_0028:
        ld (hl), $00
        inc hl
        djnz L_0028
        push af
        xor $03
        and $0F
        ld (ix), a
        pop af
        and $F0
        or $08
        ld (ix+$04), a
        ld (ix+$06), a
        ld hl, $4809
        ld (ix+$0B), l
        ld (ix+$0C), h
        ld d, a
        ld e, $00
        ld hl, $07CF
        add hl, de
        ld (ix+$01), l
        ld (ix+$02), h
        ld hl, JMPTAB4
        res 3, d
        add hl, de
        ld b, $10
        ld c, $EB
        ld a, $00

L_0062:
        out ($EA), a
        inc a
        outi
        jr nz, L_0062
        ret


K_006A:
        pop af

KBDST1:
        ld a, (ix+$0F)
        or a
        jr nz, L_00AB
        bit 3, (ix+$0D)
        jr nz, L_00AB
        ld de, $0C00
        in a, ($E6)
        cp $FF
        jr z, L_0097
        cp (ix+$0E)
        scf
        jr nz, L_0097
        ld b, a
        ld e, (ix+$10)
        ld d, (ix+$11)
        dec de
        ld a, d
        or e
        jr nz, L_0096
        ld de, $0280
        scf

L_0096:
        ld a, b

L_0097:
        ld (ix+$10), e
        ld (ix+$11), d
        ld (ix+$0E), a
        jr c, L_00AF
        xor a
        bit 5, (ix+$0D)
        ret z
        xor a
        scf
        ret


L_00AB:
        xor a
        sub $01
        ret


L_00AF:
        set 3, (ix+$0D)
        bit 4, (ix+$0D)
        jr z, L_00AB
        ld l, (ix+$09)
        ld h, (ix+$0A)

L_00BF:
        ld a, (hl)
        or a
        jr z, L_00AB
        inc hl
        cp (ix+$0E)
        jr z, L_00D4
        dec hl

L_00CA:
        ld a, (hl)
        inc hl
        inc a
        jr z, L_00BF
        dec a
        jr nz, L_00CA
        jr L_00AB


L_00D4:
        ld (ix+$07), l
        ld (ix+$08), h
        ld c, $00

L_00DC:
        ld a, (hl)
        inc c
        inc hl
        inc a
        jr z, L_00E5
        dec a
        jr nz, L_00DC

L_00E5:
        dec c
        ld (ix+$0F), c
        ld a, c
        or a
        jr z, L_00AB
        set 7, (ix+$0D)
        res 3, (ix+$0D)
        jr L_00AB


K_00F7:
        pop af

L_00F8:
        ld a, (ix+$0F)
        or a
        jr nz, L_013A
        ld a, (ix+$0E)
        bit 3, (ix+$0D)
        res 3, (ix+$0D)
        jr nz, L_011E
        bit 5, (ix+$0D)
        jr nz, L_0122
        exx
        ld hl, L_011E
        add hl, de
        push hl
        ld hl, X_0157
        add hl, de
        push hl
        exx
        ret


L_011E:
        cp (ix+$14)
        ret nz

L_0122:
        ld bc, $021B

L_0125:
        push bc
        exx
        ld hl, X_0133
        add hl, de
        push hl
        ld hl, X_019A
        add hl, de
        push hl
        exx
        ret


X_0133:
        pop bc
        ld c, $58
        djnz L_0125
        jr L_00F8


L_013A:
        ld l, (ix+$07)
        ld h, (ix+$08)
        dec a
        ld (ix+$0F), a
        bit 7, (ix+$0D)
        jr nz, L_014E
        ld a, h
        and $0F
        or d

L_014E:
        ld a, (hl)
        inc hl
        ld (ix+$07), l
        ld (ix+$08), h
        ret


X_0157:
        ld a, (ix+$0F)
        or a
        jr nz, L_013A
        bit 3, (ix+$0D)
        jr nz, L_0192
        ld l, (ix+$03)
        ld h, (ix+$04)
        exx
        ld hl, X_0176
        add hl, de
        push hl
        ld hl, $0559
        add hl, de
        push hl
        exx
        ret


X_0176:
        exx
        ld hl, X_0183
        add hl, de
        push hl
        ld hl, KBDST1
        add hl, de
        push hl
        exx
        ret


X_0183:
        jr z, X_0176
        exx
        ld hl, X_0157
        add hl, de
        push hl
        ld hl, $0564
        add hl, de
        push hl
        exx
        ret


L_0192:
        res 3, (ix+$0D)
        ld a, (ix+$0E)
        ret


X_019A:
        ld hl, $054D
        exx
        push de
        exx
        pop de
        add hl, de
        push hl
        push bc
        ld bc, $030F
        push ix
        pop hl
        inc hl
        inc hl

L_01AC:
        ld a, c
        and (hl)
        or d
        ld (hl), a
        inc hl
        inc hl
        djnz L_01AC
        pop bc
        ld l, (ix+$03)
        ld h, (ix+$04)
        ld a, (ix+$12)
        or a
        jr nz, L_01CC
        ld a, c
        cp $20
        jr nc, L_0201
        exx
        ld hl, $0741
        jr L_01EB


L_01CC:
        bit 7, a
        jr nz, L_01DF
        ld b, (ix+$12)
        dec (ix+$12)
        ld a, (ix+$13)
        exx
        ld hl, $07D0
        jr L_01EB


L_01DF:
        ld (ix+$12), $00
        ld a, c
        ld (ix+$13), a
        exx
;;; after double-increment this points to JMPTAB2
        ld hl, $076F

L_01EB:
        ld c, a
        add hl, de

L_01ED:
        inc hl
        inc hl
        ld a, (hl)
        or a
        jr z, L_01FF
        inc hl
        cp c
        jr nz, L_01ED
        ld a, (hl)
        inc hl
        ld h, (hl)
        ld l, a
        add hl, de
        push hl
        exx
        ret


L_01FF:
        exx
        ld a, c

L_0201:
        or a
        ret z
        bit 0, (ix+$0D)
        jr z, L_020B
        set 7, a

L_020B:
        ld (hl), a
        inc hl
        ld e, (ix+$01)
        ld d, (ix+$02)
        inc de
        push hl
        sbc hl, de
        pop hl
        ret c
        ld hl, $FFB0
        add hl, de
        ld (ix+$03), l
        ld (ix+$04), h
        jr L_0244


J_CHR0B:
        exx
        ld hl, $024A
        add hl, de
        push hl
        ld hl, J_CHR0D
        add hl, de
        push hl
        exx
        ret


J_CHR0A:
        ld de, $0050
        add hl, de
        ld e, (ix+$01)
        ld d, (ix+$02)
        jr c, L_0244
        inc de
        push hl
        sbc hl, de
        pop hl
        ret c

L_0244:
        ld l, (ix+$05)
        ld h, (ix+$06)
        exx
        ld hl, X_0257
        add hl, de
        push hl
        ld hl, $0651
        add hl, de
        push hl
        exx
        ret


X_0257:
        push hl
        ld l, (ix+$01)
        ld h, (ix+$02)
        pop bc
        push hl
        jr nc, L_026C
        push bc
        or a
        sbc hl, de
        ex (sp), hl
        pop bc
        ex de, hl
        inc bc
        ldir

L_026C:
        pop de
        ld hl, $FFB1
        add hl, de
        jr L_02D7


J_CHR1A:
        ld l, (ix+$05)
        ld h, (ix+$06)

K_0279:
        push hl
        ld e, (ix+$01)
        ld d, (ix+$02)
        exx
        ld hl, $0388
        add hl, de
        push hl
        ld hl, L_02D7
        add hl, de
        push hl
        exx
        ret


J_CHR0E:
        exx
        ld hl, X_029F
        add hl, de
        push hl
        ld hl, $0651
        add hl, de
        push hl
        ld hl, J_CHR0D
        add hl, de
        push hl
        exx
        ret


X_029F:
        jr nc, L_02B6
        ld l, (ix+$01)
        ld h, (ix+$02)
        push hl
        or a
        sbc hl, de
        ex (sp), hl
        pop bc
        ex de, hl
        inc bc
        ld hl, $FFB0
        add hl, de
        lddr
        ex de, hl

L_02B6:
        exx
        ld hl, X_02C3
        add hl, de
        push hl
        ld hl, J_CHR0D
        add hl, de
        push hl
        exx
        ret


X_02C3:
        ld (ix+$03), l
        ld (ix+$04), h

K_02C9:
        exx
        ld hl, $02D6
        add hl, de
        push hl
        ld hl, $0651
        add hl, de
        push hl
        exx
        ret


        ; Start of unknown area $02D6 to $02D6
        defb $1B
        ; End of unknown area $02D6 to $02D6


L_02D7:
        ex de, hl
        push hl
        or a
        sbc hl, de
        ex (sp), hl
        pop bc
        ld a, b
        or c
        ex de, hl
        ld (hl), $20
        ret z
        push hl
        pop de
        inc de
        ldir
        ret


K_02EA:
        exx
        ld hl, $0800
        add hl, de
        push hl
        exx
        pop hl
        jr L_0301


K_02F4:
        exx
        ld hl, L_0301
        add hl, de
        push hl
        ld hl, J_CHR0D
        add hl, de
        push hl
        exx
        ret


L_0301:
        ld (ix+$05), l
        ld (ix+$06), h
        or a
        ret


K_0309:
        bit 5, (ix+$0D)
        jr nz, L_0313
        ld c, $00
        jr L_0315


L_0313:
        ld c, $40

L_0315:
        ld a, $0A
        ld b, $02

L_0319:
        exx
        ld hl, X_0326
        add hl, de
        push hl
        ld hl, L_064B
        add hl, de
        push hl
        exx
        ret


X_0326:
        ld a, $0B
        ld c, $09
        djnz L_0319
        exx
        ld hl, X_0339
        add hl, de
        push hl
        ld hl, X_0157
        add hl, de
        push hl
        exx
        ret


X_0339:
        ld l, (ix+$03)
        ld h, (ix+$04)
        cp (ix+$14)
        jr nz, L_0350
        bit 5, (ix+$0D)
        jr nz, L_0368
        set 5, (ix+$0D)
        jr K_0309


L_0350:
        cp $A0
        jr nc, L_0356
        and $7F

L_0356:
        cp $0D
        jr z, L_038B
        ld c, a
        exx
        ld hl, $032C
        add hl, de
        push hl
        ld hl, X_019A
        add hl, de
        push hl
        exx
        ret


L_0368:
        res 5, (ix+$0D)

L_036C:
        push hl
        ld b, $02
        ld c, (ix+$0C)
        jr L_0377


X_0374:
        ld c, (ix+$0B)

L_0377:
        push bc
        exx
        ld hl, X_0385
        add hl, de
        push hl
        ld hl, L_063D
        add hl, de
        push hl
        exx
        ret


X_0385:
        pop bc
        djnz X_0374
        pop hl
        scf
        ret


L_038B:
        ld (ix+$0E), a
        set 3, (ix+$0D)
        res 7, (ix+$0D)

K_0396:
        exx
        ld hl, X_03A3
        add hl, de
        push hl
        ld hl, J_CHR0D
        add hl, de
        push hl
        exx
        ret


X_03A3:
        ld b, $50
        ld a, (hl)
        and $7F
        cp $2A
        jr z, L_03C4
        cp $2E
        jr z, L_03C4
        cp $23
        jr z, L_03C4
        cp $2D
        jr z, L_03C4
        inc hl
        ld a, (hl)
        and $7F
        cp $3E
        jr z, L_03C3
        dec hl
        jr L_03C6


L_03C3:
        dec b

L_03C4:
        inc hl
        dec b

L_03C6:
        ld (ix+$07), l
        ld (ix+$08), h
        push hl
        push bc
        exx
        ld hl, X_03DB
        add hl, de
        push hl
        ld hl, $0651
        add hl, de
        push hl
        exx
        ret


X_03DB:
        pop bc
        ex de, hl
        ld a, $20

L_03DF:
        dec hl
        cp (hl)
        jr nz, L_03E6
        dec b
        jr nz, L_03DF

L_03E6:
        ld (ix+$0F), b
        pop hl
        jr L_036C


J_CHR15:
        ld l, (ix+$05)
        ld h, (ix+$06)
        scf
        ret


K_03F4:
        ld e, (ix+$01)
        ld d, (ix+$02)
        jr L_040A


J_CHR16:
        exx
        ld hl, $0409
        add hl, de
        push hl
        ld hl, $0651
        add hl, de
        push hl
        exx
        ret


        ; Start of unknown area $0409 to $0409
        defb $1B
        ; End of unknown area $0409 to $0409


L_040A:
        ex de, hl
        push hl
        or a
        sbc hl, de
        ex (sp), hl
        pop bc
        ld a, b
        or c
        ex de, hl
        jr z, L_041B
        push hl
        pop de
        inc hl
        ldir

L_041B:
        ld a, $20
        ld (de), a
        ret


K_041F:
        ld e, (ix+$01)
        ld d, (ix+$02)
        jr L_0435


J_CHR17:
        exx
        ld hl, $0434
        add hl, de
        push hl
        ld hl, $0651
        add hl, de
        push hl
        exx
        ret


        ; Start of unknown area $0434 to $0434
        defb $1B
        ; End of unknown area $0434 to $0434


L_0435:
        ex de, hl
        push hl
        or a
        sbc hl, de
        ex (sp), hl
        pop bc
        ld a, b
        or c
        ex de, hl
        jr z, L_041B
        push de
        pop hl
        dec hl
        lddr
        jr L_041B


J_CHR08:
        exx
        ld hl, $0455
        add hl, de
        push hl
        ld hl, J_CHR1C
        add hl, de
        push hl
        exx
        ret


        ; Start of unknown area $0455 to $0458
        defb $D0, $36, $20, $C9
        ; End of unknown area $0455 to $0458


J_CHR1C:
        dec hl
        jr L_0468


J_CHR1F:
        ld de, $0050
        jr L_0464


J_CHR1E:
        ld de, $FFB0

L_0464:
        add hl, de
        jr L_0468


J_CHR1D:
        inc hl

L_0468:
        ex de, hl
        ld l, (ix+$01)
        ld h, (ix+$02)
        or a
        sbc hl, de
        ccf
        jr nc, L_047F
        ld l, (ix+$05)
        ld h, (ix+$06)
        dec hl
        or a
        sbc hl, de

L_047F:
        ex de, hl
        ret


J_CHR1B:
        xor a
        ld (ix+$13), a
        dec a
        ld (ix+$12), a
        ret


L_048A:
        set 5, (ix+$13)
        ld l, (ix+$09)
        ld h, (ix+$0A)
        ld a, c
        cp $1B
        jr z, L_04B2

L_0499:
        ld a, (hl)
        cp c
        jr z, L_04C1

L_049D:
        or a
        jr z, L_04A7
        inc hl
        inc a
        jr z, L_0499
        ld a, (hl)
        jr L_049D


L_04A7:
        ld b, $7F

L_04A9:
        ld (hl), c
        inc hl
        ld (hl), $FF
        inc hl
        ld (hl), $00
        jr L_04B9


L_04B2:
        set 4, (ix+$0D)
        ld b, $00
        ld (hl), b

L_04B9:
        ld (ix+$12), b
        or a
        ret


        ; Start of unknown area $04BE to $04C0
        defb $41, $57
        defb $31
        ; End of unknown area $04BE to $04C0


L_04C1:
        push bc
        push hl

L_04C3:
        ld a, (hl)
        or a
        jr z, L_04CD
        inc hl
        inc a
        jr z, L_04CD
        jr L_04C3


L_04CD:
        push hl
        ld bc, BOOT

L_04D1:
        inc bc
        ld a, (hl)
        or a
        jr z, L_04D9
        inc hl
        jr L_04D1


L_04D9:
        pop hl
        pop de
        ldir
        pop bc
        ex de, hl
        dec hl
        jr L_04A7


L_04E2:
        ld l, (ix+$09)
        ld h, (ix+$0A)

L_04E8:
        ld a, (hl)
        or a
        jr z, L_04EF
        inc hl
        jr L_04E8


L_04EF:
        ld a, c
        cp $1B
        jr nz, L_04FD
        ld a, b
        cp $7F
        jr nz, L_04B2
        dec hl
        dec hl
        jr L_04B2


L_04FD:
        dec hl
        ld b, $01
        cp $40
        jr nz, L_04A9
        ld c, $0D
        jr L_04A9


K_0508:
        bit 4, (ix+$0D)
        ret z
        res 4, (ix+$0D)

K_0511:
        ld (ix+$12), $02
        ret


K_0516:
        res 2, (ix)
        jr L_052C


K_051C:
        set 2, (ix)
        jr L_052C


K_0522:
        res 3, (ix)
        jr L_052C


K_0528:
        set 3, (ix)

L_052C:
        ld a, (ix)
        add a, d
        xor $03
        out ($EC), a
        ret


K_0535:
        res 1, (ix+$0D)
        jr L_0554


K_053B:
        set 1, (ix+$0D)
        jr L_0569


K_0541:
        res 2, (ix+$0D)
        jr L_0569


K_0547:
        set 2, (ix+$0D)
        jr L_0554


        ; Start of unknown area $054D to $0553
        defb $D0, $DD, $75
        defb $03, $DD, $74, $04
        ; End of unknown area $054D to $0553


L_0554:
        bit 2, (ix+$0D)
        ret z
        bit 1, (ix+$0D)
        ret nz
        ld a, h
        and $0F
        ld h, a
        jr L_056C


        ; Start of unknown area $0564 to $0568
        defb $DD, $CB, $0D, $56, $C0
        ; End of unknown area $0564 to $0568


L_0569:
        ld hl, $07FF

L_056C:
        ld b, $02
        ld c, $EB
        ld a, $0E

L_0572:
        out ($EA), a
        out (c), h
        inc a
        ld h, l
        djnz L_0572
        or a
        ret


K_057C:
        set 0, (ix+$0D)
        ret


K_0581:
        res 0, (ix+$0D)
        ret


L_0586:
        ld a, c
        sub $20
        jr nc, L_058F
        set 6, (ix+$0D)

L_058F:
        dec b
        jr z, L_05BE
        ld b, $FF
        ld c, $03

L_0596:
        inc b
        sub c
        jr nc, L_0596
        add a, c
        add a, a
        jr nz, L_059F
        inc a

L_059F:
        ld (ix+$16), a
        ld a, b
        jr L_05B1


L_05A5:
        ld a, c
        sub $20
        jr nc, L_05AE
        set 6, (ix+$0D)

L_05AE:
        dec b
        jr z, L_05CA

L_05B1:
        cp $19
        ccf
        jr nc, L_05BA
        set 6, (ix+$0D)

L_05BA:
        ld (ix+$15), a
        ret


L_05BE:
        srl a
        jr nc, L_05CA
        ld b, $03

L_05C4:
        sla (ix+$16)
        djnz L_05C4

L_05CA:
        cp $50
        jr c, L_05D2
        set 6, (ix+$0D)

L_05D2:
        ld hl, $07B0
        add hl, de
        ld e, a
        ld d, $00
        add hl, de
        ld a, (ix+$15)
        inc a
        ld b, a
        ld de, $0050

L_05E2:
        add hl, de
        djnz L_05E2
        bit 6, (ix+$0D)
        jr nz, L_0610
        ld a, (ix+$13)
        cp $3D
        scf
        ret z
        cp $53
        push af
        ld a, $C0
        cp (hl)
        jr c, L_05FB
        ld (hl), a

L_05FB:
        pop af
        ld a, (ix+$16)
        jr z, L_060B
        jr c, L_0607
        and (hl)
        ret z
        inc a
        ret


L_0607:
        cpl
        and (hl)
        jr L_060C


L_060B:
        or (hl)

L_060C:
        or $C0
        ld (hl), a
        ret


L_0610:
        res 6, (ix+$0D)

J_CHR07:
        in a, ($E8)
        or a
        ret


L_0618:
        dec b
        jr nz, L_0623
        ld (ix+$0A), c

K_061E:
        set 4, (ix+$0D)
        ret


L_0623:
        ld (ix+$09), c
        ret


K_0627:
        res 4, (ix+$0D)
        ret


L_062C:
        ld (ix+$14), c
        dec (ix+$12)
        ret


K_0633:
        ld c, $00
        jr L_0639


K_0637:
        ld c, $50

L_0639:
        ld a, $01
        jr L_064B


L_063D:
        ld a, $0A
        dec b
        jr nz, L_0648
        inc a
        ld (ix+$0B), c
        jr L_064B


L_0648:
        ld (ix+$0C), c

L_064B:
        out ($EA), a
        ld a, c
        out ($EB), a
        ret


        ; Start of unknown area $0651 to $0658
        defb $E5, $D9, $21, $6C, $06, $19, $E5, $D9
        ; End of unknown area $0651 to $0658


J_CHR0D:
        ex de, hl
        ld l, (ix+$01)
        ld h, (ix+$02)
        inc hl
        ld bc, $FFB0

L_0664:
        add hl, bc
        push hl
        sbc hl, de
        pop hl
        ret c
        jr L_0664


X_066C:
        ld de, $0050
        add hl, de
        ld e, (ix+$01)
        ld d, (ix+$02)
        push hl
        sbc hl, de
        pop hl
        ex de, hl
        pop hl
        ret


        ; Start of unknown area $067D to $0681
        defb $41, $57, $31
        defb $2E, $31
        ; End of unknown area $067D to $0681

;;; ========================================================
;;; NOT RELOCATABLE. Load track 0 sector 0 from drive A into memory at 0C00H
;;; using the 2797 FDC. This ROM is at 0000H-07FFH and the video RAM is at TODO

BOOT1:
        ld sp, $1000
        xor a
        ld ix, $0C00
        call VINIT1
        ld hl, MSGBOOT

L_0690:
        ld a, $01
        out ($EC), a
        ld de, $0800
        ld bc, KBDIN
        ldir
        ex de, hl
        ld bc, $07C9

L_06A0:
        ld (hl), $20
        inc hl
        dec bc
        ld a, b
        or c
        jr nz, L_06A0
        xor a
        out ($EC), a
        ld a, $D0
        call FDCCMD
        ld a, $01
        out ($E4), a

L_06B4:
        inc a
        jr nz, L_06B4

L_06B7:
        in a, ($E0)
        rlca
        jr c, L_06B7
        ld a, $0B
        call FDCCMD
        ld de, BOOT
        in a, ($E0)
        ld b, a

L_06C7:
        in a, ($E0)
        xor b
        and $02
        jr nz, L_06E6
        dec de
        ld a, d
        or e
        jr nz, L_06C7
        ld hl, MSGDSK

L_06D6:
        jr L_0690


FDCCMD:
        out ($E0), a
        ld a, $0A

L_06DC:
        dec a
        jr nz, L_06DC

L_06DF:
        in a, ($E0)
        bit 0, a
        jr nz, L_06DF
        ret


L_06E6:
        ld d, $05
        ld c, $E3

L_06EA:
        ld hl, $0C00
        xor a
        out ($E2), a
        inc a
        out ($E4), a
        ld a, $88
        out ($E0), a
        ld a, $0A

L_06F9:
        dec a
        jr nz, L_06F9

L_06FC:
        in a, ($E0)
        rrca
        jr nc, L_0708
        rrca
        jr nc, L_06FC
        ini
        jr L_06FC


L_0708:
        in a, ($E0)
        and $FC
        jr z, L_0716
        dec d
        jr nz, L_06EA
        ld hl, MSGERR
        jr L_06D6


L_0716:
        ld hl, ($0C00)
        ld de, $3038
        or a
        sbc hl, de
        jp z, L_0C02
        ld hl, MSGSYS
        jr L_06D6


MSGBOOT:
        defm "BOOTING"

MSGDSK:
        defm "DISK ??"

MSGSYS:
        defm "SYSTEM?"

MSGERR:
        defm "ERROR ?"

;;; jump table: ASCII code followed by the execution address for handling it

JMPTAB:
        defb $0D
        defw J_CHR0D
        defb $0A
        defw J_CHR0A
        defb $08
        defw J_CHR08
        defb $1B
        defw J_CHR1B
        defb $1C
        defw J_CHR1C
        defb $1D
        defw J_CHR1D
        defb $1E
        defw J_CHR1E
        defb $1F
        defw J_CHR1F
        defb $0B
        defw J_CHR0B
        defb $0E
        defw J_CHR0E
        defb $15
        defw J_CHR15
        defb $16
        defw J_CHR16
        defb $17
        defw J_CHR17
        defb $1A
        defw J_CHR1A
        defb $07
        defw J_CHR07
;;; 0 marking the end of the jump table??
        defb $00

;;; searched by routine at L_01DF

JMPTAB2:
        defb $6B
        defw K_006A
        defb $16
        defw K_03F4
        defb $17
        defw K_041F
        defb $3D
        defw K_0511
        defb $52
        defw K_0511
        defb $53
        defw K_0511
        defb $54
        defw K_0511
        defb $25
        defw K_0279
        defb $2A
        defw K_02C9
        defb $41
        defw K_057C
        defb $64
        defw K_053B
        defb $44
        defw K_0541
        defb $65
        defw K_0535
        defb $45
        defw K_0547
        defb $49
        defw K_051C
        defb $4B
        defw K_00F7
        defb $4D
        defw K_02F4
        defb $4E
        defw K_0581
        defb $4F
        defw K_02EA
        defb $50
        defw K_0511
        defb $70
        defw K_061E
        defb $51
        defw K_0627
        defb $55
        defw K_0516
        defb $58
        defw K_0309
        defb $5A
        defw K_0396
        defb $59
        defw K_0511
        defb $31
        defw K_0522
        defb $32
        defw K_0528
        defb $43
        defw K_0508
        defb $40
        defw K_0511
        defb $42
        defw K_0633
        defb $56
        defw K_0637
;;; 0 marking the end of the jump table??
        defb $00

JMPTAB3:
        defb $3D
        defw L_05A5
        defb $52
        defw L_0586
        defb $53
        defw L_0586
        defb $54
        defw L_0586
        defb $59
        defw L_063D
        defb $50
        defw L_0618
        defb $43
        defw L_048A
        defb $63
        defw L_04E2
        defb $40
        defw L_062C
;;; 0 marking the end of the jump table??
        defb $00

JMPTAB4:
        defb $72
        defw K_5A50
        defb $67
        defw K_0B1D
        defb $19
        defw K_001B
        defb $09
        defw K_0948
        defb $08
        defw K_0F00
;;; 0 marking the end of the jump table??
        defb $FF

        ; Start of unknown area $07FE to $07FF
        defb $00, $00
        ; End of unknown area $07FE to $07FF



; $0000 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $0050 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $00A0 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $00F0 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $0140 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $0190 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $01E0 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $0230 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $0280 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $02D0 CCCCCC-CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $0320 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $0370 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $03C0 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC-CCCCCC
; $0410 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC-CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC----CCCCCCC
; $0460 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $04B0 CCCCCCCCCCCCCC---CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $0500 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC---
; $0550 ----CCCCCCCCCCCCCCCC-----CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $05A0 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $05F0 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $0640 CCCCCCCCCCCCCCCCC--------CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC-----CCCCCCCCCCCCCC
; $0690 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $06E0 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCBBBBBBBBB
; $0730 BBBBBBBBBBBBBBBBBBBBWWBWWBWWBWWBWWBWWBWWBWWBWWBWWBWWBWWBWWBWWBWWBBWWBWWBWWBWWBWW
; $0780 BWWBWWBWWBWWBWWBWWBWWBWWBWWBWWBWWBWWBWWBWWBWWBWWBWWBWWBWWBWWBWWBWWBWWBWWBWWBWWBW
; $07D0 WBBWWBWWBWWBWWBWWBWWBWWBWWBWWBBWWBWWBWWBWWBWWB-

; Labels
;
; $0000 => BOOT           BOOT    => $0000
; $0003 => VINIT          BOOT1   => $0682
; $0005 => KBDST          FDCCMD  => $06D8
; $0007 => KBDIN          J_CHR07 => $0614
; $000C => VIDEO          J_CHR08 => $0448
; $000F => L_000F         J_CHR0A => $0232
; $001B => K_001B         J_CHR0B => $0225
; $001D => X_001D         J_CHR0D => $0659
; $0023 => VINIT1         J_CHR0E => $028D
; $0028 => L_0028         J_CHR15 => $03EC
; $0062 => L_0062         J_CHR16 => $03FC
; $006A => K_006A         J_CHR17 => $0427
; $006B => KBDST1         J_CHR1A => $0273
; $0096 => L_0096         J_CHR1B => $0481
; $0097 => L_0097         J_CHR1C => $0459
; $00AB => L_00AB         J_CHR1D => $0467
; $00AF => L_00AF         J_CHR1E => $0461
; $00BF => L_00BF         J_CHR1F => $045C
; $00CA => L_00CA         JMPTAB  => $0743
; $00D4 => L_00D4         JMPTAB2 => $0771
; $00DC => L_00DC         JMPTAB3 => $07D2
; $00E5 => L_00E5         JMPTAB4 => $07EE
; $00F7 => K_00F7         K_001B  => $001B
; $00F8 => L_00F8         K_006A  => $006A
; $011E => L_011E         K_00F7  => $00F7
; $0122 => L_0122         K_0279  => $0279
; $0125 => L_0125         K_02C9  => $02C9
; $0133 => X_0133         K_02EA  => $02EA
; $013A => L_013A         K_02F4  => $02F4
; $014E => L_014E         K_0309  => $0309
; $0157 => X_0157         K_0396  => $0396
; $0176 => X_0176         K_03F4  => $03F4
; $0183 => X_0183         K_041F  => $041F
; $0192 => L_0192         K_0508  => $0508
; $019A => X_019A         K_0511  => $0511
; $01AC => L_01AC         K_0516  => $0516
; $01CC => L_01CC         K_051C  => $051C
; $01DF => L_01DF         K_0522  => $0522
; $01EB => L_01EB         K_0528  => $0528
; $01ED => L_01ED         K_0535  => $0535
; $01FF => L_01FF         K_053B  => $053B
; $0201 => L_0201         K_0541  => $0541
; $020B => L_020B         K_0547  => $0547
; $0225 => J_CHR0B        K_057C  => $057C
; $0232 => J_CHR0A        K_0581  => $0581
; $0244 => L_0244         K_061E  => $061E
; $0257 => X_0257         K_0627  => $0627
; $026C => L_026C         K_0633  => $0633
; $0273 => J_CHR1A        K_0637  => $0637
; $0279 => K_0279         K_0948  => $0948
; $028D => J_CHR0E        K_0B1D  => $0B1D
; $029F => X_029F         K_0F00  => $0F00
; $02B6 => L_02B6         K_5A50  => $5A50
; $02C3 => X_02C3         KBDIN   => $0007
; $02C9 => K_02C9         KBDST   => $0005
; $02D7 => L_02D7         KBDST1  => $006B
; $02EA => K_02EA         L_000F  => $000F
; $02F4 => K_02F4         L_0028  => $0028
; $0301 => L_0301         L_0062  => $0062
; $0309 => K_0309         L_0096  => $0096
; $0313 => L_0313         L_0097  => $0097
; $0315 => L_0315         L_00AB  => $00AB
; $0319 => L_0319         L_00AF  => $00AF
; $0326 => X_0326         L_00BF  => $00BF
; $0339 => X_0339         L_00CA  => $00CA
; $0350 => L_0350         L_00D4  => $00D4
; $0356 => L_0356         L_00DC  => $00DC
; $0368 => L_0368         L_00E5  => $00E5
; $036C => L_036C         L_00F8  => $00F8
; $0374 => X_0374         L_011E  => $011E
; $0377 => L_0377         L_0122  => $0122
; $0385 => X_0385         L_0125  => $0125
; $038B => L_038B         L_013A  => $013A
; $0396 => K_0396         L_014E  => $014E
; $03A3 => X_03A3         L_0192  => $0192
; $03C3 => L_03C3         L_01AC  => $01AC
; $03C4 => L_03C4         L_01CC  => $01CC
; $03C6 => L_03C6         L_01DF  => $01DF
; $03DB => X_03DB         L_01EB  => $01EB
; $03DF => L_03DF         L_01ED  => $01ED
; $03E6 => L_03E6         L_01FF  => $01FF
; $03EC => J_CHR15        L_0201  => $0201
; $03F4 => K_03F4         L_020B  => $020B
; $03FC => J_CHR16        L_0244  => $0244
; $040A => L_040A         L_026C  => $026C
; $041B => L_041B         L_02B6  => $02B6
; $041F => K_041F         L_02D7  => $02D7
; $0427 => J_CHR17        L_0301  => $0301
; $0435 => L_0435         L_0313  => $0313
; $0448 => J_CHR08        L_0315  => $0315
; $0459 => J_CHR1C        L_0319  => $0319
; $045C => J_CHR1F        L_0350  => $0350
; $0461 => J_CHR1E        L_0356  => $0356
; $0464 => L_0464         L_0368  => $0368
; $0467 => J_CHR1D        L_036C  => $036C
; $0468 => L_0468         L_0377  => $0377
; $047F => L_047F         L_038B  => $038B
; $0481 => J_CHR1B        L_03C3  => $03C3
; $048A => L_048A         L_03C4  => $03C4
; $0499 => L_0499         L_03C6  => $03C6
; $049D => L_049D         L_03DF  => $03DF
; $04A7 => L_04A7         L_03E6  => $03E6
; $04A9 => L_04A9         L_040A  => $040A
; $04B2 => L_04B2         L_041B  => $041B
; $04B9 => L_04B9         L_0435  => $0435
; $04C1 => L_04C1         L_0464  => $0464
; $04C3 => L_04C3         L_0468  => $0468
; $04CD => L_04CD         L_047F  => $047F
; $04D1 => L_04D1         L_048A  => $048A
; $04D9 => L_04D9         L_0499  => $0499
; $04E2 => L_04E2         L_049D  => $049D
; $04E8 => L_04E8         L_04A7  => $04A7
; $04EF => L_04EF         L_04A9  => $04A9
; $04FD => L_04FD         L_04B2  => $04B2
; $0508 => K_0508         L_04B9  => $04B9
; $0511 => K_0511         L_04C1  => $04C1
; $0516 => K_0516         L_04C3  => $04C3
; $051C => K_051C         L_04CD  => $04CD
; $0522 => K_0522         L_04D1  => $04D1
; $0528 => K_0528         L_04D9  => $04D9
; $052C => L_052C         L_04E2  => $04E2
; $0535 => K_0535         L_04E8  => $04E8
; $053B => K_053B         L_04EF  => $04EF
; $0541 => K_0541         L_04FD  => $04FD
; $0547 => K_0547         L_052C  => $052C
; $0554 => L_0554         L_0554  => $0554
; $0569 => L_0569         L_0569  => $0569
; $056C => L_056C         L_056C  => $056C
; $0572 => L_0572         L_0572  => $0572
; $057C => K_057C         L_0586  => $0586
; $0581 => K_0581         L_058F  => $058F
; $0586 => L_0586         L_0596  => $0596
; $058F => L_058F         L_059F  => $059F
; $0596 => L_0596         L_05A5  => $05A5
; $059F => L_059F         L_05AE  => $05AE
; $05A5 => L_05A5         L_05B1  => $05B1
; $05AE => L_05AE         L_05BA  => $05BA
; $05B1 => L_05B1         L_05BE  => $05BE
; $05BA => L_05BA         L_05C4  => $05C4
; $05BE => L_05BE         L_05CA  => $05CA
; $05C4 => L_05C4         L_05D2  => $05D2
; $05CA => L_05CA         L_05E2  => $05E2
; $05D2 => L_05D2         L_05FB  => $05FB
; $05E2 => L_05E2         L_0607  => $0607
; $05FB => L_05FB         L_060B  => $060B
; $0607 => L_0607         L_060C  => $060C
; $060B => L_060B         L_0610  => $0610
; $060C => L_060C         L_0618  => $0618
; $0610 => L_0610         L_0623  => $0623
; $0614 => J_CHR07        L_062C  => $062C
; $0618 => L_0618         L_0639  => $0639
; $061E => K_061E         L_063D  => $063D
; $0623 => L_0623         L_0648  => $0648
; $0627 => K_0627         L_064B  => $064B
; $062C => L_062C         L_0664  => $0664
; $0633 => K_0633         L_0690  => $0690
; $0637 => K_0637         L_06A0  => $06A0
; $0639 => L_0639         L_06B4  => $06B4
; $063D => L_063D         L_06B7  => $06B7
; $0648 => L_0648         L_06C7  => $06C7
; $064B => L_064B         L_06D6  => $06D6
; $0659 => J_CHR0D        L_06DC  => $06DC
; $0664 => L_0664         L_06DF  => $06DF
; $066C => X_066C         L_06E6  => $06E6
; $0682 => BOOT1          L_06EA  => $06EA
; $0690 => L_0690         L_06F9  => $06F9
; $06A0 => L_06A0         L_06FC  => $06FC
; $06B4 => L_06B4         L_0708  => $0708
; $06B7 => L_06B7         L_0716  => $0716
; $06C7 => L_06C7         L_0C02  => $0C02
; $06D6 => L_06D6         MSGBOOT => $0727
; $06D8 => FDCCMD         MSGDSK  => $072E
; $06DC => L_06DC         MSGERR  => $073C
; $06DF => L_06DF         MSGSYS  => $0735
; $06E6 => L_06E6         VIDEO   => $000C
; $06EA => L_06EA         VINIT   => $0003
; $06F9 => L_06F9         VINIT1  => $0023
; $06FC => L_06FC         X_001D  => $001D
; $0708 => L_0708         X_0133  => $0133
; $0716 => L_0716         X_0157  => $0157
; $0727 => MSGBOOT        X_0176  => $0176
; $072E => MSGDSK         X_0183  => $0183
; $0735 => MSGSYS         X_019A  => $019A
; $073C => MSGERR         X_0257  => $0257
; $0743 => JMPTAB         X_029F  => $029F
; $0771 => JMPTAB2        X_02C3  => $02C3
; $07D2 => JMPTAB3        X_0326  => $0326
; $07EE => JMPTAB4        X_0339  => $0339
; $0948 => K_0948         X_0374  => $0374
; $0B1D => K_0B1D         X_0385  => $0385
; $0C02 => L_0C02         X_03A3  => $03A3
; $0F00 => K_0F00         X_03DB  => $03DB
; $5A50 => K_5A50         X_066C  => $066C
