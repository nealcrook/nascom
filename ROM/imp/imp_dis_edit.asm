;;; this is imp_dis.asm hand-edited with comments (as well as comments that were
;;; annotated in by dis_rom

L_030F: equ $030F
L_2800: equ $2800

        org $0000

;;; PIO A[7] - OUT error LED
;;; PIO A[6] - OUT buffer full
;;; PIO A[5] - OUT enable paper (vertical) feed
;;; PIO A[4] - IN  online switch sense
;;; PIO A[3] - IN  linefeed switch sense
;;; PIO A[2] - IN  LH carriage position sense
;;; PIO A[1] - IN  RH carriage position sense
;;; PIO A[0] - IN  ??? skt1
;;; PIO B[7] - OUT enable head motor (horizontal motion)
;;; PIO B[6:0] - OUT print head; forms a vertical column/pattern of 7 dots

COLD:
        ld sp, $2833
        jp COLD1


        ; Start of unknown area $0006 to $0007
        defb $FF, $FF
        ; End of unknown area $0006 to $0007


X_RST8:
        inc hl
        ld a, (hl)
        or a
        ret nz
        ld hl, $2885
        ret


X_RST10:
        dec hl
        ld a, (hl)
        or a
        ret nz
        ld hl, $2BFE
        ret


X_RST18:
        in a, ($30)
        res 7, a
        out ($30), a
        ret


        ; Start of unknown area $001F to $001F
        defb $FF
        ; End of unknown area $001F to $001F


X_RST20:
        push hl
        ld hl, L_016F
        ld ($2801), hl
        pop hl
        res 6, (ix+0)
        ret


        ; Start of unknown area $002D to $002F
        defb $FF, $FF, $FF
        ; End of unknown area $002D to $002F


X_RST30:
        in a, ($30)
        cpl
        and $06
        ret


        ; Start of unknown area $0036 to $0037
        defb $FF, $FF
        ; End of unknown area $0036 to $0037


X_RST38:
        bit 4, (ix+0)
        jr z, L_0043
        res 4, (ix+0)
        ret


L_0043:
        set 4, (ix+0)
        ret


L_0048:
        set 6, (ix+0)             ; 
        push af                 ; 
        push bc                 ; 
        ld b, $08               ; 
        xor a                   ; 
        ld ($2805), a           ; enable head motion??

L_0054:
        ld c, $0A               ; 

L_0056:
        halt                    ; wait for NMI at 1.2kHz 
        dec c                   ; 
        jr nz, L_0056           ; got 10 of them
        xor $80                 ; 
        ld ($2805), a           ; toggle head motion enable
        djnz L_0054             ; go do it again, 8 times in total
        pop bc                  ; 
        pop af                  ; 
        ret                     ; 


        ; Start of unknown area $0064 to $0065
        defb $FF, $FF
        ; End of unknown area $0064 to $0065


X_NMI:
        push af                 ; Come here on NMI at 1.2kHz
        ld a, ($2805)           ; get data for print head
        out ($31), a            ; send it to port B data
        push hl                 ; ?? but HL does not get popped ??
        ld hl, $2803            ; various count values end up in here: 5, 35, 10
        dec (hl)                ; 
        jp L_2800               ; 2800 is loaded with RET (should really be RETN!!)


X_0074:
        jp nz, L_016F
        in a, ($30)
        set 5, a
        out ($30), a
        res 5, a
        out ($30), a
        ld (hl), $0A
        exx
        djnz L_0087
        rst $20

L_0087:
        exx
        jp L_016F


X_008B:
        rst $30
        jp nz, L_016F
        ld hl, X_00D6
        ld ($2801), hl
        exx
        ld b, $01
        ld hl, $2833
        bit 4, (ix+0)
        jr z, L_00A4
        ld hl, $2884

L_00A4:
        exx
        ld hl, $2803
        ld (hl), $05
        jp L_016F


X_00AD:
        rst $30
        jp z, L_016F
        bit 4, (ix+0)
        jr nz, L_00BB
        bit 2, a
        jr L_00BD


L_00BB:
        bit 1, a

L_00BD:
        jp z, L_016F
        push hl
        ld hl, $00CA
        ld ($2801), hl
        pop hl
        ld (hl), $8C
        jp nz, L_016F
        ld a, $80
        ld ($2805), a
        rst $20
        jp L_016F


X_00D6:
        jp nz, L_016F
        ld (hl), $01
        exx
        dec b
        jr z, L_010D
        bit 0, b
        jr nz, L_0107
        ld a, (de)
        bit 1, (ix+0)
        jr z, L_00FC
        bit 1, b
        jr z, L_0107
        or (ix+$02)
        ld c, a
        ld a, (de)
        ld ($2806), a
        ld a, b
        cp $06
        ld a, c
        jr z, L_0108

L_00FC:
        inc de
        bit 4, (ix+0)
        jr z, L_0108
        dec de
        dec de
        jr L_0108


L_0107:
        xor a

L_0108:
        ld ($2805), a
        jr L_016E


L_010D:
        exx
        ld (hl), $05
        bit 1, (ix+0)
        jr z, L_0118
        ld (hl), $08

L_0118:
        exx
        inc l
        bit 4, (ix+0)
        jr z, L_0122
        dec l
        dec l

L_0122:
        or (hl)
        jr nz, L_0131
        res 5, (ix+0)
        ld hl, X_00AD
        ld ($2801), hl
        jr L_016E


L_0131:
        rla
        res 1, (ix+0)
        jr nc, L_0145
        set 1, (ix+0)
        inc l
        bit 4, (ix+0)
        jr z, L_0145
        dec l
        dec l

L_0145:
        rrca
        sub $02
        ld c, a
        ld b, $00
        rlca
        ld e, a
        ld d, b
        ex de, hl
        add hl, hl
        add hl, hl
        sbc hl, bc
        ld (ix+$02), b
        ld bc, charset          ; first byte of 1st char in char set if printing L->R
        bit 4, (ix+0)           ; print direction
        jr z, L_0162
        ld bc, charset+6        ; last byte of 1st char in char set if printing R->L

L_0162:
        add hl, bc
        ld b, $0F
        bit 1, (ix+0)
        jr z, L_016D
        ld b, $1F

L_016D:
        ex de, hl

L_016E:
        exx

L_016F:
        inc hl
        bit 2, (hl)
        jp z, L_0243
        in a, ($28)
        rla
        jp c, L_0243
        res 2, (hl)
        ld hl, ($2809)
        cpl
        and $1C
        in a, ($18)
        jr z, L_018A
        rst $18
        ld a, $7F

L_018A:
        and $7F
        bit 0, (ix+0)
        jr nz, L_01E1
        sub $20
        inc a
        inc a
        jp nc, L_0239
        cp $EF
        jp z, L_0223
        cp $EC
        jp z, L_0237
        cp $EE
        jr z, L_021F
        cp $EA
        jr z, L_0204
        cp $EB
        jr z, L_021B
        cp $E6
        jr z, L_0213
        cp $E7
        jr z, L_0217
        cp $E4
        jr z, L_01F8
        cp $E5
        jr z, L_01FE
        cp $01
        jr nz, L_023C
        set 0, (ix+0)
        push hl
        ld hl, L_02F8
        ld ($2807), hl
        pop hl
        ld a, (hl)
        cp $01
        jr z, L_023C
        cp $65
        jr z, L_023C
        cp $67
        jr z, L_023C
        rlca
        jr c, L_023C
        jr L_0237


L_01E1:
        or $80
        push af
        push hl
        ld hl, ($2807)
        dec hl
        ld ($2807), hl
        ld a, h
        or l
        pop hl
        jr nz, L_01F5
        res 0, (ix+0)

L_01F5:
        pop af
        jr L_0239


L_01F8:
        res 3, (ix+0)
        jr L_023C


L_01FE:
        set 3, (ix+0)
        jr L_023C


L_0204:
        ld a, (hl)
        cp $65
        jr nc, L_023C
        dec a
        jr z, L_023C
        ld (hl), $01
        rst $10
        inc iy
        jr L_023C


L_0213:
        ld a, $62
        jr L_0239


L_0217:
        ld a, $63
        jr L_0239


L_021B:
        ld a, $64
        jr L_0239


L_021F:
        ld a, $67
        jr L_0239


L_0223:
        ld a, (hl)
        cp $66
        jr z, L_023C
        cp $65
        jr z, L_023C
        ld a, $66
        call L_0247
        in a, ($30)
        bit 0, a
        jr nz, L_023C

L_0237:
        ld a, $65

L_0239:
        call L_0247

L_023C:
        ld ($2809), hl
        set 2, (ix+0)

L_0243:
        pop hl
        pop af
        retn


L_0247:
        push af
        rst $08
        ld a, (hl)
        cp $01
        jr z, L_0252
        rst $10
        rst $18
        pop af
        ret


L_0252:
        pop af
        ld (hl), a
        dec iy
        push iy
        ex (sp), hl
        ld a, h
        or a
        jr nz, L_0268
        ld a, l
        cp $05
        jr nc, L_0268
        in a, ($30)
        res 6, a
        out ($30), a

L_0268:
        pop hl
        ret


COLD1:
        ld a, $C9               ; RET
        ld (L_2800), a          ; 
        ld a, $0F               ; Port B output mode -- one-time setup of PIO
        out ($33), a            ; PIO B Ctrl
        ld a, $CF               ; Port A control mode
        out ($32), a            ; PIO A Ctrl
        ld a, $1F               ; Port A [7:5] output, [4:0] input
        out ($32), a            ; PIO A Ctrl
        ld a, $80               ; Enable/disable head motor? All print heads OFF
        out ($31), a            ; PIO B Data
        ld ($2805), a           ; next print head data?
        ld ix, $2804            ; 
        rst $20                 ; 
        ld (ix+0), $00            ; 
        ld (ix-$04), $C3        ; 
        call L_047E
        xor a
        set 7, a
        out ($30), a
        xor a
        ld ($2833), a
        ld iy, L_037A
        ld bc, $0379
        ld de, $2886
        ld hl, $2884
        ld (hl), a
        inc hl
        ld ($280B), hl
        ld (hl), $01
        ldir
        ld (de), a
        ld hl, $2BFE
        ld ($2809), hl
        in a, ($30)
        bit 3, a
        jr nz, L_02F8
        ld de, $2885
        ld hl, tab1
        ld bc, X_RST18
        ldir
        ex de, hl
        ld b, $04

L_02CC:
        ld a, $02

L_02CE:
        ld (hl), a
        inc hl
        inc a
        cp $62
        jr nz, L_02CE
        ld (hl), $65
        inc hl
        ld a, $02

L_02DA:
        ld c, $28
        ld (hl), $62
        inc hl

L_02DF:
        ld (hl), a
        inc hl
        inc a
        dec c
        jr z, L_02DA
        cp $62
        jr nz, L_02DF
        ld (hl), $65
        inc hl
        djnz L_02CC
        dec hl
        ld (hl), $67
        ld ($2809), hl
        ld iy, $004E

L_02F8:
        in a, ($30)
        set 7, a
        out ($30), a

L_02FE:
        call L_03F3
        ld hl, ($280B)
        bit 7, (hl)
        jp nz, L_0496
        ld a, (hl)
        cp $01
        jr z, L_02F8
        ld a, $CF
        ld a, (hl)
        cp $01
        jr z, L_02FE
        cp $65
        jr c, L_030F
        set 7, (ix+0)
        ld hl, ($280B)
        ld bc, $5000
        ld de, $2834

L_0326:
        ld a, (hl)
        cp $65
        jr nc, L_037A
        ld (hl), $01
        push af
        rst $08
        inc iy
        pop af
        cp $62
        jr c, L_035E
        jr z, L_0340
        cp $64
        jr z, L_0348
        ld c, $00
        jr L_0326


L_0340:
        ld a, b
        dec a
        jr z, L_0326
        ld c, $80
        jr L_0326


L_0348:
        ld a, $50
        sub b
        and $07
        ex de, hl
        jr L_0354


L_0350:
        ld (hl), $02
        inc l
        dec b

L_0354:
        inc a
        cp $08
        jr nz, L_0350
        ex de, hl
        ld a, $02
        jr L_036C


L_035E:
        or c
        jp p, L_036C
        dec b
        jr z, L_0369
        ld (de), a
        inc e
        jr L_036C


L_0369:
        inc b
        and $7F

L_036C:
        ld (de), a
        inc e
        and $7F
        cp $02
        jr z, L_0378
        res 7, (ix+0)

L_0378:
        djnz L_0326

L_037A:
        ld ($280B), hl
        ex de, hl
        ld a, b
        or a
        jr z, L_0387

L_0382:
        ld (hl), $02
        inc l
        djnz L_0382

L_0387:
        bit 7, (ix+0)
        jr nz, L_03AD
        call L_03E9
        call L_0048
        ld hl, X_008B
        ld ($2801), hl
        set 5, (ix+0)

L_039D:
        call L_03F3
        bit 5, (ix+0)
        jr nz, L_039D
        bit 3, (ix+0)
        call z, X_RST38

L_03AD:
        ld hl, ($280B)
        ld a, (hl)
        cp $65
        jr c, L_03D3

L_03B5:
        ld (hl), $01
        inc iy
        ld b, a
        rst $08
        ld a, b
        ld ($280B), hl
        cp $65
        jr z, L_03D3
        cp $67
        jr z, L_03DC
        ld a, (hl)
        cp $65
        jr z, L_03B5
        cp $67
        jr z, L_03B5
        jp L_02FE


L_03D3:
        call L_03E9
        call L_0468
        jp L_02FE


L_03DC:
        call L_03E9
        exx
        ld b, $90
        exx
        call L_046C
        jp L_02FE


L_03E9:
        bit 6, (ix+0)
        ret z
        call L_03F3
        jr L_03E9


L_03F3:
        in a, ($30)
        bit 4, a
        jr nz, L_041A
        push iy
        ex (sp), hl
        ld a, h
        or a
        jr nz, L_0405
        ld a, l
        cp $14
        jr c, L_040B

L_0405:
        in a, ($30)
        set 6, a
        out ($30), a

L_040B:
        pop hl
        bit 2, (ix+0)
        jr nz, L_0422
        in a, ($18)
        set 2, (ix+0)
        jr L_0422


L_041A:
        res 2, (ix+0)
        res 6, a
        out ($30), a

L_0422:
        bit 6, (ix+0)
        ret nz
        in a, ($30)
        bit 3, a
        ret nz
        push hl
        push bc
        ld hl, $2803
        ld (hl), $23

L_0433:
        ld a, (hl)
        cp $05
        jr nc, L_0433
        in a, ($30)
        bit 3, a
        jr nz, L_0465
        call L_0468

L_0441:
        bit 6, (ix+0)
        jr nz, L_0441
        ld b, $05

L_0449:
        ld (hl), $FF

L_044B:
        in a, ($30)
        bit 3, a
        jr nz, L_0465
        ld a, (hl)
        cp $05
        jr nc, L_044B
        djnz L_0449

L_0458:
        bit 6, (ix+0)
        call z, L_0468
        in a, ($30)
        bit 3, a
        jr z, L_0458

L_0465:
        pop bc
        pop hl
        ret


L_0468:
        exx
        ld b, $18
        exx

L_046C:
        ld a, $0A
        ld ($2803), a
        set 6, (ix+0)
        push hl
        ld hl, X_0074
        ld ($2801), hl
        pop hl
        ret


L_047E:
        in a, ($30)
        bit 2, a
        ret z
        call L_0048
        res 4, (ix+0)

L_048A:
        in a, ($30)
        bit 2, a
        jr nz, L_048A
        ld (ix+$01), $80
        rst $20
        ret


L_0496:
        call L_047E

L_0499:
        call L_03F3
        push iy
        ex (sp), hl
        ld de, $FF7D
        add hl, de
        pop hl
        jr c, L_0499
        bit 6, (ix+0)
        jr nz, L_0499
        push hl
        exx
        pop hl
        ld bc, $05F0
        exx
        xor a
        ld ($2806), a
        call L_0048
        ld hl, X_04D7
        ld ($2801), hl
        set 5, (ix+0)
        call L_03E9
        ld hl, X_00AD
        ld ($2801), hl
        set 6, (ix+0)
        call L_03E9
        jp L_02F8


X_04D7:
        rst $30
        jp nz, L_016F
        exx
        ld de, X_04E7
        ld ($2801), de
        exx
        jp L_016F


X_04E7:
        exx
        ld d, $00
        dec bc
        bit 0, c
        jr z, L_0504
        ld a, (hl)
        and $7F
        ld (hl), $01
        ld d, a
        rst $08
        inc iy
        ld a, d
        and (ix+$02)
        jr z, L_0501
        xor d
        ld d, a
        rst $18

L_0501:
        ld (ix+$02), d

L_0504:
        ld (ix+$01), d
        ld a, b
        or c
        jr nz, L_051F
        ld de, X_0074
        ld ($2801), de
        ld b, $0E
        ld (ix-$01), $01
        ld ($280B), hl
        res 5, (ix+0)

L_051F:
        exx
        jp L_016F


tab1:
        defb $64, $62, $2B, $2F, $32, $54, $4B, $50, $56, $02, $38, $13, $10, $12, $02, $13, $14, $0F, $12, $15, $0F, $1A, $13, $65

        ; Start of unknown area $053B to $055F
        defb $36, $B7, $22, $2E, $37
        defb $0E, $03, $C4, $A9, $19, $F1, $FE, $2C, $CA, $A7, $27, $C9, $3A, $1C, $37, $B7
        defb $C2, $98, $04, $CD, $7B, $0B, $2A, $35, $37, $2B, $CD, $15, $47, $B7, $CA, $ED
        ; End of unknown area $053B to $055F

;;; Character set. Each character takes 7 bytes
;;; 96 characters, for ASCII codes 0x20 (32) - 0x7f (128)
;;; bits [6:0] of each byte represent a vertical line; MSB at the top.
;;; the middle rows are kind-of smeared together in pairs??
charset:
        defb $00, $00, $00, $00, $00, $00, $00 ;20 ASCII " "
        defb $00, $00, $00, $7D, $00, $00, $00 ;21
        defb $00, $70, $00, $00, $00, $70, $00 ;22
        defb $09, $00, $3F, $40, $09, $40, $2B ;23
        defb $10, $2A, $00, $7F, $00, $2A, $04 ;24
        defb $61, $02, $64, $08, $13, $20, $43 ;25
        defb $02, $25, $50, $09, $54, $22, $01 ;26
        defb $00, $00, $10, $20, $40, $00, $00 ;27
        defb $1C, $22, $41, $00, $00, $00, $00 ;28
        defb $00, $00, $00, $00, $41, $22, $1C ;29
        defb $22, $14, $08, $77, $08, $14, $22 ;2A
        defb $08, $00, $08, $36, $08, $00, $08 ;2B
        defb $00, $00, $0D, $02, $0C, $00, $00 ;2C
        defb $08, $00, $08, $00, $08, $00, $08 ;2D
        defb $00, $00, $03, $00, $03, $00, $00 ;2E
        defb $01, $02, $04, $08, $10, $20, $40 ;2F
        defb $3E, $41, $04, $49, $10, $41, $3E ;30 ASCII "0"
        defb $00, $21, $00, $7F, $00, $01, $00 ;31
        defb $21, $42, $01, $44, $01, $48, $31 ;32
        defb $42, $01, $40, $09, $50, $29, $46 ;33
        defb $04, $08, $14, $20, $44, $1B, $04 ;34
        defb $72, $01, $50, $01, $50, $01, $4E ;35
        defb $06, $09, $10, $29, $40, $09, $06 ;36
        defb $41, $02, $44, $08, $50, $20, $40 ;37
        defb $36, $49, $00, $49, $00, $49, $36 ;38
        defb $30, $48, $01, $4A, $04, $48, $30 ;39
        defb $00, $00, $36, $00, $36, $00, $00 ;3A
        defb $00, $00, $6D, $02, $6C, $00, $00 ;3B
        defb $00, $08, $14, $22, $41, $00, $00 ;3C
        defb $14, $00, $14, $00, $14, $00, $14 ;3D
        defb $00, $00, $41, $22, $14, $08, $00 ;3E
        defb $20, $40, $00, $45, $08, $50, $20 ;3F
        defb $3E, $41, $00, $59, $24, $41, $3C ;40
        defb $0F, $10, $24, $40, $24, $10, $0F ;41 ASCII "A"
        defb $41, $3E, $41, $08, $41, $08, $36 ;42
        defb $3E, $41, $00, $41, $00, $41, $22 ;43
        defb $41, $3E, $41, $00, $41, $00, $3E ;44
        defb $7F, $00, $49, $00, $49, $00, $41 ;45
        defb $7F, $00, $48, $00, $48, $00, $40 ;46
        defb $3E, $41, $00, $41, $04, $41, $26 ;47
        defb $7F, $00, $08, $00, $08, $00, $7F ;48
        defb $00, $41, $00, $7F, $00, $41, $00 ;49
        defb $02, $01, $00, $01, $00, $01, $7E ;4A
        defb $7F, $00, $10, $08, $24, $02, $41 ;4B
        defb $7F, $00, $01, $00, $01, $00, $01 ;4C
        defb $5F, $20, $10, $08, $10, $20, $5F ;4D
        defb $5F, $20, $10, $08, $04, $02, $7D ;4E
        defb $3E, $41, $00, $41, $00, $41, $3E ;4F
        defb $7F, $00, $48, $00, $48, $00, $30 ;50
        defb $3E, $41, $00, $41, $04, $42, $3D ;51
        defb $7F, $00, $48, $00, $4C, $02, $31 ;52 ASCII "R"
        defb $32, $49, $00, $49, $00, $49, $26 ;52
        defb $40, $00, $40, $3F, $40, $00, $40 ;53
        defb $7E, $01, $00, $01, $00, $01, $7E
        defb $78, $04, $02, $01, $02, $04, $78
        defb $7E, $01, $02, $0C, $02, $01, $7E
        defb $41, $22, $14, $08, $14, $22, $41
        defb $40, $20, $10, $0F, $10, $20, $40
        defb $41, $02, $45, $08, $51, $20, $41
        defb $00, $7F, $00, $41, $00, $41, $00
        defb $40, $20, $10, $08, $04, $02, $01
        defb $00, $41, $00, $41, $00, $7F, $00
        defb $08, $10, $20, $5F, $20, $10, $08
        defb $01, $00, $01, $00, $01, $00, $01
        defb $00, $00, $40, $20, $10, $00, $00
        defb $02, $15, $00, $15, $00, $14, $0B
        defb $7F, $00, $10, $01, $10, $01, $0E
        defb $0E, $00, $11, $00, $11, $00, $11
        defb $0E, $01, $10, $01, $10, $00, $7F
        defb $0E, $01, $14, $01, $14, $01, $0C
        defb $10, $00, $3F, $40, $10, $40, $20
        defb $09, $14, $01, $14, $01, $14, $2B
        defb $7F, $00, $10, $00, $10, $00, $0F
        defb $00, $11, $00, $5F, $00, $01, $00
        defb $00, $02, $01, $00, $01, $00, $5E
        defb $7F, $00, $04, $00, $0A, $00, $11
        defb $00, $41, $00, $7F, $00, $01, $00
        defb $0F, $10, $08, $04, $08, $10, $0F
        defb $10, $0F, $00, $10, $00, $10, $0F
        defb $0E, $00, $11, $00, $11, $00, $0E
        defb $1F, $00, $04, $10, $04, $10, $08
        defb $08, $14, $00, $14, $00, $04, $1B
        defb $10, $0F, $00, $10, $00, $10, $08
        defb $08, $15, $00, $15, $00, $15, $02
        defb $10, $00, $3E, $01, $10, $01, $02
        defb $1E, $01, $00, $01, $00, $1E, $01
        defb $18, $04, $02, $01, $02, $04, $18
        defb $1E, $01, $02, $04, $02, $01, $1E
        defb $11, $0A, $00, $04, $00, $0A, $11
        defb $10, $08, $05, $02, $00, $04, $18
        defb $11, $02, $11, $04, $11, $08, $11
        defb $08, $00, $08, $36, $41, $00, $41
        defb $00, $00, $00, $77, $00, $00, $00
        defb $41, $00, $41, $36, $08, $00, $08
        defb $40, $00, $40, $00, $40, $00, $40
        defb $02, $01, $00, $51, $08, $05, $02


; $0000 CCCCCC--CCCCCCCCCCCCCCCCCCCCCCC-CCCCCCCCCCCCC---CCCCCC--CCCCCCCCCCCCCCCCCCCCCCCC
; $0050 CCCCCCCCCCCCCCCCCCCC--CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $00A0 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $00F0 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $0140 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $0190 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $01E0 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $0230 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $0280 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $02D0 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $0320 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $0370 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $03C0 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $0410 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $0460 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $04B0 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $0500 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCBBBBBBBBBBBBBBBBBBBBBBBB---------------------
; $0550 ----------------BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $05A0 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $05F0 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $0640 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $0690 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $06E0 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $0730 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $0780 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $07D0 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB

; Labels
;
; $0000 => COLD           charset => $0560
; $0008 => X_RST8         COLD    => $0000
; $0010 => X_RST10        COLD1   => $026A
; $0018 => X_RST18        L_0043  => $0043
; $0020 => X_RST20        L_0048  => $0048
; $0030 => X_RST30        L_0054  => $0054
; $0038 => X_RST38        L_0056  => $0056
; $0043 => L_0043         L_0087  => $0087
; $0048 => L_0048         L_00A4  => $00A4
; $0054 => L_0054         L_00BB  => $00BB
; $0056 => L_0056         L_00BD  => $00BD
; $0066 => X_NMI          L_00FC  => $00FC
; $0074 => X_0074         L_0107  => $0107
; $0087 => L_0087         L_0108  => $0108
; $008B => X_008B         L_010D  => $010D
; $00A4 => L_00A4         L_0118  => $0118
; $00AD => X_00AD         L_0122  => $0122
; $00BB => L_00BB         L_0131  => $0131
; $00BD => L_00BD         L_0145  => $0145
; $00D6 => X_00D6         L_0162  => $0162
; $00FC => L_00FC         L_016D  => $016D
; $0107 => L_0107         L_016E  => $016E
; $0108 => L_0108         L_016F  => $016F
; $010D => L_010D         L_018A  => $018A
; $0118 => L_0118         L_01E1  => $01E1
; $0122 => L_0122         L_01F5  => $01F5
; $0131 => L_0131         L_01F8  => $01F8
; $0145 => L_0145         L_01FE  => $01FE
; $0162 => L_0162         L_0204  => $0204
; $016D => L_016D         L_0213  => $0213
; $016E => L_016E         L_0217  => $0217
; $016F => L_016F         L_021B  => $021B
; $018A => L_018A         L_021F  => $021F
; $01E1 => L_01E1         L_0223  => $0223
; $01F5 => L_01F5         L_0237  => $0237
; $01F8 => L_01F8         L_0239  => $0239
; $01FE => L_01FE         L_023C  => $023C
; $0204 => L_0204         L_0243  => $0243
; $0213 => L_0213         L_0247  => $0247
; $0217 => L_0217         L_0252  => $0252
; $021B => L_021B         L_0268  => $0268
; $021F => L_021F         L_02CC  => $02CC
; $0223 => L_0223         L_02CE  => $02CE
; $0237 => L_0237         L_02DA  => $02DA
; $0239 => L_0239         L_02DF  => $02DF
; $023C => L_023C         L_02F8  => $02F8
; $0243 => L_0243         L_02FE  => $02FE
; $0247 => L_0247         L_030F  => $030F
; $0252 => L_0252         L_0326  => $0326
; $0268 => L_0268         L_0340  => $0340
; $026A => COLD1          L_0348  => $0348
; $02CC => L_02CC         L_0350  => $0350
; $02CE => L_02CE         L_0354  => $0354
; $02DA => L_02DA         L_035E  => $035E
; $02DF => L_02DF         L_0369  => $0369
; $02F8 => L_02F8         L_036C  => $036C
; $02FE => L_02FE         L_0378  => $0378
; $030F => L_030F         L_037A  => $037A
; $0326 => L_0326         L_0382  => $0382
; $0340 => L_0340         L_0387  => $0387
; $0348 => L_0348         L_039D  => $039D
; $0350 => L_0350         L_03AD  => $03AD
; $0354 => L_0354         L_03B5  => $03B5
; $035E => L_035E         L_03D3  => $03D3
; $0369 => L_0369         L_03DC  => $03DC
; $036C => L_036C         L_03E9  => $03E9
; $0378 => L_0378         L_03F3  => $03F3
; $037A => L_037A         L_0405  => $0405
; $0382 => L_0382         L_040B  => $040B
; $0387 => L_0387         L_041A  => $041A
; $039D => L_039D         L_0422  => $0422
; $03AD => L_03AD         L_0433  => $0433
; $03B5 => L_03B5         L_0441  => $0441
; $03D3 => L_03D3         L_0449  => $0449
; $03DC => L_03DC         L_044B  => $044B
; $03E9 => L_03E9         L_0458  => $0458
; $03F3 => L_03F3         L_0465  => $0465
; $0405 => L_0405         L_0468  => $0468
; $040B => L_040B         L_046C  => $046C
; $041A => L_041A         L_047E  => $047E
; $0422 => L_0422         L_048A  => $048A
; $0433 => L_0433         L_0496  => $0496
; $0441 => L_0441         L_0499  => $0499
; $0449 => L_0449         L_0501  => $0501
; $044B => L_044B         L_0504  => $0504
; $0458 => L_0458         L_051F  => $051F
; $0465 => L_0465         L_2800  => $2800
; $0468 => L_0468         tab1    => $0523
; $046C => L_046C         X_0074  => $0074
; $047E => L_047E         X_008B  => $008B
; $048A => L_048A         X_00AD  => $00AD
; $0496 => L_0496         X_00D6  => $00D6
; $0499 => L_0499         X_04D7  => $04D7
; $04D7 => X_04D7         X_04E7  => $04E7
; $04E7 => X_04E7         X_NMI   => $0066
; $0501 => L_0501         X_RST10 => $0010
; $0504 => L_0504         X_RST18 => $0018
; $051F => L_051F         X_RST20 => $0020
; $0523 => tab1           X_RST30 => $0030
; $0560 => charset        X_RST38 => $0038
; $2800 => L_2800         X_RST8  => $0008
