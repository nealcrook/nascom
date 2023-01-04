;;; Lollipop lady trainer
;;; for NAS-SYS3
;;; Deconstructed from the binary; AFAIK, the source was never published,
;;; but I think that versions existed for both T4 and NAS-SYS3; for reasons
;;; I don't (yet) understand, it doesn't work under NAS-SYS1.

        org $1000

;;; VDU layout
L16:    equ $0BCA               ;top line (not scrolled)
L01:    equ $080A
L07:    equ $098A
L08:    equ $09CA
L15:    equ $0B8A               ;bottom line


START:  ld a, $AA
        ld (X_12EA), a
        xor a
        ld (X_12EC), a
        ld bc, $0D05
        ld hl, L15 + 32
        ld de, $6019
        exx
        call SETUP
X_1016: call L_1115
        ld de, $087A
        call L_1073
        ld de, $09FA
        call L_1073
        call L_10C2
L_1028: call L_1096
        call L_108A
        call L_10A2
        call L_112A
        ld a, (X_12EA)
        cp $96
        call z, L_1194
        call L_10D6
        cp $11
        jr z, L_1049
        cp $03
        jr z, L_104E
        jr L_1061


L_1049: ld de, $087A
        jr L_1051


L_104E: ld de, $09FA
L_1051: call L_1073
        ld a, $20
        ld ($0A89), a
        ld a, $20
        ld ($08FA), a
        call L_10C2
L_1061: jp L_1028


;;; Clear screen and display title on top line. Also called at L_106A
SETUP:  rst $28                 ; PRS - clear screen
        defb $0C
        defb $00
L_1067: ld hl, TITLE
L_106A: ld de, L16 + 11         ; 11 + 26 + 11 = 48, line width, so it's centred.
        ld bc, $001A
        ldir                    ; copy title to top line
        ret


L_1073: ld hl, CAR1
        ld c, $05
L_1078: push bc
        ld bc, $0010
        ldir
        push hl
        ld hl, $0030
        add hl, de
        ex de, hl
        pop hl
        pop bc
        dec c
        jr nz, L_1078
        ret


L_108A: ld hl, L08 - 1
        ld de, L08 - 2
        ld bc, $0142            ;322
        ldir
        ret


L_1096: ld hl, L07 + 46         ;$09B8
        ld de, L07 + 47         ;$09B9
        ld bc, $0140            ;320
        lddr
        ret


L_10A2: ld hl, $087A
L_10A5: ld bc, $0005
L_10A8: ld a, $20
        ld (hl), a
        ld de, $0040
        add hl, de
        dec c
        jr nz, L_10A8
        ld a, $0B
        cp h
        ret z
        ld hl, $09C9
        jr L_10A5


WAIT:   ld c, $0C
L_10BD: rst $38                 ;wait for period in A
        dec c
        jr nz, L_10BD
        ret


L_10C2: ld c, $13
L_10C4: push bc
        call L_1096
        call L_108A
        call L_112A
X_10CE: call L_10A2
        pop bc
        dec c
        jr nz, L_10C4
        ret


L_10D6: push bc
        ld a, $20
        ld hl, X_12ED
        ld b, a
        ld a, r                 ;sort-of 7-bit random number
        add a, (hl)
        jr c, L_10E3
        dec a
L_10E3: ld (hl), a
L_10E4: sub b
        jr nc, L_10E4
        add a, b
        inc a
        pop bc
        ret


L_10EB: push hl
        push de
        push bc
        ld a, e
        ld (hl), a
        dec hl
        ld a, d
        ld (hl), a
        call L_1100
        ld a, $28
        ld (hl), a
        inc hl
        inc a
        ld (hl), a
        pop bc
        pop de
        pop hl
        ret


L_1100: ld c, $40
L_1102: dec hl
        dec c
        jr nz, L_1102
        ret


L_1107: push hl
        ld a, $20
        ld (hl), a
        dec hl
        ld (hl), a
        call L_1100
        ld (hl), a
        inc hl
        ld (hl), a
        pop hl
        ret


L_1115: ld hl, $0BAA
        ld c, $05
L_111A: ld de, $1919
        push hl
        call L_10EB
        pop hl
        dec hl
        dec hl
        dec hl
        dec hl
        dec c
        jr nz, L_111A
        ret


L_112A: ld a, (X_12EC)
        or a
        jr nz, L_1146
        call L_1238
X_1133: cp $1B                  ;ESCape key?
        jr nz, L_1139
        rst $18
        defb $5B                ;MRET - return to NAS-SYS
L_1139: cp $20                  ;Space key? (move??)
        jr z, L_1141
        call WAIT
X_1140: ret


L_1141: ld a, $FF
        ld (X_12EC), a
L_1146: exx
        call L_10EB
        push bc
        call L_122E
        call WAIT
        call L_1107
        pop bc
        dec c
        exx
        ret nz
        exx
        ld c, $05
        push bc
        call L_1100
        call L_11D9
        pop bc
        cp $AA
        jr z, L_117E
        nop
        ld a, $19
        cp e
        ld de, $1927
        jr z, L_1173
        ld de, $6019
L_1173: dec b
        jr z, L_1178
        exx
        ret


L_1178: ld de, $1919
        call L_10EB
L_117E: ld de, $1919
        ld a, $00
        ld (X_12EC), a
        ld b, $0D
        ld hl, (X_12EA)
        dec hl
        dec hl
        dec hl
        dec hl
        ld (X_12EA), hl
        exx
        ret


L_1194: ld a, $AA
        ld (X_12EA), a
        ld hl, CONT             ;Press space to continue
        call L_106A             ;Copy to top line
        ld hl, $2710
        ld (X_12EF), hl
L_11A5: rst $18
        defb $7D                ;scan keyboard and provide repeat key feature (does not exist on NAS-SYS1.. use 61?)
        jr c, L_11B6
        ld hl, (X_12EF)
        dec hl
        ld (X_12EF), hl
        ld a, h
        or l
        jr z, L_11BC
        jr L_11A5


L_11B6: cp $1B                  ;ESCape key?
        jr nz, L_11BC
        rst $18
        defb $5B                ;MRET - return to NAS-SYS
L_11BC: call L_1115
        ld hl, $0190
        ld (X_12EF), hl
        ld hl, L01
        ld de, L01 + 1
        ld bc, $0080            ;2 lines
        ldir
        call L_1067
        exx
        ld hl, $0BAA
        exx
        ret


L_11D9: push hl
        ld a, $20
        inc hl
        cp (hl)
        jr nz, L_11FA
        dec hl
        dec hl
        dec hl
        cp (hl)
        jr nz, L_11FA
        call L_1100
        cp (hl)
        jr nz, L_11FA
        inc hl
        cp (hl)
        jr nz, L_11FA
        inc hl
        cp (hl)
        jr nz, L_11FA
        inc hl
        cp (hl)
        jr nz, L_11FA
        pop hl
        ret


L_11FA: pop hl
        call L_10A2
        call L_10C2
        ld de, $09FA
        call L_1073
        ld de, $0A80
        ld hl, CAR3             ;"AMBULANCE" - been run over
        ld bc, $0009
        ldir
        ld de, $0A40
        ld hl, CAR4
        ld bc, $000A
        ldir
        ld hl, CAR4
        ld de, $09FE
        ld bc, $000C
        ldir
        call L_10C2
        ld a, $AA
        ret


L_122E: ld a, ($0B0A)
        cp $20
        ret z
        call L_1107
        ret


L_1238: push hl
        push de
        push bc
        rst $18
        defb $7D                ;scan keyboard and provide repeat key feature (does not exist on NAS-SYS1.. use 61?)
        jr c, L_1253
        ld hl, (X_12EF)
        dec hl
        ld a, h
        or l
        ld a, $00
        jr nz, L_124E
        ld a, $20
        ld hl, $0190
L_124E: ld (X_12EF), hl
        jr L_1259


L_1253: ld hl, $0190
        ld (X_12EF), hl
L_1259: pop bc
        pop de
        pop hl
        ret


CAR1:   defm "     ______     "

CAR2:   defm "    /  ()      " ;NOT REFERENCED

CAR4:   defb $7F, $7F, $7F, $7F, $7F, $7F, $7F, $7F, $7F, $7F
        defb $7F, $7F

CAR5:   defb $7F, $7F, $7F, $7F ;NOT REFERENCED
        defb $7F, $7F, $7F, $7F, $7F, $7F, $7F, $7F, $7F, $7F, $7F, $7F, $7F, $7F, $7F, $7F

CAR6:   defm "              " ;NOT REFERENCED

CAR3:   defm "AMBULANCE"

TITLE:  defm "* LOLLYPOP LADY TRAINER * "

CONT:   defm "press space to continue   "

X_12EA: defb $AA, $0B
X_12EC: defb $00
X_12ED: defb $F3, $00
X_12EF: defb $FB, $1B
        defb $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
        ; End of unknown area $12E8 to $12FF



; $1000 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $1040 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCBBCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $1090 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $10E0 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $1130 CCCCCCCCBCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $1180 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCBCCCCCCCCCCCCCCCCCCCCBCCCCCCCCCCCCCCCCCCCC
; $11D0 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $1220 CCCCCCCCCCCCCCCCCCCCCCCCCCCCBCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCBBBBBBBBBBBBBBBBBBB
; $1270 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $12C0 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB-----------------------

; Labels
;
; $0018 => L_0018        CAR1   => $125D
; $0028 => L_0028        CAR2   => $126D
; $0038 => L_0038        CAR3   => $12AD
; $1000 => START         CAR4   => $127D
; $1016 => X_1016        CAR5   => $128D
; $1028 => L_1028        CAR6   => $129D
; $1049 => L_1049        CONT   => $12CF
; $104E => L_104E        L_0018 => $0018
; $1051 => L_1051        L_0028 => $0028
; $1061 => L_1061        L_0038 => $0038
; $1064 => L_1064        L_1028 => $1028
; $1067 => L_1067        L_1049 => $1049
; $106A => L_106A        L_104E => $104E
; $1073 => L_1073        L_1051 => $1051
; $1078 => L_1078        L_1061 => $1061
; $108A => L_108A        L_1064 => $1064
; $1096 => L_1096        L_1067 => $1067
; $10A2 => L_10A2        L_106A => $106A
; $10A5 => L_10A5        L_1073 => $1073
; $10A8 => L_10A8        L_1078 => $1078
; $10BB => X_10BB        L_108A => $108A
; $10BD => L_10BD        L_1096 => $1096
; $10C2 => L_10C2        L_10A2 => $10A2
; $10C4 => L_10C4        L_10A5 => $10A5
; $10CE => X_10CE        L_10A8 => $10A8
; $10D6 => L_10D6        L_10BD => $10BD
; $10E3 => L_10E3        L_10C2 => $10C2
; $10E4 => L_10E4        L_10C4 => $10C4
; $10EB => L_10EB        L_10D6 => $10D6
; $1100 => L_1100        L_10E3 => $10E3
; $1102 => L_1102        L_10E4 => $10E4
; $1107 => L_1107        L_10EB => $10EB
; $1115 => L_1115        L_1100 => $1100
; $111A => L_111A        L_1102 => $1102
; $112A => L_112A        L_1107 => $1107
; $1133 => X_1133        L_1115 => $1115
; $1139 => L_1139        L_111A => $111A
; $1140 => X_1140        L_112A => $112A
; $1141 => L_1141        L_1139 => $1139
; $1146 => L_1146        L_1141 => $1141
; $1173 => L_1173        L_1146 => $1146
; $1178 => L_1178        L_1173 => $1173
; $117E => L_117E        L_1178 => $1178
; $1194 => L_1194        L_117E => $117E
; $11A5 => L_11A5        L_1194 => $1194
; $11B6 => L_11B6        L_11A5 => $11A5
; $11BC => L_11BC        L_11B6 => $11B6
; $11D9 => L_11D9        L_11BC => $11BC
; $11FA => L_11FA        L_11D9 => $11D9
; $122E => L_122E        L_11FA => $11FA
; $1238 => L_1238        L_122E => $122E
; $124E => L_124E        L_1238 => $1238
; $1253 => L_1253        L_124E => $124E
; $1259 => L_1259        L_1253 => $1253
; $125D => CAR1          L_1259 => $1259
; $126D => CAR2          START  => $1000
; $127D => CAR4          TITLE  => $12B6
; $128D => CAR5          X_1016 => $1016
; $129D => CAR6          X_10BB => $10BB
; $12AD => CAR3          X_10CE => $10CE
; $12B6 => TITLE         X_1133 => $1133
; $12CF => CONT          X_1140 => $1140
