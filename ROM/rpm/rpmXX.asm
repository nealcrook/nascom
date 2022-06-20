L_0000: equ $0000
L_0002: equ $0002
L_0005: equ $0005
L_0038: equ $0038

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

CBOOT:
        jp START


WBOOT:
        jp L_F152


XF006:
        jp L_F188


UARTDIV:
        defw $01A1

IOBYTE:
        ;; ===================================
        if RPMVER = 20
        defb $01
        endif
        if RPMVER = 21
        defb $81
        endif
        if RPMVER = 23
        defb $81
        endif

LINPPAG:
        defb $42
;;; Table of jumps to RP/M I/O routines. Copied to RAM by code at L_F0AB

XF00D:
        defb $C3
        defw CBOOT
        defb $C3
        defw WBOOT
        defb $C3
        defw CONST
        defb $C3
        defw CONIN
        defb $C3
        defw CONOU
        defb $C3
        defw LIST
        defb $C3
        defw PUNCH
        defb $C3
        defw READ

SYS0:
        ld hl, $FF83            ; Routine 0: Restart R/PM
        jr L_F046               ; go via jump table to CBOOT


L_F02A:
        ld hl, $FF86
        jr L_F046


L_F02F:
        ld hl, $FF89
        jr L_F046


L_F034:
        ld hl, $FF8C
        jr L_F046


SYS5:
        ld hl, $FF8F            ; Routine 5: List Output (printer: serial or parallel)
        jr L_F046               ; go via jump table to CONOU


SYS4:
        ld hl, $FF92            ; Routine 4: Punch Output (serial out)
        jr L_F046               ; go via jump table to ???order seems wrong..


L_F043:
        ld hl, $FF95

L_F046:
        ld de, ($004E)
        add hl, de
        jp (hl)


MSGSIZ:
        ;; ===================================
        if RPMVER = 20
        defm " bytes - RP/M for Gemini V2.0$"
        endif
        if RPMVER = 21
        defm " bytes - RP/M for Gemini V2.1$"
        endif
        if RPMVER = 23
        defm " bytes - RP/M for Gemini V2.3$"
        endif
        ;; ===================================

START:
        ld d, $64               ; ??

L_F06C:
        ld bc, L_F0FE           ; B=?? C= memory mapper port
        ld e, $0F               ; value?

L_F071:
        out (c), e              ; initialise memory mapper
        dec e                   ; 
        ld a, b                 ; 
        sub $10                 ; 
        ld b, a                 ; 
        jr nc, L_F071           ; continue
        dec d                   ; 
        jr nz, L_F06C           ; 0x64 = 40
        ld a, $11               ; value?
        out ($FF), a            ; Page-mode register
        out ($B3), a            ; Reset IVC (if present)
        ld hl, L_0000           ; 
        ld (hl), $00            ; 
        ld de, $0001            ; 
        ld bc, $00FF            ; 
        ldir                    ; zero out the first 256 bytes of memory
        ld hl, L_0000           ; 

L_F093:
        ld a, (hl)              ; RAM sizing? Read value
        cpl                     ; 
        ld (hl), a              ; store complement
        cp (hl)                 ; should match..
        jr nz, L_F0AB           ; ..but does not: found top of RAM
        cpl                     ; 
        ld (hl), a              ; restore original
        inc hl                  ; next location to test
        ld de, $000C            ; 

L_F09F:
        ld a, (de)              ; 
        inc a                   ; 
        ld (de), a              ; 
        cp $0A                  ; 
        jr nz, L_F093           ; 
        xor a                   ; 
        ld (de), a              ; 
        dec de                  ; 
        jr L_F09F               ; 


L_F0AB:
        ld ($004E), hl          ; Store RAM top
        ld de, $FFC0            ; 
        add hl, de              ; 
        ld sp, hl               ; 
        ld de, $FF40            ; 
        add hl, de              ; 
        ld a, $C3               ; 
        ld (L_0005), a          ; 
        ld ($0006), hl          ; 
        ld (hl), a              ; 
        inc hl                  ; 
        ld de, XF006            ; 
        ld (hl), e              ; 
        inc hl                  ; 
        ld (hl), d              ; 
        inc hl                  ; 
        ld ($0046), hl          ; 
        ld hl, ($004E)          ; 
        ld de, $FF83            ; 
        add hl, de              ; 
        ld (L_0000), a          ; 
        ld ($0001), hl          ; 
        ex de, hl               ; 
        dec de                  ; 
        dec de                  ; 
        dec de                  ; 
        ld hl, XF00D            ; 
        ld bc, $0018            ; 
        ldir                    ; 
        ld (L_0038), a          ; 
        ld hl, XFBEF            ; 
        ld ($0039), hl          ; 
        ld a, (IOBYTE)          ; get initial/default value of IOBYTE
        ld hl, $0003            ; 
        ld (hl), a              ; store in 0x0003
        in a, ($BE)             ; 
        bit 6, a
        jr z, L_F0FE
        ld a, (hl)
        xor $01
        ld (hl), a

L_F0FE:
        ld bc, $00FE
        ld a, $0F
        out (c), a
        ld a, (hl)
        cp $C3

        ;; ===================================
        if RPMVER = 20
        jr nz, L_F10E
        out (c), b
        endif
        if RPMVER = 21
        out (c), b
        jr nz, L_F10E
        endif
        if RPMVER = 23
        out (c), b
        jr nz, L_F10E
        endif
        ;; ===================================

        set 1, (hl)
L_F10E: ld hl, $0200            ; 
        ld ($004C), hl          ; Initialise ??what
        ld a, (LINPPAG)         ; 
        ld ($0042), a           ; Initialise printer lines per page from ROM default
        in a, ($B1)             ; IVC data
        call L_FEB6             ; Scan?/Initialise? local keyboard, if any
        ld hl, (UARTDIV)        ; 
        ld ($003B), hl          ; Initialise baud rate from ROM default
        call SELSER             ; 
        ld a, (L_FFD8)          ; First unused location in ROM
        cp $FF                  ; unprogrammed?
        call nz, L_FFD8         ; if not, call custom user post-reset routine
        call L_FB27             ; 
        ld hl, $0008            ; 
        ld b, $05               ; print memory size.. 5 digits?

L_F138:
        ld a, (hl)
        add a, $30
        ld e, a
        push hl
        push bc
        call COUT02
        pop bc
        pop hl
        inc hl
        djnz L_F138
        ld de, MSGSIZ
        call PRS09
        call CHKDSK
        call z, L_FC0E

L_F152:
        ld hl, ($004E)          ; HL = RAM top
        ld de, $FFC0            ; 
        add hl, de              ; 
        ld sp, hl               ; 
        ld hl, $0080            ; 
        ld ($004A), hl          ; 
        xor a                   ; 
        ld ($0041), a           ; init current printer line count to 0
        ld ($0045), a           ; 
        ld ($0053), a           ; 
        ld a, $FF               ; 
        out ($B4), a            ; soft init
        out ($B5), a            ; of PIO
        out ($B6), a            ; 
        ld a, $FD               ; 
        out ($B6), a            ; 
        ld a, $FF               ; 
        out ($B7), a            ; 
        xor a                   ; 
        out ($B7), a            ; 
        ld a, (L_FFDB)          ; Fourth unused location in ROM
        cp $FF                  ; unprogrammed?
        call nz, L_FFDB         ; if not, call custom user post-restart (warm start) routine
        jp L_F73F               ; 


L_F188:
        ld ($0057), de          ; Dispatcher for RP/M System routines
        ld hl, L_0000           ; 
        ld ($0059), hl          ; save
        ld ($0055), sp          ; save
        ld sp, ($004E)          ; switch to/clear System Stack at top of memory 
        ld hl, CMDRET           ; will return to RP/M command environment??
        push hl                 ; 
        ld a, c                 ; move routine number from C to A
        cp $1B                  ; routines 0-26 (0x1A) are defined
        ret nc                  ; ignore undefined routine number
        ld c, e                 ; move command argument from E to C
        ld hl, SYSTAB           ; point to table of system commands
        ld e, a                 ; 
        ld d, $00               ; DE is routine number
        add hl, de              ; 
        add hl, de              ; HL is pointing to the routine address in SYSTAB
        ld e, (hl)              ; get..
        inc hl                  ; 
        ld d, (hl)              ; ..routine address in DE
        ld hl, ($0057)          ; this will set DE to 0
        ex de, hl               ; 
        jp (hl)                 ; go to system routine


SYSTAB:
        defw SYS0, SYS1, SYS2, SYS3, SYS4, SYS5, SYS6, SYS7
        defw SYS8, SYS9, SYS10, SYS11, DUMMY, SYS13, DUMMY, SYS15
        defw SYS16, DUMMY, DUMMY, DUMMY, SYS20, SYS21, SYS15, DUMMY
        defw DUMMY, DUMMY, SYS26

CMDRET:
        ld sp, ($0055)          ; return from RP/M system routine to RP/M command environment: restore stack
        ld hl, ($0059)          ; restore HL
        ld a, l                 ; return values??
        ld b, h                 ; 

DUMMY:
        ret                     ; 


L_F1F3:
        ld hl, $0054
        ld a, (hl)
        ld (hl), $00
        or a
        ret nz
        jp L_F02F


L_F1FE:
        call L_F1F3
        call L_F20C
        ret c
        push af
        ld c, a
        call SYS2
        pop af
        ret


L_F20C:
        cp $0D
        ret z
        cp $0A
        ret z
        cp $09
        ret z
        cp $08
        ret z
        cp $20
        ret


L_F21B:
        ld a, ($0054)
        or a
        jr nz, L_F23B
        call L_F02A
        and $01
        ret z
        call L_F02F
        cp $13
        jr nz, L_F238
        call L_F02F
        cp $03
        jp z, L_0000
        xor a
        ret


L_F238:
        ld ($0054), a

L_F23B:
        ld a, $01
        ret


L_F23E:
        ld a, ($0050)
        or a
        jr nz, L_F257
        push bc
        call L_F21B
        pop bc
        push bc
        call L_F034
        pop bc
        push bc
        ld a, ($0053)
        or a
        call nz, SYS5
        pop bc

L_F257:
        ld a, c
        ld hl, $0052
        cp $7F
        ret z
        inc (hl)
        cp $20
        ret nc
        dec (hl)
        ld a, (hl)
        or a
        ret z
        ld a, c
        cp $08
        jr nz, L_F26D
        dec (hl)
        ret


L_F26D:
        cp $0D
        ret nz
        ld (hl), $00
        ret


L_F273:
        ld a, c
        call L_F20C
        jr nc, SYS2
        push af
        ld c, $5E
        call L_F23E
        pop af
        or $40
        ld c, a

SYS2:
        ld a, c                 ; Routine 2: Console Output
        cp $09                  ; 
        jr nz, L_F23E

L_F288:
        ld c, $20
        call L_F23E
        ld a, ($0052)
        and $07
        jr nz, L_F288
        ret


L_F295:
        call L_F29D
        ld c, $20
        call L_F034

L_F29D:
        ld c, $08
        jp L_F034


L_F2A2:
        ld c, $23
        call L_F23E
        call L_F2B9

L_F2AA:
        ld a, ($0052)
        ld hl, $0051
        cp (hl)
        ret nc
        ld c, $20
        call L_F23E
        jr L_F2AA


L_F2B9:
        ld c, $0D
        call L_F23E
        ld c, $0A
        jp L_F23E


L_F2C3:
        ld a, (bc)
        cp $24
        ret z
        inc bc
        push bc
        ld c, a
        call SYS2
        pop bc
        jr L_F2C3


SYS10:
        ld a, ($0052)           ; Routine 10: Read Console Buffer
        ld ($0051), a           ; 
        ld hl, ($0057)
        ld c, (hl)
        inc hl
        push hl
        ld b, $00

L_F2DE:
        push bc
        push hl

L_F2E0:
        call L_F1F3
        and $7F
        pop hl
        pop bc
        cp $0D
        jp z, L_F39F
        cp $0A
        jp z, L_F39F
        cp $08
        jr nz, L_F302
        ld a, b
        or a
        jr z, L_F2DE
        dec b
        ld a, ($0052)
        ld ($0050), a
        jr L_F352


L_F302:
        cp $7F
        jr nz, L_F310
        ld a, b
        or a
        jr z, L_F2DE
        ld a, (hl)
        dec b
        dec hl
        jp L_F388


L_F310:
        cp $05
        jr nz, L_F31F
        push bc
        push hl
        call L_F2B9
        xor a
        ld ($0051), a
        jr L_F2E0


L_F31F:
        cp $10
        jr nz, L_F32E
        push hl
        ld hl, $0053
        ld a, $01
        sub (hl)
        ld (hl), a
        pop hl
        jr L_F2DE


L_F32E:
        cp $18
        jr nz, L_F343
        pop hl

L_F333:
        ld a, ($0051)
        ld hl, $0052
        cp (hl)
        jp nc, SYS10
        dec (hl)
        call L_F295
        jr L_F333


L_F343:
        cp $15
        jr nz, L_F34E
        call L_F2A2
        pop hl
        jp SYS10


L_F34E:
        cp $12
        jr nz, L_F385

L_F352:
        push bc
        call L_F2A2
        pop bc
        pop hl
        push hl
        push bc

L_F35A:
        ld a, b
        or a
        jr z, L_F36A
        inc hl
        ld c, (hl)
        dec b
        push bc
        push hl
        call L_F273
        pop hl
        pop bc
        jr L_F35A


L_F36A:
        push hl
        ld a, ($0050)
        or a
        jp z, L_F2E0
        ld hl, $0052
        sub (hl)
        ld ($0050), a

L_F379:
        call L_F295
        ld hl, $0050
        dec (hl)
        jr nz, L_F379
        jp L_F2E0


L_F385:
        inc hl
        ld (hl), a
        inc b

L_F388:
        push bc
        push hl
        ld c, a
        call L_F273
        pop hl
        pop bc
        ld a, (hl)
        cp $03
        ld a, b
        jr nz, L_F39B
        cp $01
        jp z, L_0000

L_F39B:
        cp c
        jp c, L_F2DE

L_F39F:
        pop hl
        ld (hl), b
        ld c, $0D
        jp L_F23E


SYS1:
        call L_F1FE             ; Routine 1: Console Input 
        jr L_F3DA               ; 


SYS3:
        call L_F043             ; Routine 3: Reader Input (serial in)
        jr L_F3DA               ; 


SYS6:
        ld a, c                 ; Routine 6: Direct Console I/O
        inc a                   ; 
        jr z, L_F3BB
        inc a
        jp z, L_F02A
        jp L_F034


L_F3BB:
        call L_F02A
        or a
        jp z, CMDRET
        call L_F02F
        jr L_F3DA


SYS7:
        ld a, ($0003)           ; Routine 7: Get IOBYTE
        jr L_F3DA               ; 


SYS8:
        ld hl, $0003            ; Routine 8: Set IOBYTE
        ld (hl), c              ; 
        ret


SYS9:
        ex de, hl               ; Routine 9: Print String
        ld c, l                 ; 
        ld b, h
        jp L_F2C3


SYS11:
        call L_F21B             ; Routine 11: Get Console Status

L_F3DA:
        ld ($0059), a           ; 
        ret


MSG2:
        defb $0D, $0A
        defm "Insert"

MSG3:
        defb $0D, $0A
        defm "Remove"

MSG4:
        defm " file: "

MSG5:
        defm "Start playing.  "

MSG6:
        defm "Start recording.  "

MSG7:
        defm "Press return"
        defb $0D, $0A

MSG8:
        defm "."
        defb $0D, $0A

MSG9:
        defb $0D, $0A
        defm "Wrong file: "

MSG10:
        defb $0D, $0A
        defm "Rewind and retry"
        defb $0D, $0A

MSGIO:
        defb $0D, $0A
        defm "Invalid I/O"

MSGMEM:
        defb $0D, $0A
        defm "No memory"

SYS15:
        ld hl, MSG2             ; Routine 15: Open File
        ld b, $08               ; 
        call PRMSG
        call L_F6CF
        ld hl, $001B
        add hl, de
        ld (hl), $00
        ld hl, $001E
        add hl, de
        ld (hl), $4F
        inc hl
        ld (hl), $50
        call SELCASS
        xor a
        jp L_F3DA


SYS16:
        call L_F69F             ; Routine 16: Close File
        cp $52                  ; 
        jr z, L_F493
        ld hl, $001B
        add hl, de
        ld (hl), $FF
        call L_F5D1

L_F493:
        ld hl, $001E
        add hl, de
        ld (hl), $00
        call SELSER
        ld hl, MSG3
        ld b, $08
        call PRMSG
        call L_F6CF
        call L_F6B9
        xor a
        jp L_F3DA


SYS20:
        call L_F660             ; Read Cassette Record

L_F4B1:
        ld b, $03               ; 
        ld c, a

L_F4B4:
        call L_FE8B
        cp c
        jr nz, L_F4B1
        djnz L_F4B4
        cp $03
        jr z, L_F4F2
        cp $5A
        jr nz, L_F4B1
        ld hl, $0011
        add hl, de
        push de
        ld b, $0D

L_F4CB:
        call L_FE8B
        ld (hl), a
        inc hl
        djnz L_F4CB
        dec hl
        dec hl
        dec hl
        ld a, (hl)
        ld e, a
        or a
        jr nz, L_F4F8
        ld bc, $FF80
        ld hl, ($0006)
        add hl, bc
        ld bc, ($004A)
        or a
        sbc hl, bc
        jr nc, L_F4F8
        ld hl, MSGMEM
        ld b, $0B
        call PRMSG

L_F4F2:
        call SELSER
        jp L_0000


L_F4F8:
        ld bc, L_0000
        ld hl, ($004A)
        ld d, $80

L_F500:
        call L_FE8B
        call L_F657
        push af
        ld a, e
        or a
        jr nz, L_F50F
        pop af
        ld (hl), a
        inc hl
        push af

L_F50F:
        pop af
        dec d
        jr nz, L_F500
        pop de
        ld hl, $0011
        add hl, de
        push de
        ld d, $0B

L_F51B:
        ld a, (hl)
        call L_F657
        inc hl
        dec d
        jr nz, L_F51B
        pop de
        ld hl, $001C
        add hl, de
        push de
        ld e, (hl)
        inc hl
        ld h, (hl)
        ld l, e
        pop de
        or a
        sbc hl, bc
        jr z, L_F53B
        ld a, $3F
        call PUTIVC
        jp L_F4B1


L_F53B:
        push de
        ld hl, $0001
        add hl, de
        ld b, $08
        ld de, $0010

L_F545:
        push hl
        ld a, (hl)
        add hl, de
        cp (hl)
        jr z, L_F569
        pop hl
        pop de
        ld hl, MSG9
        ld b, $0E
        call PRMSG
        ld hl, $0011
        add hl, de
        ld b, $08
        call PRMSG
        ld hl, MSG9
        ld b, $02
        call PRMSG
        jp L_F4B1


L_F569:
        pop hl
        inc hl
        djnz L_F545
        pop de
        ld hl, $000C
        add hl, de
        ld a, (hl)
        ld hl, $001A
        add hl, de
        cp (hl)
        jr z, L_F587
        jr nc, L_F595

L_F57C:
        ld hl, MSG10
        ld b, $14
        call PRMSG
        jp L_F4B1


L_F587:
        ld hl, $0020
        add hl, de
        ld a, (hl)
        ld hl, $0019
        add hl, de
        cp (hl)
        jr z, L_F59D
        jr c, L_F57C

L_F595:
        ld a, $2D
        call PUTIVC
        jp L_F4B1


L_F59D:
        ld hl, $0020
        add hl, de
        inc (hl)
        jr nz, L_F5A9
        ld hl, $000C
        add hl, de
        inc (hl)

L_F5A9:
        ld hl, $001B
        add hl, de
        ld a, (hl)
        or a
        jr nz, L_F5BA
        ld a, $2A
        call PUTIVC
        xor a
        jp L_F3DA


L_F5BA:
        ld hl, MSG8
        ld b, $03
        call PRMSG
        call SELSER
        ld a, $01
        jp L_F3DA


SYS21:
        call L_F5D1             ; Write Cassette Record
        xor a                   ; 
        jp L_F3DA


L_F5D1:
        call L_F67C
        ld bc, L_0000
        ld hl, ($004A)
        push de
        ld d, $80

L_F5DD:
        ld a, (hl)
        call L_F657
        inc hl
        dec d
        jr nz, L_F5DD
        pop de
        push bc
        xor a
        call SOUT
        ld a, $5A
        ld b, $04

L_F5EF:
        call SOUT
        djnz L_F5EF
        ld hl, $0001
        add hl, de
        pop bc
        push de
        ld d, $08

L_F5FC:
        call L_F653
        inc hl
        dec d
        jr nz, L_F5FC
        pop de
        ld hl, $0020
        call L_F652
        ld hl, $000C
        call L_F652
        ld hl, $001B
        call L_F652
        ld a, c
        call SOUT
        ld a, b
        call SOUT
        ld hl, ($004A)
        ld b, $80

L_F623:
        ld a, (hl)
        call SOUT
        inc hl
        djnz L_F623
        ld b, $04
        ld a, $01

L_F62E:
        call SOUT
        djnz L_F62E
        ld hl, $0020
        add hl, de
        inc (hl)
        jr nz, L_F63F
        ld hl, $000C
        add hl, de
        inc (hl)

L_F63F:
        ld a, $2A
        call PUTIVC
        ld b, $28
        call L_F6ED
        ret


SYS13:
        ld de, $0080            ; Routine 13: Reset File I/O System

SYS26:
        ld ($004A), de          ; Set Data Address
        ret                     ; 


L_F652:
        add hl, de

L_F653:
        ld a, (hl)
        call SOUT

L_F657:
        push hl
        ld h, $00
        ld l, a
        add hl, bc
        ld b, h
        ld c, l
        pop hl
        ret


L_F660:
        ld hl, $001F
        add hl, de
        ld a, (hl)
        cp $52
        jr z, L_F69F
        cp $50
        jr nz, L_F6AB
        ld (hl), $52
        ld hl, MSG5
        ld b, $10
        call PRMSG
        call L_F6B9
        jr L_F69F


L_F67C:
        ld hl, $001F
        add hl, de
        ld a, (hl)
        cp $57
        jr z, L_F69F
        cp $50
        jr nz, L_F6AB
        ld (hl), $57
        ld hl, MSG6
        ld b, $12
        call PRMSG
        call L_F6B9
        ld b, $96
        ld a, $01

L_F69A:
        call SOUT
        djnz L_F69A

L_F69F:
        ld hl, $001E
        add hl, de
        ld a, (hl)
        cp $4F
        jr nz, L_F6AB
        inc hl
        ld a, (hl)
        ret


L_F6AB:
        ld hl, MSGIO
        ld b, $0D
        call PRMSG
        call SELSER
        jp L_0000


L_F6B9:
        ld hl, MSG7
        ld b, $0E
        call PRMSG
        call L_FF41

L_F6C4:
        call L_FE85
        cp $0D
        jr nz, L_F6C4
        call L_FF68
        ret


L_F6CF:
        ld hl, MSG4
        ld b, $07
        call PRMSG
        ld hl, $0001
        add hl, de
        ld b, $08
        call PRMSG
        ld hl, MSG2
        ld b, $02

PRMSG:
        ld a, (hl)
        call PUTIVC
        inc hl
        djnz PRMSG
        ret


L_F6ED:
        xor a

L_F6EE:
        dec a
        jr nz, L_F6EE
        djnz L_F6ED
        ret


MSGRDY:
        defb $0D, $0A
        defm "** RP/M ready **$"

MSGWOT:
        defm "What?$"

MSGCMD:
        defm "No such command$"

MSGARG:
        defm "Too many/few values$"

MSG17:
        defb $0D, $0A
        defm "** Trap at $"

L_F73F:
        ld de, MSGRDY           ; 
        call PRS09              ; print startup message

CMDLOP:
        ld e, $2A               ; interactive command loop. Commands are dispatched with a JP/JR and terminate with RET
        call COUT02             ; print prompt: *
        call L_FB4C             ; ??
        call L_FB13             ; ??
        jr z, CMDLOP            ; ??nothing to do
        call L_FB43             ; ??
        ld ($005C), a           ; 0x5C is start of default file control block (FCB) used as command line buffer?
        inc de                  ; 
        ld hl, CMDLOP           ; 
        push hl                 ; put CMDLOP on stack so that a command that terminates with a RET will re-enter the command loop
        cp $52                  ; 
        jr z, CMD_RWI           ; R - needs filename
        cp $57                  ; 
        jr z, CMD_RWI           ; W - needs filename
        cp $49                  ; 
        jr z, CMD_RWI           ; I - needs filename
        call L_FB68             ; ??
        jr c, WOT               ; 
        ld a, ($005C)           ; get 1st letter of command
        cp $44                  ; 
        jp z, CMD_D             ; Display memory in hex and ASCII
        cp $53                  ; 
        jp z, CMD_S             ; Set or examine memory
        cp $47                  ; 
        jp z, CMD_G             ; Go to code at address
        cp $43                  ; 
        jp z, CMD_C             ; Copy memory from/to/length
        cp $46                  ; 
        jp z, CMD_F             ; Fill memory start/end/character
        cp $50                  ; 
        jp z, CMD_P             ; move Package to 0x100 ??and execute
        cp $55                  ; 
        jp z, CMD_U             ; UART configure
        cp $4C                  ; 
        jp z, CMD_L             ; display or set the Length of a program
        cp $4F                  ; 
        jp z, CMD_O             ; Out to port
        cp $51                  ; 
        jp z, CMD_Q             ; Query port
        cp $42                  ; 
        jp z, CMD_B             ; Boot from floppy
        ld de, MSGCMD           ; no such command
        jr PRS09I2              ; print message ??how to get back to cmd loop


BADARG:
        ld de, MSGARG
        jr PRS09I2


WOT:
        ld de, MSGWOT

PRS09I2:
        jp PRS09


CMD_RWI:
        ld hl, $005D
        ld b, $23

L_F7BD:
        ld (hl), $20
        inc hl
        djnz L_F7BD
        xor a
        ld ($0068), a
        call L_FB13
        jr z, L_F7FA
        ld b, $09
        ld hl, $005D

L_F7D0:
        ld a, (de)
        call L_FB43
        cp $30
        jr c, L_F7EB
        cp $5B
        jr nc, L_F7EB
        cp $3A
        jr c, L_F7E4
        cp $41
        jr c, L_F7EB

L_F7E4:
        ld (hl), a
        inc de
        inc hl
        djnz L_F7D0
        jr L_F7FA


L_F7EB:
        call L_FB13
        jr nz, L_F7FA
        ld a, ($005C)
        cp $49
        jp z, L_F886
        jr L_F804


L_F7FA:
        ld a, ($005C)
        cp $49
        jp z, L_F886
        jr WOT


L_F804:
        ld a, ($0003)
        and $01
        jr z, WOT
        xor a
        ld ($007C), a
        ld de, $005C
        ld c, $0F
        call L_0005
        ld de, $0100
        ld ($0069), de
        ld c, $1A
        call L_0005
        ld a, ($005C)
        cp $52
        jp z, L_F857
        ld hl, ($003D)
        inc hl
        ld ($0065), hl

L_F832:
        ld hl, ($0065)
        dec hl
        ld a, h
        or l
        jr z, L_F87E
        ld ($0065), hl
        ld de, $005C
        ld c, $15
        call L_0005
        ld hl, ($0069)
        ld de, $0080
        add hl, de
        ld ($0069), hl
        ex de, hl
        ld c, $1A
        call L_0005
        jr L_F832


L_F857:
        ld hl, L_0000

L_F85A:
        ld ($003D), hl
        ld de, $005C
        ld c, $14
        call L_0005
        or a
        jr nz, L_F87E
        ld hl, ($0069)
        ld de, $0080
        add hl, de
        ld ($0069), hl
        ex de, hl
        ld c, $1A
        call L_0005
        ld hl, ($003D)
        inc hl
        jr L_F85A


L_F87E:
        ld de, $005C
        ld c, $10
        jp L_0005


L_F886:
        ld hl, $0080
        dec (hl)
        inc hl
        ld d, h
        ld e, l
        inc hl

L_F88E:
        ld a, (hl)
        call L_FB43
        ld (de), a
        inc de
        inc hl
        or a
        jr nz, L_F88E
        ld hl, L_F73F
        ex (sp), hl
        ld hl, $0100
        jp L_F9E6


CMD_D:
        ld a, ($0060)
        cp $03
        jp nc, BADARG
        call L_FBE3
        cp $02
        jr nc, L_F8B6
        ld de, $0080
        jr L_F8BC


L_F8B6:
        or a
        ex de, hl
        sbc hl, de
        ex de, hl
        inc de

L_F8BC:
        push hl
        push de
        push hl
        push de
        call L_FBC5
        ld b, $02
        call L_FB37
        pop de
        pop hl
        ld b, $10

L_F8CC:
        ld a, (hl)
        push hl
        push de
        push bc
        call L_FBCC
        call L_FB33
        pop bc
        call L_F928
        pop de
        pop hl
        inc hl
        dec de
        ld a, d
        or e
        jr z, L_F8E4
        djnz L_F8CC

L_F8E4:
        ld b, $02
        call L_FB37
        pop de
        pop hl
        ld b, $10

L_F8ED:
        ld a, (hl)
        push hl
        push de
        push bc
        cp $20
        jr c, L_F8F9
        cp $7F
        jr c, L_F8FB

L_F8F9:
        ld a, $2E

L_F8FB:
        ld e, a
        call COUT02
        pop bc
        call L_F928
        pop de
        pop hl
        inc hl
        ld ($0061), hl
        dec de
        ld a, d
        or e
        jp z, L_FB27
        djnz L_F8ED
        push hl
        push de
        call L_FB27
        ld c, $0B
        call L_0005
        pop de
        pop hl
        or a
        jr z, L_F8BC
        ld c, $01
        call L_0005
        jp L_FB27


L_F928:
        ld a, b
        cp $09
        ret nz
        push bc
        call L_FB33
        pop bc
        ret


CMD_S:
        ld a, ($0060)
        cp $01
        jp nz, BADARG

L_F93A:
        ld hl, ($0061)

L_F93D:
        ld ($0061), hl
        push hl
        call L_FBC5
        call L_FB33
        pop hl
        ld a, (hl)
        push hl
        push af
        call L_FBCC
        call L_FB33
        pop af
        cp $20
        jr c, L_F966
        cp $7F
        jr nc, L_F966
        push af
        call L_FB3F
        pop af
        ld e, a
        call COUT02
        call L_FB3F

L_F966:
        call L_FB27
        ld b, $0B
        call L_FB37
        call L_FB4C
        pop hl
        ld b, $00

L_F974:
        call L_FB13
        jr nz, L_F980
        ld a, b
        or a
        jr nz, L_F93D
        inc hl
        jr L_F93D


L_F980:
        inc b
        push hl
        call L_FB87
        ld a, (hl)
        or a
        jr z, L_F996
        inc hl
        inc hl
        ld a, (hl)
        or a
        jr nz, L_F9CA
        dec hl
        ld a, (hl)
        pop hl

L_F992:
        ld (hl), a
        inc hl
        jr L_F974


L_F996:
        pop hl
        ld a, (de)
        cp $2E
        jr nz, L_F9A3
        inc de
        call L_FB13
        ret z
        jr L_F9CB


L_F9A3:
        cp $22
        jr nz, L_F9AF
        inc de
        ld a, (de)
        or a
        jr z, L_F9CB
        inc de
        jr L_F992


L_F9AF:
        cp $2D
        jr nz, L_F9B7
        dec hl
        inc de
        jr L_F974


L_F9B7:
        cp $2F
        jr nz, L_F9CB
        inc de
        call L_FB87
        jr c, L_F9CB
        ld a, (hl)
        or a
        jr z, L_F9CB
        ld hl, ($005E)
        jr L_F974


L_F9CA:
        pop hl

L_F9CB:
        call WOT
        jp L_F93A


CMD_G:
        ld a, ($0060)
        cp $02
        jp nc, BADARG
        ld hl, L_F73F
        ex (sp), hl
        ld hl, $0100
        or a
        jr z, L_F9E6
        ld hl, ($0061)

L_F9E6:
        push hl
        ld de, $0080
        ld c, $1A
        jp L_0005


CMD_C:
        ld a, ($0060)
        cp $03
        jp nz, BADARG
        call L_FBE3
        or a
        sbc hl, de
        add hl, de
        jr nc, L_FA09
        dec bc
        ex de, hl
        add hl, bc
        ex de, hl
        add hl, bc
        inc bc
        lddr
        ret


L_FA09:
        ldir
        ret


CMD_F:
        ld a, ($0060)
        cp $03
        jp nz, BADARG
        call L_FBE3
        ld a, b
        or a
        jp nz, WOT
        inc de

L_FA1D:
        or a
        sbc hl, de
        add hl, de
        ret z
        jp nc, WOT
        ld (hl), c
        inc hl
        jr L_FA1D


CMD_P:
        ld a, ($0060)
        cp $04
        jp nc, BADARG
        call L_FBE3
        cp $03
        jr z, L_FA3B
        ld bc, $6000

L_FA3B:
        cp $02
        jr nc, L_FA42
        ld de, L_0000

L_FA42:
        cp $01
        jr nc, L_FA49
        ld hl, $C000

L_FA49:
        ld a, d
        or a
        jp nz, WOT
        ld a, e
        cp $04
        jp nc, WOT
        ld a, $01
        inc e

L_FA57:
        dec e
        jr z, L_FA5D
        add a, a
        jr L_FA57


L_FA5D:
        or $10
        out ($FF), a
        ld de, $0100
        ldir
        ld a, $11
        out ($FF), a
        ret


CMD_U:
        ld a, ($0060)
        cp $01
        jp c, BADARG
        cp $03
        jp nc, BADARG
        call L_FBE3
        ld a, h
        or a
        jp nz, WOT
        ld a, l
        call L_FB43
        cp $0C
        jr nz, L_FA93
        ld a, ($0060)
        cp $01
        jp nz, BADARG
        jp SELCASS


L_FA93:
        cp $0D
        jp nz, WOT
        call SELSER
        ld a, ($0060)
        cp $01
        ret z
        ld hl, BAUDTAB

L_FAA4:
        ld c, (hl)
        inc hl
        ld b, (hl)
        inc hl
        ld a, b
        or c
        jp z, WOT
        ld a, b
        cp d
        jr nz, L_FAB5
        ld a, c
        cp e
        jr z, L_FAB9

L_FAB5:
        inc hl
        inc hl
        jr L_FAA4


L_FAB9:
        ld c, (hl)
        inc hl
        ld b, (hl)
        ld ($003B), bc
        jp SELSER


CMD_L:
        ld a, ($0060)
        cp $02
        jp nc, BADARG
        or a
        jr z, L_FAD4
        ld hl, ($0061)
        ld ($003D), hl

L_FAD4:
        ld hl, ($003D)
        call L_FBC5
        call L_FB27
        ret


CMD_O:
        ld a, ($0060)
        cp $02
        jp nz, BADARG
        call L_FBE3
        ld a, d
        or a
        jp nz, WOT
        ld b, h
        ld c, l
        out (c), e
        ret


CMD_Q:
        ld a, ($0060)
        cp $01
        jp nz, BADARG
        call L_FBE3
        ld b, h
        ld c, l
        in a, (c)
        call L_FBCC
        jp L_FB27


CMD_B:
        ;; ===================================
        if RPMVER = 20
        ld a, ($0060)
        endif
        if RPMVER = 21
        ld a, ($0060)
        endif
        if RPMVER = 23
        call L_FFEF
        endif
        ;; ===================================
        or a
        jp nz, BADARG
        jp L_FC0E


L_FB12:
        inc de

L_FB13:
        ld a, (de)
        cp $20
        jr z, L_FB12
        cp $09
        jr z, L_FB12
        cp $2C
        jr z, L_FB12
        or a
        ret


PRS09:
        ld c, $09               ; DE=string address, terminated by $. CP/M routine 9: print string.
        call L_0005

L_FB27:
        ld e, $0D
        call COUT02
        ld e, $0A

COUT02:
        ld c, $02               ; CP/M routine 2: console output.
        jp L_0005


L_FB33:
        ld e, $20
        jr COUT02


L_FB37:
        push bc
        call L_FB33
        pop bc
        djnz L_FB37
        ret


L_FB3F:
        ld e, $22
        jr COUT02


L_FB43:
        cp $61
        ret c
        cp $7B
        ret nc
        sub $20
        ret


L_FB4C:
        ld de, $007F
        ld a, $7E
        ld (de), a
        ld c, $0A
        call L_0005
        call L_FB27
        ld hl, $0080
        ld e, (hl)
        ld d, $00
        add hl, de
        inc hl
        ld (hl), $00
        ld de, $0081
        ret


L_FB68:
        ld bc, $0060            ; point to argument count
        xor a                   ; 
        ld (bc), a              ; set it to 0

L_FB6D:
        call L_FB87             ; 
        ret c                   ; 
        ld a, (hl)              ; 
        or a                    ; 
        ret z                   ; 
        inc hl                  ; 
        inc bc                  ; 
        ld a, (hl)              ; 
        ld (bc), a              ; 
        inc hl                  ; 
        inc bc                  ; 
        ld a, (hl)              ; 
        ld (bc), a              ; 
        ld hl, $0060            ; point to argument count
        inc (hl)                ; increment
        ld a, (hl)              ; get argument count
        cp $0B                  ; max number we're prepared to look for??
        jr c, L_FB6D            ; go back for more
        scf                     ; 
        ret                     ; return with carry set


L_FB87:
        call L_FB13
        ld hl, L_0000
        ld ($005E), hl
        xor a
        ld hl, $005D
        ld (hl), a

L_FB95:
        ld a, (de)
        or a
        ret z
        cp $20
        ret z
        cp $09
        ret z
        cp $2C
        ret z
        call L_FB43
        sub $30
        ret c
        cp $0A
        jr c, L_FBB6
        sub $07
        cp $0A
        ret c
        cp $10
        jr c, L_FBB6
        scf
        ret


L_FBB6:
        inc de
        inc (hl)
        inc hl
        rld
        inc hl
        rld
        dec hl
        dec hl
        jr z, L_FB95
        dec de
        scf
        ret


L_FBC5:
        ld a, h
        push hl
        call L_FBCC
        pop hl
        ld a, l

L_FBCC:
        push af
        rra
        rra
        rra
        rra
        call L_FBD5
        pop af

L_FBD5:
        and $0F
        add a, $90
        daa
        adc a, $40
        daa
        ld e, a
        ld c, $02
        jp L_0005


L_FBE3:
        ld hl, ($0061)
        ld de, ($0063)
        ld bc, ($0065)
        ret


XFBEF:
        ld de, MSG17
        ld c, $09
        call L_0005
        pop hl
        dec hl
        call L_FBC5
        jp L_0000


CHKDSK:
        ld a, $55
        out ($E1), a

L_FC03:
        ;; ===================================
        if RPMVER = 20
        ld de, MSGNODSK
        endif
        if RPMVER = 21
        ld de, MSGNODSK
        endif
        if RPMVER = 23
        dec a
        jr nz, L_FC03
        endif
        ;; ===================================

        ld hl, L_0000
        in a, ($E1)
        cp $55
        ret


L_FC0E: call CHKDSK

        ;; ===================================
        if RPMVER = 20
        jr nz, PRS09I1
        ld a, $D0
        call L_FC8C
        ld a, $01
        out ($E4), a
        ld a, $5B
        endif
        if RPMVER = 21
        jr nz, PRS09I1
        ld a, $D0
        call L_FC8C
        ld a, $01
        out ($E4), a
        ld a, $5B
        endif
        if RPMVER = 23
        ld de, MSGNODSK
        jr nz, PRS09I1
        ld a, $D0
        call L_FC8C
        call L_FFDE
        endif
        ;; ===================================

        call L_FC8C
        in a, ($E0)
        ld b, a
        ld c, $00

L_FC26:
        in a, ($E0)
        xor b
        or c
        and $02
        ld c, a
        in a, ($E0)
        rlca
        rlca
        cpl
        and c
        jr nz, L_FC3D
        dec hl
        ld a, h
        or l
        jr nz, L_FC26

PRS09I1:
        jp PRS09


L_FC3D:
        ld a, $0B               ; Load boot sector..
        call L_FC8C             ; 
        ;; ===================================
        if RPMVER = 20
        xor a
        out ($E2), a
        endif
        if RPMVER = 21
        xor a
        out ($E2), a
        endif
        if RPMVER = 23
        nop                     ; 
        nop                     ; 
        nop                     ; 
        endif
        ;; ===================================

        ld a, $88               ; 
        out ($E0), a            ; 
        ld hl, $0080            ; destination of boot sector
        ld c, $E4               ; 
        ld b, $80               ; load 128 bytes

L_FC50:
        in a, (c)               ; data available?
        jr z, L_FC50            ; no so wait
        in a, ($E3)             ; get data byte
        ld (hl), a              ; store
        inc hl                  ; next
        djnz L_FC50             ; loop for all 128 bytes

L_FC5A:
        in a, (c)               ; but that isn't the whole of the sector..
        jr z, L_FC5A            ; so loop until next byte
        in a, ($E3)             ; fetch and discard data
        jp m, L_FC5A            ; until command complete (ie whole sector processed)
        in a, ($E0)             ; ??status
        or a                    ; 
        ld de, MSGBAD           ; bad disk.. abort?
        jr nz, PRS09I1          ; 
        ld hl, ($0080)          ; expect first 2 bytes to contain magic value GG
        ld de, $4747            ; 
        sbc hl, de              ; 
        ld de, MSGINV           ; 
        jr nz, PRS09I1          ; not the right disk for this system.. abort?
        ld de, MSGBOOT          ; 
        call PRS09I1            ; announce that we're booting in case we die/hang in the attempt
        ld de, L_0000           ; 
        ld hl, $0080            ; 
        ld bc, $0080            ; 
        ldir                    ; copy the boot sector code from $80 to $0
        jp L_0002               ; and jump to it (not the GG, but to address 2)


L_FC8C:
        out ($E0), a
        ld a, $0A

L_FC90:
        dec a
        jr nz, L_FC90

L_FC93:
        in a, ($E0)
        rrca
        jr c, L_FC93
        ret


MSGNODSK:
        defm "No disk$"

MSGBAD:
        defm "Bad disk$"

MSGINV:
        defm "Wrong disk$"

MSGBOOT:
        defm "Executing boot$"

CONST:
        ld a, ($0045)
        or a
        jr nz, L_FCDC
        ld a, ($0040)
        or a
        jr nz, L_FCDC
        call L_FE77
        jr c, L_FCD7
        xor a
        ret


L_FCD7:
        or a
        ret z
        ld ($0040), a

L_FCDC:
        ld a, $FF
        ret


CONIN:
        ld a, ($0045)
        or a
        jr z, L_FCFE
        ld hl, ($0046)
        dec hl
        ld e, a
        ld d, $00
        add hl, de
        ld a, (hl)
        cp $0D
        jr nz, L_FCF9
        xor a
        ld ($0045), a
        ld a, $0D
        ret


L_FCF9:
        ld hl, $0045
        inc (hl)
        ret


L_FCFE:
        ld a, ($0040)
        or a
        jr nz, L_FD0D
        call L_FF41
        call L_FE85
        call L_FF68

L_FD0D:
        ld c, a
        xor a
        ld ($0040), a
        ld a, c
        ld hl, $0003
        bit 0, (hl)
        ret z
        ld hl, $004C
        cp (hl)
        ret nz
        call L_FF47

L_FD21:
        call L_FE85
        cp $03
        jr nz, L_FD32
        ld hl, ($0046)
        ld (hl), $03
        inc hl
        ld (hl), $0D
        jr L_FD5A


L_FD32:
        ld hl, $004D
        cp (hl)
        jr nz, L_FD43
        call L_FE10
        ld a, $0D
        ld hl, ($0046)
        ld (hl), a
        jr L_FD5A


L_FD43:
        call PUTIVC
        cp $0D
        jr nz, L_FD21
        call L_FF36
        ld de, ($0046)

L_FD51:
        call GETIVC
        ld (de), a
        inc de
        cp $0D
        jr nz, L_FD51

L_FD5A:
        call L_FF68
        ld a, $01
        ld ($0045), a
        ld hl, ($0046)
        inc hl
        ld a, (hl)
        dec hl
        cp $3E
        jr nz, L_FD79
        ld a, (hl)
        cp $41
        jr c, L_FD79
        cp $5B
        jr nc, L_FD79
        ld a, $03
        jr L_FD89


L_FD79:
        ld a, (hl)
        cp $2A
        jr z, L_FD87
        cp $2D
        jr z, L_FD87
        cp $23
        jp nz, CONIN

L_FD87:
        ld a, $02

L_FD89:
        ld ($0045), a

L_FD8C:
        dec a
        jp z, CONIN
        push af
        ld a, $1D
        call PUTIVC
        pop af
        jr L_FD8C


CONOU:
        ld a, c
        push hl
        ld hl, $0003
        bit 0, (hl)
        pop hl
        jr z, L_FDC0
        cp $0C
        jr nz, L_FDAE
        ld a, $0D
        call L_FDAE
        ld a, $0A

L_FDAE:
        jp PUTIVC


LIST:
        call L_FDD4             ; 
        call L_FDFD             ; 
        ld a, c                 ; 
        ld hl, $0003            ; point to IOBYTE
        bit 7, (hl)             ; 0 -> serial printer, 1 -> parallel printer
        jp nz, L_FEA0           ; parallel printer

L_FDC0:
        call L_FE70             ; ?serial printer
        ld a, c
        call L_FE0B
        jp SOUT


PUNCH:
        ld a, c                 ; Output character in C to UART
        jp SOUT


READ:
        call SIN                ; Wait for character from UART. Return character in A
        jr nc, READ
        ret


L_FDD4:
        ld a, c
        cp $0C
        ret nz
        pop hl
        ld ($0043), hl
        ld a, ($0041)
        or a
        jr nz, L_FDE9
        ld a, ($0042)
        ld ($0041), a
        ret


L_FDE9:
        ld c, $0D
        ld hl, XFDF3
        push hl
        ld hl, ($0043)
        jp (hl)


XFDF3:
        ld c, $0A
        ld hl, $FDDC
        push hl
        ld hl, ($0043)
        jp (hl)


L_FDFD:
        ld a, c
        cp $0A
        ret nz
        ld a, ($0041)
        or a
        ret z
        dec a
        ld ($0041), a
        ret


L_FE0B:
        or a
        ret pe
        xor $80
        ret


L_FE10:
        call L_FE51
        ld b, $50
        ld a, $5F

L_FE17:
        call L_FE58
        djnz L_FE17
        call L_FE51
        call L_FF05
        ld hl, L_0000

L_FE25:
        call L_FF1F
        call L_FF36

L_FE2B:
        call GETIVC
        cp $0D
        jr z, L_FE37
        call L_FE58
        jr L_FE2B


L_FE37:
        call L_FE51
        inc h
        ld a, h
        cp $19
        jr nz, L_FE25
        ld hl, ($0048)
        call L_FF1F
        ld b, $50
        ld a, $7E

L_FE4A:
        call L_FE58
        djnz L_FE4A
        jr L_FE51


L_FE51:
        ld a, $0D
        call L_FE58
        ld a, $0A

L_FE58:
        push af
        push bc
        push de
        push hl
        ld c, a
        call SYS5
        pop hl
        pop de
        pop bc
        pop af
        ret


SOUT:
        push af

L_FE66:
        in a, ($BD)
        bit 5, a
        jr z, L_FE66
        pop af
        out ($B8), a
        ret


L_FE70:
        in a, ($BE)
        bit 4, a
        jr z, L_FE70
        ret


L_FE77:
        call L_FEB6
        ret c
        call L_FECF
        ret c
        call SIN
        res 7, a
        ret


L_FE85:
        call L_FE77
        jr nc, L_FE85
        ret


L_FE8B:
        call L_FE91
        jr nc, L_FE8B
        ret


L_FE91:
        call L_FEB6
        ret c
        call L_FECF
        ret c

SIN:
        in a, ($BD)             ; check UART for input character. Return C and character in A or NC if no character
        rra
        ret nc
        in a, ($B8)
        ret


L_FEA0:
        push af

L_FEA1:
        in a, ($B4)
        rra
        jr c, L_FEA1
        pop af
        push af
        out ($B5), a
        nop
        ld a, $FD
        out ($B4), a
        nop
        ld a, $FF
        out ($B4), a
        pop af
        ret


L_FEB6:
        ld a, ($0003)           ; get IOBYTE
        and $02                 ; CPU card with keyboard port?
        ret nz                  ; no local keyboard port; return
        push de                 ; ?Scan of GM813 serial port
        ld a, ($003F)           ; 
        ld e, a                 ; 
        in a, ($B0)             ; 
        xor e                   ; 
        jr z, L_FECD            ; 
        xor e                   ; 
        ld ($003F), a           ; 
        rlca                    ; 
        or a                    ; 
        rra                     ; 

L_FECD:
        pop de                  ; 
        ret                     ; 


L_FECF:
        ld a, ($0003)           ; load IOBYTE
        and $01                 ; check Video Card bit
        ret z                   ; no video card -> do nothing
        ld a, $1B               ; 
        call PUTIVC             ; 
        ld a, $6B               ; 
        call PUTIVC             ; 
        call GETIVC             ; 
        or a                    ; 
        ret z                   ; 
        ld a, $1B               ; 
        call PUTIVC             ; 
        ld a, $4B               ; 
        call PUTIVC             ; 
        call GETIVC             ; 
        scf                     ; 
        ret                     ; 


PUTIVC:
        push af

L_FEF4:
        in a, ($B2)
        rra
        jr c, L_FEF4
        pop af
        out ($B1), a
        ret


GETIVC:
        in a, ($B2)
        rla
        jr c, GETIVC
        in a, ($B1)
        ret


L_FF05:
        ld a, $1B               ; 1b 3f = Get cursor co-ordinates
        call PUTIVC             ; 
        ld a, $3F               ; 
        call PUTIVC             ; 
        call GETIVC             ; 
        ld ($0049), a           ; store row
        call GETIVC             ; 
        ld ($0048), a           ; store column
        call GETIVC             ; 
        ret                     ; A holds character at cursor position


L_FF1F:
        ld a, $1B               ; 1b 3d = Set cursor position (screen top-left is 0,0)
        call PUTIVC             ; H holds row, L holds col
        ld a, $3D               ; 
        call PUTIVC             ; 
        ld a, h                 ; 
        add a, $20              ; row of N is sent as N+0x20
        call PUTIVC             ; 
        ld a, l                 ; 
        add a, $20              ; col of N is sent as N+0x20
        call PUTIVC             ; 
        ret


L_FF36:
        ld a, $1B               ; 1b 5a = Get line where cursor is currently positioned
        call PUTIVC             ; strip trailing blanks
        ld a, $5A               ; line is terminated by CR
        call PUTIVC             ; 
        ret                     ; 


L_FF41:
        push de                 ; 
        ld de, $4808            ; cursor type ??decode
        jr L_FF4B               ; 


L_FF47:
        push de                 ; 
        ld de, $4009            ; cursor type ??decode

L_FF4B:
        push af                 ; 
        ld a, ($0003)           ; get IOBYTE
        and $01                 ; check Video Card bit
        jr z, L_FF65            ; no video card -> skip
        ld a, $1B               ; 
        call PUTIVC             ; 
        ld a, $59               ; 1B 59 = Define Cursor Type
        call PUTIVC             ; 
        ld a, d                 ; CRTC register 10
        call PUTIVC             ; 
        ld a, e                 ; CRTC register 11
        call PUTIVC             ; 

L_FF65:
        pop af                  ; 
        pop de                  ; 
        ret                     ; 


L_FF68:
        push de                 ; 
        ld de, $0808            ; Cursor type ??decode
        jr L_FF4B               ; 


SELCASS:
        ld a, $03               ; 
        out ($BC), a            ; enable UART for cassette, switch TR1 on for motor control
        ld hl, $0068            ; baud rate divisor for 1200bd - fixed value for cassette
        jp L_FF7F               ; 


SELSER:
        ld a, $07               ; 
        out ($BC), a            ; enable UART for serial port, switch TR1 off
        ld hl, ($003B)          ; current selected baud rate divider for serial

L_FF7F:
        ld a, $83               ; allow access to UART baud rate divisor registers
        out ($BB), a            ; 
        ld a, h                 ; 
        out ($B9), a            ; set baud rate divisor hi
        ld a, l                 ; 
        out ($B8), a            ; set baud rate divisor lo
        ld a, $03               ; 
        out ($BB), a            ; restore access to UART data/interrupt registers
        ret                     ; 

;;; Lookup table baud rate -> divisor terminated by 0000

BAUDTAB:
        defw $0050, $09C4
        defw $0075, $0683
        defw $0110, $0470
        defw $0134, $03A1
        defw $0150, $0341
        defw $0300, $01A1
        defw $0600, $00D0
        defw $1200, $0068
        defw $1800, $0045
        defw $2000, $003F
        defw $2400, $0034
        defw $3600, $0023
        defw $4800, $001A
        defw $7200, $0011
        defw $9600, $000D
        defw $192F, $0007
        defw $384F, $0003
        defw $560F, L_0002
        defw L_0000

L_FFD8:
        defb $FF, $FF, $FF

L_FFDB:
        defb $FF, $FF, $FF

        ;; ===================================
        if RPMVER = 23

L_FFDE: ld a, ($0061)
        or a
        jr nz, L_FFE5
        inc a
L_FFE5: out ($E4), a
        ld a, ($0062)
        out ($E2), a
        ld a, $5B
        ret


L_FFEF: ld a, ($0060)
        or a
        jr nz, L_FFFB
        ld hl, L_0000
        ld ($0061), hl
L_FFFB: cp $02
        ret nc
        xor a
        ret


        else ;; ++++++++++++++++++++++++++++++
        defb $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        endif
        ;; ===================================


; $F000 CCCCCCCCCWWBBBWWBWWBWWBWWBWWBWWBWWBWWCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCBBBB
; $F050 BBBBBBBBBBBBBBBBBBBBBBBBBBCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $F0A0 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $F0F0 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $F140 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $F190 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW
; $F1E0 WWWWWWWWWCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $F230 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $F280 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $F2D0 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $F320 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $F370 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $F3C0 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $F410 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $F460 BBCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $F4B0 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $F500 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $F550 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $F5A0 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $F5F0 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $F640 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $F690 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $F6E0 CCCCCCCCCCCCCCCCCCCCBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $F730 BBBBBBBBBBBBBBBCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $F780 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $F7D0 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $F820 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $F870 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $F8C0 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $F910 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $F960 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $F9B0 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $FA00 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $FA50 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $FAA0 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $FAF0 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $FB40 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $FB90 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $FBE0 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $FC30 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $FC80 CCCCCCCCCCCCCCCCCCCCCCCCCBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBCCCCCCCCCCCC
; $FCD0 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $FD20 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $FD70 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $FDC0 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $FE10 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $FE60 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $FEB0 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $FF00 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $FF50 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCWWWWWWWWWWWWWWWWWW
; $FFA0 WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWC--C--CCCCCCCCCCCCCCCCCC
; $FFF0 CCCCCCCCCCCCCCC

; Labels
;
; $0000 => L_0000          BADARG   => $F7AD
; $0002 => L_0002          BAUDTAB  => $FF8E
; $0005 => L_0005          CBOOT    => $F000
; $0038 => L_0038          CHKDSK   => $FBFF
; $F000 => CBOOT           CMD_B    => $FB08
; $F003 => WBOOT           CMD_C    => $F9EF
; $F006 => XF006           CMD_D    => $F8A2
; $F009 => UARTDIV         CMD_F    => $FA0C
; $F00B => IOBYTE          CMD_G    => $F9D1
; $F00C => LINPPAG         CMD_L    => $FAC3
; $F00D => XF00D           CMD_O    => $FADE
; $F025 => SYS0            CMD_P    => $FA29
; $F02A => L_F02A          CMD_Q    => $FAF3
; $F02F => L_F02F          CMD_RWI  => $F7B8
; $F034 => L_F034          CMD_S    => $F932
; $F039 => SYS5            CMD_U    => $FA6B
; $F03E => SYS4            CMDLOP   => $F745
; $F043 => L_F043          CMDRET   => $F1E9
; $F046 => L_F046          CONIN    => $FCDF
; $F04C => MSGSIZ          CONOU    => $FD99
; $F06A => START           CONST    => $FCC4
; $F06C => L_F06C          COUT02   => $FB2E
; $F071 => L_F071          DUMMY    => $F1F2
; $F093 => L_F093          GETIVC   => $FEFD
; $F09F => L_F09F          IOBYTE   => $F00B
; $F0AB => L_F0AB          L_0000   => $0000
; $F0FE => L_F0FE          L_0002   => $0002
; $F10E => L_F10E          L_0005   => $0005
; $F138 => L_F138          L_0038   => $0038
; $F152 => L_F152          L_F02A   => $F02A
; $F188 => L_F188          L_F02F   => $F02F
; $F1B3 => SYSTAB          L_F034   => $F034
; $F1E9 => CMDRET          L_F043   => $F043
; $F1F2 => DUMMY           L_F046   => $F046
; $F1F3 => L_F1F3          L_F06C   => $F06C
; $F1FE => L_F1FE          L_F071   => $F071
; $F20C => L_F20C          L_F093   => $F093
; $F21B => L_F21B          L_F09F   => $F09F
; $F238 => L_F238          L_F0AB   => $F0AB
; $F23B => L_F23B          L_F0FE   => $F0FE
; $F23E => L_F23E          L_F10E   => $F10E
; $F257 => L_F257          L_F138   => $F138
; $F26D => L_F26D          L_F152   => $F152
; $F273 => L_F273          L_F188   => $F188
; $F283 => SYS2            L_F1F3   => $F1F3
; $F288 => L_F288          L_F1FE   => $F1FE
; $F295 => L_F295          L_F20C   => $F20C
; $F29D => L_F29D          L_F21B   => $F21B
; $F2A2 => L_F2A2          L_F238   => $F238
; $F2AA => L_F2AA          L_F23B   => $F23B
; $F2B9 => L_F2B9          L_F23E   => $F23E
; $F2C3 => L_F2C3          L_F257   => $F257
; $F2D0 => SYS10           L_F26D   => $F26D
; $F2DE => L_F2DE          L_F273   => $F273
; $F2E0 => L_F2E0          L_F288   => $F288
; $F302 => L_F302          L_F295   => $F295
; $F310 => L_F310          L_F29D   => $F29D
; $F31F => L_F31F          L_F2A2   => $F2A2
; $F32E => L_F32E          L_F2AA   => $F2AA
; $F333 => L_F333          L_F2B9   => $F2B9
; $F343 => L_F343          L_F2C3   => $F2C3
; $F34E => L_F34E          L_F2DE   => $F2DE
; $F352 => L_F352          L_F2E0   => $F2E0
; $F35A => L_F35A          L_F302   => $F302
; $F36A => L_F36A          L_F310   => $F310
; $F379 => L_F379          L_F31F   => $F31F
; $F385 => L_F385          L_F32E   => $F32E
; $F388 => L_F388          L_F333   => $F333
; $F39B => L_F39B          L_F343   => $F343
; $F39F => L_F39F          L_F34E   => $F34E
; $F3A6 => SYS1            L_F352   => $F352
; $F3AB => SYS3            L_F35A   => $F35A
; $F3B0 => SYS6            L_F36A   => $F36A
; $F3BB => L_F3BB          L_F379   => $F379
; $F3C7 => SYS7            L_F385   => $F385
; $F3CC => SYS8            L_F388   => $F388
; $F3D1 => SYS9            L_F39B   => $F39B
; $F3D7 => SYS11           L_F39F   => $F39F
; $F3DA => L_F3DA          L_F3BB   => $F3BB
; $F3DE => MSG2            L_F3DA   => $F3DA
; $F3E6 => MSG3            L_F493   => $F493
; $F3EE => MSG4            L_F4B1   => $F4B1
; $F3F5 => MSG5            L_F4B4   => $F4B4
; $F405 => MSG6            L_F4CB   => $F4CB
; $F417 => MSG7            L_F4F2   => $F4F2
; $F425 => MSG8            L_F4F8   => $F4F8
; $F428 => MSG9            L_F500   => $F500
; $F436 => MSG10           L_F50F   => $F50F
; $F44A => MSGIO           L_F51B   => $F51B
; $F457 => MSGMEM          L_F53B   => $F53B
; $F462 => SYS15           L_F545   => $F545
; $F483 => SYS16           L_F569   => $F569
; $F493 => L_F493          L_F57C   => $F57C
; $F4AE => SYS20           L_F587   => $F587
; $F4B1 => L_F4B1          L_F595   => $F595
; $F4B4 => L_F4B4          L_F59D   => $F59D
; $F4CB => L_F4CB          L_F5A9   => $F5A9
; $F4F2 => L_F4F2          L_F5BA   => $F5BA
; $F4F8 => L_F4F8          L_F5D1   => $F5D1
; $F500 => L_F500          L_F5DD   => $F5DD
; $F50F => L_F50F          L_F5EF   => $F5EF
; $F51B => L_F51B          L_F5FC   => $F5FC
; $F53B => L_F53B          L_F623   => $F623
; $F545 => L_F545          L_F62E   => $F62E
; $F569 => L_F569          L_F63F   => $F63F
; $F57C => L_F57C          L_F652   => $F652
; $F587 => L_F587          L_F653   => $F653
; $F595 => L_F595          L_F657   => $F657
; $F59D => L_F59D          L_F660   => $F660
; $F5A9 => L_F5A9          L_F67C   => $F67C
; $F5BA => L_F5BA          L_F69A   => $F69A
; $F5CA => SYS21           L_F69F   => $F69F
; $F5D1 => L_F5D1          L_F6AB   => $F6AB
; $F5DD => L_F5DD          L_F6B9   => $F6B9
; $F5EF => L_F5EF          L_F6C4   => $F6C4
; $F5FC => L_F5FC          L_F6CF   => $F6CF
; $F623 => L_F623          L_F6ED   => $F6ED
; $F62E => L_F62E          L_F6EE   => $F6EE
; $F63F => L_F63F          L_F73F   => $F73F
; $F64A => SYS13           L_F7BD   => $F7BD
; $F64D => SYS26           L_F7D0   => $F7D0
; $F652 => L_F652          L_F7E4   => $F7E4
; $F653 => L_F653          L_F7EB   => $F7EB
; $F657 => L_F657          L_F7FA   => $F7FA
; $F660 => L_F660          L_F804   => $F804
; $F67C => L_F67C          L_F832   => $F832
; $F69A => L_F69A          L_F857   => $F857
; $F69F => L_F69F          L_F85A   => $F85A
; $F6AB => L_F6AB          L_F87E   => $F87E
; $F6B9 => L_F6B9          L_F886   => $F886
; $F6C4 => L_F6C4          L_F88E   => $F88E
; $F6CF => L_F6CF          L_F8B6   => $F8B6
; $F6E5 => PRMSG           L_F8BC   => $F8BC
; $F6ED => L_F6ED          L_F8CC   => $F8CC
; $F6EE => L_F6EE          L_F8E4   => $F8E4
; $F6F4 => MSGRDY          L_F8ED   => $F8ED
; $F707 => MSGWOT          L_F8F9   => $F8F9
; $F70D => MSGCMD          L_F8FB   => $F8FB
; $F71D => MSGARG          L_F928   => $F928
; $F731 => MSG17           L_F93A   => $F93A
; $F73F => L_F73F          L_F93D   => $F93D
; $F745 => CMDLOP          L_F966   => $F966
; $F7AD => BADARG          L_F974   => $F974
; $F7B2 => WOT             L_F980   => $F980
; $F7B5 => PRS09I2         L_F992   => $F992
; $F7B8 => CMD_RWI         L_F996   => $F996
; $F7BD => L_F7BD          L_F9A3   => $F9A3
; $F7D0 => L_F7D0          L_F9AF   => $F9AF
; $F7E4 => L_F7E4          L_F9B7   => $F9B7
; $F7EB => L_F7EB          L_F9CA   => $F9CA
; $F7FA => L_F7FA          L_F9CB   => $F9CB
; $F804 => L_F804          L_F9E6   => $F9E6
; $F832 => L_F832          L_FA09   => $FA09
; $F857 => L_F857          L_FA1D   => $FA1D
; $F85A => L_F85A          L_FA3B   => $FA3B
; $F87E => L_F87E          L_FA42   => $FA42
; $F886 => L_F886          L_FA49   => $FA49
; $F88E => L_F88E          L_FA57   => $FA57
; $F8A2 => CMD_D           L_FA5D   => $FA5D
; $F8B6 => L_F8B6          L_FA93   => $FA93
; $F8BC => L_F8BC          L_FAA4   => $FAA4
; $F8CC => L_F8CC          L_FAB5   => $FAB5
; $F8E4 => L_F8E4          L_FAB9   => $FAB9
; $F8ED => L_F8ED          L_FAD4   => $FAD4
; $F8F9 => L_F8F9          L_FB12   => $FB12
; $F8FB => L_F8FB          L_FB13   => $FB13
; $F928 => L_F928          L_FB27   => $FB27
; $F932 => CMD_S           L_FB33   => $FB33
; $F93A => L_F93A          L_FB37   => $FB37
; $F93D => L_F93D          L_FB3F   => $FB3F
; $F966 => L_F966          L_FB43   => $FB43
; $F974 => L_F974          L_FB4C   => $FB4C
; $F980 => L_F980          L_FB68   => $FB68
; $F992 => L_F992          L_FB6D   => $FB6D
; $F996 => L_F996          L_FB87   => $FB87
; $F9A3 => L_F9A3          L_FB95   => $FB95
; $F9AF => L_F9AF          L_FBB6   => $FBB6
; $F9B7 => L_F9B7          L_FBC5   => $FBC5
; $F9CA => L_F9CA          L_FBCC   => $FBCC
; $F9CB => L_F9CB          L_FBD5   => $FBD5
; $F9D1 => CMD_G           L_FBE3   => $FBE3
; $F9E6 => L_F9E6          L_FC03   => $FC03
; $F9EF => CMD_C           L_FC0E   => $FC0E
; $FA09 => L_FA09          L_FC26   => $FC26
; $FA0C => CMD_F           L_FC3D   => $FC3D
; $FA1D => L_FA1D          L_FC50   => $FC50
; $FA29 => CMD_P           L_FC5A   => $FC5A
; $FA3B => L_FA3B          L_FC8C   => $FC8C
; $FA42 => L_FA42          L_FC90   => $FC90
; $FA49 => L_FA49          L_FC93   => $FC93
; $FA57 => L_FA57          L_FCD7   => $FCD7
; $FA5D => L_FA5D          L_FCDC   => $FCDC
; $FA6B => CMD_U           L_FCF9   => $FCF9
; $FA93 => L_FA93          L_FCFE   => $FCFE
; $FAA4 => L_FAA4          L_FD0D   => $FD0D
; $FAB5 => L_FAB5          L_FD21   => $FD21
; $FAB9 => L_FAB9          L_FD32   => $FD32
; $FAC3 => CMD_L           L_FD43   => $FD43
; $FAD4 => L_FAD4          L_FD51   => $FD51
; $FADE => CMD_O           L_FD5A   => $FD5A
; $FAF3 => CMD_Q           L_FD79   => $FD79
; $FB08 => CMD_B           L_FD87   => $FD87
; $FB12 => L_FB12          L_FD89   => $FD89
; $FB13 => L_FB13          L_FD8C   => $FD8C
; $FB22 => PRS09           L_FDAE   => $FDAE
; $FB27 => L_FB27          L_FDC0   => $FDC0
; $FB2E => COUT02          L_FDD4   => $FDD4
; $FB33 => L_FB33          L_FDE9   => $FDE9
; $FB37 => L_FB37          L_FDFD   => $FDFD
; $FB3F => L_FB3F          L_FE0B   => $FE0B
; $FB43 => L_FB43          L_FE10   => $FE10
; $FB4C => L_FB4C          L_FE17   => $FE17
; $FB68 => L_FB68          L_FE25   => $FE25
; $FB6D => L_FB6D          L_FE2B   => $FE2B
; $FB87 => L_FB87          L_FE37   => $FE37
; $FB95 => L_FB95          L_FE4A   => $FE4A
; $FBB6 => L_FBB6          L_FE51   => $FE51
; $FBC5 => L_FBC5          L_FE58   => $FE58
; $FBCC => L_FBCC          L_FE66   => $FE66
; $FBD5 => L_FBD5          L_FE70   => $FE70
; $FBE3 => L_FBE3          L_FE77   => $FE77
; $FBEF => XFBEF           L_FE85   => $FE85
; $FBFF => CHKDSK          L_FE8B   => $FE8B
; $FC03 => L_FC03          L_FE91   => $FE91
; $FC0E => L_FC0E          L_FEA0   => $FEA0
; $FC26 => L_FC26          L_FEA1   => $FEA1
; $FC3A => PRS09I1         L_FEB6   => $FEB6
; $FC3D => L_FC3D          L_FECD   => $FECD
; $FC50 => L_FC50          L_FECF   => $FECF
; $FC5A => L_FC5A          L_FEF4   => $FEF4
; $FC8C => L_FC8C          L_FF05   => $FF05
; $FC90 => L_FC90          L_FF1F   => $FF1F
; $FC93 => L_FC93          L_FF36   => $FF36
; $FC99 => MSGNODSK        L_FF41   => $FF41
; $FCA1 => MSGBAD          L_FF47   => $FF47
; $FCAA => MSGINV          L_FF4B   => $FF4B
; $FCB5 => MSGBOOT         L_FF65   => $FF65
; $FCC4 => CONST           L_FF68   => $FF68
; $FCD7 => L_FCD7          L_FF7F   => $FF7F
; $FCDC => L_FCDC          L_FFD8   => $FFD8
; $FCDF => CONIN           L_FFDB   => $FFDB
; $FCF9 => L_FCF9          L_FFDE   => $FFDE
; $FCFE => L_FCFE          L_FFE5   => $FFE5
; $FD0D => L_FD0D          L_FFEF   => $FFEF
; $FD21 => L_FD21          L_FFFB   => $FFFB
; $FD32 => L_FD32          LINPPAG  => $F00C
; $FD43 => L_FD43          LIST     => $FDB1
; $FD51 => L_FD51          MSG10    => $F436
; $FD5A => L_FD5A          MSG17    => $F731
; $FD79 => L_FD79          MSG2     => $F3DE
; $FD87 => L_FD87          MSG3     => $F3E6
; $FD89 => L_FD89          MSG4     => $F3EE
; $FD8C => L_FD8C          MSG5     => $F3F5
; $FD99 => CONOU           MSG6     => $F405
; $FDAE => L_FDAE          MSG7     => $F417
; $FDB1 => LIST            MSG8     => $F425
; $FDC0 => L_FDC0          MSG9     => $F428
; $FDCA => PUNCH           MSGARG   => $F71D
; $FDCE => READ            MSGBAD   => $FCA1
; $FDD4 => L_FDD4          MSGBOOT  => $FCB5
; $FDE9 => L_FDE9          MSGCMD   => $F70D
; $FDF3 => XFDF3           MSGINV   => $FCAA
; $FDFD => L_FDFD          MSGIO    => $F44A
; $FE0B => L_FE0B          MSGMEM   => $F457
; $FE10 => L_FE10          MSGNODSK => $FC99
; $FE17 => L_FE17          MSGRDY   => $F6F4
; $FE25 => L_FE25          MSGSIZ   => $F04C
; $FE2B => L_FE2B          MSGWOT   => $F707
; $FE37 => L_FE37          PRMSG    => $F6E5
; $FE4A => L_FE4A          PRS09    => $FB22
; $FE51 => L_FE51          PRS09I1  => $FC3A
; $FE58 => L_FE58          PRS09I2  => $F7B5
; $FE65 => SOUT            PUNCH    => $FDCA
; $FE66 => L_FE66          PUTIVC   => $FEF3
; $FE70 => L_FE70          READ     => $FDCE
; $FE77 => L_FE77          SELCASS  => $FF6E
; $FE85 => L_FE85          SELSER   => $FF78
; $FE8B => L_FE8B          SIN      => $FE99
; $FE91 => L_FE91          SOUT     => $FE65
; $FE99 => SIN             START    => $F06A
; $FEA0 => L_FEA0          SYS0     => $F025
; $FEA1 => L_FEA1          SYS1     => $F3A6
; $FEB6 => L_FEB6          SYS10    => $F2D0
; $FECD => L_FECD          SYS11    => $F3D7
; $FECF => L_FECF          SYS13    => $F64A
; $FEF3 => PUTIVC          SYS15    => $F462
; $FEF4 => L_FEF4          SYS16    => $F483
; $FEFD => GETIVC          SYS2     => $F283
; $FF05 => L_FF05          SYS20    => $F4AE
; $FF1F => L_FF1F          SYS21    => $F5CA
; $FF36 => L_FF36          SYS26    => $F64D
; $FF41 => L_FF41          SYS3     => $F3AB
; $FF47 => L_FF47          SYS4     => $F03E
; $FF4B => L_FF4B          SYS5     => $F039
; $FF65 => L_FF65          SYS6     => $F3B0
; $FF68 => L_FF68          SYS7     => $F3C7
; $FF6E => SELCASS         SYS8     => $F3CC
; $FF78 => SELSER          SYS9     => $F3D1
; $FF7F => L_FF7F          SYSTAB   => $F1B3
; $FF8E => BAUDTAB         UARTDIV  => $F009
; $FFD8 => L_FFD8          WBOOT    => $F003
; $FFDB => L_FFDB          WOT      => $F7B2
; $FFDE => L_FFDE          XF006    => $F006
; $FFE5 => L_FFE5          XF00D    => $F00D
; $FFEF => L_FFEF          XFBEF    => $FBEF
; $FFFB => L_FFFB          XFDF3    => $FDF3


; Check these calls manualy: $0038

