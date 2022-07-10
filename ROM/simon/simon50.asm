;;; SIMON version 5.0 (For HD64180)
;;;
;;; Source recreated by disassembly; all comments inferred from code inspection
;;;
;;; 2Kbyte ROM decoded at address $0000
;;; Can boot automatically if disk present, else enter command-loop supporting these commands:
;;;
;;; A                - ?? boot 5.25" disk
;;; B
;;; C ffff tttt cccc - copy cccc bytes from ffff to tttt. Can overwrite if regions overlap
;;; G aaaa           - go (execute) at address aaaa
;;; F ffff cccc vv   - fill from ffff for cccc bytes with value vv
;;; S aaaa           - inspect and modify memory at address aaaa
;;; O pp vv          - output (write) value vv to I/O port pp
;;; Q pp             - query (read) value from I/O port pp
;;; D ffff cc        - display memory from ffff - cc lines of 16 bytes-per-line
;;; V                - print SIMON version number
;;; 8                - ?? boot 8" disk
;;; N                - ??

XP4HEX: equ $1013
XP2HEX: equ $1018
XCRLF:  equ $102C
XSPACE: equ $1031
L_104C: equ $104C
L_1071: equ $1071
L_107D: equ $107D
PRS:    equ $1087
XCHRIN: equ $10B2
XCHROUT:equ $10B5
L_10C9: equ $10C9
L_10D3: equ $10D3
L_10E0: equ $10E0
L_10EF: equ $10EF
L_110D: equ $110D
L_1112: equ $1112
CMD_M:  equ $111E
L_8002: equ $8002
L_80F4: equ $80F4
L_90E6: equ $90E6
L_90E9: equ $90E9
L_E9F2: equ $E9F2
L_F3E9: equ $F3E9

        org $0000

;;; Documented entry points for user-accessible subroutines
COLD:   jp XCOLD
CHRIN:  jp XCHRIN
CHROUT: jp XCHROUT
P2HEX:  jp XP2HEX
P4HEX:  jp XP4HEX
SPACE:  jp XSPACE
CRLF:   jp XCRLF


MSG1:   defm "(C) dci software"

MSG20:  defb $0D
        defm "29-01-88 "

MSG19:  defm "GG"
        defb $0D, $00


XCOLD:  ld sp, COLD
        ld hl, $FFFF
        xor a
L_003A: dec hl
        cp h
        jr nz, L_003A
        ld a, $83
        ld c, $36
        ld b, $00
        out (c), a
        xor a
        ld c, $32
        out (c), a
        out ($B3), a
        ld hl, $FFFF
        xor a
L_0051: dec hl
        cp h
        jr nz, L_0051
        ld a, $01
        out ($E4), a
        ld b, $05
L_005B: ld hl, COLD
L_005E: dec hl
        ld a, h
        or l
        jr nz, L_005E
        djnz L_005B
        ld sp, COLD
        call L_0207
X006B:  xor a
        ld i, a
        ld a, i
        ld a, $01
        push af
        ld i, a
        pop af
        jr z, L_007B
        ld a, ($90EF)
L_007B: ld ($90EF), a
        push af
        ld a, $F3
        out ($E5), a
        ld a, $E3
L_0085: dec a
        jr nz, L_0085
        ld a, $F7
        out ($E5), a
        ld hl, MSG8
        call PRS
        pop af
        jr nz, L_00F5
        jp L_0165


MSG2:   defm " while loading Boot sector"
        defb $00

MSG3:   defm " during System load"
        defb $00

MSG4:   defb $C0, $D2, $C5, $C1, $C4, $80, $C5, $D2, $D2, $CF, $D2, $C0, $00

MSG5:   defm " - Press any key to repeat<"
        defb $00


X00F0:  ld hl, MSG2
        jr L_00F8


L_00F5: ld hl, MSG3
L_00F8: push hl
        ld hl, MSG4
        call PRS
        pop hl
        call PRS
        ld hl, MSG5
L_0106: call PRS
L_0109: call X02BB
X010C:  jr z, L_0110
        jr nc, L_0109
L_0110: call L_031D
X0113:  jr L_0165


X0115:  inc a
        add hl, bc
        add hl, bc
        add hl, bc
        inc a
        add hl, bc
        add a, b
        ret


X011D:  xor $F3
        push hl
        jp p, L_80F4
        call nz, L_F3E9
        ex de, hl
        add a, b
        jp (hl)


X0129:  xor $80
        call po, L_E9F2
        or $E5
        add a, b
        nop
        and b
        inc a
        nop
L_0135: ld hl, X0115
        call PRS
        ld a, ($90EF)
        ld b, $C0
L_0140: inc b
        rrca
        jr nc, L_0140
        ld a, b
        cp $C1
        jr z, L_014B
        sub $10
L_014B: call XCHROUT
        jp PRS


L_0151: call L_0135
X0154:  call X02B6
X0157:  call z, L_0135
        call X02BB
        call L_031D
        call X02BB
        jr z, X0154
L_0165: ld sp, COLD
        call X02BB
        jr z, L_0151
        inc a
        jr z, L_0175
        call X03D6
X0173:  jr L_0188


L_0175: in a, ($E0)
        bit 0, a
        jr nz, L_0175
        ld a, $5B
        call X0350
        ld a, $0B
        call X0350
        call L_01D4
L_0188: or a
        jp nz, X00F0
        ld hl, ($8000)
        ld de, (MSG19)
        or a
        sbc hl, de
        call z, X0320
        ld a, ($90EF)
        jp z, L_8002
        ld hl, MSG17
        jp L_0106


MSG17:  defb $09, $80, $C0, $CE, $EF, $80, $F2, $E5, $E3, $EF, $E7, $EE, $E9, $F3, $E1, $E2, $EC, $E5, $80, $C3, $D0, $AF, $CD, $80, $F3, $F9, $F3, $F4, $E5, $ED, $80, $EF, $EE, $80, $F4, $E8, $E9, $F3, $80, $E4, $E9, $F3, $EB, $C0, $80
        defm "<"
        defb $00


L_01D4: ld a, $0B
        call X0350
        ld a, ($90EF)
        and $20
        jr z, L_01E2
        ld a, $01
L_01E2: out ($E2), a
        ld hl, $8000
        ld c, $E4
        ld a, $88
        out ($E0), a
        ld b, $80
        jr L_01F1


L_01F1: in a, (c)
        jr z, L_01F1
        in a, ($E3)
        ld (hl), a
        inc hl
        djnz L_01F1
L_01FB: in a, (c)
        jr z, L_01FB
        in a, ($E3)
        jp m, L_01FB
        in a, ($E0)
        ret


L_0207: xor a
        ld ($90F0), a
        ld hl, JPTAB1
        call CP92E6
        in a, ($B1)
        ld a, $1A
        out ($B1), a
        in a, ($B2)
        rrca
        ccf
        ld a, $FF
        ret c
        ld hl, COLD
L_0221: dec hl
        ld a, h
        or l
        scf
        ld a, $FF
        ret z
        in a, ($B2)
        rrca
        jr c, L_0221
L_022D: ld hl, COLD
        ld a, $1B
        call L_10C9
X0235:  ld a, $76
        call L_10C9
L_023A: dec hl
        ld a, h
        or l
        jr z, L_022D
        in a, ($B2)
        rlca
        jr c, L_023A
        xor a
        in a, ($B1)
        ret


X0248:  ld hl, X02AD
        call CP92E6
        ld a, $03
        out ($BB), a
        ld a, $07
        out ($BC), a
        ld c, $BB
L_0258: ld hl, BAUDTAB
L_025B: ld e, (hl)
        inc hl
        ld d, (hl)
        inc hl
        ld a, d
        or e
        jr z, L_0258
        ld a, $83
        out (c), a
        ld a, e
        out ($B8), a
        ld a, d
        out ($B9), a
        ld a, $03
        out (c), a
        call L_90E9
X0274:  cp $0D
        jr nz, L_025B
        call L_90E9
        cp $0D
        jr nz, L_025B
        or a
        ret


BAUDTAB:defw $000D              ;9600bd
        defw $0011              ;7200bd
        defw $001A              ;4800bd
        defw $0023              ;3600bd
        defw $0034              ;2400bd
        defw $003F              ;2000bd
        defw $0045              ;1800bd
        defw $0068              ;1200bd
        defw $00D0              ; 600bd
        defw $01A1              ; 300bd
        defw $0341              ; 150bd
        defw $0470              ; 110bd
        defw $0000              ; mark end of table


CP92E6: ld de, L_90E6
        ld bc, P2HEX
        ldir
        ret


JPTAB1: jp L_10E0
X02A7:  jp L_10EF
X02AA:  jp L_10C9
X02AD:  jp L_110D
X02B0:  jp L_1112
X02B3:  jp L_10D3


X02B6:  ld a, ($90F0)
        or a
        ret


X02BB:  in a, ($E4)
        inc a
        jr z, L_02FC
        ld a, $D0
        call X0350
X02C5:  ld a, ($90EF)
        out ($E4), a
        ld a, $0B
        out ($E0), a
        ld b, $00
L_02D0: djnz L_02D0
        ld hl, $FFFF
        in a, ($E0)
        ld c, a
L_02D8: in a, ($E0)
        xor c
        and $02
        jr z, L_02E1
        ld b, $FF
L_02E1: dec l
        jr nz, L_02D8
        call X0320
        or a
        scf
        ret nz
        dec h
        jr nz, L_02D8
        ld a, b
        or a
        ret nz
        call L_02FC
        call X035E
        jr nz, L_02FA
        inc a
        ret


L_02FA: xor a
        ret


L_02FC: call X0320
        or a
        scf
        ret nz
        ld hl, $8000
        xor a
        out ($FB), a
        out ($FC), a
        ld bc, $80F8
        inir
        ld hl, ($8000)
        ld de, (MSG19)
        or a
        sbc hl, de
        ret nz
        jp L_8002


L_031D: call X033C
X0320:  call L_90E6
X0323:  or a
        ret z
        and $1F
        cp $01
        jp z, CMD_A
        cp $18
        jp z, CMD_8
        cp $13
        ld a, $01
        ret nz
        call X033C
        jp L_0514


X033C:  call X02B6
        ld hl, MSG13
        jp z, PRS
        ld hl, MSG14
        jp PRS


MSG13:  defb $1B
        defm "*"
        defb $00


MSG14:  defm "<"
        defb $00


X0350:  out ($E0), a
        ld a, $0F
L_0354: dec a
        jr nz, L_0354
L_0357: in a, ($E0)
        bit 0, a
        jr nz, L_0357
        ret


X035E:  call X0399
X0361:  nop
        nop
        nop
        nop
        nop
        nop
        jp L_03E2


X036A:  xor a
L_036B: push af
        in a, ($E5)
        and $10
        jr z, L_0378
        pop af
        dec a
        jr nz, L_036B
        jr L_0379


L_0378: pop af
L_0379: ld a, $F7
        out ($E5), a
        ret


X037E:  in a, ($E5)
        and $10
        ld a, $01
        ret nz
L_0385: in a, ($E5)
        rrca
        jr c, L_0385
        ret


X038B:  ld a, $FF
        out ($E6), a
        ld b, $00
L_0391: in a, ($E6)
        djnz L_0391
        ld a, $04
        or a
        ret


X0399:  ld b, $00
L_039B: in a, ($E5)
        or $E0
        inc a
        jr z, L_03A6
        djnz L_039B
        jr X038B


L_03A6: ld a, $FE
        out ($E6), a
        ld a, $F5
        out ($E5), a
        call X036A
X03B1:  pop hl
        call X037E
X03B5:  ld a, (hl)
        cpl
        out ($E6), a
        inc hl
        inc hl
        call X037E
        ld a, ($90EF)
        dec a
        jr z, L_03C6
        ld a, $20
L_03C6: cpl
        out ($E6), a
        ld b, $04
L_03CB: call X037E
        ld a, (hl)
        cpl
        out ($E6), a
        inc hl
        djnz L_03CB
        jp (hl)


X03D6:  call X0399
        ex af, af'
        nop
        nop
        nop
        ld bc, $2100
        nop
        add a, b
L_03E2: call X037E
        rrca
        jr c, X038B
        rrca
        jr nc, L_03F7
        in a, ($E6)
        cpl
        ld (hl), a
        ld a, l
        cp $7F
        jr z, L_03E2
        inc hl
        jr L_03E2


L_03F7: in a, ($E6)
        cpl
        ld b, a
        call X037E
        rrca
        jr c, X038B
        in a, ($E6)
        ld a, b
        and $0F
        ret


CMD_A:  ld hl, MSG6
        call PRS
L_040D: call L_90E9
        sub $31
        jr c, L_040D
        cp $04
        jr nc, L_040D
        ld c, $00
L_041A: ld b, a
        inc b
        xor a
        scf
L_041E: rla
        djnz L_041E
        or c
        bit 7, a
        jp L_007B


MSG6:   defb $0D
        defm "Select master Drive (1 or 2) "
        defb $00


CMD_8:  ld hl, MSG7
        call PRS
L_044C: call L_90E9
        sub $31
        jr c, L_044C
        cp $04
        jr nc, L_044C
        ld c, $30
        jr L_041A


MSG7:   defb $0D
        defm "Select 8\" Drive (1-4) "
        defb $00

MSG8:   defm "  "
        defb $1A, $0A, $0A, $0A, $09
        defm "@ MultiBoard Computer System @"
        defb $0D, $0A, $0A, $00

MSG9:   defm "This is spare"

MSG18:  defb $0D, $0A
        defm "       SImple MONitor Version 5.0 (HD64180)"
        defb $0D, $0A, $00

MSG10:  defm "         GM809/829 present"
        defb $0D, $0A, $00

MSG11:  defm "         GM849/849A present"


XF511:  dec c
        ld a, (bc)
        nop
L_0514: xor a
        out ($E4), a
        ld hl, MSG18
        call PRS
CMDLOP: ld a, $0F
        out ($E5), a
        in a, ($E5)
        rlca
        ld hl, MSG11
        jr nc, L_052C
        ld hl, MSG10
L_052C: call PRS
        ld sp, COLD
        ld a, $3E
        call XCHROUT
X0537:  call XCHROUT
        ld hl, $052F
        push hl
        call XCHRIN
X0541:  cp $41
        jp z, CMD_A
        cp $42
        jp z, CMD_B
        cp $43
        jp z, CMD_C
        cp $47
        jp z, CMD_G
        cp $46
        jp z, CMD_F
        cp $53
        jp z, CMD_S
        cp $4F
        jp z, CMD_O
        cp $51
        jp z, CMD_Q
        cp $44
        jp z, CMD_D
        cp $56
        jp z, CMD_V
        cp $38
        jp z, CMD_8
        cp $4D
        jp z, CMD_M
L_057D: ld hl, MSG12
        jp PRS


MSG12:  defm "  -What?"
        defb $0D, $00

CMD_B:  ld a, ($90EF)
        jp L_007B


CMD_C:  call L_1071
X0596:  ex de, hl
        call L_1071
        ld b, h
        ld c, l
        call L_107D
X059F:  push bc
        ex (sp), hl
        pop bc
        ex de, hl
        ldir
        ret


CMD_G:  call L_107D
        jp (hl)


CMD_F:  call L_1071
        ex de, hl
        call L_1071
        sbc hl, de
        ret c
        ld b, h
        ld c, l
        call L_107D
        ex de, hl
        ld (hl), e
        ld d, h
        ld e, l
        inc de
        ldir
        ret


CMD_S:  call L_107D
L_05C4: call XP4HEX
X05C7:  ld a, $2D
        call XCHROUT
        ld a, (hl)
        call XP2HEX
X05D0:  call XSPACE
X05D3:  ex de, hl
        call L_104C
X05D7:  ex de, hl
        push af
        cp $0D
        call nz, XCRLF
        pop af
        jr nc, L_05EC
        cp $0D
        jr z, L_05EB
        cp $2D
        ret nz
        dec hl
        jr L_05C4


L_05EB: ld e, (hl)
L_05EC: ld a, d
        or a
        jp nz, L_057D
        ld (hl), e
        ld a, (hl)
        cp e
        jp nz, L_057D
        inc hl
        jr L_05C4


CMD_O:  call L_1071
        ld a, h
        or a
        jp nz, L_057D
        ld c, l
        call L_107D
        ld a, h
        or a
        jp nz, L_057D
        out (c), l
        ret


CMD_Q:  call L_107D
        ld a, h
        or a
        jp nz, L_057D
        ld c, l
        in a, (c)
        call XP2HEX
        jp XCRLF


MSG21:  defm "     00 01 02 03 04 05 06 07  08 09 0A 0B 0C 0D 0E 0F        ASCII"
        defb $0D, $0A, $00


CMD_D:  call L_107D
        ld d, h
        ld e, l
L_0669: push hl
        ld hl, MSG21
        call PRS
        pop hl
        ld b, $10
L_0673: push bc
        call XP4HEX
        ld b, $10
L_0679: call XSPACE
        ld a, (hl)
        call XP2HEX
        inc hl
        ld a, $09
        cp b
        jr nz, L_0689
        call XSPACE
L_0689: djnz L_0679
        call XSPACE
        call XSPACE
        ld b, $10
L_0693: ld a, (de)
        cp $3C
        jr z, L_069C
        cp $20
        jr nc, L_069E
L_069C: ld a, $2E
L_069E: call XCHROUT
        inc de
        djnz L_0693
        call XCRLF
        pop bc
        djnz L_0673
        call L_90E9
        cp $1B
        ret z
        call XCRLF
        call XCRLF
        call XCRLF
        jr L_0669


CMD_V:  ld hl, MSG20
        jp PRS


X06C1:  xor a
        call L_06D5
        ld a, $FF
        call L_06D5
        ld a, $55
        call L_06D5
        ld a, $AA
        call L_06D5
        ret


L_06D5: ld hl, $1000
        ld bc, $1000
        ld e, a
L_06DC: ld a, (hl)
        ld d, a
        ld a, e
        ld (hl), a
        inc a
        ld a, (hl)
        cp e
        jr z, L_070F
        push bc
        push hl
        push de
        push hl
        ld b, a
        ld hl, $1278
        call PRS
        xor a
        call XP2HEX
        pop hl
        call XP4HEX
        ld hl, $1283
        call PRS
        pop de
        ld a, e
        call XP2HEX
        ld hl, $128B
        call PRS
        ld a, b
        call XP2HEX
        pop hl
        pop bc
L_070F: ld a, d
        ld (hl), a
        inc hl
        dec bc
        ld a, b
        or c
        jr nz, L_06DC
        ret


        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF


; $0000 CCCCCCCCCCCCCCCCCCCCCBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $0050 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCBBBBBBBB
; $00A0 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $00F0 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $0140 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $0190 CCCCCCCCCCCCCCCCCCCCCBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB-CCCCCCCCCCCC
; $01E0 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $0230 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $0280 CWWWWWWWWWWWWWWWWWWWWWWWWWWCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $02D0 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $0320 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCBBBBBCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $0370 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $03C0 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $0410 CCCCCCCCCCCCCCCCCCCCCCCBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBCCCCCCCCCCCCCCCCCCCCCBBBBB
; $0460 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $04B0 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $0500 BBBBBBBBBBBBBBBBBCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $0550 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCBBBBBBBBBBCCCCCCCCCCCCCCCCCCC
; $05A0 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $05F0 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $0640 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $0690 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $06E0 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCBBBBBBBBBBBBBBBBBBBBBBBB
; $0730 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $0780 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $07D0 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB

; Labels
;
; $0000 => COLD           BAUDTAB => $0281
; $0003 => CHRIN          CHRIN   => $0003
; $0006 => CHROUT         CHROUT  => $0006
; $0009 => P2HEX          CMD_8   => $0446
; $000C => P4HEX          CMD_A   => $0407
; $000F => SPACE          CMD_B   => $058D
; $0012 => CRLF           CMD_C   => $0593
; $0015 => MSG1           CMD_D   => $0664
; $0025 => MSG20          CMD_F   => $05AA
; $002F => MSG19          CMD_G   => $05A6
; $0033 => XCOLD          CMD_M   => $111E
; $003A => L_003A         CMD_O   => $05FA
; $0051 => L_0051         CMD_Q   => $060E
; $005B => L_005B         CMD_S   => $05C1
; $005E => L_005E         CMD_V   => $06BB
; $006B => X006B          CMDLOP  => $051D
; $007B => L_007B         COLD    => $0000
; $0085 => L_0085         CP92E6  => $029B
; $0098 => MSG2           CRLF    => $0012
; $00B3 => MSG3           JPTAB1  => $02A4
; $00C7 => MSG4           L_003A  => $003A
; $00D4 => MSG5           L_0051  => $0051
; $00F0 => X00F0          L_005B  => $005B
; $00F5 => L_00F5         L_005E  => $005E
; $00F8 => L_00F8         L_007B  => $007B
; $0106 => L_0106         L_0085  => $0085
; $0109 => L_0109         L_00F5  => $00F5
; $010C => X010C          L_00F8  => $00F8
; $0110 => L_0110         L_0106  => $0106
; $0113 => X0113          L_0109  => $0109
; $0115 => X0115          L_0110  => $0110
; $011D => X011D          L_0135  => $0135
; $0129 => X0129          L_0140  => $0140
; $0135 => L_0135         L_014B  => $014B
; $0140 => L_0140         L_0151  => $0151
; $014B => L_014B         L_0165  => $0165
; $0151 => L_0151         L_0175  => $0175
; $0154 => X0154          L_0188  => $0188
; $0157 => X0157          L_01D4  => $01D4
; $0165 => L_0165         L_01E2  => $01E2
; $0173 => X0173          L_01F1  => $01F1
; $0175 => L_0175         L_01FB  => $01FB
; $0188 => L_0188         L_0207  => $0207
; $01A5 => MSG17          L_0221  => $0221
; $01D4 => L_01D4         L_022D  => $022D
; $01E2 => L_01E2         L_023A  => $023A
; $01F1 => L_01F1         L_0258  => $0258
; $01FB => L_01FB         L_025B  => $025B
; $0207 => L_0207         L_02D0  => $02D0
; $0221 => L_0221         L_02D8  => $02D8
; $022D => L_022D         L_02E1  => $02E1
; $0235 => X0235          L_02FA  => $02FA
; $023A => L_023A         L_02FC  => $02FC
; $0248 => X0248          L_031D  => $031D
; $0258 => L_0258         L_0354  => $0354
; $025B => L_025B         L_0357  => $0357
; $0274 => X0274          L_036B  => $036B
; $0281 => BAUDTAB        L_0378  => $0378
; $029B => CP92E6         L_0379  => $0379
; $02A4 => JPTAB1         L_0385  => $0385
; $02A7 => X02A7          L_0391  => $0391
; $02AA => X02AA          L_039B  => $039B
; $02AD => X02AD          L_03A6  => $03A6
; $02B0 => X02B0          L_03C6  => $03C6
; $02B3 => X02B3          L_03CB  => $03CB
; $02B6 => X02B6          L_03E2  => $03E2
; $02BB => X02BB          L_03F7  => $03F7
; $02C5 => X02C5          L_040D  => $040D
; $02D0 => L_02D0         L_041A  => $041A
; $02D8 => L_02D8         L_041E  => $041E
; $02E1 => L_02E1         L_044C  => $044C
; $02FA => L_02FA         L_0514  => $0514
; $02FC => L_02FC         L_052C  => $052C
; $031D => L_031D         L_057D  => $057D
; $0320 => X0320          L_05C4  => $05C4
; $0323 => X0323          L_05EB  => $05EB
; $033C => X033C          L_05EC  => $05EC
; $034B => MSG13          L_0669  => $0669
; $034E => MSG14          L_0673  => $0673
; $0350 => X0350          L_0679  => $0679
; $0354 => L_0354         L_0689  => $0689
; $0357 => L_0357         L_0693  => $0693
; $035E => X035E          L_069C  => $069C
; $0361 => X0361          L_069E  => $069E
; $036A => X036A          L_06D5  => $06D5
; $036B => L_036B         L_06DC  => $06DC
; $0378 => L_0378         L_070F  => $070F
; $0379 => L_0379         L_104C  => $104C
; $037E => X037E          L_1071  => $1071
; $0385 => L_0385         L_107D  => $107D
; $038B => X038B          L_10C9  => $10C9
; $0391 => L_0391         L_10D3  => $10D3
; $0399 => X0399          L_10E0  => $10E0
; $039B => L_039B         L_10EF  => $10EF
; $03A6 => L_03A6         L_110D  => $110D
; $03B1 => X03B1          L_1112  => $1112
; $03B5 => X03B5          L_8002  => $8002
; $03C6 => L_03C6         L_80F4  => $80F4
; $03CB => L_03CB         L_90E6  => $90E6
; $03D6 => X03D6          L_90E9  => $90E9
; $03E2 => L_03E2         L_E9F2  => $E9F2
; $03F7 => L_03F7         L_F3E9  => $F3E9
; $0407 => CMD_A          MSG1    => $0015
; $040D => L_040D         MSG10   => $04D9
; $041A => L_041A         MSG11   => $04F6
; $041E => L_041E         MSG12   => $0583
; $0427 => MSG6           MSG13   => $034B
; $0446 => CMD_8          MSG14   => $034E
; $044C => L_044C         MSG17   => $01A5
; $045B => MSG7           MSG18   => $04A9
; $0473 => MSG8           MSG19   => $002F
; $049C => MSG9           MSG2    => $0098
; $04A9 => MSG18          MSG20   => $0025
; $04D9 => MSG10          MSG21   => $061F
; $04F6 => MSG11          MSG3    => $00B3
; $0511 => XF511          MSG4    => $00C7
; $0514 => L_0514         MSG5    => $00D4
; $051D => CMDLOP         MSG6    => $0427
; $052C => L_052C         MSG7    => $045B
; $0537 => X0537          MSG8    => $0473
; $0541 => X0541          MSG9    => $049C
; $057D => L_057D         P2HEX   => $0009
; $0583 => MSG12          P4HEX   => $000C
; $058D => CMD_B          PRS     => $1087
; $0593 => CMD_C          SPACE   => $000F
; $0596 => X0596          X006B   => $006B
; $059F => X059F          X00F0   => $00F0
; $05A6 => CMD_G          X010C   => $010C
; $05AA => CMD_F          X0113   => $0113
; $05C1 => CMD_S          X0115   => $0115
; $05C4 => L_05C4         X011D   => $011D
; $05C7 => X05C7          X0129   => $0129
; $05D0 => X05D0          X0154   => $0154
; $05D3 => X05D3          X0157   => $0157
; $05D7 => X05D7          X0173   => $0173
; $05EB => L_05EB         X0235   => $0235
; $05EC => L_05EC         X0248   => $0248
; $05FA => CMD_O          X0274   => $0274
; $060E => CMD_Q          X02A7   => $02A7
; $061F => MSG21          X02AA   => $02AA
; $0664 => CMD_D          X02AD   => $02AD
; $0669 => L_0669         X02B0   => $02B0
; $0673 => L_0673         X02B3   => $02B3
; $0679 => L_0679         X02B6   => $02B6
; $0689 => L_0689         X02BB   => $02BB
; $0693 => L_0693         X02C5   => $02C5
; $069C => L_069C         X0320   => $0320
; $069E => L_069E         X0323   => $0323
; $06BB => CMD_V          X033C   => $033C
; $06C1 => X06C1          X0350   => $0350
; $06D5 => L_06D5         X035E   => $035E
; $06DC => L_06DC         X0361   => $0361
; $070F => L_070F         X036A   => $036A
; $1013 => XP4HEX         X037E   => $037E
; $1018 => XP2HEX         X038B   => $038B
; $102C => XCRLF          X0399   => $0399
; $1031 => XSPACE         X03B1   => $03B1
; $104C => L_104C         X03B5   => $03B5
; $1071 => L_1071         X03D6   => $03D6
; $107D => L_107D         X0537   => $0537
; $1087 => PRS            X0541   => $0541
; $10B2 => XCHRIN         X0596   => $0596
; $10B5 => XCHROUT        X059F   => $059F
; $10C9 => L_10C9         X05C7   => $05C7
; $10D3 => L_10D3         X05D0   => $05D0
; $10E0 => L_10E0         X05D3   => $05D3
; $10EF => L_10EF         X05D7   => $05D7
; $110D => L_110D         X06C1   => $06C1
; $1112 => L_1112         XCHRIN  => $10B2
; $111E => CMD_M          XCHROUT => $10B5
; $8002 => L_8002         XCOLD   => $0033
; $80F4 => L_80F4         XCRLF   => $102C
; $90E6 => L_90E6         XF511   => $0511
; $90E9 => L_90E9         XP2HEX  => $1018
; $E9F2 => L_E9F2         XP4HEX  => $1013
; $F3E9 => L_F3E9         XSPACE  => $1031
