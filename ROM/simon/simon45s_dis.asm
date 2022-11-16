L_0002  equ $0002
L_00E6  equ $00E6
L_00E9  equ $00E9
L_00EC  equ $00EC

        org $F000

;;; After reset, the ROM is decoded at 0 and throughout the address map. After the
;;; first write to port 0xFF, the ROM is only decoded at 0xFXXX. Before that write,
;;; there must be a jump to 0xFXXX. ROM can be disabled by setting port 0xBC[3]=1
;;;ports: 0xB4-0xB7 PIO
;;;        0xB8-0xBF 8250 UART
;;;        0xFE      Memory mapper
;;;        0xFF      Page-mode.
;;; IVC:
;;;        0xB1      IVC Data (r/w)
;;;        0xB2      IVC Status (ro)
;;;        0xB3      IVC Reset (r/w)
;;; 0x3B-0x5B RP/M Workspace

COLD:
        jp XCOLD


CHRIN:
        jp XCHRIN


CHROUT:
        jp XCHROUT


P2HEX:
        jp XP2HEX


P4HEX:
        jp XP4HEX


SPACE:
        jp XSPACE


CRLF:
        jp XCRLF


MSG1:
        defm "(C) dci software"

MSG20:
        defb $0D
        defm "10-03-87 "

MSG19:
        defm "mG"
        defb $0D, $00

XCOLD:
        in a, ($B3)             ; reset IVC
        ld a, $01               ; 
        out ($E4), a            ; select drive 0/A
        ld d, $40               ; count ??of mapper pages to init??

L_F03B:
        ld bc, $F0FE            ; B=?? C= port for MMAP
        ld e, $0F               ; value?

L_F040:
        out (c), e              ; initialise memory mapper
        dec e                   ; 
        ld a, b                 ; 
        sub $10                 ; 
        ld b, a                 ; 
        jr nc, L_F040           ; continue
        dec d                   ; 
        jr nz, L_F03B           ; 0x64 = 40
        ld a, $11               ; value?
        out ($FF), a            ; page-mode register
        ld sp, L_00E6           ; 
        call L_F1E7             ; 
        ld a, i                 ; 
        ld a, $01               ; 
        push af                 ; wot??
        ld i, a                 ; 
        pop af                  ; 
        jr z, L_F063            ; 
        ld a, ($00EF)           ; 

L_F063:
        ld ($00EF), a           ; 
        push af                 ; 
        ld a, $F3               ; 
        out ($E5), a            ; e5
        ld a, $09

L_F06D:
        dec a
        jr nz, L_F06D
        ld a, $F7
        out ($E5), a
        ld hl, MSG8
        call PRS
        pop af
        jr nz, L_F0DD
        jp L_F14D


MSG2:
        defm " while loading Boot sector"
        defb $00

MSG3:
        defm " during System load"
        defb $00

MSG4:
        defb $C0, $D2, $C5, $C1, $C4, $80, $C5, $D2, $D2, $CF, $D2, $C0, $00

MSG5:
        defm " - Press any key to repeat<"
        defb $00

X_F0D8:
        ld hl, MSG2
        jr L_F0E0


L_F0DD:
        ld hl, MSG3

L_F0E0:
        push hl
        ld hl, MSG4
        call PRS
        pop hl
        call PRS
        ld hl, MSG5

L_F0EE:
        call PRS

L_F0F1:
        call L_F27C
        jr z, L_F0F8
        jr nc, L_F0F1

L_F0F8:
        call L_F2B5
        jr L_F14D


MSG15:
        defm "<"
        defb $09, $09, $09
        defm "<"
        defb $09, $80, $C9, $EE, $F3, $E5, $F2, $F4, $80, $C4, $E9, $F3, $EB, $80, $E9, $EE, $00

MSG15A:
        defb $E4, $F2, $E9, $F6, $E5, $80, $00

MSG16:
        defb $A0
        defm "<"
        defb $00

L_F11D:
        ld hl, MSG15
        call PRS
        ld a, ($00EF)
        ld b, $C0

L_F128:
        inc b
        rrca
        jr nc, L_F128
        ld a, b
        cp $C1
        jr z, L_F133
        sub $10

L_F133:
        call XCHROUT
        jp PRS


L_F139:
        call L_F11D

L_F13C:
        call L_F277
        call z, L_F11D
        call L_F27C
        call L_F2B5
        call L_F27C
        jr z, L_F13C

L_F14D:
        ld sp, L_00E6
        call L_F27C
        jr z, L_F139
        inc a
        jr z, L_F15D
        call L_F36E
        jr L_F170


L_F15D:
        in a, ($E0)
        bit 0, a
        jr nz, L_F15D
        ld a, $5B
        call CMD2FDC
        ld a, $0B
        call CMD2FDC
        call L_F1B4

L_F170:
        or a
        jp nz, X_F0D8
        ld hl, ($0000)
        ld de, (MSG19)
        or a
        sbc hl, de
        call z, L_F2B8
        ld a, ($00EF)
        jp z, L_0002
        ld hl, MSG17
        jp L_F0EE


MSG17:
        defb $09, $80, $C0, $CE, $EF, $80, $C4, $D8, $80, $B3, $80, $C3, $D0, $AF, $CD, $80, $F3, $F9, $F3, $F4, $E5, $ED, $80, $EF, $EE, $80, $F4, $E8, $E9, $F3, $80, $E4, $E9, $F3, $EB, $C0, $80
        defm "<"
        defb $00

L_F1B4:
        ld a, $0B
        call CMD2FDC
        ld a, ($00EF)
        and $20
        jr z, L_F1C2
        ld a, $01

L_F1C2:
        out ($E2), a
        ld hl, $0000
        ld c, $E4
        ld a, $88
        out ($E0), a
        ld b, $80
        jr L_F1D1


L_F1D1:
        in a, (c)
        jr z, L_F1D1
        in a, ($E3)
        ld (hl), a
        inc hl
        djnz L_F1D1

L_F1DB:
        in a, (c)
        jr z, L_F1DB
        in a, ($E3)
        jp m, L_F1DB
        in a, ($E0)
        ret


L_F1E7:
        in a, ($BE)
        and $40
        ld ($00F0), a
        jr nz, L_F22D
        ld hl, $F265
        call L_F25C
        in a, ($B1)
        ld a, $1A
        out ($B1), a
        in a, ($B2)
        rrca
        ccf
        ld a, $FF
        ret c
        ld hl, $0000

L_F206:
        dec hl
        ld a, h
        or l
        scf
        ld a, $FF
        ret z
        in a, ($B2)
        rrca
        jr c, L_F206

L_F212:
        ld hl, $0000
        ld a, $1B
        call PUTIVC
        ld a, $76
        call PUTIVC

L_F21F:
        dec hl
        ld a, h
        or l
        jr z, L_F212
        in a, ($B2)
        rlca
        jr c, L_F21F
        xor a
        in a, ($B1)
        ret


L_F22D:
        ld l, $06

L_F22F:
        ld bc, $0000

L_F232:
        dec bc
        ld a, b
        or c
        jr nz, L_F232
        dec l
        jr nz, L_F22F
        ld hl, $F26E
        call L_F25C
        ld a, $66
        out ($48), a
        ld hl, XXXTAB
        ld bc, $0E42
        otir
        or a
        ret


XXXTAB:
        defb $00, $18, $04, $44, $03, $C0, $05, $60, $01, $00, $03, $C1, $05, $68

L_F25C:
        ld de, L_00E6
        ld bc, $0009
        ldir
        ret

        jp L_F402

        jp L_F411

        jp PUTIVC

        jp L_F42F

        jp L_F434

        jp L_F3EB


L_F277:
        ld a, ($00F0)
        or a
        ret


L_F27C:
        ld a, $D0
        call CMD2FDC
        ld a, ($00EF)
        out ($E4), a
        ld a, $0B
        out ($E0), a
        ld b, $28

L_F28C:
        djnz L_F28C
        ld hl, $D000
        in a, ($E0)
        ld c, a

L_F294:
        in a, ($E0)
        xor c
        and $02
        jr z, L_F29D
        ld b, $FF

L_F29D:
        dec l
        jr nz, L_F294
        call L_F2B8
        or a
        scf
        ret nz
        dec h
        jr nz, L_F294
        ld a, b
        or a
        ret nz
        call L_F2F6
        jr nz, L_F2B3
        inc a
        ret


L_F2B3:
        xor a
        ret


L_F2B5:
        call L_F2D4

L_F2B8:
        call L_00E6
        or a
        ret z
        and $1F
        cp $01
        jp z, CMD_A
        cp $18
        jp z, CMD_8
        cp $13
        ld a, $01
        ret nz
        call L_F2D4
        jp L_F53C


L_F2D4:
        call L_F277
        ld hl, MSG13
        jp z, PRS
        ld hl, MSG14
        jp PRS


MSG13:
        defb $1B
        defm "*"
        defb $00

MSG14:
        defm "<"
        defb $00

CMD2FDC:
        out ($E0), a            ; send command in A to FDC then wait then poll status (for completion?)
        ld a, $0A               ; delay loop count for command acceptance

L_F2EC:
        dec a                   ; 
        jr nz, L_F2EC           ; wait a little while

L_F2EF:
        in a, ($E0)             ; read status
        bit 0, a                ; completion?
        jr nz, L_F2EF           ; not yet.. loop
        ret                     ; done


L_F2F6:
        call L_F331
        nop
        nop
        nop
        nop
        nop
        nop
        jp L_F37A


L_F302:
        xor a

L_F303:
        push af
        in a, ($E5)
        and $10
        jr z, L_F310
        pop af
        dec a
        jr nz, L_F303
        jr L_F311


L_F310:
        pop af

L_F311:
        ld a, $F7
        out ($E5), a
        ret


L_F316:
        in a, ($E5)
        and $10
        ld a, $01
        ret nz

L_F31D:
        in a, ($E5)
        rrca
        jr c, L_F31D
        ret


L_F323:
        ld a, $FF
        out ($E6), a
        ld b, $00

L_F329:
        in a, ($E6)
        djnz L_F329
        ld a, $04
        and a
        ret


L_F331:
        ld b, $00

L_F333:
        in a, ($E5)
        or $E0
        inc a
        jr z, L_F33E
        djnz L_F333
        jr L_F323


L_F33E:
        ld a, $FE
        out ($E6), a
        ld a, $F5
        out ($E5), a
        call L_F302
        pop hl
        call L_F316
        ld a, (hl)
        cpl
        out ($E6), a
        inc hl
        inc hl
        call L_F316
        ld a, ($00EF)
        dec a
        jr z, L_F35E
        ld a, $20

L_F35E:
        cpl
        out ($E6), a
        ld b, $04

L_F363:
        call L_F316
        ld a, (hl)
        cpl
        out ($E6), a
        inc hl
        djnz L_F363
        jp (hl)


L_F36E:
        call L_F331
        ex af, af'
        nop
        nop
        nop
        ld bc, $2100
        nop
        nop

L_F37A:
        call L_F316
        rrca
        jr c, L_F323
        rrca
        jr nc, L_F38F
        in a, ($E6)
        cpl
        ld (hl), a
        ld a, l
        cp $7F
        jr z, L_F37A
        inc hl
        ex af, af'
        ex de, hl

L_F38F:
        set 4, (hl)
        cpl
        ld b, a
        call L_F316
        rrca
        jr c, L_F323
        in a, ($E6)
        ld a, b
        and $0F
        ret


PRS:
        ld l, (hl)              ; print 0-terminated string at (HL)
        inc hl                  ; ??with special treatment of 0x80 and othere?
        or a
        ret z
        cp $80
        jr nz, L_F3A9
        ld a, $A0

L_F3A9:
        push bc
        ld bc, $1420
        cp $09
        jr z, L_F3C1
        ld bc, $052A
        cp $40
        jr z, L_F3C1
        ld c, $AA
        cp $C0
        jr z, L_F3C1
        ld b, $01
        ld c, a

L_F3C1:
        ld a, c
        call XCHROUT
        djnz L_F3C1
        pop bc
        jr PRS


XCHRIN:
        call L_00E9

XCHROUT:
        cp $3C
        jr z, L_F3DB
        cp $0D
        jp nz, L_00EC
        ld a, $0A
        call L_00EC

L_F3DB:
        ld a, $0D
        call L_00EC
        ret


PUTIVC:
        push af

L_F3E2:
        in a, ($B2)
        rrca
        jr c, L_F3E2
        pop af
        out ($B1), a
        ret


L_F3EB:
        push af

L_F3EC:
        in a, ($42)
        and $04
        jr z, L_F3EC

L_F3F2:
        ld a, $10
        out ($42), a
        in a, ($42)
        and $20
        jr z, L_F3F2
        pop af
        and $7F
        out ($40), a
        ret


L_F402:
        ld a, $1B
        call PUTIVC
        ld a, $6B
        call PUTIVC
        call GETIVC
        or a
        ret z

L_F411:
        ld a, $1B
        call PUTIVC
        ld a, $4B
        call PUTIVC
        call GETIVC

L_F41E:
        cp $61
        ret c
        cp $7B
        ret nc
        and $5F
        ret


GETIVC:
        in a, ($B2)
        rlca
        jr c, GETIVC
        in a, ($B1)
        ret


L_F42F:
        in a, ($42)
        and $01
        ret z

L_F434:
        in a, ($42)
        and $01
        jr z, L_F434
        in a, ($40)
        and $7F
        jr L_F41E


CMD_A:
        ld hl, MSG6
        call PRS

L_F446:
        call L_00E9
        sub $31
        jr c, L_F446
        cp $04
        jr nc, L_F446
        ld c, $00

L_F453:
        ld b, a
        inc b
        xor a
        scf

L_F457:
        rla
        djnz L_F457
        or c
        bit 7, a
        jp L_F063


MSG6:
        defb $0D
        defm "Select master Drive (1 or 2) "
        defb $00

CMD_8:
        ld hl, MSG7
        call PRS

L_F485:
        call L_00E9
        sub $31
        jr c, L_F485
        cp $04
        jr nc, L_F485
        ld c, $30
        jr L_F453


MSG7:
        defb $0D
        defm "Select 8\" Drive (1-4) "
        defb $00

MSG8:
        defm "  "
        defb $1A, $0A, $0A, $0A, $09
        defm "Timeclaim DX3 System @"
        defb $0D, $0A, $0A, $00

MSG9:
        defm "This is spare"

MSG18:
        defb $0D, $0A
        defm "       SImple MONitor Version 4.5S"
        defb $0D, $0A, $00

MSG10:
        defm "         GM809/829 present"
        defb $0D, $0A, $00

MSG11:
        defm "         GM849/849A present"
        defb $0D, $0A, $00

L_F53C:
        xor a
        out ($E4), a
        ld hl, MSG18
        call PRS
        ld a, $0F
        out ($E5), a
        in a, ($E5)
        rlca
        ld hl, MSG11
        jr nc, L_F554
        ld hl, MSG10

L_F554:
        call PRS
        ld sp, L_00E6
        ld a, $3E
        call XCHROUT
        call XCHROUT
        ld hl, $F557
        push hl
        call XCHRIN
        cp $41
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

L_F5A0:
        ld hl, MSG12
        jp PRS


MSG12:
        defm "  -What?"
        defb $0D, $00

CMD_B:
        ld a, ($00EF)
        jp L_F063

        cp $30
        ret c
        cp $3A
        jr c, L_F5C6
        cp $41
        ret c
        cp $47
        ccf
        ret c
        sub $07

L_F5C6:
        and $0F
        ret


XP4HEX:
        ld a, h
        call XP2HEX
        ld a, l

XP2HEX:
        push af
        rrca
        rrca
        rrca
        rrca
        call L_F5D7
        pop af

L_F5D7:
        and $0F
        add a, $90
        daa
        adc a, $40
        daa
        jp XCHROUT


XCRLF:
        ld a, $0D
        jp XCHROUT


XSPACE:
        ld a, $20
        jp XCHROUT


L_F5EC:
        call XCHRIN
        cp $30
        ret c
        cp $3A
        jr c, L_F5FF
        cp $41
        ret c
        cp $47
        ccf
        ret c
        sub $07

L_F5FF:
        and $0F
        ret


L_F602:
        ld hl, $0000
        call L_F5EC
        jr nc, L_F610
        cp $20
        jr z, L_F602
        scf
        ret


L_F610:
        add hl, hl
        ret c
        add hl, hl
        ret c
        add hl, hl
        ret c
        add hl, hl
        ret c
        add a, l
        ld l, a
        call L_F5EC
        jr nc, L_F610
        cp $20
        ret z
        cp $0D
        ret z
        scf
        ret


L_F627:
        call L_F602
        jr c, L_F62F
        cp $20
        ret z

L_F62F:
        pop hl
        jp L_F5A0


L_F633:
        call L_F602
        jr c, L_F62F
        cp $0D
        ret z
        jr L_F62F


CMD_C:
        call L_F627
        ex de, hl
        call L_F627
        ld b, h
        ld c, l
        call L_F633
        push bc
        ex (sp), hl
        pop bc
        ex de, hl
        ldir
        ret


CMD_G:
        call L_F633
        jp (hl)


CMD_F:
        call L_F627
        ex de, hl
        call L_F627
        sbc hl, de
        ret c
        ld b, h
        ld c, l
        call L_F633
        ex de, hl
        ld (hl), e
        ld d, h
        ld e, l
        inc de
        ldir
        ret


CMD_S:
        call L_F633

L_F66E:
        call XP4HEX
        ld a, $2D
        call XCHROUT
        ld a, (hl)
        call XP2HEX
        call XSPACE
        ex de, hl
        call L_F602
        ex de, hl
        push af
        cp $0D
        call nz, XCRLF
        pop af
        jr nc, L_F696
        cp $0D
        jr z, L_F695
        cp $2D
        ret nz
        dec hl
        jr L_F66E


L_F695:
        ld e, (hl)

L_F696:
        ld a, d
        or a
        jp nz, L_F5A0
        ld (hl), e
        ld a, (hl)
        cp e
        jp nz, L_F5A0
        inc hl
        jr L_F66E


CMD_O:
        call L_F627
        ld a, h
        or a
        jp nz, L_F5A0
        ld c, l
        call L_F633
        ld a, h
        or a
        jp nz, L_F5A0
        out (c), l
        ret


CMD_Q:
        call L_F633
        ld a, h
        or a
        jp nz, L_F5A0
        ld c, l
        in a, (c)
        call XP2HEX
        jp XCRLF


CMD_D:
        call L_F627
        ex de, hl
        call L_F633
        ld c, l
        ex de, hl

L_F6D2:
        call XP4HEX
        ld b, $10

L_F6D7:
        call XSPACE
        ld a, (hl)
        call XP2HEX
        inc hl
        ld a, $09
        cp b
        jr nz, L_F6EC
        call XSPACE
        ld a, $2D
        call XCHROUT

L_F6EC:
        djnz L_F6D7

L_F6EE:
        call XCRLF
        dec c
        jr nz, L_F6D2
        ret


CMD_V:
        ld hl, MSG20
        jp PRS

        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF
        push af
        cp $0D
        call nz, XCRLF
        pop af
        jr nc, L_F716
        cp $0D
        jr z, L_F715
        cp $2D
        ret nz
        dec hl
        jr L_F6EE


L_F715:
        ld e, (hl)

L_F716:
        ld a, d
        or a
        jp nz, L_F5A0
        ld (hl), e
        ld a, (hl)
        cp e
        jp nz, L_F5A0
        inc hl
        jr L_F6EE

        call L_F627
        ld a, h
        or a
        jp nz, L_F5A0
        ld c, l
        call L_F633
        ld a, h
        or a
        jp nz, L_F5A0
        out (c), l
        ret

        call L_F633
        ld a, h
        or a
        jp nz, L_F5A0
        ld c, l
        in a, (c)
        call XP2HEX
        jp XCRLF

        call L_F627
        ex de, hl
        call L_F633
        ld c, l
        ex de, hl

L_F752:
        call XP4HEX
        ld b, $10

L_F757:
        call XSPACE
        ld a, (hl)
        call XP2HEX
        inc hl
        ld a, $09
        cp b
        jr nz, L_F76C
        call XSPACE
        ld a, $2D
        call XCHROUT

L_F76C:
        djnz L_F757
        call XCRLF
        dec c
        jr nz, L_F752
        ret

        ld hl, MSG20
        jp PRS

        defb $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF


; $F000 CCCCCCCCCCCCCCCCCCCCCBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $F050 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $F0A0 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBCCCCCCCCCCCCCCCCCCCCCCCC
; $F0F0 CCCCCCCCCCCCCBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $F140 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCBBB
; $F190 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $F1E0 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $F230 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCBBBBBBBBBBBBBBCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $F280 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $F2D0 CCCCCCCCCCCCCCCCCCCBBBBBCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $F320 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $F370 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $F3C0 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $F410 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $F460 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBCCCCCCCCCCCCCCCCCCCCCBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $F4B0 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $F500 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBCCCCCCCCCCCCCCCCCCCC
; $F550 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $F5A0 CCCCCCBBBBBBBBBBCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $F5F0 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $F640 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $F690 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $F6E0 CCCCCCCCCCCCCCCCCCCCCCCCCCCBBBBBBBCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $F730 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCBBBBB
; $F780 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $F7D0 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB

; Labels
;
; $0002 => L_0002         CHRIN   => $F003
; $00E6 => L_00E6         CHROUT  => $F006
; $00E9 => L_00E9         CMD2FDC => $F2E8
; $00EC => L_00EC         CMD_8   => $F47F
; $F000 => COLD           CMD_A   => $F440
; $F003 => CHRIN          CMD_B   => $F5B0
; $F006 => CHROUT         CMD_C   => $F63D
; $F009 => P2HEX          CMD_D   => $F6C9
; $F00C => P4HEX          CMD_F   => $F654
; $F00F => SPACE          CMD_G   => $F650
; $F012 => CRLF           CMD_O   => $F6A4
; $F015 => MSG1           CMD_Q   => $F6B8
; $F025 => MSG20          CMD_S   => $F66B
; $F02F => MSG19          CMD_V   => $F6F5
; $F033 => XCOLD          COLD    => $F000
; $F03B => L_F03B         CRLF    => $F012
; $F040 => L_F040         GETIVC  => $F427
; $F063 => L_F063         L_0002  => $0002
; $F06D => L_F06D         L_00E6  => $00E6
; $F080 => MSG2           L_00E9  => $00E9
; $F09B => MSG3           L_00EC  => $00EC
; $F0AF => MSG4           L_F03B  => $F03B
; $F0BC => MSG5           L_F040  => $F040
; $F0D8 => X_F0D8         L_F063  => $F063
; $F0DD => L_F0DD         L_F06D  => $F06D
; $F0E0 => L_F0E0         L_F0DD  => $F0DD
; $F0EE => L_F0EE         L_F0E0  => $F0E0
; $F0F1 => L_F0F1         L_F0EE  => $F0EE
; $F0F8 => L_F0F8         L_F0F1  => $F0F1
; $F0FD => MSG15          L_F0F8  => $F0F8
; $F113 => MSG15A         L_F11D  => $F11D
; $F11A => MSG16          L_F128  => $F128
; $F11D => L_F11D         L_F133  => $F133
; $F128 => L_F128         L_F139  => $F139
; $F133 => L_F133         L_F13C  => $F13C
; $F139 => L_F139         L_F14D  => $F14D
; $F13C => L_F13C         L_F15D  => $F15D
; $F14D => L_F14D         L_F170  => $F170
; $F15D => L_F15D         L_F1B4  => $F1B4
; $F170 => L_F170         L_F1C2  => $F1C2
; $F18D => MSG17          L_F1D1  => $F1D1
; $F1B4 => L_F1B4         L_F1DB  => $F1DB
; $F1C2 => L_F1C2         L_F1E7  => $F1E7
; $F1D1 => L_F1D1         L_F206  => $F206
; $F1DB => L_F1DB         L_F212  => $F212
; $F1E7 => L_F1E7         L_F21F  => $F21F
; $F206 => L_F206         L_F22D  => $F22D
; $F212 => L_F212         L_F22F  => $F22F
; $F21F => L_F21F         L_F232  => $F232
; $F22D => L_F22D         L_F25C  => $F25C
; $F22F => L_F22F         L_F277  => $F277
; $F232 => L_F232         L_F27C  => $F27C
; $F24E => XXXTAB         L_F28C  => $F28C
; $F25C => L_F25C         L_F294  => $F294
; $F277 => L_F277         L_F29D  => $F29D
; $F27C => L_F27C         L_F2B3  => $F2B3
; $F28C => L_F28C         L_F2B5  => $F2B5
; $F294 => L_F294         L_F2B8  => $F2B8
; $F29D => L_F29D         L_F2D4  => $F2D4
; $F2B3 => L_F2B3         L_F2EC  => $F2EC
; $F2B5 => L_F2B5         L_F2EF  => $F2EF
; $F2B8 => L_F2B8         L_F2F6  => $F2F6
; $F2D4 => L_F2D4         L_F302  => $F302
; $F2E3 => MSG13          L_F303  => $F303
; $F2E6 => MSG14          L_F310  => $F310
; $F2E8 => CMD2FDC        L_F311  => $F311
; $F2EC => L_F2EC         L_F316  => $F316
; $F2EF => L_F2EF         L_F31D  => $F31D
; $F2F6 => L_F2F6         L_F323  => $F323
; $F302 => L_F302         L_F329  => $F329
; $F303 => L_F303         L_F331  => $F331
; $F310 => L_F310         L_F333  => $F333
; $F311 => L_F311         L_F33E  => $F33E
; $F316 => L_F316         L_F35E  => $F35E
; $F31D => L_F31D         L_F363  => $F363
; $F323 => L_F323         L_F36E  => $F36E
; $F329 => L_F329         L_F37A  => $F37A
; $F331 => L_F331         L_F38F  => $F38F
; $F333 => L_F333         L_F3A9  => $F3A9
; $F33E => L_F33E         L_F3C1  => $F3C1
; $F35E => L_F35E         L_F3DB  => $F3DB
; $F363 => L_F363         L_F3E2  => $F3E2
; $F36E => L_F36E         L_F3EB  => $F3EB
; $F37A => L_F37A         L_F3EC  => $F3EC
; $F38F => L_F38F         L_F3F2  => $F3F2
; $F39F => PRS            L_F402  => $F402
; $F3A9 => L_F3A9         L_F411  => $F411
; $F3C1 => L_F3C1         L_F41E  => $F41E
; $F3CA => XCHRIN         L_F42F  => $F42F
; $F3CD => XCHROUT        L_F434  => $F434
; $F3DB => L_F3DB         L_F446  => $F446
; $F3E1 => PUTIVC         L_F453  => $F453
; $F3E2 => L_F3E2         L_F457  => $F457
; $F3EB => L_F3EB         L_F485  => $F485
; $F3EC => L_F3EC         L_F53C  => $F53C
; $F3F2 => L_F3F2         L_F554  => $F554
; $F402 => L_F402         L_F5A0  => $F5A0
; $F411 => L_F411         L_F5C6  => $F5C6
; $F41E => L_F41E         L_F5D7  => $F5D7
; $F427 => GETIVC         L_F5EC  => $F5EC
; $F42F => L_F42F         L_F5FF  => $F5FF
; $F434 => L_F434         L_F602  => $F602
; $F440 => CMD_A          L_F610  => $F610
; $F446 => L_F446         L_F627  => $F627
; $F453 => L_F453         L_F62F  => $F62F
; $F457 => L_F457         L_F633  => $F633
; $F460 => MSG6           L_F66E  => $F66E
; $F47F => CMD_8          L_F695  => $F695
; $F485 => L_F485         L_F696  => $F696
; $F494 => MSG7           L_F6D2  => $F6D2
; $F4AC => MSG8           L_F6D7  => $F6D7
; $F4CD => MSG9           L_F6EC  => $F6EC
; $F4DA => MSG18          L_F6EE  => $F6EE
; $F501 => MSG10          L_F715  => $F715
; $F51E => MSG11          L_F716  => $F716
; $F53C => L_F53C         L_F752  => $F752
; $F554 => L_F554         L_F757  => $F757
; $F5A0 => L_F5A0         L_F76C  => $F76C
; $F5A6 => MSG12          MSG1    => $F015
; $F5B0 => CMD_B          MSG10   => $F501
; $F5C6 => L_F5C6         MSG11   => $F51E
; $F5C9 => XP4HEX         MSG12   => $F5A6
; $F5CE => XP2HEX         MSG13   => $F2E3
; $F5D7 => L_F5D7         MSG14   => $F2E6
; $F5E2 => XCRLF          MSG15   => $F0FD
; $F5E7 => XSPACE         MSG15A  => $F113
; $F5EC => L_F5EC         MSG16   => $F11A
; $F5FF => L_F5FF         MSG17   => $F18D
; $F602 => L_F602         MSG18   => $F4DA
; $F610 => L_F610         MSG19   => $F02F
; $F627 => L_F627         MSG2    => $F080
; $F62F => L_F62F         MSG20   => $F025
; $F633 => L_F633         MSG3    => $F09B
; $F63D => CMD_C          MSG4    => $F0AF
; $F650 => CMD_G          MSG5    => $F0BC
; $F654 => CMD_F          MSG6    => $F460
; $F66B => CMD_S          MSG7    => $F494
; $F66E => L_F66E         MSG8    => $F4AC
; $F695 => L_F695         MSG9    => $F4CD
; $F696 => L_F696         P2HEX   => $F009
; $F6A4 => CMD_O          P4HEX   => $F00C
; $F6B8 => CMD_Q          PRS     => $F39F
; $F6C9 => CMD_D          PUTIVC  => $F3E1
; $F6D2 => L_F6D2         SPACE   => $F00F
; $F6D7 => L_F6D7         X_F0D8  => $F0D8
; $F6EC => L_F6EC         XCHRIN  => $F3CA
; $F6EE => L_F6EE         XCHROUT => $F3CD
; $F6F5 => CMD_V          XCOLD   => $F033
; $F715 => L_F715         XCRLF   => $F5E2
; $F716 => L_F716         XP2HEX  => $F5CE
; $F752 => L_F752         XP4HEX  => $F5C9
; $F757 => L_F757         XSPACE  => $F5E7
; $F76C => L_F76C         XXXTAB  => $F24E
