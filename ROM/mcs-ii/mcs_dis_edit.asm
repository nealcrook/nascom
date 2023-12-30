;;; this is mcs_dis.asm hand-edited with comments (as well as comments that were
;;; annotated in by dis_all)

;;; All data for the drum software is stored at $2800 and upwards
;;; The "save" command uses NAS-SYS "G" to save all of this data
;;; and, on reload, to execute at ????
;;;
;;; When starting the Drum Computer program, "clear store" writes 0
;;; to memory from $2800 - $8FFF.
;;;
;;; There are 10 pages (0-9) each of 10 named rhythms (numbered 0-9)
;;; Looks as though the pages are not stored contiguously -- the info
;;; page is after the page 0 stuff?
;;; Save of page  0    seems to save data $2800-$4300
;;; Save of pages 0,1  seems to save data $2800-$4B00 (another 2Kbytes)
;;;
;;; $2800 - ???? common
;;; $3f00 - $4280 info screen (little bit smaller than the 1Kbyte video RAM)
;;;
;;; $29f0 - ???? page 0 stuff
;;; $     - ???? page 1 stuff
;;; $     - ???? page 2 stuff
;;; $     - ???? page 3 stuff
;;; $     - ???? page 4 stuff
;;; $     - ???? page 5 stuff
;;; $     - ???? page 6 stuff
;;; $     - ???? page 7 stuff
;;; $     - ???? page 8 stuff
;;; $85f0 - ???? page 9 stuff
;;; $
;;; ...... see comments to L_D422
        
        org $0000


COLD:
        ld sp, $1000
        rst $10
        defb $08
        jp MRET


rst_rin:
        rst $18
        defb $62                ; in
        ret c
        jr rst_rin


stmon:
        jp strtb


rst_rcal:
        ex (sp), hl
        inc hl
        ex (sp), hl
        push hl
        push af
        jp rcalb


rst_scal:
        jr rst_rcal


tx1:
        rst $10
        defb $00
        rst $18
        defb $66                ; X_0312 - modified from NAS-SYS
        ex de, hl
        ret


L_RST20:
        ex (sp), hl
        dec hl
        ex (sp), hl
        jp _NMI


        ; Start of unknown area $0026 to $0027
        defb $00, $00
        ; End of unknown area $0026 to $0027


L_0028:
        ex (sp), hl

L_0029:
        ld a, (hl)
        inc hl
        or a
        jr nz, L_0034
        ex (sp), hl

dret:
        ret


L_RST30:
        push hl
        jp L_0739


L_0034:
        rst $30
        jr L_0029


        ; Start of unknown area $0037 to $0037
        defb $00
        ; End of unknown area $0037 to $0037


rst_rdel:
        dec a
        ret z
        push af
        pop af
        jr rst_rdel


X_003E:
        xor a
        ld b, a

L_0040:
        rst $38
        rst $38
        djnz L_0040
        ret


L_0045:
        push hl
        ld hl, initz
        xor (hl)
        out ($00), a
        ld a, (hl)

L_004D:
        out ($00), a
        pop hl
        ret


mflp:
        ld a, $10
        push hl
        ld hl, initz
        xor (hl)
        ld (hl), a
        jr L_004D


srlx:
        push af
        out ($01), a

L_005E:
        in a, ($02)
        bit 6, a
        jr z, L_005E
        pop af
        ret


L_NMI:
        jp _NMI


BIN:
        push hl
        ld hl, $0190

BIN2:
        rst $18
        defb $62                ; in
        jr c, BIN8
        dec hl
        ld a, h
        or l
        jr nz, BIN2

BIN8:
        pop hl
        ret


blink:
        ld hl, (cursor)
        ld d, (hl)
        ld (hl), $5F
        rst $10
        defb $E9
        ld (hl), d
        ret c
        rst $10
        defb $E5
        jr nc, blink
        ret


srlin:
        in a, ($02)
        rla
        ret nc
        in a, ($01)
        ret


rkbd:
        rst $18
        defb $61                ; kbd
        jr nc, RK2
        ld hl, $0250
        ld ($0C2C), hl
        ret


RK2:
        ld hl, ($0C2C)
        dec hl
        ld ($0C2C), hl
        ld a, h
        or l
        ret nz
        ld hl, $0C02
        ld bc, $0800

RK3:
        ld d, $FF
        ld a, l
        cp $06
        jr nz, RK5
        ld d, $BF

RK5:
        cp $09
        jr nz, RK6
        ld d, $C7

RK6:
        ld a, (hl)
        and d
        jr z, RK7
        ld c, $01
        ld a, d
        cpl
        and (hl)
        ld (hl), a

RK7:
        inc hl
        djnz RK3
        ld a, c
        or a
        ret z
        ld hl, $0025
        ld ($0C2C), hl

kbd:
        ld a, $02
        call L_0045
        ld hl, $0C01
        in a, ($00)
        cpl
        ld (hl), a
        ld b, $08

ksc1:
        ld a, $01
        call L_0045
        inc hl
        in a, ($00)
        cpl
        and $7F
        ld d, a
        xor (hl)
        jp nz, ksc2

KSC1A:
        djnz ksc1

KSC8:
        or a
        ret


L_00F0:
        retn


_NMI:
        ld a, (initz)
        out ($00), a
        call L_00F0
        rst $18
        defb $5B                ; mret

;;; scal $53. Get a single digit (0-9) or ESC (1B). Return the character; Z set if ESC
;;; this could be coded more efficiently..
L_00FC:
        rst $18
        defb $7B                ; blink
        cp $1B
        ret z
        sub $30
        jp m, L_00FC
        sub $0A
        jp p, L_00FC
        add a, $3A
        ret


ksc2:
        xor a
        rst $38
        in a, ($00)
        cpl
        and $7F
        ld e, a
        ld a, d
        xor (hl)
        ld c, $FF
        ld d, $00
        scf

ksc4:
        rl d
        inc c
        rra
        jr nc, ksc4
        ld a, d
        and e
        ld e, a
        ld a, (hl)
        and d
        cp e
        jr z, KSC1A
        ld a, (hl)
        xor d
        ld (hl), a
        ld a, e
        or a
        jr z, KSC1A
        ld a, ($0C01)
        and $10
        or b
        add a, a
        add a, a
        add a, a
        or c
        rst $10
        defb $50
        jr z, ksc5
        and $7F
        rst $10
        defb $4A                ; X_01E4
        jr nz, KSC8

ksc5:
        ld a, c
        ld hl, $0C01
        cp $41
        jr c, k20
        cp $5B
        jr nc, k20
        bit 4, (hl)
        jr z, k7
        ccf

k7:
        ld a, (kopt)
        bit 0, a
        ld a, c
        jr z, k8
        ccf

k8:
        jr c, k20
        add a, $20

k20:
        cp $40
        jr nz, k30
        bit 4, (hl)
        jr z, KSC8
        jr k35


k30:
        bit 5, (hl)
        jr z, k35
        xor $40

k35:
        bit 3, (hl)
        jr z, k40
        xor $40

k40:
        ld hl, $0C06
        bit 6, (hl)
        jr z, k55
        xor $80

k55:
        ld hl, kopt
        bit 2, (hl)
        jr z, k60
        xor $80

k60:
        scf
        ret


kse:
        ld hl, ($0C6F)
        ld bc, ($0C6D)
        cpdr
        ret


initt:
        defw $0060              ; length of ktab
        defw $0605              ; end of keyboard table
        defw $06EB              ; subroutine table
        defw $0764              ; output table
        defw $0767              ; input table
        defb $C3, $2F, $00      ; user jump (output)
        defb $C3, $2F, $00      ; user jump (input)
        defb $00

crt:
        or a
        ret z
        push af
        cp $0A
        jr z, crt2
        cp $0C
        jr nz, crt6
        ld hl, $080A
        push hl
        ld b, $30

cr1:
        ld (hl), $20
        inc hl
        djnz cr1
        ld b, $10

cr3:
        ld (hl), $00
        inc hl
        djnz cr3
        ex de, hl
        pop hl
        push hl
        ld bc, L_03B0
        ldir
        pop hl

crt0:
        rst $18
        defb $7C

crt1:
        ld (cursor), hl

crt2:
        pop af
        ret


X_LINE16:
        ld hl, M_LINE16
        push de
        ld de, $0BCE            ; top line of display
        ld bc, $0027            ; length to copy
        ldir
        pop de
        ret

;;; some kind of output formatting, called as DF 4A
;;; A = rhythm number, 0..9
X_01E4:
        push de
        ld de, COLD
        sbc a, $0A
        jr c, L_01F4
        inc d

L_01ED:
        sbc a, $0A
        jr c, L_01FC
        inc d
        jr L_01ED


L_01F4:
        add a, $3A
        rst $30
        ld a, $20
        rst $30
        pop de
        ret


L_01FC:
        ld e, a
        ld a, d
        add a, $30
        rst $30
        ld a, e
        add a, $3A
        rst $30
        pop de
        ret


crt6:
        ld hl, (cursor)
        cp $08
        jr nz, crt14

crt8:
        push af

crt10:
        dec hl
        ld a, (hl)
        or a
        jr z, crt10
        pop af
        cp $11
        jr z, crt12
        ld (hl), $20

crt12:
        rst $10
        defb $66
        jr crt2


crt14:
        cp $11
        jr z, crt8
        cp $17
        jr z, crt0
        cp $1B
        jr nz, crt20
        rst $18
        defb $7C
        ld b, $30

crt18:
        ld (hl), $20
        inc hl
        djnz crt18
        jr crt0


crt20:
        cp $0D
        jr z, crt38
        cp $18
        jr nz, crt25
        push hl
        rst $18
        defb $7C
        pop de
        or a
        sbc hl, de
        add hl, de
        jr z, crt1
        jr crt38


crt25:
        cp $13
        jr nz, crt28
        ld de, $FFC0

crt26:
        add hl, de
        rst $10
        defb $2F
        jp crt2


crt28:
        cp $14
        jr nz, crt29
        ld de, L_0040
        jr crt26


crt29:
        cp $15
        jr nz, crt32

crt30:
        inc hl
        ld a, (hl)
        dec hl
        or a
        jr nz, crt31
        ld (hl), $20
        jp crt2


crt31:
        ld (hl), a
        inc hl
        jr crt30


crt32:
        cp $16
        jr nz, crt34
        ld b, $20

crt33:
        ld a, (hl)
        or a
        jp z, crt2
        ld (hl), b
        ld b, a
        inc hl
        jr crt33


ctst:
        ld de, $080A
        or a
        sbc hl, de
        add hl, de
        ret c
        ld de, $0BBA
        or a
        sbc hl, de
        add hl, de
        ret nc
        pop af

ct8:
        jp crt1


crt34:
        cp $12
        jr z, crt36
        ld (hl), a

crt36:
        inc hl
        ld a, (hl)
        or a
        jr z, crt36
        ld de, $0BCA
        or a
        sbc hl, de
        add hl, de
        jr nz, ct8

crt38:
        rst $18
        defb $7C
        ld de, L_0040
        add hl, de
        rst $10
        defb $D1
        ld de, $080A
        ld hl, $084A
        ld bc, $0370
        ldir
        ld b, $30

crt50:
        dec hl
        ld (hl), $20
        djnz crt50
        jr ct8


cpos:
        ld a, l
        and $C0
        add a, $0A
        ld l, a
        ret


M_LINE16:
        defb $A8, $A6
        defm "   MOVEMENT COMPUTER SYSTEMS II.   "
        defb $A8, $A6

inlin:
        push hl

inl2:
        rst $18
        defb $7B                ; blink
        rst $30
        cp $0D
        jr nz, inl2
        ld hl, (cursor)
        ld de, $FFC0
        add hl, de
        ex de, hl
        pop hl
        ret


brst0:
        xor a
        ld (conflg), a
        ld hl, (brkadr)
        ld a, (hl)
        ld (brkval), a
        ret


X_0312:
        ld a, h
        call L_033D

X_0316:
        ld a, l
        call L_033D

space:
        ld a, $20
        rst $30
        ret


X_031E:
        call space
        jr space


errm:
        rst $28
        defm " Incorrect command. "
        defb $00

crlf:
        ld a, $0D
        rst $30
        ret


L_033D:
        push af
        add a, c
        ld c, a
        pop af
        push af
        rra
        rra
        rra
        rra
        rst $10
        defb $01
        pop af
        and $0F
        add a, $90
        daa
        adc a, $40
        daa
        rst $30
        ret


num:
        ld a, (de)
        cp $20
        inc de
        jr z, num
        dec de
        ld hl, COLD
        ld (numv), hl
        xor a
        ld hl, numn
        ld (hl), a

nn1:
        ld a, (de)
        or a
        ret z
        cp $20
        ret z
        sub $30
        ret c
        cp $0A
        jr c, nn2
        sub $07
        cp $0A
        ret c
        cp $10
        jr c, nn2
        scf
        ret


nn2:
        inc de
        inc (hl)
        inc hl
        rld
        inc hl
        rld
        dec hl
        dec hl
        jr z, nn1
        dec de
        scf
        ret


rlin:
        ld bc, argn
        xor a
        ld (bc), a

rl2:
        rst $18
        defb $64
        ret c
        ld a, (hl)
        or a
        ret z
        inc hl
        inc bc
        ld a, (hl)
        ld (bc), a
        inc hl
        inc bc
        ld a, (hl)
        ld (bc), a
        ld hl, argn
        inc (hl)
        ld a, (hl)
        cp $0B
        jr c, rl2
        scf
        ret

;;; point to workspace
;;; zero-out $6d bytes

strtb:
        ld de, initz
        ld b, $6D
        xor a

L_03B0:
        ld (de), a
        inc de
        djnz L_03B0
        ld hl, initt
        ld bc, $0011
        ldir
        rst $28
        defb $0C, $00
        ret


MRET:
        ld sp, $0C61
        ld hl, $1000
        ld ($0C6B), hl
        rst $28
        defb $0C, $0D, $0D, $0D, $0D
        defm "D - Drum computer"
        defb $0D, $0D
        defm "T - Track sheet."
        defb $0D, $0D
        defm "V - Verify : R - Read tape"
        defb $0D, $0D
        defm "Z - Basic start : B - Basic."
        defb $0D, $0D, $0D, $0D, $00
        rst $18
        defb $54

L_0433:
        call inlin

X_0436:
        ld bc, $0C2B            ; where 1 character would be
        ld a, (de)              ; get it
        cp $20                  ; space (no command)?
        jr nz, L_0440           ; no, might be command
        jr L_0433               ; clear line and try again

;;; this is rather a messy way of doing things!
L_0440:
        cp $42                  ; B
        jr c, L_0476            ; character before B..illegal.
        cp $5B                  ; [
        jr nc, L_0476           ; character after Z..illegal
        cp $50                  ; P
        jr z, L_0476            ; illegal
        cp $59                  ; Y
        jr z, L_0476            ; illegal
        cp $43                  ; C
        jr z, L_0476            ; illegal
        cp $57                  ; W
        jr z, L_0476            ; illegal
        cp $47                  ; G
        jr z, L_0476            ; illegal
        cp $4A                  ; J
        jr z, L_0476            ; illegal
        cp $53                  ; S
        jr z, L_0476            ; illegal
        cp $51                  ; Q
        jr z, L_0476            ; illegal
        cp $54                  ; T
        call z, L_0480          ; Track Sheet command -> change A from 54 to 51 ??!!
        ld (bc), a              ; remaining letters allegedly legal commands: ABDEFHIKLMNOQRUVXZ ??
        ld ($0C0A), a           ; argc (command character)
        inc de                  ; 
        rst $18                 ; 
        defb $79                ; rlin - process command arguments (why??)
        jr nc, L_047A           ; no error.. else fall through to error

L_0476:                         ; no such command: print error message and loop to get command letter
        rst $18
        defb $6B
        jr L_0433


L_047A:                         ; got a "good" command
        rst $18
        defb $60                ; args - load HL/DE/BC with values from command line
        rst $18
        defb $5C                ; go call the routine associated with command letter in (argc)

L_047E:
        jr L_0433               ; go back around command loop


L_0480:                         ; T command modify 'T' to 'Q' ??why??
        ld a, $51
        ret


X_0483:
        ret z
        ld a, (brkval)
        ld (hl), a
        ret


exec:
        ld a, $FF
        ld (conflg), a
        pop af
        ld a, (argn)
        or a
        jr z, L_0498
        ld ($0C69), hl

L_0498:
        pop bc
        pop de
        pop hl
        pop af
        ld sp, ($0C6B)
        push hl
        ld hl, ($0C69)
        ex (sp), hl
        retn


X_04a7:
        push de
        push bc
        ld hl, COLD
        add hl, sp
        ld sp, $0C61
        ld de, $0C61
        ld bc, $000A
        ldir
        ld ($0C6B), hl
        jr L_047E


X_04BD:
        ld (hl), a
        inc hl
        djnz X_04BD
        ret


args:
        ld hl, ($0C0C)

args2:
        ld de, ($0C0E)

args3:
        ld bc, ($0C10)
        ret


write:
        rst $18
        defb $5F
        rst $18
        defb $5D
        rst $18
        defb $77
        push hl
        xor a
        ld b, a

w3:
        rst $18
        defb $6F
        djnz w3
        rst $18
        defb $60

L_04DD:
        rst $10
        defb $E6
        ex de, hl
        scf
        sbc hl, de
        jp c, L_0669
        ex de, hl
        xor a
        rst $38
        ld b, $05

L_04EB:
        rst $18
        defb $6F
        ld a, $FF
        djnz L_04EB
        xor a
        cp d
        jr nz, L_04F7
        ld b, e
        inc b

L_04F7:
        ld e, b
        ld a, l
        rst $18
        defb $6F
        ld a, h
        rst $18
        defb $6F
        ld a, e
        rst $18
        defb $6F
        ld a, d
        rst $18
        defb $6F
        ld c, $00
        rst $18
        defb $6C
        ld a, c
        rst $18
        defb $6F
        rst $18
        defb $6D
        ld b, $0B
        ld a, c

L_0510:
        rst $18
        defb $6F
        xor a
        djnz L_0510
        rst $28
        defm ". "
        defb $00
        jr L_04DD


X_051B:
        ld (hl), a
        push hl
        pop de
        inc de
        ldir
        ret


L_0522:
        ld a, $11
        rst $30
        jr L_052A


;;; get 1 or 2 digits and return the value as a binary number in A
;;; eg, "20" would be returned as $14
;;; ignore non-numeric input except for CR and BS as follows:
;;; single digit can be terminated by CR
;;; after entering single digit, accept BS to correct/change it
;;; after entering second digit, return immediately (no BS possible,
;;; no CR needed/permitted)
getnum:
        push bc
        push de
        push hl

L_052A:
        xor a                   ; redundant?
        rst $18
        defb $7B                ; blink
        call ascnum
        jr c, L_052A            ; loop until ASCII '0'..'9'
        ld ($0C0C), a           ; store as number
        add a, $30              ; convert number back to ASCII
        rst $30                 ; and display it

L_0538:
        rst $18
        defb $7B                ; blink
        and $7F
        cp $08                  ; backspace
        jr z, L_0522            ; do backspace
        ld b, a                 ; preserve it
        cp $0D                  ; CR
        ld a, ($0C0C)
        jr z, L_055C            ; CR so done: tidy up and return
        ld a, b
        call ascnum
        jr c, L_0538            ; loop until ASCII '0'..'9'
        ld d, a                 ; save LS digit
        add a, $30
        rst $30                 ; display it
        ld a, ($0C0C)           ; get MS digit
        ld e, a
        ld b, $09

L_0558:
        add a, e
        djnz L_0558             ; multiply MS digit by 10
        add a, d                ; add LS digit

L_055C:
        pop hl
        pop de
        pop bc
        ret


ascnum:                          ;is A numeric ASCII (ie '0'..'9') C if no, NC if yes: return number 0..9
        sub $30
        ret c
        cp $0A
        ccf
        ret


X_0567:
        ld a, l
        rrca
        rst $18
        defb $68
        jp crlf


        ; Start of unknown area $056E to $056F
        defb $00, $C9
        ; End of unknown area $056E to $056F


rcalb:
        push de
        ld hl, $0006
        add hl, sp
        ld e, (hl)
        inc hl
        ld d, (hl)
        ex de, hl
        dec hl
        dec hl
        bit 3, (hl)
        inc hl
        jr nz, SCAL2
        ld e, (hl)
        ld a, e
        rla
        sbc a, a
        ld d, a
        inc hl
        add hl, de

RCAL4:
        pop de
        pop af
        ex (sp), hl
        ret


SCAL2:
        ld e, (hl)

SCAL3:
        ld d, $00
        ld hl, (_stab)
        add hl, de
        add hl, de
        ld e, (hl)
        inc hl
        ld d, (hl)
        ex de, hl
        jr RCAL4


SCALJ:
        push hl
        push af
        push de
        ld hl, $0C0A
        jr SCAL2


scali:
        push hl
        push af
        push de
        jr SCAL3


ktab:
        defb $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF
        defb $08, $FF, $8E, $FF
        defb $88, $09, $FF, $FF
        defb $FF, $3E, $2E, $46
        defb $36, $BE, $AE, $0E
        defb $FF, $FF, $FF, $89
        defb $FF, $FF, $FF, $FF
        defb $14, $9C, $9B, $A3
        defb $92, $C2, $BA, $B2
        defb $AA, $A2, $98, $A0
        defb $29, $0A, $21, $19
        defb $1A, $1C, $1B, $23
        defb $12, $42, $3A, $32
        defb $2A, $22, $18, $20
        defb $A9, $8A, $A1, $99
        defb $0D, $2C, $41, $13
        defb $3B, $33, $43, $10
        defb $40, $2D, $38, $30
        defb $28, $31, $39, $25
        defb $1D, $24, $15, $34
        defb $45, $35, $11, $2B
        defb $44, $3D, $3C, $1E
        defb $9E, $16, $9A, $96

kop:
        ld a, l
        ld (kopt), a
        ret


break:
        ld (brkadr), hl
        ret


g:
        ld hl, $075F
        rst $18
        defb $71
        push hl
        ld hl, gds
        ld b, $06

L_061A:
        ld a, (hl)
        rst $30
        ld c, $14
        xor a

L_061F:
        rst $38
        dec c
        jr nz, L_061F
        inc hl
        djnz L_061A
        rst $18
        defb $57
        xor a
        rst $38
        ld a, $45
        rst $30
        ld hl, ($0C10)
        rst $18
        defb $66
        ld a, $0D
        rst $30
        pop hl
        rst $18
        defb $71
        ret


gds:
        defb $0D, $45, $30, $0D, $52, $0D

sout:
        ld c, $00

L_0641:
        ld a, (hl)
        rst $18
        defb $6F
        add a, c
        ld c, a
        inc hl
        djnz L_0641
        ret


read:
        rst $18
        defb $5F
        rst $18
        defb $77
        push hl
        rst $18
        defb $78
        push hl

L_0652:
        ld b, $03
        ld c, a

L_0655:
        rst $08
        cp c
        jr nz, L_0652
        djnz L_0655
        cp $FF
        jr z, L_0672
        cp $1B
        jr nz, L_0652

L_0663:
        rst $28
        defb $18, $00
        pop hl
        rst $18
        defb $72

L_0669:
        rst $28
        defb $18, $00
        pop hl
        rst $18
        defb $71
        jp mflp


L_0672:
        rst $08
        ld l, a
        rst $08
        ld h, a
        rst $08
        ld e, a
        rst $08
        ld d, a
        ld c, $00
        rst $18
        defb $6C
        rst $08
        cp c
        jr nz, L_06A0
        ld b, e
        ld c, $00

L_0685:
        ld a, ($0C2B)
        cp $52
        jr z, L_068F
        rst $08
        jr L_0691


L_068F:
        rst $08
        ld (hl), a

L_0691:
        push hl
        ld hl, (cursor)
        ld (hl), a
        pop hl
        add a, c
        ld c, a
        inc hl
        djnz L_0685
        rst $08
        cp c
        jr z, L_06A6

L_06A0:
        rst $28
        defm "? "
        defb $00
        jr L_0652


L_06A6:
        rst $28
        defb $06
        defm " "
        defb $00
        xor a
        cp d
        jr nz, L_0652
        jr L_0663


X_06B0:
        ld hl, $0766
        rst $18
        defb $72
        ld hl, $0763
        rst $18
        defb $71
        ret


X_06BB:
        ld a, l
        ld ($0C28), a
        ld hl, $076A
        rst $18
        defb $72
        ld hl, $0762
        rst $18
        defb $71
        ret


X_06CA:
        rst $18
        defb $70
        ret nc
        and $7F
        ld hl, $0C28
        bit 5, (hl)
        call z, L_0701
        bit 1, (hl)
        jr nz, L_06E8
        push af
        rst $10
        defb $1B
        pop af
        or a
        jr z, L_06E8
        cp $1B
        jr z, L_06E8
        set 7, (hl)

L_06E8:
        scf
        ret


xout:
        push af
        ld hl, $0C28
        bit 7, (hl)
        call z, L_06F7
        res 7, (hl)
        pop af
        ret


L_06F7:
        rst $10
        defb $08
        cp $0D
        ret nz
        bit 4, (hl)
        ret nz
        ld a, $0A

L_0701:
        or a
        push af
        jp pe, L_0708
        xor $80

L_0708:
        bit 0, (hl)
        jr z, L_070E
        xor $80

L_070E:
        call srlx
        pop af
        ret


xn:
        rst $18
        defb $63
        jr xn


normal:
        rst $18
        defb $78
nnom:   ld hl, $0764
nom:    push hl
        ld hl, ($0C73)
        ex (sp), hl
        ld ($0C73), hl
        pop hl
        ret


nnim:
        ld hl, $0767
nim:    push hl
        ld hl, ($0C75)
        ex (sp), hl
        ld ($0C75), hl
        pop hl
        ret


in:
        push hl
        ld hl, $0C75
        jr L_073C


L_0739:
        ld hl, $0C73

L_073C:
        push de
        push bc
        ld e, (hl)
        inc hl
        ld d, (hl)

L_0741:
        push af
        ld a, (de)
        inc de
        or a
        jr z, L_0753
        ld l, a
        pop af
        push de
        or a
        ld e, l
        call scali
        pop de
        jr nc, L_0741
        push af

L_0753:
        pop af
        pop bc
        pop de
        pop hl
        ret


        ; Start of unknown area $0758 to $076C
        defb $6F, $00, $00, $70, $00, $7D, $00, $65
        defb $6F, $00, $6E, $75, $65, $00, $76, $7D, $70, $00, $74, $7D, $00
        ; End of unknown area $0758 to $076C

;;; first is for "A" (0x41)
;;; next is for "B" etc.
;;; 0x5B is MRET
;;;

staba:
        defw getnum             ;41 A
        defw $FFFD              ;42 B BASIC warm start (NAS-SYS uses Z for this)
        defw X_051B             ;43 C - illegal in command loop
        defw drum               ;44 D
        defw exec               ;45 E
        defw errm               ;46 F no such command (same as NAS-SYS)
        defw g                  ;47 G - illegal in command loop
        defw xn                 ;48 H
        defw $056E              ;49 I
        defw X_01E4             ;4A J - illegal in command loop
        defw kop                ;4B K
        defw errm               ;4C L no such command (same as NAS-SYS)
        defw COLD               ;4D M
        defw normal             ;4E N
        defw X_04BD             ;4F O
        defw $B806              ;50 P - illegal in command loop
        defw $D800              ;51 Q Track Sheet - jumps to empty area of ROM (but, as Q, illegal in command loop)
        defw read               ;52 R
        defw L_00FC             ;53 S - illegal in command loop
        defw X_LINE16           ;54 T
        defw X_06B0             ;55 U
        defw read               ;56 V
        defw write              ;57 W - illegal in command loop
        defw X_06BB             ;58 X
        defw $B800              ;59 Y - illegal in command loop (normal NAS-SYS would jump to $B000)
        defw $FFFA              ;5A Z BASIC cold start (NAS-SYS uses J for this)
        defw MRET               ;5B Return to monitor and print menu
        defw SCALJ              ;5C
        defw X_003E             ;5D
        defw L_0045             ;5E
        defw mflp               ;5F
        defw args               ;60
        defw kbd                ;61
        defw in                 ;62
        defw inlin              ;63
        defw num                ;64
        defw crt                ;65
        defw X_0312             ;66
        defw L_033D             ;67
        defw $0341              ;68
        defw space              ;69
        defw crlf               ;6A
        defw errm               ;6B
        defw tx1                ;6C
        defw sout               ;6D
        defw xout               ;6E
        defw srlx               ;6F
        defw srlin              ;70
        defw nom                ;71
        defw nim                ;72
        defw L_073C             ;73
        defw X_06CA             ;74
        defw $0C77              ;75
        defw $0C7A              ;76
        defw nnom               ;77
        defw nnim               ;78
        defw rlin               ;79
        defw $0349              ;7A
        defw blink              ;7B
        defw cpos               ;7C
        defw rkbd               ;7D
        defw X_031E             ;7E
        defw scali              ;7F

        ; Start of unknown area $07EB to $07FF
        defb $00, $00, $00, $00, $00
        defb $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
        ; End of unknown area $07EB to $07FF


        org $0C00


initz:
        defb $00

        org $0C0B


argn:
        defb $00

        org $0C20


numn:
        defb $00

numv:
        defw COLD

brkadr:
        defw COLD

brkval:
        defb $00

conflg:
        defb $00

kopt:
        defb $00

        org $0C29


cursor:
        defw COLD

        org $0C71


_stab:
        defw COLD

        org $2820


PTIME:
        defb $00

        org $2822


RNUM:
        defb $00

        org $282A


DPAGE:
        defb $00

        org $C000


drum:
        jp L_C0D6


M_BPM:
        defb $C3
        defm "_"
        defb $C3
        defm "B.P.M."

M_RUN:
        defm ">> RUNNING <<"

M_XFER:
        defm ">> TRANSFER RHYTHMS <<"

M_PLAY:
        defm ">> PLAYING  RHYTHMS <<"

M_ERAS:
        defm ">>  ERASING RHYTHM  <<"

M_SAVE:
        defm "SAVING RHYTHMS ON TAPE"

M_SPACE:
        defm "Use space bar to pause"

M_SEQ:
        defm "Type sequence : "

M_FULL:
        defm "PAGE FULL. "

M_INFO:
        defm "> INFORMATION < "

M_INFO2:
        defm "1"
        defb $07
        defm "A"
        defb $05
        defm "2"
        defb $03
        defm "4"
        defb $01
        defm "8"
        defb $00
        defm "F"
        defb $FA
        defm "H"
        defb $0F
        defm ":"
        defb $1F
        defm "1"
        defb $05
        defm "A"
        defb $04
        defm "T"
        defb $03
        defm "2"
        defb $02
        defm "3"
        defb $01
        defm "6"
        defb $00
        defm "F"
        defb $FA
        defm "H"
        defb $0B
        defm ":"
        defb $17

L_C0D4  defb $7D, $00           ; input table: RKBD, END

L_C0D6:
        ld hl, L_C0D4           ; input table
        ld ($0C75), hl          ; set input table (this table ignores UART input)
        call CLS                ; clear screen
        rst $18
        defb $54                ; print heading to line 16
        ld hl, L_C336           ; "Type command letter."
        ld de, $084A            ; line 2
        ld bc, $0014
        ldir                    ; copy it
        rst $28                 ; print menu

M_MENU:
        defb $0D, $0D, $0D
        defm "C - Continue."
        defb $0D, $0D
        defm "N - NORMAL  start (48)"
        defb $0D, $0D
        defm "S - SHUFFLE start (64)"
        defb $0D, $0D
        defm "H - HIGH    start (128)"
        defb $0D, $0D, $0D
        defm "MCSII.(c) : Ser 3003 :"
        defb $00

L_C160:
        rst $08                 ; wait for character
        and $7F                 ; clear MSB
        cp $43                  ; C
        jp z, CONT              ; check for legal DPAGE and continue
        cp $63                  ; c
        jp z, CONT1             ; continue WITHOUT checking for legal DPAGE
        cp $53                  ; S
        jp z, START             ; shuffle start
        cp $48                  ; H
        jr z, START             ; high start
        cp $4E                  ; N
        jr z, START             ; normal start
        cp $0C                  ; CTRL-L
        jp z, RESTART           ; back to boot menu
        jr L_C160               ; Illegal.. go round again


CONT:
        ld a, (DPAGE)
        cp $00
        jr c, L_C160
        cp $0A
        jr nc, L_C160
        jp CONT1


L_C18F:
        call L_D422             ; get DPAGE-dependent address in HL
        ld d, $00
        ld a, (RNUM)
        ld e, a
        add hl, de
        ret


X_C19A:                         ; unreachable??
        ld hl, $2850
        call L_C18F
        ld a, (hl)
        ld ($280B), a
        ret


X_C1A5:                         ; go via RAM to CONT1
        ld hl, ($2800)
        jp (hl)


;;; "cold start" of drum computer software - clears memory
START:
        push af                 ; A shows how we got here: N(ormal) S(huffle) or H(igh) start
        rst $28
        defm "Confirm to clear store Y"
        defb $11, $00           ; cursor left over the top of the Y
        rst $18
        defb $7B                ; blink: wait for input
        and $7F
        cp $59                  ; 'Y'
        jp nz, L_C0D6           ; abort; go back to menu/start of Drum code
        ld hl, $2800
        ld bc, $6800
        ld a, $00
        rst $18
        defb $43                ; Fill memory with 0; $6800 bytes @ $2800
        call CLS
        ld hl, $0800
        ld de, $3F00            ; clear the Info page at $3f00 by copying an image
        ld bc, $0380            ; of a cleared screen into it.
        ldir
        ld a, $00
        ld ($2835), a
        ld a, $01
        ld ($2834), a
        ld b, $0A               ; 10 pages

L_C1F2:
        ld a, b
        dec a                   ; page number, 9..0
        ld (DPAGE), a           ; select page (on loop exit, leave page 0 selected)
        push bc
        ld hl, $29F0            ; start of page 0 stuff
        call L_D422             ; get DPAGE-dependent address in HL
        ld a, $2E
        ld bc, $010F
        rst $18
        defb $43                ; Fill memory with $2E, $010F bytes @ ??
        pop bc
        djnz L_C1F2             ; loop, clearing all 10 pages 
        ld hl, CONT1
        ld ($2800), hl
        ld hl, $080A
        ld ($2818), hl
        ld b, $0A

L_C216:
        ld a, b
        ld (DPAGE), a
        ld hl, $084A
        call L_CF6A
        ld hl, $2880
        call L_D422             ; get DPAGE-dependent address in HL
        push bc
        ld bc, $0138
        ld a, $20
        rst $18
        defb $43                ; Fill memory with $20, $0138 bytes @ ??
        pop bc
        djnz L_C216
        ld hl, $2833
        ld a, $01
        ld (hl), a
        pop af
        ld b, $10
        ld iy, $2803
        set 4, (iy)
        cp $48
        jr z, L_C25A
        push af
        ld a, $02
        ld (hl), a
        pop af
        ld b, $0C
        cp $53
        jr z, L_C25A
        res 4, (iy)
        ld b, $08
        ld a, $03
        ld (hl), a

L_C25A:
        ld a, b
        ld ($2812), a
        xor a
        ld (DPAGE), a
        jp CONT1


L_C265:
        call CLS
        rst $18
        defb $54                ; X_LINE16
        call L_D437
        ld a, ($2834)
        bit 0, a
        jr nz, L_C277
        call L_D4AD

L_C277:
        ld hl, $080A
        ld (cursor), hl
        call D_LINE

X_C280:
        ld a, (DPAGE)
        add a, $30
        rst $30
        rst $28
        defm " - Page No       ( 0 to 9 )"
        defb $0D
        defm "C - Compose"
        defb $0D
        defm "P - Play,modify"
        defb $0D
        defm "E - Erase"
        defb $0D
        defm "T - Transfer"
        defb $0D
        defm "R - Run chain"
        defb $0D
        defm "A - Assemble chain"
        defb $0D
        defm "I - Info page      : H - Help"
        defb $0D
        defm "S - Save on tape   : X - "
        defb $00
        call L_D4C4

X_C332:
        rst $28
        defm "."
        defb $0D, $0D
L_C336  defm "Type command letter."
        defb $00
        ld hl, $0B4A
        call D_LINE
        ret


RESTART:
        rst $18
        defb $5B                ; MRET - back to boot menu

CLS:
        ld a, $0C
        rst $30
        ret


L_C358:
        ld a, $FC
        out ($01), a            ; MIDI command: Stop
        call L_C471

CONT1:
        ld sp, $1000
        di
        ld hl, $C0D4
        ld ($0C75), hl
        call L_C265             ; clear screen, print main Drum menu

X_C36c:
        ld hl, $2804
        res 5, (hl)
        ld hl, $2834
        res 1, (hl)
        ld hl, $2803
        set 0, (hl)
        res 5, (hl)
        res 6, (hl)
        set 2, (hl)
        bit 4, (hl)
        jr nz, L_C389
        ld a, $01
        jr L_C38B


L_C389:
        ld a, $03

L_C38B:
        ld ($2809), a
        ld a, $32
        ld ($280A), a
        ld a, ($2812)
        cp $0C
        jp nz, L_C416
        ld a, $02
        ld ($2809), a
        jp L_C416


X_C3A3:                         ; unreachable??
        in a, ($01)             ; UART data
        cp $0A
        jr nc, L_C3B6
        ld (DPAGE), a
        jp CONT1


X_C3AF:                         ; unreachable??
        xor a
        ld (DPAGE), a
        jp CONT1


L_C3B6:
        ld a, ($2834)
        bit 0, a
        jr z, L_C3C3
        call TIME
        jp nz, L_C416

L_C3C3:
        in a, ($02)             ; UART status
        rla
        jp nc, L_C416           ; no char
        in a, ($01)             ; get MIDI char
        cp $F8                  ; incoming timing clock?
        jp z, L_C416            ; yes, go to menu??
        jr L_C3EA


L_C3D2:
        ld bc, COLD

L_C3D5:
        in a, ($02)             ; UART status
        rla
        jr c, L_C3E8            ; got char
        call TIME
        dec bc
        ld a, b
        or c
        jr nz, L_C3D5
        call L_D437
        jp L_C416


L_C3E8:
        in a, ($01)             ; get char from UART

L_C3EA:
        ld e, a
        and $F0
        cp $90
        jp nz, L_C3D5
        ld a, e
        and $0F
        ld hl, $2835
        cp (hl)
        jp z, L_C745
        jp L_C416


L_C3FF:
        ld hl, $0A72
        ld (cursor), hl
        rst $18
        defb $41                ; getnum
        cp $11
        jr nc, L_C413
        cp $00
        jr c, L_C413
        dec a
        ld ($2835), a

L_C413:
        call L_D4AD

L_C416:
        rst $18                 ; scal
        defb $62                ; in - scan the keyboard
        jp nc, L_C3B6           ; no character
        and $7F                 ; clear MSB (no need..)
        cp $1B                  ; ESC
        jp z, X_C1A5            ; jump through ($2800) - usually to CONT1
        cp $0C                  ; CTRL-L
        jp z, RESTART           ; 
        cp $58                  ; X
        jp z, L_C478            ; Toggle Int/Midi
        cp $78                  ; x
        jp z, L_C3FF            ; Select channel
        cp $45                  ; E
        jp z, erase             ; Erase
        cp $43                  ; C
        jp z, compose           ; Compose
        cp $50                  ; P
        jp z, play              ; Play,modify
        cp $52                  ; R
        jp z, run               ; Run chain
        cp $41                  ; A
        jp z, assemble          ; Assemble chain
        cp $54                  ; T
        jp z, transfer          ; Transfer
        cp $48                  ; H
        jp z, help              ; Help
        cp $49                  ; I
        jp z, info              ; Info page
        cp $53                  ; S
        jp z, save              ; Save on tape
        sub $30                 ; Number?
        jp m, L_C416            ; 
        sub $0A                 ; 
        jp p, L_C416            ; 
        ld d, a                 ; 
        add a, $0A              ; 
        ld (DPAGE), a           ; Store number 0-9 as Page Number
        jp CONT1                ; Start again


L_C471:
        in a, ($02)             ; get UART status
        bit 6, a                ; TX done?
        jr z, L_C471            ; no.. loop waiting for TX done
        ret


L_C478:
        call L_D49D
        ld hl, $0A63
        ld (cursor), hl
        call L_D4C4
        call L_D4AD
        jp L_C416


L_C48A:
        push hl
        ld hl, (cursor)
        push hl
        ld hl, $0BCA
        ld (cursor), hl
        rst $28
        defm "Page "
        defb $00
        ld a, (DPAGE)
        add a, $30
        ld hl, $0BCF
        ld (hl), a
        pop hl
        ld (cursor), hl
        pop hl
        ret


compose:
        call L_D03A             ; ?find number for next unused rhythmn on this page
        ld hl, $2804
        set 7, (hl)
        ld hl, $2803
        bit 7, (hl)
        jp z, L_C4EB            ; Compose screen: prompt for rhythmn name etc.
        call CLS
        ld hl, M_FULL           ; else.. all 10 rythmns defined: Page full
        ld de, $09CB
        ld bc, $000A
        ldir
        call wait
        jp CONT1


wait:                           ; wait a while
        exx
        ld bc, $0014

L_C4D3:
        ld a, $FF
        rst $38
        djnz L_C4D3
        exx
        ret


;;; Used to get rhyhmn name during 'compose' and during 'transfer'.
;;; On entry, a value in B of N allows upto N+1 characters to be entered. The characters are then
;;; read directly from VDU RAM so that the name is right-padded with spaces.
;;; End with CR. Abort with ESCape (A holds most recent character on return, so ESCape can be detected)
;;; When called for 'compose' B is set to 25 allowing 26 letters to be entered.
;;; When called for 'transfer' B is set to 26, but due to the length of the prompt on the screen,
;;; text entry starts too far in from the left: when 25 characters have been entered, the display
;;; scrolls and the actual transfer name is read from the pre-scrolled position of video RAM resulting
;;; in a name of all-spaces.
getname:
        rst $18
        defb $7B                ; blink
        and $7F
        cp $0D
        ret z                   ; exit on CR
        cp $1B
        ret z                   ; exit on ESCape
        rst $30                 ; output char
        xor a
        cp b
        ret z                   ; exit on max length (B+1) reached
        dec b
        jr getname


L_C4EB:                         ; main compose screen/dialog
        call CLS
        call L_CD15
        ld hl, $08D9
        ld (cursor), hl
        ld b, $19               ; 25
        call getname            ; get rythmn name: upto 25+1 characters
        cp $1B
        jp z, CONT1             ; name aborted; go back to main command loop
        call L_CE1E
        ex de, hl
        ld hl, $08D9
        ld bc, $001A
        ldir

L_C50D:
        ld iy, $0998
        ld (iy), $3F
        ld (iy+$01), $20
        ld (iy+$19), $3F
        ld (iy+$1A), $20
        ld hl, $0998
        ld (cursor), hl
        rst $18
        defb $41                ; getnum
        call L_D3D0
        and a
        jr z, L_C50D
        ld hl, $09B1
        ld (cursor), hl
        rst $18
        defb $41                ; getnum
        call L_D401
        and a
        jr z, L_C50D
        call L_CF9D
        ld hl, ($2824)
        ld a, l
        or h
        jr z, L_C50D
        push hl
        pop bc
        call L_D409
        ld hl, ($2826)
        sbc hl, bc
        jr c, L_C50D
        jp m, L_C50D
        call L_CF7E
        call L_D2E6

X_C55C:
        jp L_C7A3


save:
        ld hl, $4400
        ld ($2816), hl
        call CLS
        ld hl, M_SAVE
        call D_MSG16
        ld hl, $084A
        ld (cursor), hl
        rst $28
        defm "ENSURE MIDI SWITCH IS IN TAPE POSITION !"
        defb $0D, $0D, $0D
        defm "Save page No's 0 to ?"
        defb $11, $00
        nop
        rst $18
        defb $7B                ; blink
        and $7F
        cp $30
        jp c, CONT1
        cp $3A
        jp nc, CONT1
        rst $30
        sbc a, $30
        ld b, a
        cp $00
        jr z, L_C5DA
        ld hl, ($2816)
        ld de, $0800

L_C5D4:
        add hl, de
        djnz L_C5D4
        ld ($2816), hl

L_C5DA:
        rst $28
        defb $0D, $0D
        defm " To Go press T"
        defb $11, $00
        rst $18
        defb $7B                ; blink
        cp $54
        jp nz, CONT1
        ld b, $02

L_C5F6:
        call wait
        djnz L_C5F6
        ld hl, $2800
        ld ($0C0C), hl
        ld de, ($2816)
        ld ($0C0E), de
        ld bc, M_BPM
        ld ($0C10), bc
        rst $18
        defb $47                ; g (generate)
        rst $28
        defm " "
        defb $0D, $0D, $0D
        defm "Finished - put switch back to MIDI position ."
        defb $11, $00
        rst $18
        defb $7B                ; blink
        jp CONT1


assemble:
        call CLS
        call L_CE3C

X_C651:
        ld hl, M_SEQ
        ld de, $0BD2
        ld bc, $0010
        ldir
        ld hl, M_OPTION
        ld de, $0BE2
        ld bc, $0014
        ldir
        jr L_C66F


L_C669:
        ld hl, $084A
        ld (cursor), hl

L_C66F:
        ld hl, $0B76
        ld de, (cursor)
        sbc hl, de
        jp c, L_C669
        ld hl, (cursor)
        ld de, $084A
        sbc hl, de
        jr c, L_C669
        rst $18
        defb $7B                ; blink
        and $7F
        ld hl, (cursor)
        cp $20
        jr z, L_C6F1
        cp $11
        jr z, L_C6CC
        cp $12
        jr z, L_C6D0
        cp $13
        jr z, L_C6CD
        cp $14
        jr z, L_C6CD
        cp $17
        jr z, L_C669
        cp $1B
        jr z, L_C71A
        cp $5E
        jr z, L_C6D9
        cp $21
        jr c, L_C6B4
        cp $2A
        jr c, L_C6DB

L_C6B4:
        cp $30
        jr c, L_C6BC
        cp $3A
        jr c, L_C6E5

L_C6BC:
        cp $41
        jr c, L_C66F
        cp $5B
        jr c, L_C6E5
        jr L_C66F


L_C6C6:
        rst $30
        ld a, $20
        rst $30
        jr L_C66F


L_C6CC:
        rst $30

L_C6CD:
        rst $30
        jr L_C66F


L_C6D0:
        push af
        ld a, (hl)
        cp $70
        jr z, L_C6EE
        pop af
        jr L_C6C6


L_C6D9:
        ld a, $20

L_C6DB:
        push af
        rst $28
        defm "pg"
        defb $00
        pop af
        add a, $10
        jr L_C6C6


L_C6E5:
        push af
        ld a, (hl)
        cp $70
        jr z, L_C6EE
        pop af
        jr L_C6C6


L_C6EE:
        pop af
        jr L_C6FA


L_C6F1:
        push af
        ld a, (hl)
        cp $70
        jr z, L_C702
        pop af
        jr L_C6C6


L_C6FA:
        inc hl
        inc hl
        ld (cursor), hl
        jp L_C66F


L_C702:
        pop af
        rst $28
        defm "    "
        defb $00
        jp L_C66F


L_C70C:
        exx
        ld hl, $C006
        ld de, $0BEF
        ld bc, $0006
        ldir
        exx
        ret


L_C71A:
        ld hl, (cursor)
        call L_CF6A
        ld hl, $2880
        call L_D422             ; get DPAGE-dependent address in HL
        ex de, hl
        ld hl, $084A
        ld (cursor), hl
        ld bc, $0138

L_C730:
        ld a, (hl)
        cp $00
        call z, L_C742
        ld (de), a
        inc hl
        inc hl
        inc de
        dec bc
        ld a, b
        or c
        jr nz, L_C730
        jp CONT1


L_C742:
        inc hl
        jr L_C730


L_C745:
        ld bc, $07D0

L_C748:
        in a, ($02)
        rla
        jr c, L_C755
        dec bc
        ld a, b
        or c
        jr nz, L_C748
        jp L_C3D5


L_C755:
        in a, ($01)
        cp $24
        jr c, L_C791
        cp $33
        jr nc, L_C791
        sbc a, $23
        cp $06
        jr nc, L_C76E
        ld b, a
        ld a, $01

L_C768:
        sla a
        djnz L_C768
        jr L_C794


L_C76E:
        sbc a, $06
        ld b, a
        ld a, $01

L_C773:
        sla a                   ; 
        djnz L_C773             ; 
        push af                 ; 
        ld a, $CF               ; 
        out ($07), a            ; port B control mode
        pop af                  ; 
        cpl                     ; 
        out ($07), a            ; define which bits are outputs
        ld a, $FF               ; 
        out ($05), a            ; data B: set all outputs high

L_C784:
        ld b, $96

L_C786:
        in a, ($02)
        rla
        jp c, L_C3E8
        djnz L_C786
        call L_D437

L_C791:
        jp L_C3D2


L_C794:
        push af                 ; 
        ld a, $CF               ; 
        out ($06), a            ; port A control mode
        pop af                  ; 
        cpl                     ; 
        out ($06), a            ; define which bits are output
        ld a, $FE               ; 
        out ($04), a            ; data A: set [7:1] high, [0] low
        jr L_C784


L_C7A3:
        call L_CF9D
        ld hl, ($2824)
        ld a, h
        or l
        jp z, CONT1
        call L_CD15

X_C7B1:
        ld hl, $094A
        call L_CC1A

L_C7B7:
        ld hl, $0BEA
        ld (cursor), hl
        call L_D4C4
        ld hl, $2803
        res 3, (hl)
        ld a, $FA
        out ($01), a            ; MIDI command: Start
        call L_C471

L_C7CC:
        ld hl, PTIME
        in a, ($04)
        and $01
        ld (hl), a
        ld hl, $280E
        set 1, (hl)
        jp L_C8C7


L_C7DC:
        xor a
        ld ($2814), a
        ld ($2816), a
        ld ($2807), a
        ld ($2808), a

L_C7E9:
        call L_C48A

X_C7EC:
        xor a
        ld iy, $2804
        set 3, (iy)
        bit 5, (iy)
        jr z, L_C801
        ld a, ($2809)
        srl a
        inc a

L_C801:
        ld ($280C), a
        ld bc, ($2824)
        call L_CF7E
        ld iy, $0B9F
        ld (iy), $FF
        ld (iy+$01), $FF
        ld iy, $2804
        set 2, (iy)

L_C81F:
        call L_C893
        ld a, (ix)
        ld d, a
        ld a, (ix+$01)
        ld e, a
        call L_C830
        jp L_C855


L_C830:
        ld a, $4F               ; 
        out ($07), a            ; port B input mode
        out ($06), a            ; port A input mode
        ld a, $CF               ; 
        out ($06), a            ; port A control mode
        ld a, d                 ; 
        cpl                     ; 
        out ($06), a            ; define which bits are output
        ld a, $CF               ; 
        out ($07), a            ; port B control mode
        ld a, e                 ; 
        cpl                     ; 
        out ($07), a            ; define which bits are output
        ld a, $FF               ; 
        out ($04), a            ; data A: set all outputs high
        out ($05), a            ; data B: set all outputs high
        call L_CE33             ; 
        xor a                   ; 
        out ($04), a            ; data A: set all outputs low
        out ($05), a            ; data B: set all outputs low
        ret


L_C855:
        ld iy, COLD
        ld a, ($280C)
        cp $00
        jr z, L_C86C
        dec a
        ld ($280C), a
        ld hl, $2803
        set 6, (hl)
        jp L_C8C4


L_C86C:
        ld a, ($2809)           ; 
        ld ($280C), a           ; 
        ld hl, $2803            ; 
        res 6, (hl)             ; 
        bit 2, (hl)             ; 
        jp nz, L_C8C4           ; 
        ld a, $0F               ; 
        out ($07), a            ; port B output mode
        ld a, $4F               ; 
        out ($06), a            ; port A input mode
        ld a, $CF               ; 
        out ($06), a            ; port A control mode
        ld a, $01               ; 
        cpl                     ; 
        out ($06), a            ; port A[0] output, all others inputs
        call L_CE33
        jp L_C8C4


L_C893:
        inc iy
        push iy
        pop af
        bit 6, a
        jr z, L_C8A9
        call L_CFD6

X_C89F:
        cp $20
        jp z, L_CB3C
        cp $1B
        jp z, L_C358

L_C8A9:
        in a, ($04)
        ld ($2805), a
        ld d, a
        ld a, ($2814)
        or d
        ld ($2814), a
        in a, ($05)
        ld ($2806), a
        ld d, a
        ld a, ($2816)
        or d
        ld ($2816), a
        ret


L_C8C4:
        call L_D437

L_C8C7:
        xor a
        ld hl, $2832
        ld (hl), a
        ld iy, COLD
        ld hl, $2804
        set 3, (hl)
        jr L_C925


L_C8D7:
        push bc
        ld de, $0B9E
        ld bc, $0005
        ldir
        pop bc
        ret


L_C8E2:
        ld hl, $CB5F
        call L_C8D7

L_C8E8:
        call L_CFD6
        jr nc, L_C901
        cp $1B
        jp z, L_C358
        cp $20
        jr nz, L_C901
        ld hl, $2803
        bit 1, (hl)
        jp nz, L_C914
        jp L_CB3C


L_C901:
        in a, ($02)
        rla
        jr nc, L_C8E8
        in a, ($01)
        cp $FB
        jp z, L_C914
        cp $FA
        jr nz, L_C8E8
        jp z, L_C946

L_C914:
        ld hl, $CB79
        call L_C8D7
        ld a, $FB
        out ($01), a            ; MIDI command: Continue
        call L_C471
        jr L_C925


L_C923:
        ex (sp), hl
        ex (sp), hl

L_C925:
        call L_C893
        ld a, ($2834)
        bit 0, a
        jp nz, L_C95E
        in a, ($02)
        rla
        jp nc, L_C923
        in a, ($01)
        cp $F8
        jr z, L_C96E
        cp $FC
        jp z, L_C8E2
        cp $FA
        jp nz, L_C925

L_C946:
        ld hl, $2803
        bit 1, (hl)
        jr z, L_C955
        ld hl, $2834
        set 1, (hl)
        jp run


L_C955:
        ld hl, $CB79
        call L_C8D7
        jp L_C7CC


L_C95E:
        in a, ($04)
        and $01
        nop
        nop
        nop
        nop
        ld hl, PTIME
        cp (hl)
        jp z, L_C925
        ld (hl), a

L_C96E:
        ld hl, $280E
        bit 1, (hl)
        jp z, L_C97B
        res 1, (hl)
        jp L_C7DC


L_C97B:
        ld a, $F8
        out ($01), a            ; MIDI command: Timing Clock
        ld hl, $2832
        inc (hl)
        ld a, ($2833)
        cp (hl)
        jr nz, L_C98E
        ld hl, $280E
        set 0, (hl)

L_C98E:
        call L_CFD6
        jr nc, L_C9A2
        ld hl, $2804
        set 3, (hl)
        cp $20
        jp z, L_CB3C
        cp $1B
        jp z, L_C358

L_C9A2:
        push iy
        pop de
        ld a, d
        or e
        jr z, L_CA25
        ld a, ($2812)
        cp $10
        jr z, L_C9B8
        ld hl, $2804
        bit 3, (hl)
        jp nz, L_CA21

L_C9B8:
        ld a, d
        cp $00
        jr nz, L_C9DB
        ld a, e
        cp $9E
        jr nc, L_C9D4
        cp $91
        jr nc, L_C9CD
        ld hl, $55F0
        ld a, $46
        jr L_C9E0


L_C9CD:
        ld hl, $5DC0
        ld a, $37
        jr L_C9E0


L_C9D4:
        ld hl, $639C
        ld a, $20
        jr L_C9E0


L_C9DB:
        ld hl, $7D00
        ld a, $00

L_C9E0:
        sbc hl, de
        jr c, L_C9E7
        inc a
        jr L_C9E0


L_C9E7:
        adc a, $02
        cp $0A
        jr nc, L_C9EE
        xor a

L_C9EE:
        ld l, a
        ld a, ($280D)
        add a, $02
        cp l
        jr c, L_C9FC
        sbc a, $04
        cp l
        jr c, L_CA00

L_C9FC:
        ld a, l
        ld ($280D), a

L_CA00:
        ld hl, $2804
        set 3, (hl)

L_CA05:
        ld hl, $0BF5
        ld (cursor), hl
        ld a, ($280D)
        call L_D461
        ld iy, COLD
        ld hl, $280E
        bit 0, (hl)
        jp z, L_C925
        res 0, (hl)
        jr L_CA25


L_CA21:
        res 3, (hl)
        jr L_CA05


L_CA25:
        ld hl, $2803
        bit 1, (hl)
        jp nz, L_CA98
        bit 6, (hl)
        jr nz, L_CA98
        bit 2, (hl)
        jr z, L_CA4D
        ld a, ($2807)
        cpl
        ld d, a
        ld a, ($2814)
        and d
        ld ($2814), a
        ld a, ($2808)
        cpl
        ld d, a
        ld a, ($2816)
        and d
        ld ($2816), a

L_CA4D:
        bit 0, (hl)
        jr z, L_CA5C
        ld a, ($2814)
        or (ix)
        ld (ix), a
        jr L_CA66


L_CA5C:
        ld a, ($2814)
        cpl
        and (ix)
        ld (ix), a

L_CA66:
        bit 0, (hl)
        jr z, L_CA75
        ld a, ($2816)
        or (ix+$01)
        ld (ix+$01), a
        jr L_CA7F


L_CA75:
        ld a, ($2816)
        cpl
        and (ix+$01)
        ld (ix+$01), a

L_CA7F:
        ld a, ($2805)
        ld ($2807), a
        ld a, ($2806)
        ld ($2808), a
        xor a
        ld ($2814), a
        ld ($2816), a
        ld ($2805), a
        ld ($2806), a

L_CA98:
        ld hl, $2803
        bit 1, (hl)
        jr nz, L_CAEB
        bit 0, (hl)
        jr z, L_CAB5
        ld iy, $0A18
        ld (iy), $06
        ld iy, $0A98
        ld (iy), $20
        jr L_CAC5


L_CAB5:
        ld iy, $0A98
        ld (iy), $06
        ld iy, $0A18
        ld (iy), $20

L_CAC5:
        bit 2, (hl)
        jr z, L_CADB
        ld iy, $0A31
        ld (iy), $06
        ld iy, $0AB1
        ld (iy), $20
        jr L_CAEB


L_CADB:
        ld iy, $0AB1
        ld (iy), $06
        ld iy, $0A31
        ld (iy), $20

L_CAEB:
        ld iy, $2804
        bit 2, (iy)
        jr z, L_CAFB
        res 2, (iy)
        jr L_CB07


L_CAFB:
        ld iy, $0B9F
        ld (iy), $20
        ld (iy+$01), $20

L_CB07:
        inc ix
        inc ix
        dec bc
        dec bc
        ld a, b
        or c
        jr z, L_CB2A
        ld hl, $2803
        bit 1, (hl)
        jp z, L_C81F
        ld hl, ($281A)
        ld a, (hl)
        ld d, a
        ld a, ($281E)
        ld (hl), a
        ld hl, $281E
        ld a, d
        ld (hl), a
        jp L_C81F


L_CB2A:
        ld hl, $2803
        bit 1, (hl)
        jr nz, L_CB34
        jp L_C7E9


L_CB34:
        ld hl, ($281A)
        ld (hl), $7F
        jp L_CEDF


L_CB3C:
        xor a
        ld ($2814), a
        ld ($2816), a
        call L_D437
        ld a, $FC
        out ($01), a            ; MIDI command: Stop
        ld hl, $2803
        bit 1, (hl)
        jp nz, L_CC4B
        call CLS
        ld hl, $0819
        ld (cursor), hl
        rst $28
        defm ">> PAUSE <<"
        defb $0D, $0D
        defm " D - Clear drums         C - Clear cymbals"
        defb $0D, $0D, $0D
        defm " I - Insert metro         K - Kill metro"
        defb $0D, $0D, $0D
        defm " M - Multiply bars  (x )  X - "
        defb $00
        call L_D4C4
        rst $28
        defm "."
        defb $0D, $0D, $0D

M_OPTION:
        defm " For menu shift/esc  :  Space bar to Continue."
        defb $00
        jp L_CC7F


L_CC1A:
        push hl
        ld (cursor), hl
        rst $28
        defm "O - Beats   (x"
        defb $00
        ld a, ($280A)
        rst $30
        ld a, $29
        rst $30
        ld iy, $2804
        bit 5, (iy)
        jr z, L_CC49
        ld (cursor), hl
        rst $28
        defm " Offb"
        defb $00

L_CC49:
        pop hl
        ret


L_CC4B:
        ld a, $2A
        ld hl, ($281A)
        ld (hl), a
        push bc
        push ix

L_CC54:
        call TIME
        rst $18
        defb $62                ; in
        jr nc, L_CC54
        pop ix
        pop bc
        and $7F
        cp $1B
        jp z, L_C358
        cp $20
        jr nz, L_CC54
        ld a, $FB
        out ($01), a            ; MIDI command: Continue
        jp L_C925


TIME:
        in a, ($04)             ; check port A
        and $01                 ; bit[0]
        ld hl, PTIME            ; previous value
        cp (hl)                 ; 
        ret z                   ; has not changed
        ld (hl), a              ; update
        ld a, $F8               ; 
        out ($01), a            ; MIDI command: Timing Clock
        ret


L_CC7F:
        call TIME               ; poll for timing signal transition
        rst $18                 ; scal
        defb $62                ; in - scan the keyboard
        jr nc, L_CC7F           ; no character
        and $7F                 ; clear MSB (no need..)
        cp $1B                  ; ESC
        jp z, L_C358            ; Back to menu
        cp $58                  ; X
        jr z, L_CCB1            ; Int/Midi
        cp $4D                  ; M
        jp z, L_D33D            ; Multiply bars
        cp $44                  ; D
        jp z, L_D0CA            ; Clear drums
        cp $43                  ; C
        jp z, L_D102            ; Clear cymbals
        cp $4B                  ; K
        jp z, L_CCC0            ; Kill metro
        cp $49                  ; I
        jp z, L_D2E6            ; Insert metro
        cp $20                  ; SPACE
        jp z, L_C7A3            ; Continue
        jr L_CC7F               ; No match; go round again


L_CCB1:
        call L_D49D
        ld hl, $0A28
        ld (cursor), hl
        call L_D4C4
        jp L_CC7F


L_CCC0:
        ld iy, $2804
        res 0, (iy)
        jp L_D2EE


L_CCCB:
        ld e, a
        ld hl, $2804
        res 5, (hl)
        ld hl, M_INFO2
        ld a, ($2812)
        cp $0C
        jr nz, L_CCDE
        ld hl, $C0C2

L_CCDE:
        ld a, e
        cp (hl)
        jr z, L_CCED
        ld a, $3A
        cp (hl)
        jr z, L_CCEA
        inc hl
        jr L_CCDE


L_CCEA:
        or a
        ld a, e
        ret


L_CCED:
        inc hl
        ld a, (hl)
        ld hl, $2803
        bit 4, (hl)
        jr nz, L_CCF8
        rr a

L_CCF8:
        ld ($2809), a
        ld a, e
        bit 4, (hl)
        jr nz, L_CD04
        cp $38
        jr z, L_CCEA

L_CD04:
        ld ($280A), a
        cp $36
        jr nz, L_CD0D
        set 2, (hl)

L_CD0D:
        cp $38
        jr nz, L_CD13
        set 2, (hl)

L_CD13:
        scf
        ret


L_CD15:
        ld hl, $2850
        call L_D422             ; get DPAGE-dependent address in HL
        ld a, (hl)
        ld ($280B), a
        call CLS
        call L_C48A
        ld hl, M_RUN
        ld de, $0BD8            ; top line
        ld bc, $000D            ; length of message
        ldir
        ld iy, $2804
        res 1, (iy)
        call L_C70C
        ld hl, $084A
        ld (cursor), hl
        rst $28
        defm "Rhythm No   :  "
        defb $00
        ld a, (RNUM)
        rst $18
        defb $4A                ; X_01E4
        rst $28
        defb $0D, $0D
        defm "Rhythm name :  "
        defb $00
        ld hl, $2804
        bit 7, (hl)
        jr nz, L_CD7D
        call L_CE1E
        ld de, (cursor)
        ld bc, $001A
        ldir

L_CD7D:
        res 7, (hl)
        rst $28
        defb $0D, $0D, $0D
        defm "Beats to Bar: "
        defb $00
        call L_D3D6
        rst $18
        defb $4A                ; X_01E4
        rst $28
        defm "       No of Bars    : "
        defb $00
        call L_D405
        rst $18
        defb $4A                ; X_01E4
        rst $28
        defb $0D, $0D
        defm "Add    =  A :          Single    = S :"
        defb $0D, $0D
        defm "Erase  =  E :          Repeating = R :"
        defb $00
        ld hl, M_SPACE
        ld de, $0B0A
        ld bc, $0016
        ldir
        ret


X_CE13:
        ld hl, $A109
        ld de, $1093
        ld bc, $0F00
        ldir

L_CE1E:
        ld a, (RNUM)
        ld b, a
        ld hl, $29F0
        push af
        call L_D422             ; get DPAGE-dependent address in HL
        pop af
        or a
        ret z
        ld de, $001A

L_CE2F:
        add hl, de
        djnz L_CE2F
        ret


L_CE33:
        push bc
        ld b, $46

L_CE36:
        ex (sp), hl
        ex (sp), hl
        djnz L_CE36
        pop bc
        ret


L_CE3C:
        call L_C48A
        ld iy, $084A
        ld hl, $2880
        call L_D422             ; get DPAGE-dependent address in HL
        ld bc, $0138

L_CE4C:
        ld a, (iy)
        cp $00
        jr nz, L_CE57
        inc iy
        jr L_CE4C


L_CE57:
        ld a, (hl)
        cp $70
        jr z, L_CE7B
        cp $00
        jr nz, L_CE62
        ld a, $20

L_CE62:
        ld (iy), a
        inc iy
        ld a, $20
        ld (iy), a
        inc iy
        inc hl
        dec bc
        ld a, b
        or c
        jr nz, L_CE4C
        call L_CF5F
        ld (cursor), hl
        ret


L_CE7B:
        ld a, $70
        ld (iy), a
        inc iy
        ld a, $67
        ld (iy), a
        inc iy
        inc hl
        dec bc
        jr L_CE4C


run:
        ld hl, $2804
        set 4, (hl)
        ld a, (DPAGE)
        ld ($2830), a

L_CE98:
        call L_CF5F
        dec hl
        ld ($281A), hl
        call CLS
        call L_CE3C
        ld hl, M_SPACE
        call D_MSG16
        call L_C70C
        ld hl, $2803
        set 1, (hl)
        set 3, (hl)
        set 2, (hl)
        ld hl, $2834
        bit 0, (hl)
        jr nz, L_CEDF
        bit 1, (hl)
        jr nz, L_CEDF

L_CEC2:
        rst $18
        defb $62                ; in
        jr nc, L_CED0
        cp $20
        jp z, L_CEDF
        cp $1B
        jp z, L_C358

L_CED0:
        in a, ($02)
        rla
        jr nc, L_CEC2
        in a, ($01)
        cp $FA
        jr z, L_CEDF
        cp $FB
        jr nz, L_CEC2

L_CEDF:
        ld a, $DB
        ld ($281E), a
        ld hl, ($281A)

L_CEE7:
        inc hl
        push hl
        or a
        ld de, $0B79
        sbc hl, de
        pop hl
        jp nc, L_CF43
        ld a, (hl)
        cp $20                  ;' '
        jr z, L_CEE7
        cp $70                  ;p
        jr z, L_CF27
        cp $30                  ;0
        jr c, L_CEE7
        cp $3A                  ;beyond 9
        jp nc, L_CEE7
        sbc a, $2F              ;ascii '0'..'9' to 0..9
        ld (RNUM), a            ;and store as rhythm number
        ld ($281A), hl
        call L_CF9D
        ld hl, ($2824)
        ld a, h
        or l
        jr z, L_CF76
        ld hl, $2804
        res 4, (hl)
        ld hl, $2803
        bit 3, (hl)
        jp nz, L_C7B7
        jp L_C7E9


L_CF27:
        inc hl
        inc hl
        ld a, (hl)
        cp $30
        jr c, L_CF3D
        cp $3A
        jp nc, L_CF3D
        sbc a, $2F
        ld (DPAGE), a
        call L_C48A
        jr L_CEE7


L_CF3D:
        ld a, $2A
        ld (hl), a
        jp L_CEE7


L_CF43:
        ld hl, $2804
        bit 4, (hl)
        jp z, L_CF56
        res 4, (hl)
        ld hl, $084A
        call L_CF6A
        jp L_CE98


L_CF56:
        ld a, ($2830)
        ld (DPAGE), a
        jp L_C358


L_CF5F:
        ld hl, $281C
        call L_D422             ; get DPAGE-dependent address in HL
        ld e, (hl)
        inc hl
        ld d, (hl)
        ex de, hl
        ret


L_CF6A:
        push hl
        ld hl, $281C
        call L_D422             ; get DPAGE-dependent address in HL
        pop de
        ld (hl), e
        inc hl
        ld (hl), d
        ret


L_CF76:
        ld hl, ($281A)
        ld (hl), $3F
        jp L_CEDF


L_CF7E:
        push de
        push bc
        ld hl, $2B00
        call L_D422             ; get DPAGE-dependent address in HL
        ld a, (RNUM)
        ld b, a
        call L_D409
        ld de, ($2826)
        or a
        jr z, L_CF97

L_CF94:
        add hl, de
        djnz L_CF94

L_CF97:
        push hl
        pop ix
        pop bc
        pop de
        ret


L_CF9D:
        push bc
        push de
        call L_D3D6
        ld e, a
        ld d, $00
        call L_D405
        ld b, a
        cp $00
        ld hl, COLD
        jr z, L_CFC8
        xor a

L_CFB1:
        adc hl, de
        djnz L_CFB1
        ld a, l
        ld e, a
        ld a, h
        cp $00
        jr nz, L_CFD1
        ld a, ($2812)
        ld b, a
        ld d, $00
        ld hl, COLD

L_CFC5:
        add hl, de
        djnz L_CFC5

L_CFC8:
        ld ($2824), hl
        ld hl, $2824
        pop de
        pop bc
        ret


L_CFD1:
        ld hl, COLD
        jr L_CFC8


L_CFD6:
        push ix
        push bc
        rst $18
        defb $62                ; in
        jr nc, L_D037
        and $7F
        ld hl, $2803
        bit 1, (hl)
        jr z, L_CFE9
        scf
        jr L_D033


L_CFE9:
        cp $41                  ;A
        jr nz, L_CFF1
        set 0, (hl)
        jr L_D033


L_CFF1:
        cp $53                  ;S
        jr nz, L_CFF9
        set 2, (hl)
        jr L_D033


L_CFF9:
        cp $52                  ;R
        jr nz, L_D001
        res 2, (hl)
        jr L_D033


L_D001:
        cp $45                  ;E
        jr nz, L_D009
        res 0, (hl)
        jr L_D033


L_D009:
        cp $4F                  ;O
        jr nz, L_D014
        ld hl, $2804
        set 5, (hl)
        jr L_D02D


L_D014:
        cp $48                  ;H
        jr z, L_D028
        cp $54                  ;T
        jr z, L_D028
        cp $46                  ;F
        jr z, L_D028
        cp $30                  ;0
        jr c, L_D033
        cp $3A                  ;beyond 9
        jr nc, L_D033

L_D028:
        call L_CCCB
        jr nc, L_D033

L_D02D:
        ld hl, $094A
        call L_CC1A

L_D033:
        pop bc
        pop ix
        ret


L_D037:
        xor a
        jr L_D033


L_D03A:
        ld hl, $2803
        res 7, (hl)
        xor b

L_D040:
        ld a, b
        cp $0A
        jr z, L_D054
        ld (RNUM), a
        call L_CF9D
        ld hl, ($2824)
        ld a, h
        or l
        ret z
        inc b
        jr L_D040


L_D054:
        ld hl, $2803
        set 7, (hl)
        ret


play:
        call CLS
        ld hl, $2803
        res 1, (hl)
        ld hl, M_PLAY
        call D_MSG16
        call L_D08B

X_D06B:
        rst $28
        defb $0D
        defm "   Play No ?"     ; get rhythmn number
        defb $11, $00
        rst $18
        defb $53                ; L_00FC - get digit
        cp $1B
        jp z, CONT1             ; ESCape; restart command loop
        rst $30                 ; display the digit
        sub $30                 ; convert to 0..9
        ld (RNUM), a            ; store it
        jp L_C7A3

;;; called by play/transfer/erase. Displays list of names for current page of Rhythms??
L_D08B:
        call L_C48A
        ld hl, $088D
        ld (cursor), hl
        ld b, $0A
        ld d, $30

L_D098:
        ld a, d
        rst $30
        rst $28
        defb $0D
        defm "   "
        defb $00
        inc d
        djnz L_D098
        ld b, $0A
        push bc
        ld hl, $29F0
        call L_D422             ; get DPAGE-dependent address in HL
        ld de, $0890
        ld bc, $001A
        ldir

L_D0B4:
        push hl
        ex de, hl
        ld de, $0026
        add hl, de
        ex de, hl
        pop hl
        ld bc, $001A
        ldir
        pop bc
        dec b
        ld a, b
        dec a
        push bc
        jr nz, L_D0B4
        pop bc
        ret


L_D0CA:
        ld a, $01
        ld iy, $2804
        set 6, (iy)
        push af

L_D0D5:
        call L_CF7E
        push hl
        call L_CF9D
        ld de, ($2824)
        pop hl
        pop af
        dec a
        jr z, L_D0E6
        inc hl

L_D0E6:
        ld iy, $2804
        bit 6, (iy)
        jr z, L_D0F6
        ld a, (hl)
        and $02
        ld (hl), a
        jr L_D0F8


L_D0F6:
        ld (hl), $00

L_D0F8:
        inc hl
        inc hl
        dec de
        ld a, d
        or e
        jr nz, L_D0E6
        jp L_C7A3


L_D102:
        ld a, $00
        ld iy, $2804
        res 6, (iy)
        push af
        jp L_D0D5


transfer:
        call CLS
        ld hl, M_XFER
        call D_MSG16
        call L_D08B
        rst $28
        defb $0D
        defm "   Transfer No ?"
        defb $11, $00
        nop
        rst $18
        defb $53                ; L_00FC  - get digit
        cp $1B
        jp z, CONT1             ; ESCape; restart command loop
        rst $30                 ; display the digit
        sub $30                 ; comvert to 0..9
        ld ($2814), a
        rst $28
        defb $0D
        defm "   To number ?"
        defb $11, $00
        nop
        rst $18
        defb $53                ; L_00FC - get digit
        cp $1B
        jp z, CONT1             ; ESCape; restart command loop
        rst $30
        sub $30
        ld ($2816), a
        ld (RNUM), a
        ld b, $1A               ; 26
        rst $28
        defb $0D
        defm "   Title for transfer ?"
        defb $11, $00
        call getname            ; upto 26+1 characters theoretically..

X_D181:
        cp $1B                  ; ESCape?
        jp z, CONT1             ; abort to main command loop
        call L_CE1E
        ex de, hl
        ld hl, $0BA0
        ld bc, $001A
        ldir
        ld a, ($2816)
        ld (RNUM), a
        call L_CF9D
        ex de, hl
        ld a, ($2814)
        ld (RNUM), a
        call L_CF9D
        ld bc, $0002
        ldir
        ld a, ($2814)
        ld (RNUM), a
        call L_D405
        push af
        ld a, ($2816)
        ld (RNUM), a
        pop af
        call L_D401
        ld a, ($2814)
        ld (RNUM), a
        call L_D3D6
        push af
        ld a, ($2816)
        ld (RNUM), a
        pop af
        call L_D3D0
        ld a, ($2816)
        ld (RNUM), a
        call L_CF7E
        push ix
        pop de
        ld a, ($2814)
        ld (RNUM), a
        call L_CF7E
        push ix
        pop hl
        call L_D409
        ld bc, ($2826)
        ldir
        jp CONT1

;;; Info screen is 1 screen of free-form text stored in RAM at $3F00. It is saved to/restored from tape.
;;; It is cleared/initialised using N/S/H Start from the main menu. The clear-screen key code (CTRL-L) is
;;; explicitly ignored, so ou cannot manually clear the screen later.
info:
        ld hl, $3F00            ;copy info screen from $3F00
        ld de, $0800
        ld bc, $0380
        ldir
        ld hl, $0B8A
        ld b, $0D
        ld a, $98
        rst $18
        defb $4F                ;draw top-left line
        ex de, hl
        ld hl, M_OPTION
        ld bc, $0014
        ldir
        ex de, hl
        ld b, $2D
        ld a, $98
        rst $18
        defb $4F                ;draw top-right line
        ex de, hl
        ld hl, $C0A1
        ld bc, $0011
        ldir
        ex de, hl
        ld b, $11
        ld a, $98
        rst $18
        defb $4F                ;draw bottom line
        ld hl, ($2818)          ;save info screen cursor position
        ld (cursor), hl

info1:
        ld hl, $0B7A
        ld de, (cursor)
        sbc hl, de
        call c, L_D3C7
        rst $18
        defb $7B                ;blink - wait for character
        and $7F                 ;clear MSB
        cp $0C                  ;CTRL-L
        jr z, info1             ;(clear screen) ignore
        cp $0D                  ;CTRL-M
        jr z, info1             ;(enter) ignore
        cp $1B                  ;ESC
        jr z, info2             ;leave info screen
        rst $30                 ;echo character
        jr info1                ;loop


info2:
        ld de, (cursor)
        ld ($2818), de          ;restore info screen cursor position
        ld de, $3F00            ;save info screen to $3F00
        ld hl, $0800
        ld bc, $0380
        ldir
        jp CONT1                ;leave info screen; back to main menu


erase:
        call CLS
        ld hl, M_ERAS
        call D_MSG16
        call L_D08B
        rst $28
        defb $0D
        defm "   Erase No ?"
        defb $11, $00
        rst $18
        defb $53                ; L_00FC - get digit
        cp $1B
        jp z, CONT1
        ld ($2814), a
        rst $30
        rst $28
        defb $0D
        defm "   Confirm, Y"
        defb $11, $00
        rst $18
        defb $7B                ; blink
        and $7F
        cp $59
        jp nz, CONT1
        ld a, ($2814)
        sub $30
        ld (RNUM), a
        call L_CE1E
        ld b, $1A

L_D2B4:
        ld (hl), $2E
        inc hl
        djnz L_D2B4
        call L_CF7E
        call L_D409
        ld bc, ($2826)

L_D2C3:
        ld (hl), $00
        inc hl
        dec bc
        ld a, b
        or c
        jr nz, L_D2C3
        call L_CF9D
        ld (hl), $00
        inc hl
        ld (hl), $00
        xor a
        call L_D3D0
        call L_D401
        jp CONT1


L_D2DD:
        ld hl, $2803
        bit 1, (hl)
        jp nz, CONT1
        ret


L_D2E6:
        ld iy, $2804
        set 0, (iy)

L_D2EE:
        call L_D2DD
        call L_D405
        ld e, a
        call L_D3D6
        ld d, a
        call L_CF7E

L_D2FC:
        bit 0, (iy)
        inc hl
        jr nz, L_D309
        ld a, $40
        cpl
        and (hl)
        jr L_D30C


L_D309:
        ld a, (hl)
        or $40

L_D30C:
        ld (hl), a
        dec hl

L_D30E:
        ld a, ($2812)
        inc a
        ld b, a
        ld iy, $2804

L_D317:
        inc hl
        djnz L_D317
        bit 0, (iy)
        jr nz, L_D326
        ld a, $80
        cpl
        and (hl)
        jr L_D329


L_D326:
        ld a, (hl)
        or $80

L_D329:
        ld (hl), a
        dec hl
        ld a, d
        cp $01
        jr z, L_D333
        dec d
        jr L_D30E


L_D333:
        dec e
        jp z, L_C7A3
        call L_D3D6
        ld d, a
        jr L_D2FC


L_D33D:
        call L_D2DD
        ld hl, $0A20
        ld (hl), $3F
        ld (cursor), hl
        rst $18
        defb $53                ; L_00FC - get digit
        cp $08
        jr z, L_D3BB
        cp $31
        jr z, L_D3BB
        cp $30
        jr z, L_D3BB
        rst $30
        sub $30
        ld ($2814), a
        ld ($2816), a
        call L_CF9D
        ld de, ($2824)
        ld hl, COLD
        ld a, ($2814)
        ld b, a

L_D36D:
        add hl, de
        djnz L_D36D
        push hl
        pop bc
        push hl
        or a
        call L_D409
        ld hl, ($2826)
        sbc hl, bc
        jp c, L_D3BA
        call L_CF7E

L_D382:
        ld de, ($2824)
        push hl
        add hl, de
        ex de, hl
        pop hl
        ld bc, ($2824)
        ldir
        ld a, ($2814)
        cp $02
        jp z, L_D39E
        dec a
        ld ($2814), a
        jr L_D382


L_D39E:
        call L_CF9D
        pop de
        ld (hl), d
        inc hl
        ld (hl), e
        call L_D405
        ld c, a
        ld a, ($2816)
        ld b, a
        xor a

L_D3AE:
        adc a, c
        djnz L_D3AE
        call L_D401
        call wait
        jp L_C7A3


L_D3BA:
        pop de

L_D3BB:
        ld iy, $0A20
        ld (iy), $2E
        pop hl
        jp L_CC7F


L_D3C7:
        push hl
        ld hl, $080A
        ld (cursor), hl
        pop hl
        ret


L_D3D0:
        ld c, $00

L_D3D2:
        ld b, $01
        jr L_D3DA


L_D3D6:
        ld c, $00

L_D3D8:
        ld b, $00

L_D3DA:
        push hl
        push de
        push af
        dec c
        jr z, L_D3E8
        ld hl, $283C
        call L_D422             ; get DPAGE-dependent address in HL
        jr L_D3EE


L_D3E8:
        ld hl, $2846
        call L_D422             ; get DPAGE-dependent address in HL

L_D3EE:
        ld de, COLD
        ld a, (RNUM)
        ld e, a
        add hl, de
        pop af
        dec b
        jr z, L_D3FE
        ld a, (hl)

L_D3FB:
        pop de
        pop hl
        ret


L_D3FE:
        ld (hl), a
        jr L_D3FB


L_D401:
        ld c, $01
        jr L_D3D2


L_D405:
        ld c, $01
        jr L_D3D8


L_D409:
        push af
        push hl
        ld a, (DPAGE)
        or a
        jr z, L_D41A
        ld hl, $0080
        ld ($2826), hl

L_D417:
        pop hl
        pop af
        ret


L_D41A:
        ld hl, $0200
        ld ($2826), hl
        jr L_D417

;;; come here with some value in HL; advance it depending upon the display page
;;; .. but different space assigned for page 0 vs other pages
;;; HL is $281C $283C $2846 $2850 $2880 $29F0 $2B00
;;; ..presumably different regions within each page
;;; ..which suggests that page 0 actually starts at $281c
;;; page 0 data starts at $29f0 (or maybe earlier??)
;;; page 0 itself occupies $800 bytes, but it is followed by $1400 of other stuff: ~$400 of
;;; data for the Info page.. but what's the remaining $1000 for?
;;; page 1-9 each occupy $800 bytes
L_D422:
        ld a, (DPAGE)
        or a
        ret z                   ; page=0, leave HL as-is
        ld de, $1C00            ; step over page 0 data and the Info page data that follows it
        add hl, de
        dec a
        ret z                   ; page=1, done
        push bc
        ld b, a
        ld de, $0800            ; all the other pages occupy 2Kbytes

L_D432:
        add hl, de
        djnz L_D432
        pop bc
        ret


L_D437:
        ld a, $4F               ; 
        out ($06), a            ; port A input mode
        out ($07), a            ; port B input mode
        ld a, $CF               ; 
        out ($06), a            ; port A control mode
        ld a, $FF               ; 
        out ($06), a            ; port A all inputs
        ld a, $CF               ; 
        out ($07), a            ; port B control mode
        ld a, $FF               ; 
        out ($07), a            ; port B all inputs
        ret


D_LINE:
        ld b, $30               ; Draw horizontal line at (HL); count of 48
        ld a, $98               ; full-width - character
        rst $18                 ; SCAL O -> call to X_04BD
        defb $4F                ; store B copies of A starting at HL
        ld a, $0D               ; 
        rst $30                 ; 
        ret                     ; ROUT -> print CR


D_MSG16:                        ; copy 16-byte message (in HL) to line 16 (top line)
        ld de, $0BD2
        ld bc, $0016
        ldir
        ret


L_D461:
        exx
        ld hl, (cursor)
        ld b, $00
        cp $64
        jr c, L_D475
        sbc a, $64
        inc b
        cp $64
        jr c, L_D475
        sbc a, $64
        inc b

L_D475:
        push af
        ld a, b
        cp $00
        jr z, L_D47F
        add a, $30
        jr L_D481


L_D47F:
        ld a, $20

L_D481:
        ld (hl), a
        pop af
        inc hl
        ld c, $00
        ld b, $09

L_D488:
        cp $0A
        jr c, L_D491
        sbc a, $0A
        inc c
        djnz L_D488

L_D491:
        push af
        ld a, c
        add a, $30
        ld (hl), a
        pop af
        inc hl
        add a, $30
        ld (hl), a
        exx
        ret


L_D49D:                         ; seems to always set bit[0] of ($2834)
        ld a, ($2834)
        and $FE
        ld e, a                 ; get bit[0] in E
        ld a, ($2834)
        xor $01                 ; toggle bit[0]
        or e                    ; 0->1, 1->1
        ld ($2834), a
        ret


L_D4AD:
        ld hl, $0A6A
        ld (cursor), hl
        rst $28
        defm "Chanell "
        defb $00
        ld a, ($2835)
        inc a
        rst $18
        defb $4A                ; X_01E4
        ret


L_D4C4:
        ld a, ($2834)
        bit 0, a
        jr z, L_D4D2
        rst $28
        defm "Int "
        defb $00
        ret


L_D4D2:
        rst $28
        defm "MIDI"
        defb $00
        ret


help:
        nop
        rst $28
        defb $0C
        defm "NORM,SHUFFLE & HIGH at start clear rhythms !."
        defb $0D
        defm "Use C to continue as before (if memory allows)."
        defb $0D
        defm "Beats (x ) option can use, F= First beat to bar"
        defb $0D
        defm "1 = Beats as entered  -  2 = Twice No of beats"
        defb $0D
        defm "In'SHUFFLE' T=Triplets, 3=1/4 Triplets, 6=1/8"
        defb $0D
        defm "In 'NORMAL'(x4) is max In 'HIGH RES' (x8) max"
        defb $0D
        defm "'O' can be used on all but highest numbers to "
        defb $0D
        defm "give an offbeat feel."
        defb $0D, $0D
        defm "Remember, when erasing only the beats selected"
        defb $0D
        defm "will be erased."
        defb $0D
        defm "In assemble chain,to select from another page"
        defb $0D
        defm "use shift and number of page required togther"
        defb $0D, $0D
        defm "(c)  M.C.S.     good luck!"
        defb $00
        rst $08
        and $7F
        jp CONT1


        ; Start of unknown area $D6F8 to $D707
        defb $44, $2E, $47, $2E, $53, $2E, $20, $32
        defb $36, $2F, $36, $2F, $31, $39, $38, $34
        ; End of unknown area $D6F8 to $D707

        defb $00, $00, $00, $00, $00, $00, $00, $00
        defb $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
        defb $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
        defb $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
        defb $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
        defb $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
        defb $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
        defb $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
        defb $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
        defb $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
        defb $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
        defb $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
        defb $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
        defb $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20
        defb $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20
        defb $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20
        defb $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30
        defb $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30
        defb $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30
        defb $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30
        defb $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30
        defb $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30
        defb $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30
        defb $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30
        defb $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30
        defb $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30
        defb $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30
        defb $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30
        defb $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30
        defb $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30
        defb $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30
        defb $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30
        defb $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30
        defb $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30
        defb $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30
        defb $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30
        defb $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30
        defb $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30
        defb $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30
        defb $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30
        defb $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30
        defb $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30
        defb $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30
        defb $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30
        defb $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30
        defb $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30
        defb $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30
        defb $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30
        defb $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30
        defb $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30
        defb $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30
        defb $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30
        defb $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30
        defb $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30
        defb $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30
        defb $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30
        defb $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30
        defb $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30
        defb $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30
        defb $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30
        defb $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30
        defb $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30
        defb $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30
        defb $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30
        defb $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30
        defb $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30
        defb $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30
        defb $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30
        defb $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30
        defb $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30
        defb $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30
        defb $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30
        defb $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30
        defb $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30
        defb $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30
        defb $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30
        defb $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30
        defb $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30
        defb $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30
        defb $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30
        defb $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30
        defb $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30
        defb $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30
        defb $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30
        defb $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30
        defb $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30
        defb $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30
        defb $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30
        defb $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30
        defb $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30
        defb $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30
        defb $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30
        defb $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30
        defb $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30
        defb $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30
        defb $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30
        defb $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30
        defb $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30
        defb $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30
        defb $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30
        defb $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30
        defb $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30
        defb $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30
        defb $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30
        defb $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30
        defb $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30
        defb $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30
        defb $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30
        defb $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30
        defb $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30
        defb $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30
        defb $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30
        defb $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30
        defb $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30
        defb $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30
        defb $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30
        defb $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30
        defb $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30
        defb $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30
        defb $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30
        defb $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30
        defb $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30
        defb $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30
        defb $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30
        defb $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30
        defb $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30
        defb $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30
        defb $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30
        defb $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30
        defb $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30
        defb $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30
        defb $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30
        defb $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30
        defb $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30
        defb $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30
        defb $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30
        defb $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30
        defb $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30
        defb $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30
        defb $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30
        defb $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30
        defb $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30
        defb $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30
        defb $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30


; $0000 CCCCBCCCCBCCCCCCCCCCCCCCCCCBCBCCCCCCCC--CCCCCCCCCCCCCCC-CCCCCCCCCCCCCCCCCCCCCCCC
; $0050 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCBCCCCCCCCCCCCCCCCBCCCBCCCCCCCCCCCBCCCCCCCCCCCCCCCC
; $00A0 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $00F0 CCCCCCCCCCCBCBCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCBCC
; $0140 CCCBCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $0190 CCCCCCCCWWWWWWWWWWBBBBBBBCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCBCCCCCCCCCCCCCCC
; $01E0 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCBCCCCCCCCCCCCCCCBCCC
; $0230 CCCCCCCCCCCCCCCCBCCCCCCCCCCCCCCCCCCBCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $0280 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCBCCCCCBCCCCCCCCCCCCCCCCCCCCCCCCCCCBBB
; $02D0 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBCCBCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $0320 CCCCBBBBBBBBBBBBBBBBBBBBBCCCCCCCCCCCCCCBCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $0370 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCBCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCBBC
; $03C0 CCCCCCCCCCBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $0410 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBCBCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $0460 CCCCCCCCCCCCCCCCCCCBCCCBCCCBCBCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $04B0 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCBCBCBCCCCBCCCBCBCCCCCCCCCCCCCBCCCCCCCCCCCCCBCCBCC
; $0500 BCCBCCCBCCBCBCCCCBCCCCBBBCCCCCCCCCCCCCCCCCCCBCCCCCCCCCCCCBCCCCCCCCCCCCCCCCCCCCCC
; $0550 CCCCCCCCCCCCCCCCCCCCCCCCCCBCCC--CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $05A0 CCCCCCBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $05F0 BBBBBBBBBBBBBBBBBBBBBBCCCCCCCCCCCCCBCCCCCCCCCCCCCCCCCCCBCCCCCCCCCBCCCCCBCBBBBBBC
; $0640 CCCBCCCCCCCBCBCCBCCCCCCCCCCCCCCCCCCCBBCCBCBBCCBCCCCCCCCCCCCCCBCCCCCCCCCCCCCCCCCC
; $0690 CCCCCCCCCCCCCCCCCBBBCCCBBBCCCCCCCCCCBCCCCBCCCCCCCCCBCCCCBCCBCCCCCCCCCCCCCCCCCBCC
; $06E0 CCCCCCCCCCCCCCCCCCCCCCCCBCCCCCCCCCCCCCCCCCCCCCCCCCCCBCCCBCCCCCCCCCCCCCCCCCCCCCCC
; $0730 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC---------------------WWWWWWWWWWWWWWWWWWW
; $0780 WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW
; $07D0 WWWWWWWWWWWWWWWWWWWWWWWWWWW--------------------



; $0C20 BWWWWBB

; $0C29 W

; $0C71 W




; $C000 CCCBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $C030 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $C080 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $C0D0 BBBBBBCCCCCCCCCCBCCCCCCCCCCCCBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $C120 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBCCCCCCCCCCCCCCCC
; $C170 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCBBBBBBBBBBBBBBBBBBBBB
; $C1C0 BBBBBCBCCCCCCCCCCCCCCCCBCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCBCCCCCCCCCCC
; $C210 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCBCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $C260 CCCCCCCCCBCCCCCCCCCCCCCCCCCCCCCCCCCCCCCBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $C2B0 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $C300 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBCCCCBBBBBBBBBBBBBBBBBBBBBBBBCCCCC
; $C350 CCCBCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $C3A0 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $C3F0 CCCCCCCCCCCCCCCCCCCCCCBCCCCCCCCCCCCCCCCBCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $C440 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $C490 CCCCCCBBBBBBCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCBCCCC
; $C4E0 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCBCCCCCCC
; $C530 CCCCCCBCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCBBBBBBBBBBB
; $C580 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBCCBCCCCCCCCCCCCCCCCCCCCCC
; $C5D0 CCCCCCCCCCCBBBBBBBBBBBBBBBBBBCBCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCBCBBBBBBBBBBBBB
; $C620 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBCBCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $C670 CCCCCCCCCCCCCCCCCCCCCCBCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $C6C0 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCBBBCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCBBBBBCCCCCCC
; $C710 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $C760 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $C7B0 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $C800 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $C850 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $C8A0 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $C8F0 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $C940 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $C990 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $C9E0 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $CA30 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $CA80 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $CAD0 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $CB20 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCBBBBBBBBBBBBBBBBBBBB
; $CB70 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $CBC0 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBCCCCBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $CC10 BBBBBBBCCCCCCCCBBBBBBBBBBBBBBBCCCCCCCCCCCCCCCCCCCCCBBBBBBCCCCCCCCCCCCCCCBCCCCCCC
; $CC60 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCBCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $CCB0 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $CD00 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCBBBBBBBBBBBBBB
; $CD50 BBCCCCBCBBBBBBBBBBBBBBBBBBCCCCCCCCCCCCCCCCCCCCCCBBBBBBBBBBBBBBBBBBCCCCBCBBBBBBBB
; $CDA0 BBBBBBBBBBBBBBBBCCCCBCBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $CDF0 BBBBBBBBBBBBBBBBBBBBBBBCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $CE40 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $CE90 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCBCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $CEE0 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $CF30 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $CF80 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $CFD0 CCCCCCCCCCBCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $D020 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCBBBB
; $D070 BBBBBBBBBBBCBCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCBBBBBCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $D0C0 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $D110 CCCCCCCCCCCCCBBBBBBBBBBBBBBBBBBBCCBCCCCCCCCCCCCBBBBBBBBBBBBBBBBBCCBCCCCCCCCCCCCC
; $D160 CCCCBBBBBBBBBBBBBBBBBBBBBBBBBBCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $D1B0 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $D200 CCCCCCCCCBCCCCCCCCCCCCCCCBCCCCCCCCCCCCCCCBCCCCCCCCCCCCCCCCCCCBCCCCCCCCCCCCCCCCCC
; $D250 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCBBBBBBBBBBBBBBBBCBCCCCCCCCCCBBBBBBBBBBBBBBBBCB
; $D2A0 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $D2F0 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $D340 CCCCCCCCCBCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $D390 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $D3E0 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $D430 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCBCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $D480 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCBBBBBBBBBCCCCCBCCCCCCCCCBBBB
; $D4D0 BCCBBBBBCCCBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $D520 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $D570 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $D5C0 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $D610 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $D660 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $D6B0 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBCCCCCC--------
; $D700 --------BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $D750 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $D7A0 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $D7F0 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $D840 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $D890 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $D8E0 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $D930 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $D980 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $D9D0 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $DA20 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $DA70 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $DAC0 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $DB10 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $DB60 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $DBB0 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $DC00 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $DC50 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $DCA0 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $DCF0 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $DD40 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $DD90 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $DDE0 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $DE30 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $DE80 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $DED0 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $DF20 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $DF70 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $DFC0 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB

; Labels
;
; $0000 => COLD            _NMI     => $00F2
; $0008 => rst_rin         _stab    => $0C71
; $000D => stmon           argn     => $0C0B
; $0010 => rst_rcal        args     => $04C2
; $0018 => rst_scal        args2    => $04C5
; $001A => tx1             args3    => $04C9
; $0020 => L_RST20         assemble => $C64B
; $0028 => L_0028          BIN      => $0069
; $0029 => L_0029          BIN2     => $006D
; $002F => dret            BIN8     => $0076
; $0030 => L_RST30         blink    => $0078
; $0034 => L_0034          break    => $060B
; $0038 => rst_rdel        brkadr   => $0C23
; $003E => X_003E          brkval   => $0C25
; $0040 => L_0040          brst0    => $0306
; $0045 => L_0045          CLS      => $C354
; $004D => L_004D          COLD     => $0000
; $0051 => mflp            compose  => $C4AB
; $005B => srlx            conflg   => $0C26
; $005E => L_005E          CONT     => $C181
; $0066 => L_NMI           CONT1    => $C35F
; $0069 => BIN             cpos     => $02C6
; $006D => BIN2            cr1      => $01BA
; $0076 => BIN8            cr3      => $01C1
; $0078 => blink           crlf     => $0339
; $0087 => srlin           crt      => $01A9
; $008E => rkbd            crt0     => $01CF
; $0099 => RK2             crt1     => $01D1
; $00A9 => RK3             crt10    => $020F
; $00B2 => RK5             crt12    => $021B
; $00B8 => RK6             crt14    => $021F
; $00C2 => RK7             crt18    => $022F
; $00DC => KBD             crt2     => $01D4
; $00EC => KSC1A           crt20    => $0236
; $00EE => KSC8            crt25    => $024A
; $00F0 => L_00F0          crt26    => $0251
; $00F2 => _NMI            crt28    => $0257
; $00FC => L_00FC          crt29    => $0260
; $010E => ksc2            crt30    => $0264
; $011D => ksc4            crt31    => $026F
; $0146 => ksc5            crt32    => $0273
; $0157 => k7              crt33    => $0279
; $0160 => k8              crt34    => $0297
; $0164 => k20             crt36    => $029C
; $016E => k30             crt38    => $02AA
; $0174 => k35             crt50    => $02BF
; $017A => k40             crt6     => $0207
; $0183 => k55             crt8     => $020E
; $018C => k60             ct8      => $0294
; $018E => kse             ctst     => $0283
; $0198 => initt           cursor   => $0C29
; $01A9 => crt             D_LINE   => $D44E
; $01BA => cr1             D_MSG16  => $D458
; $01C1 => cr3             DPAGE    => $282A
; $01CF => crt0            dret     => $002F
; $01D1 => crt1            drum     => $C000
; $01D4 => crt2            erase    => $D265
; $01D6 => X_LINE16        errm     => $0323
; $01E4 => X_01E4          exec     => $0489
; $01ED => L_01ED          g        => $060F
; $01F4 => L_01F4          gds      => $0639
; $01FC => L_01FC          help     => $D4D9
; $0207 => crt6            in       => $0733
; $020E => crt8            info     => $D1F6
; $020F => crt10           initt    => $0198
; $021B => crt12           initz    => $0C00
; $021F => crt14           inl2     => $02F5
; $022F => crt18           inlin    => $02F4
; $0236 => crt20           k20      => $0164
; $024A => crt25           k30      => $016E
; $0251 => crt26           k35      => $0174
; $0257 => crt28           k40      => $017A
; $0260 => crt29           k55      => $0183
; $0264 => crt30           k60      => $018C
; $026F => crt31           k7       => $0157
; $0273 => crt32           k8       => $0160
; $0279 => crt33           KBD      => $00DC
; $0283 => ctst            kop      => $0606
; $0294 => ct8             kopt     => $0C27
; $0297 => crt34           KSC1A    => $00EC
; $029C => crt36           ksc2     => $010E
; $02AA => crt38           ksc4     => $011D
; $02BF => crt50           ksc5     => $0146
; $02C6 => cpos            KSC8     => $00EE
; $02CD => M_LINE16        kse      => $018E
; $02F4 => inlin           ktab     => $05A6
; $02F5 => inl2            L_0028   => $0028
; $0306 => brst0           L_0029   => $0029
; $0312 => X_0312          L_0034   => $0034
; $0316 => X_0316          L_0040   => $0040
; $031A => space           L_0045   => $0045
; $031E => X_031E          L_004D   => $004D
; $0323 => errm            L_005E   => $005E
; $0339 => crlf            L_00F0   => $00F0
; $033D => L_033D          L_00FC   => $00FC
; $0353 => num             L_01ED   => $01ED
; $0365 => nn1             L_01F4   => $01F4
; $037D => nn2             L_01FC   => $01FC
; $038C => rlin            L_033D   => $033D
; $0391 => rl2             L_03B0   => $03B0
; $03AA => strtb           L_0433   => $0433
; $03B0 => L_03B0          L_0440   => $0440
; $03C0 => MRET            L_0476   => $0476
; $0433 => L_0433          L_047A   => $047A
; $0436 => X_0436          L_047E   => $047E
; $0440 => L_0440          L_0480   => $0480
; $0476 => L_0476          L_0498   => $0498
; $047A => L_047A          L_04DD   => $04DD
; $047E => L_047E          L_04EB   => $04EB
; $0480 => L_0480          L_04F7   => $04F7
; $0483 => X_0483          L_0510   => $0510
; $0489 => exec            L_052A   => $052A
; $0498 => L_0498          L_0538   => $0538
; $04A7 => X_04a7          L_0558   => $0558
; $04BD => X_04BD          L_055C   => $055C
; $04C2 => args            ascnum   => $0560
; $04C5 => args2           L_061A   => $061A
; $04C9 => args3           L_061F   => $061F
; $04CE => write           L_0641   => $0641
; $04D7 => w3              L_0652   => $0652
; $04DD => L_04DD          L_0655   => $0655
; $04EB => L_04EB          L_0663   => $0663
; $04F7 => L_04F7          L_0669   => $0669
; $0510 => L_0510          L_0672   => $0672
; $051B => X_051B          L_0685   => $0685
; $0522 => X_0522          L_068F   => $068F
; $0527 => getnum          L_0691   => $0691
; $052A => L_052A          L_06A0   => $06A0
; $0538 => L_0538          L_06A6   => $06A6
; $0558 => L_0558          L_06E8   => $06E8
; $055C => L_055C          L_06F7   => $06F7
; $0560 => ascnum          L_0701   => $0701
; $0567 => X_0567          L_0708   => $0708
; $0570 => rcalb           L_070E   => $070E
; $0587 => RCAL4           L_0739   => $0739
; $058B => SCAL2           L_073C   => $073C
; $058C => SCAL3           L_0741   => $0741
; $0599 => SCALJ           L_0753   => $0753
; $05A1 => scali           L_C0D6   => $C0D6
; $05A6 => ktab            L_C1F2   => $C1F2
; $0606 => kop             L_C216   => $C216
; $060B => break           L_C25A   => $C25A
; $060F => g               L_C265   => $C265
; $061A => L_061A          L_C277   => $C277
; $061F => L_061F          L_C389   => $C389
; $0639 => gds             L_C38B   => $C38B
; $063F => sout            L_C3B6   => $C3B6
; $0641 => L_0641          L_C3C3   => $C3C3
; $064A => read            L_C3D2   => $C3D2
; $0652 => L_0652          L_C3D5   => $C3D5
; $0655 => L_0655          L_C3E8   => $C3E8
; $0663 => L_0663          L_C3EA   => $C3EA
; $0669 => L_0669          L_C3FF   => $C3FF
; $0672 => L_0672          L_C413   => $C413
; $0685 => L_0685          L_C416   => $C416
; $068F => L_068F          L_C471   => $C471
; $0691 => L_0691          L_C478   => $C478
; $06A0 => L_06A0          L_C48A   => $C48A
; $06A6 => L_06A6          wait     => $C4CF
; $06B0 => X_06B0          L_C4D3   => $C4D3
; $06BB => X_06BB          getname  => $C4DA
; $06CA => X_06CA          L_C4EB   => $C4EB
; $06E8 => L_06E8          L_C50D   => $C50D
; $06EA => xout            L_C5D4   => $C5D4
; $06F7 => L_06F7          L_C5DA   => $C5DA
; $0701 => L_0701          L_C5F6   => $C5F6
; $0708 => L_0708          L_C669   => $C669
; $070E => L_070E          L_C66F   => $C66F
; $0713 => xn              L_C6B4   => $C6B4
; $0717 => normal          L_C6BC   => $C6BC
; $0726 => nnim            L_C6C6   => $C6C6
; $0733 => in              L_C6CC   => $C6CC
; $0739 => L_0739          L_C6CD   => $C6CD
; $073C => L_073C          L_C6D0   => $C6D0
; $0741 => L_0741          L_C6D9   => $C6D9
; $0753 => L_0753          L_C6DB   => $C6DB
; $076D => staba           L_C6E5   => $C6E5
; $0C00 => initz           L_C6EE   => $C6EE
; $0C0B => argn            L_C6F1   => $C6F1
; $0C20 => numn            L_C6FA   => $C6FA
; $0C21 => numv            L_C702   => $C702
; $0C23 => brkadr          L_C70C   => $C70C
; $0C25 => brkval          L_C71A   => $C71A
; $0C26 => conflg          L_C730   => $C730
; $0C27 => kopt            L_C742   => $C742
; $0C29 => cursor          L_C745   => $C745
; $0C71 => _stab           L_C748   => $C748
; $2820 => PTIME           L_C755   => $C755
; $2822 => RNUM            L_C768   => $C768
; $282A => DPAGE           L_C76E   => $C76E
; $C000 => drum            L_C773   => $C773
; $C003 => M_BPM           L_C784   => $C784
; $C00C => M_RUN           L_C786   => $C786
; $C019 => M_XFER          L_C791   => $C791
; $C02F => M_PLAY          L_C794   => $C794
; $C045 => M_ERAS          L_C7A3   => $C7A3
; $C05B => M_SAVE          L_C7B7   => $C7B7
; $C071 => M_SPACE         L_C7CC   => $C7CC
; $C087 => M_SEQ           L_C7DC   => $C7DC
; $C097 => M_FULL          L_C7E9   => $C7E9
; $C0A2 => M_INFO          L_C801   => $C801
; $C0B2 => M_INFO2         L_C81F   => $C81F
; $C0D6 => L_C0D6          L_C830   => $C830
; $C0ED => M_MENU          L_C855   => $C855
; $C160 => X_C160          L_C86C   => $C86C
; $C181 => CONT            L_C893   => $C893
; $C18F => L_C18F          L_C8A9   => $C8A9
; $C19A => X_C19A          L_C8C4   => $C8C4
; $C1A5 => X_C1A5          L_C8C7   => $C8C7
; $C1A9 => START           L_C8D7   => $C8D7
; $C1F2 => L_C1F2          L_C8E2   => $C8E2
; $C216 => L_C216          L_C8E8   => $C8E8
; $C25A => L_C25A          L_C901   => $C901
; $C265 => L_C265          L_C914   => $C914
; $C277 => L_C277          L_C923   => $C923
; $C280 => X_C280          L_C925   => $C925
; $C332 => X_C332          L_C946   => $C946
; $C352 => RESTART         L_C955   => $C955
; $C354 => CLS             L_C95E   => $C95E
; $C358 => X_C358          L_C96E   => $C96E
; $C35F => CONT1           L_C97B   => $C97B
; $C36C => X_C36c          L_C98E   => $C98E
; $C389 => L_C389          L_C9A2   => $C9A2
; $C38B => L_C38B          L_C9B8   => $C9B8
; $C3A3 => X_C3A3          L_C9CD   => $C9CD
; $C3AF => X_C3AF          L_C9D4   => $C9D4
; $C3B6 => L_C3B6          L_C9DB   => $C9DB
; $C3C3 => L_C3C3          L_C9E0   => $C9E0
; $C3D2 => L_C3D2          L_C9E7   => $C9E7
; $C3D5 => L_C3D5          L_C9EE   => $C9EE
; $C3E8 => L_C3E8          L_C9FC   => $C9FC
; $C3EA => L_C3EA          L_CA00   => $CA00
; $C3FF => L_C3FF          L_CA05   => $CA05
; $C413 => L_C413          L_CA21   => $CA21
; $C416 => L_C416          L_CA25   => $CA25
; $C471 => L_C471          L_CA4D   => $CA4D
; $C478 => L_C478          L_CA5C   => $CA5C
; $C48A => L_C48A          L_CA66   => $CA66
; $C4AB => compose         L_CA75   => $CA75
; $C4CF => wait            L_CA7F   => $CA7F
; $C4D3 => L_C4D3          L_CA98   => $CA98
; $C4DA => getname         L_CAB5   => $CAB5
; $C4EB => L_C4EB          L_CAC5   => $CAC5
; $C50D => L_C50D          L_CADB   => $CADB
; $C55C => X_C55C          L_CAEB   => $CAEB
; $C55F => save            L_CAFB   => $CAFB
; $C5D4 => L_C5D4          L_CB07   => $CB07
; $C5DA => L_C5DA          L_CB2A   => $CB2A
; $C5F6 => L_C5F6          L_CB34   => $CB34
; $C64B => assemble        L_CB3C   => $CB3C
; $C651 => X_C651          L_CC1A   => $CC1A
; $C669 => L_C669          L_CC49   => $CC49
; $C66F => L_C66F          L_CC4B   => $CC4B
; $C6B4 => L_C6B4          L_CC54   => $CC54
; $C6BC => L_C6BC          L_CC7F   => $CC7F
; $C6C6 => L_C6C6          L_CCB1   => $CCB1
; $C6CC => L_C6CC          L_CCC0   => $CCC0
; $C6CD => L_C6CD          L_CCCB   => $CCCB
; $C6D0 => L_C6D0          L_CCDE   => $CCDE
; $C6D9 => L_C6D9          L_CCEA   => $CCEA
; $C6DB => L_C6DB          L_CCED   => $CCED
; $C6E5 => L_C6E5          L_CCF8   => $CCF8
; $C6EE => L_C6EE          L_CD04   => $CD04
; $C6F1 => L_C6F1          L_CD0D   => $CD0D
; $C6FA => L_C6FA          L_CD13   => $CD13
; $C702 => L_C702          L_CD15   => $CD15
; $C70C => L_C70C          L_CD7D   => $CD7D
; $C71A => L_C71A          L_CE1E   => $CE1E
; $C730 => L_C730          L_CE2F   => $CE2F
; $C742 => L_C742          L_CE33   => $CE33
; $C745 => L_C745          L_CE36   => $CE36
; $C748 => L_C748          L_CE3C   => $CE3C
; $C755 => L_C755          L_CE4C   => $CE4C
; $C768 => L_C768          L_CE57   => $CE57
; $C76E => L_C76E          L_CE62   => $CE62
; $C773 => L_C773          L_CE7B   => $CE7B
; $C784 => L_C784          L_CE98   => $CE98
; $C786 => L_C786          L_CEC2   => $CEC2
; $C791 => L_C791          L_CED0   => $CED0
; $C794 => L_C794          L_CEDF   => $CEDF
; $C7A3 => L_C7A3          L_CEE7   => $CEE7
; $C7B1 => X_C7B1          L_CF27   => $CF27
; $C7B7 => L_C7B7          L_CF3D   => $CF3D
; $C7CC => L_C7CC          L_CF43   => $CF43
; $C7DC => L_C7DC          L_CF56   => $CF56
; $C7E9 => L_C7E9          L_CF5F   => $CF5F
; $C7EC => X_C7EC          L_CF6A   => $CF6A
; $C801 => L_C801          L_CF76   => $CF76
; $C81F => L_C81F          L_CF7E   => $CF7E
; $C830 => L_C830          L_CF94   => $CF94
; $C855 => L_C855          L_CF97   => $CF97
; $C86C => L_C86C          L_CF9D   => $CF9D
; $C893 => L_C893          L_CFB1   => $CFB1
; $C89F => X_C89F          L_CFC5   => $CFC5
; $C8A9 => L_C8A9          L_CFC8   => $CFC8
; $C8C4 => L_C8C4          L_CFD1   => $CFD1
; $C8C7 => L_C8C7          L_CFD6   => $CFD6
; $C8D7 => L_C8D7          L_CFE9   => $CFE9
; $C8E2 => L_C8E2          L_CFF1   => $CFF1
; $C8E8 => L_C8E8          L_CFF9   => $CFF9
; $C901 => L_C901          L_D001   => $D001
; $C914 => L_C914          L_D009   => $D009
; $C923 => L_C923          L_D014   => $D014
; $C925 => L_C925          L_D028   => $D028
; $C946 => L_C946          L_D02D   => $D02D
; $C955 => L_C955          L_D033   => $D033
; $C95E => L_C95E          L_D037   => $D037
; $C96E => L_C96E          L_D03A   => $D03A
; $C97B => L_C97B          L_D040   => $D040
; $C98E => L_C98E          L_D054   => $D054
; $C9A2 => L_C9A2          L_D08B   => $D08B
; $C9B8 => L_C9B8          L_D098   => $D098
; $C9CD => L_C9CD          L_D0B4   => $D0B4
; $C9D4 => L_C9D4          L_D0CA   => $D0CA
; $C9DB => L_C9DB          L_D0D5   => $D0D5
; $C9E0 => L_C9E0          L_D0E6   => $D0E6
; $C9E7 => L_C9E7          L_D0F6   => $D0F6
; $C9EE => L_C9EE          L_D0F8   => $D0F8
; $C9FC => L_C9FC          L_D102   => $D102
; $CA00 => L_CA00          L_D230   => $D230
; $CA05 => L_CA05          L_D24F   => $D24F
; $CA21 => L_CA21          L_D2B4   => $D2B4
; $CA25 => L_CA25          L_D2C3   => $D2C3
; $CA4D => L_CA4D          L_D2DD   => $D2DD
; $CA5C => L_CA5C          L_D2E6   => $D2E6
; $CA66 => L_CA66          L_D2EE   => $D2EE
; $CA75 => L_CA75          L_D2FC   => $D2FC
; $CA7F => L_CA7F          L_D309   => $D309
; $CA98 => L_CA98          L_D30C   => $D30C
; $CAB5 => L_CAB5          L_D30E   => $D30E
; $CAC5 => L_CAC5          L_D317   => $D317
; $CADB => L_CADB          L_D326   => $D326
; $CAEB => L_CAEB          L_D329   => $D329
; $CAFB => L_CAFB          L_D333   => $D333
; $CB07 => L_CB07          L_D33D   => $D33D
; $CB2A => L_CB2A          L_D36D   => $D36D
; $CB34 => L_CB34          L_D382   => $D382
; $CB3C => L_CB3C          L_D39E   => $D39E
; $CC1A => L_CC1A          L_D3AE   => $D3AE
; $CC49 => L_CC49          L_D3BA   => $D3BA
; $CC4B => L_CC4B          L_D3BB   => $D3BB
; $CC54 => L_CC54          L_D3C7   => $D3C7
; $CC70 => TIME            L_D3D0   => $D3D0
; $CC7F => L_CC7F          L_D3D2   => $D3D2
; $CCB1 => L_CCB1          L_D3D6   => $D3D6
; $CCC0 => L_CCC0          L_D3D8   => $D3D8
; $CCCB => L_CCCB          L_D3DA   => $D3DA
; $CCDE => L_CCDE          L_D3E8   => $D3E8
; $CCEA => L_CCEA          L_D3EE   => $D3EE
; $CCED => L_CCED          L_D3FB   => $D3FB
; $CCF8 => L_CCF8          L_D3FE   => $D3FE
; $CD04 => L_CD04          L_D401   => $D401
; $CD0D => L_CD0D          L_D405   => $D405
; $CD13 => L_CD13          L_D409   => $D409
; $CD15 => L_CD15          L_D417   => $D417
; $CD7D => L_CD7D          L_D41A   => $D41A
; $CE13 => X_CE13          L_D422   => $D422
; $CE1E => L_CE1E          L_D432   => $D432
; $CE2F => L_CE2F          L_D437   => $D437
; $CE33 => L_CE33          L_D461   => $D461
; $CE36 => L_CE36          L_D475   => $D475
; $CE3C => L_CE3C          L_D47F   => $D47F
; $CE4C => L_CE4C          L_D481   => $D481
; $CE57 => L_CE57          L_D488   => $D488
; $CE62 => L_CE62          L_D491   => $D491
; $CE7B => L_CE7B          L_D49D   => $D49D
; $CE8D => run             L_D4AD   => $D4AD
; $CE98 => L_CE98          L_D4C4   => $D4C4
; $CEC2 => L_CEC2          L_D4D2   => $D4D2
; $CED0 => L_CED0          L_NMI    => $0066
; $CEDF => L_CEDF          L_RST20  => $0020
; $CEE7 => L_CEE7          L_RST30  => $0030
; $CF27 => L_CF27          M_BPM    => $C003
; $CF3D => L_CF3D          M_ERAS   => $C045
; $CF43 => L_CF43          M_FULL   => $C097
; $CF56 => L_CF56          M_INFO   => $C0A2
; $CF5F => L_CF5F          M_INFO2  => $C0B2
; $CF6A => L_CF6A          M_LINE16 => $02CD
; $CF76 => L_CF76          M_MENU   => $C0ED
; $CF7E => L_CF7E          M_PLAY   => $C02F
; $CF94 => L_CF94          M_RUN    => $C00C
; $CF97 => L_CF97          M_SAVE   => $C05B
; $CF9D => L_CF9D          M_SEQ    => $C087
; $CFB1 => L_CFB1          M_SPACE  => $C071
; $CFC5 => L_CFC5          M_XFER   => $C019
; $CFC8 => L_CFC8          mflp     => $0051
; $CFD1 => L_CFD1          MRET     => $03C0
; $CFD6 => L_CFD6          nn1      => $0365
; $CFE9 => L_CFE9          nn2      => $037D
; $CFF1 => L_CFF1          nnim     => $0726
; $CFF9 => L_CFF9          normal   => $0717
; $D001 => L_D001          num      => $0353
; $D009 => L_D009          numn     => $0C20
; $D014 => L_D014          numv     => $0C21
; $D028 => L_D028          play     => $D05A
; $D02D => L_D02D          PTIME    => $2820
; $D033 => L_D033          RCAL4    => $0587
; $D037 => L_D037          rcalb    => $0570
; $D03A => L_D03A          read     => $064A
; $D040 => L_D040          RK2      => $0099
; $D054 => L_D054          RK3      => $00A9
; $D05A => play            RK5      => $00B2
; $D06B => X_D06B          RK6      => $00B8
; $D08B => L_D08B          RK7      => $00C2
; $D098 => L_D098          rkbd     => $008E
; $D0B4 => L_D0B4          rl2      => $0391
; $D0CA => L_D0CA          rlin     => $038C
; $D0D5 => L_D0D5          rst_rcal => $0010
; $D0E6 => L_D0E6          rst_rdel => $0038
; $D0F6 => L_D0F6          rst_rin  => $0008
; $D0F8 => L_D0F8          rst_scal => $0018
; $D102 => L_D102          SCAL2    => $058B
; $D110 => transfer        SCAL3    => $058C
; $D181 => X_D181          scali    => $05A1
; $D1F6 => info            SCALJ    => $0599
; $D230 => info1           sout     => $063F
; $D24F => info2           space    => $031A
; $D265 => erase           srlin    => $0087
; $D2B4 => L_D2B4          srlx     => $005B
; $D2C3 => L_D2C3          staba    => $076D
; $D2DD => L_D2DD          START    => $C1A9
; $D2E6 => L_D2E6          strtb    => $03AA
; $D2EE => L_D2EE          TIME     => $CC70
; $D2FC => L_D2FC          w3       => $04D7
; $D309 => L_D309          CONT1    => $C35F
; $D30C => L_D30C          RESTART  => $C352
; $D30E => L_D30E          write    => $04CE
; $D317 => L_D317          stmon    => $000D
; $D326 => L_D326          tx1      => $001A
; $D329 => L_D329          X_003E   => $003E
; $D333 => L_D333          X_01E4   => $01E4
; $D33D => L_D33D          X_0312   => $0312
; $D36D => L_D36D          X_0316   => $0316
; $D382 => L_D382          X_031E   => $031E
; $D39E => L_D39E          X_0436   => $0436
; $D3AE => L_D3AE          X_0483   => $0483
; $D3BA => L_D3BA          X_04a7   => $04A7
; $D3BB => L_D3BB          X_04BD   => $04BD
; $D3C7 => L_D3C7          X_051B   => $051B
; $D3D0 => L_D3D0          X_0522   => $0522
; $D3D2 => L_D3D2          getnum   => $0527
; $D3D6 => L_D3D6          X_0567   => $0567
; $D3D8 => L_D3D8          X_06B0   => $06B0
; $D3DA => L_D3DA          X_06BB   => $06BB
; $D3E8 => L_D3E8          X_06CA   => $06CA
; $D3EE => L_D3EE          xout     => $06EA
; $D3FB => L_D3FB          xn       => $0713
; $D3FE => L_D3FE          normal   => $0717
; $D401 => L_D401          nnim     => $0726
; $D405 => L_D405          in       => $0733
; $D409 => L_D409          X_C160   => $C160
; $D417 => L_D417          L_C18F   => $C18F
; $D41A => L_D41A          X_C19A   => $C19A
; $D422 => L_D422          X_C1A5   => $C1A5
; $D432 => L_D432          X_C280   => $C280
; $D437 => L_D437          X_C332   => $C332
; $D44E => D_LINE          X_C358   => $C358
; $D458 => D_MSG16         X_C36c   => $C36C
; $D461 => L_D461          X_C3A3   => $C3A3
; $D475 => L_D475          X_C3AF   => $C3AF
; $D47F => L_D47F          X_C55C   => $C55C
; $D481 => L_D481          X_C651   => $C651
; $D488 => L_D488          X_C7B1   => $C7B1
; $D491 => L_D491          X_C7EC   => $C7EC
; $D49D => L_D49D          X_C89F   => $C89F
; $D4AD => L_D4AD          X_CE13   => $CE13
; $D4C4 => L_D4C4          X_D06B   => $D06B
; $D4D2 => L_D4D2          X_D181   => $D181
; $D4D9 => help            X_LINE16 => $01D6
