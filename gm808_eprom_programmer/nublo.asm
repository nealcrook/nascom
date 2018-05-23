;;; Control program for the BITS & P.C.s COMPUTER PRODUCTS LTD
;;; 2708/2716 PROM BLOWER
;;;
;;; also known as "Gemini GM808"
;;;
;;; This source code was disassembled from binary using the PERL
;;; CPU::Z80::Disassembler module. The labels were inserted by
;;; consulting the assembly listing in the GM808 manual.
;;; This code has 1 area in which it differs from the original:
;;; It has been "patched" (not reassembled) to add support for
;;; the 2732. At a hardware level this involved some extra
;;; switching and gates to re-jig the pin assignment and add
;;; the extra address line. At the software level it just involved
;;; recognising a different part and changing the count of the
;;; number of locations in the device. The code is identified
;;; here by the label PATCH.
;;; foofoobedoo@gmail.com April 2018.

        org 0x1000


START1:
        rst 0x28
        defb 0x0C
        defb 0x00

START2:
        rst 0x28
        defb 0x0D
        defb 0x0D
        defb 0x0D
        defm 'Enter options as follows'
        defb 0x0D
        defm 'Execution address prefixed by E'
        defb 0x0D
        defm 'Rom type 2708 or 2716 '
        defb 0x0D
        defm 'Source address or D for Donor '
        defb 0x0D
        defm 'Execution options:'
        defb 0x0D
        defm '11E5 BLOW A ROM (Fully erased)'
        defb 0x0D
        defm '1341 BLOW A ROM (Not erased)'
        defb 0x0D
        defm '12B8 VERIFY A ROM'
        defb 0x0D
        defm '12A0 LOAD DATA FROM DONOR TO RAM'
        defb 0x0D
        defm '129A CHECK FOR FULLY ERASED ROM'
        defb 0x0D
        defb 0x00
        rst 0x18
        defb 0x5B

INBYTE:
        ld a,0x7F
        out (0x06),a
        ld a,c
        out (0x05),a
        in a,(0x04)
        ret


ROMCHK:
        ld de,(0x0C0E)
        ld a,0x27
        cp d
        jr nz,ERROR
        ld a,0x08
        cp e
        jr nz,ROMT2
        ld de,0x0400
        ld a,c
        res 7,a
        ld c,a
        ret


ROMT2:
        jp PATCH

        nop
        nop

L_1140:
        ld de,0x0800

L_1143:
        ld a,c
        set 7,a
        ld c,a
        ret


INIT:
        ld a,0x0F
        out (0x07),a
        ld a,0x6F
        out (0x05),a
        res 1,a
        out (0x05),a
        ld c,a
        ret


DONRAM:
        ld hl,(0x0C10)
        ld a,0x0D
        cp l
        jr nz,MBRAM
        ld a,c
        res 3,a
        ld c,a
        ld hl,0x0000

MBRAM:
        ret


ERROR:
        rst 0x28
        defb 0x0C
        defm '*** OPTIONS INCORRECT ***'
        defb 0x00
        jp START2


INCADD:
        ld a,c
        res 0,a
        out (0x05),a
        nop
        set 0,a
        out (0x05),a
        ld c,a
        inc hl

DECDE:
        dec de
        ld a,d
        or e
        ret


FINISH:
        rst 0x28
        defb 0x0D
        defb 0x0D
        defm 'ENTER "E" FOR SAME OPTIONS'
        defb 0x0D
        defm 'OR E1000 TO RETURN TO START'
        defb 0x0D
        defb 0x0D
        defb 0x00
        rst 0x18
        defb 0x5B

PNTHEX:
        ld a,b
        dec a
        rst 0x18
        defb 0x68
        ld a,0x07
        add a,l
        ld l,a
        ld (0x0C29),hl
        ld a,d
        rst 0x18
        defb 0x68
        ld a,e
        rst 0x18
        defb 0x68
        ret


ROMBLO:
        call ALSET1

BLO:
        ld hl,MES1
        call TLINE
        ld a,c
        bit 7,a
        jp nz,CYCL16
        ld b,0x64
        jr ROMBL4


CYCL16:
        ld b,0x02

ROMBL4:
        call INIT
        call ROMCHK
        call DONRAM
        ld a,c
        res 6,a
        ld c,a
        bit 3,a
        call nz,ROMBL1
        ld a,0x7F
        jr ROMBL2


ROMBL1:
        ld a,0x0F

ROMBL2:
        out (0x06),a
        ld a,c
        out (0x05),a

ROMBL3:
        ld a,(hl)
        out (0x04),a
        ld a,c
        set 4,a
        out (0x05),a
        push de
        ld d,h
        ld e,l
        push hl
        ld hl,0x081B
        ld (0x0C29),hl
        call PNTHEX
        pop hl
        pop de
        ld a,c
        push de
        bit 7,a
        jp z,NODEL
        ld de,0x0555

GODEL:
        call DECDE
        jp nz,GODEL

NODEL:
        pop de
        ld a,c
        out (0x05),a
        call INCADD
        jr nz,ROMBL3
        dec b
        jp nz,ROMBL4
        nop
        nop
        nop
        rst 0x28
        defb 0x0C
        defm 'WAITING 4 Secs                 '
        defb 0x00
        rst 0x18
        defb 0x5D
        rst 0x18
        defb 0x5D
        rst 0x18
        defb 0x5D
        rst 0x18
        defb 0x5D
        call VERIF1

ALSET1:
        rst 0x28
        defb 0x0C
        defb 0x00
        call INIT
        call ROMCHK
        ld a,c
        res 2,a
        set 6,a
        res 5,a
        ld c,a

ALSET2:
        call INBYTE
        cp 0xFF
        jp nz,ERROR1
        call INCADD
        jr nz,ALSET2
        ret


ERASE:
        call ALSET1
        jp FINISH


INPUT:
        call INIT
        call ROMCHK
        ld hl,(0x0C10)
        res 3,a
        ld c,a

INPUT2:
        call INBYTE
        ld (hl),a
        call INCADD
        jr nz,INPUT2
        jp FINISH


VERIF1:
        ld hl,MES2
        call TLINE

VERIFY:
        call INIT
        call ROMCHK
        call DONRAM

V1:
        push de
        ld a,c
        ld e,a
        res 2,a
        set 6,a
        res 5,a
        set 3,a
        ld c,a
        call INBYTE
        ld d,a
        ld a,e
        bit 3,a
        jr nz,VRAM
        set 5,a
        set 2,a
        set 6,a
        res 3,a
        ld c,a
        call INBYTE
        jr V2


VRAM:
        ld a,(hl)

V2:
        cp d
        call nz,ERROR2
        pop de
        call INCADD
        jr nz,V1
        jp FINISH


CURPOS:
        ld hl,0x0BCA
        ld (0x0C29),hl
        ret


ERROR1:
        rst 0x28
        defb 0x0C
        defm ' ** ROM NOT ERASED **'
        defb 0x00
        jp FINISH


ERROR2:
        ld b,a
        inc b
        push hl
        push de
        ld d,h
        ld e,l
        rst 0x28
        defb 0x0D
        defm 'ERROR  @   '
        defb 0x00
        ld hl,(0x0C29)
        call PNTHEX
        ld a,0x08
        add a,l
        ld l,a
        ld (0x0C29),hl
        pop de
        ld a,d
        rst 0x18
        defb 0x68
        pop hl
        ret


FBLOW:
        call ROMCHK
        jp BLO


MES1:
        defm '*** BLOWING *** LOOP  LOCATION'

MES2:
        defm '*** VERIFYING ***             '

TLINE:
        push bc
        rst 0x28
        defb 0x0C
        defb 0x00
        ld de,0x0BCA
        ld bc,0x001E
        ldir
        pop bc
        ret


PATCH:
        ld a,0x16
        cp e
        jp z,L_1140
        ld a,0x32
        cp e
        jp nz,ERROR
        ld de,0x1000
        jp L_1143










; 0x1000 CBBCBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; 0x1040 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; 0x1090 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; 0x10E0 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBCBCCCCCCCCCCCCCCCCCCCCC
; 0x1130 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCBBBBBBBBBBBBBBBBBBBBBBBBB
; 0x1180 BBCCCCCCCCCCCCCCCCCCCCBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; 0x11D0 BCBCCCBCCCCCCCCCBCCBCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; 0x1220 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; 0x1270 CBCBCBCBCCCCBBCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; 0x12C0 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCBBBBBBBBBBBBBBBB
; 0x1310 BBBBBBBCCCCCCCCCCBBBBBBBBBBBBBCCCCCCCCCCCCCCCCBCCCCCCCCBBBBBBBBBBBBBBBBBBBBBBBBB
; 0x1360 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBCCBBCCCCCCCCCCCCCCCCCCCCCCCCCCC

; Labels
;
; 0x0005 => NAS           ALSET1 => 0x127B
; 0x000D => STMON         ALSET2 => 0x128C
; 0x0018 => L_0018        BLO    => 0x11E8
; 0x0028 => L_0028        CURPOS => 0x12F8
; 0x1000 => START1        CYCL16 => 0x11F8
; 0x1003 => START2        DECDE  => 0x1191
; 0x111B => INBYTE        DONRAM => 0x1156
; 0x1125 => ROMCHK        ERASE  => 0x129A
; 0x113B => ROMT2         ERROR  => 0x1166
; 0x1140 => L_1140        ERROR1 => 0x12FF
; 0x1143 => L_1143        ERROR2 => 0x131A
; 0x1148 => INIT          FBLOW  => 0x1341
; 0x1156 => DONRAM        FINISH => 0x1195
; 0x1165 => MBRAM         GODEL  => 0x1238
; 0x1166 => ERROR         INBYTE => 0x111B
; 0x1185 => INCADD        INCADD => 0x1185
; 0x1191 => DECDE         INIT   => 0x1148
; 0x1195 => FINISH        INPUT  => 0x12A0
; 0x11D3 => PNTHEX        INPUT2 => 0x12AC
; 0x11E5 => ROMBLO        L_0018 => 0x0018
; 0x11E8 => BLO           L_0028 => 0x0028
; 0x11F8 => CYCL16        L_1140 => 0x1140
; 0x11FA => ROMBL4        L_1143 => 0x1143
; 0x1210 => ROMBL1        MBRAM  => 0x1165
; 0x1212 => ROMBL2        MES1   => 0x1347
; 0x1217 => ROMBL3        MES2   => 0x1365
; 0x1238 => GODEL         NAS    => 0x0005
; 0x123E => NODEL         NODEL  => 0x123E
; 0x127B => ALSET1        PATCH  => 0x1391
; 0x128C => ALSET2        PNTHEX => 0x11D3
; 0x129A => ERASE         ROMBL1 => 0x1210
; 0x12A0 => INPUT         ROMBL2 => 0x1212
; 0x12AC => INPUT2        ROMBL3 => 0x1217
; 0x12B8 => VERIF1        ROMBL4 => 0x11FA
; 0x12BE => VERIFY        ROMBLO => 0x11E5
; 0x12C7 => V1            ROMCHK => 0x1125
; 0x12EA => VRAM          ROMT2  => 0x113B
; 0x12EB => V2            START1 => 0x1000
; 0x12F8 => CURPOS        START2 => 0x1003
; 0x12FF => ERROR1        STMON  => 0x000D
; 0x131A => ERROR2        TLINE  => 0x1383
; 0x1341 => FBLOW         V1     => 0x12C7
; 0x1347 => MES1          V2     => 0x12EB
; 0x1365 => MES2          VERIF1 => 0x12B8
; 0x1383 => TLINE         VERIFY => 0x12BE
; 0x1391 => PATCH         VRAM   => 0x12EA
