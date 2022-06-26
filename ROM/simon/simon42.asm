;;; SIMON version 4.2
;;;
;;; Source recreated by disassembly; all comments inferred from code inspection
;;;
;;; 2Kbyte ROM decoded at address $F000
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

L_0002: equ $0002
L_00E6: equ $00E6
L_00E9: equ $00E9
L_00EC: equ $00EC

;;; Ports for GM811/GM813 CPU board

KBD:    equ $B0                 ; keyboard - GM811 only

PIOADAT:equ $B4
PIOBDAT:equ $B5
PIOACTL:equ $B6
PIOBCTL:equ $B7

MMAP:   equ $FE                 ; memory mapper - GM813 only
PMOD:   equ $FF                 ; page mode     - GM813 only

UARTDAT:equ $B8                 ; data holding
UARTIE: equ $B9                 ; interrupt enable         UNUSED HERE
UARTII: equ $BA                 ; interrupt identification UNUSED HERE
UARTLC: equ $BB                 ; line control             UNUSED HERE
UARTMC: equ $BC                 ; modem control
UARTLS: equ $BD                 ; line status
UARTMS: equ $BE                 ; modem status


;;; Ports for IVC board
IVCDAT: equ $B1    ;data (r/w)
IVCSTA: equ $B2    ;status (ro)
IVCRST: equ $B3    ;reset (r/w)

;;; Ports for FDC board
FDCCMD: equ $E0    ;1793 command register
FDCSTA: equ $E0    ;1793 status register
FDCTRK: equ $E1    ;1793 track register
FDCSEC: equ $E2    ;1793 sector register
FDCDAT: equ $E3    ;1793 data register
FDCDRV: equ $E4    ;FDC card drive select port
SCSCTL: equ $E5    ;SCSI control lines - only on GM849
SCSDAT: equ $E6    ;SCSI data - only on GM849


        org $F000

;;; After reset, the ROM is decoded at 0 and throughout the address map. After the
;;; first write to port 0xFF, the ROM is only decoded at 0xFXXX. Before that write,
;;; there must be a jump to 0xFXXX. ROM can be disabled by setting port 0xBC[3]=1

;;; Documented entry points for user-accessible subroutines
COLD:   jp XCOLD
CHRIN:  jp XCHRIN
CHROUT: jp XCHROUT
P2HEX:  jp XP2HEX
P4HEX:  jp XP4HEX
SPACE:  jp XSPACE
CRLF:   jp XCRLF


MSG1:   defm "(C) dci software" ; TODO never referenced

MSG20:  defb $0D                ; printed by V (version) command
        defm "10-06-86 "        ; (falls through to print the GG CR also)

MSG19:  defm "GG"               ; magic compared with first 2 bytes of boot sector
        defb $0D, $00


XCOLD:  in a, (IVCRST)          ; reset IVC
        ld a, $01
        out ($E4), a            ; select drive 0/A
        ld d, $40               ; count ??of mapper pages to init??
L_F03B: ld bc, $F0FE            ; B=?? C= port for MMAP
        ld e, $0F               ; value?
L_F040: out (c), e              ; initialise memory mapper
        dec e
        ld a, b
        sub $10
        ld b, a
        jr nc, L_F040           ; continue
        dec d
        jr nz, L_F03B           ; 0x64 = 40
        ld a, $11               ; value?
        out (PMOD), a           ; page-mode register
        ld sp, L_00E6           ;
        call L_F1ED             ; Will execute at FXXX instead of 0XXX
                                ; BUT: how does the ROM get disabled so that the
                                ; stack at $000E6 can be used?
        ld a, i                 ; 
        ld a, $01               ; 
        push af                 ; wot??
        ld i, a                 ; 
        pop af                  ; 
        jr z, L_F063            ; 
        ld a, ($00EF)           ; 
L_F063: ld ($00EF), a           ; 
        push af                 ; 
        ld a, $F3               ; 
        out ($E5), a            ; e5
        ld a, $09
L_F06D: dec a
        jr nz, L_F06D
        ld a, $F7
        out ($E5), a
        ld hl, MSG8             ; clear screen, power-on message
        call PRS
        pop af
        jr nz, L_F0DD
        jp L_F14B


MSG2:   defm " while loading Boot sector"
        defb $00

MSG3:   defm " during System load"
        defb $00

MSG4:   defb $C0, $D2, $C5, $C1, $C4, $80, $C5, $D2, $D2, $CF, $D2, $C0, $00

MSG5:   defm " - Press any key to repeat<"
        defb $00


L_F0D8: ld hl, MSG2             ; (error) while loading Boot sector
        jr L_F0E0


L_F0DD: ld hl, MSG3             ; (error) during System load
L_F0E0: push hl
        ld hl, MSG4             ; ??
        call PRS
        pop hl
        call PRS
        ld hl, MSG5             ; press any key to repeat<
L_F0EE: call PRS
L_F0F1: call L_F2A6
        jr z, L_F0F8
        jr nc, L_F0F1
L_F0F8: call L_F2DF
        jr L_F14B


MSG15:  defb $1B, $2A           ; delete to end of line
        defm "<"
        defb $09, $80, $C9, $EE, $F3, $E5, $F2, $F4, $80, $C4, $E9, $F3, $EB, $80, $E9, $EE, $80, $E4, $F2, $E9, $F6, $E5, $80, $00

MSG16:  defb $A0                ;TODO no reference. 
        defm "<"
        defb $00


L_F11B: ld hl, MSG15
        call PRS
        ld a, ($00EF)
        ld b, $C0
L_F126: inc b
        rrca
        jr nc, L_F126
        ld a, b
        cp $C1
        jr z, L_F131
        sub $10
L_F131: call XCHROUT
        jp PRS


L_F137: call L_F11B
L_F13A: call L_F2A1
        call z, L_F11B
        call L_F2A6
        call L_F2DF
        call L_F2A6
        jr z, L_F13A
L_F14B: ld sp, L_00E6
        call L_F2A6
        jr z, L_F137
        inc a
        jr z, L_F15B
        call L_F3A0
        jr L_F16E


L_F15B: in a, (FDCSTA)
        bit 0, a
        jr nz, L_F15B
        ld a, $5B
        call CMD2FDC
        ld a, $0B
        call CMD2FDC
        call L_F1BA
L_F16E: or a
        jp nz, L_F0D8
        ld hl, ($0000)          ; get first 2 bytes from boot sector
        ld de, (MSG19)          ; "GG"
        or a
        sbc hl, de
        call z, L_F2E2          ; if good disk??
        ld a, ($00EF)
        jp z, L_0002            ; enter code loaded from boot sector (first 2 bytes is "magic" eg GG for Gemini)
        ld hl, MSG17            ; ??wot??
        jp L_F0EE


;;; TODO how is this used?
MSG17:  defb $09, $80, $C0, $CE, $EF, $80, $F2, $E5, $E3, $EF, $E7, $EE, $E9, $F3, $E1, $E2
        defb $EC, $E5, $80, $C3, $D0, $AF, $CD, $80, $F3, $F9, $F3, $F4, $E5, $ED, $80, $EF
        defb $EE, $80, $F4, $E8, $E9, $F3, $80, $E4, $E9, $F3, $EB, $C0, $80
        defm "<"
        defb $00


L_F1BA: ld a, $0B
        call CMD2FDC
        ld a, ($00EF)
        and $20
        jr z, L_F1C8
        ld a, $01
L_F1C8: out (FDCSEC), a
        ld hl, $0000
        ld c, FDCDRV            ; ?fast access to FDC data available?
        ld a, $88
        out (FDCCMD), a
        ld b, $80
        jr L_F1D7               ; why not fall through? need slight delay?


L_F1D7: in a, (c)               ; data?
        jr z, L_F1D7            ; no data
        in a, (FDCDAT)          ; get data
        ld (hl), a              ; store
        inc hl                  ; next location
        djnz L_F1D7             ; total of $80 (128) bytes
L_F1E1: in a, (c)               ; read and discard remaining bytes, if any
        jr z, L_F1E1
        in a, (FDCDAT)
        jp m, L_F1E1
        in a, (FDCSTA)
        ret


L_F1ED: in a, (UARTMS)
        and $40
        ld ($00F0), a
        jr nz, L_F233
        ld hl, JPTAB1
        call CP92E6
        in a, (IVCDAT)
        ld a, $1A               ; home/clear screen
        out (IVCDAT), a
        in a, (IVCSTA)
        rrca
        ccf
        ld a, $FF
        ret c
        ld hl, $0000
L_F20C: dec hl
        ld a, h
        or l
        scf
        ld a, $FF
        ret z                   ; timeout waiting - maybe no IVC?
        in a, (IVCSTA)
        rrca
        jr c, L_F20C
L_F218: ld hl, $0000
        ld a, $1B
        call PUTIVC
        ld a, $76               ; get version number of IVC software
        call PUTIVC
L_F225: dec hl
        ld a, h
        or l
        jr z, L_F218            ; timeout; try again
        in a, (IVCSTA)
        rlca
        jr c, L_F225            ; wait
        xor a
        in a, (IVCDAT)          ; version number in A
        ret


L_F233: ld hl, JPTAB2
        call CP92E6
        ld a, $03
        out (UARTLC), a
        ld a, $07
        out (UARTMC), a
        ld c, UARTLC
L_F243: ld hl, BAUDTAB
L_F246: ld e, (hl)
        inc hl
        ld d, (hl)
        inc hl
        ld a, d
        or e
        jr z, L_F243
        ld a, $83
        out (c), a
        ld a, e
        out (UARTDAT), a
        ld a, d
        out (UARTIE), a
        ld a, $03
        out (c), a
        call L_00E9
        cp $0D
        jr nz, L_F246
        call L_00E9
        cp $0D
        jr nz, L_F246
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


CP92E6: ld de, L_00E6           ; copy 9 bytes (3 x JP XXXX) to $00E6
        ld bc, $0009
        ldir
        ret


JPTAB1: jp L_F42A
        jp L_F439
        jp PUTIVC
JPTAB2: jp L_F457
        jp L_F45C
        jp L_F41D


L_F2A1: ld a, ($00F0)
        or a
        ret


L_F2A6: ld a, $D0
        call CMD2FDC
        ld a, ($00EF)
        out ($E4), a
        ld a, $0B
        out (FDCCMD), a
        ld b, $28
L_F2B6: djnz L_F2B6
        ld hl, $D000
        in a, (FDCSTA)
        ld c, a
L_F2BE: in a, (FDCSTA)
        xor c
        and $02
        jr z, L_F2C7
        ld b, $FF
L_F2C7: dec l
        jr nz, L_F2BE
        call L_F2E2
        or a
        scf
        ret nz
        dec h
        jr nz, L_F2BE
        ld a, b
        or a
        ret nz
        call L_F320
        jr nz, L_F2DD
        inc a
        ret


L_F2DD: xor a
        ret


L_F2DF: call L_F2FE
L_F2E2: call L_00E6
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
        call L_F2FE
        jp L_F56C               ; continue to command loop


L_F2FE: call L_F2A1
        ld hl, MSG13            ; delete to end of line
        jp z, PRS
        ld hl, MSG14            ; "<"
        jp PRS                  ; print and return (tail-recurse)


MSG13:  defb $1B, $2A, $00      ; delete to end of line

MSG14:  defm "<"
        defb $00


CMD2FDC:out (FDCCMD), a         ; send command in A to FDC then wait then poll status (for completion?)
        ld a, $0A               ; delay loop count for command acceptance
L_F316: dec a                   ; 
        jr nz, L_F316           ; wait a little while
L_F319: in a, (FDCSTA)          ; read status
        bit 0, a                ; completion?
        jr nz, L_F319           ; not yet.. loop
        ret                     ; done


L_F320: ld a, $55
        out ($E6), a
        in a, ($E6)
        cpl
        out ($E6), a
        ld b, a
        in a, ($E6)
        xor b
        ret nz
        call L_F369
        nop
        nop
        nop
        nop
        nop
        nop
        jp L_F3AC


L_F33A: xor a
L_F33B: push af
        in a, ($E5)
        and $10
        jr z, L_F348
        pop af
        dec a
        jr nz, L_F33B
        jr L_F349


L_F348: pop af
L_F349: ld a, $F7
        out ($E5), a
        ret


L_F34E: in a, ($E5)
        and $10
        ld a, $01
        ret nz
L_F355: in a, ($E5)
        rrca
        jr c, L_F355
        ret


L_F35B: ld a, $FF
        out ($E6), a
        ld b, $00
L_F361: in a, ($E6)
        djnz L_F361
        ld a, $04
        or a
        ret


L_F369: in a, ($E5)
        or $E0
        inc a
        jr nz, L_F35B
        ld a, $FE
        out ($E6), a
        ld a, $F5
        out ($E5), a
        call L_F33A
        pop hl
        call L_F34E
        ld a, (hl)
L_F380: cpl
        out ($E6), a
        inc hl
        inc hl
        call L_F34E
        ld a, ($00EF)
        dec a
        jr z, L_F390
        ld a, $20
L_F390: cpl
        out ($E6), a
        ld b, $04
L_F395: call L_F34E
        ld a, (hl)
        cpl
        out ($E6), a
        inc hl
        djnz L_F395
        jp (hl)


L_F3A0: call L_F369
        ex af, af'
        nop
        nop
        nop
        ld bc, $2100
        nop
        nop
L_F3AC: call L_F34E
        rrca
        jr c, L_F35B
        rrca
        jr nc, L_F3C1
        in a, ($E6)
        cpl
        ld (hl), a
        ld a, l
        cp $7F
        jr z, L_F3AC
        inc hl
        jr L_F3AC


L_F3C1: in a, ($E6)
        cpl
        ld b, a
        call L_F34E
        rrca
        jr c, L_F35B
        in a, ($E6)
        ld a, b
        and $0F
        ret


PRS:    ld a, (hl)              ; print 0-terminated string at (HL)
        inc hl                  ; ??with special treatment of 0x80 and others?
        or a
        ret z
        cp $80
        jr nz, L_F3DB
        ld a, $A0               ; change $80 to $A0??
L_F3DB: push bc
        ld bc, $1420
        cp $09                  ; TAB translates as "print 20 spaces"
        jr z, L_F3F3
        ld bc, $052A
        cp $40                  ; @ translates as "print 5 *"
        jr z, L_F3F3
        ld c, $AA               ; ???
        cp $C0                  ; ???
        jr z, L_F3F3
        ld b, $01               ; default is to print character in A once
        ld c, a
L_F3F3: ld a, c                 ; print character in C, B times
        call XCHROUT
        djnz L_F3F3
        pop bc
        jr PRS


XCHRIN: call L_00E9
XCHROUT:cp $3C
        jr z, L_F40D
        cp $0D
        jp nz, L_00EC
        ld a, $0A
        call L_00EC
L_F40D: ld a, $0D
        call L_00EC
        ret


PUTIVC: push af
L_F414: in a, (IVCSTA)
        rrca
        jr c, L_F414
        pop af
        out (IVCDAT), a
        ret


L_F41D: push af
L_F41E: in a, (UARTLS)
        and $20
        jr z, L_F41E
        pop af
        and $7F
        out (UARTDAT), a
        ret


L_F42A: ld a, $1B               ; check keyboard status return with Z if no character
        call PUTIVC             ; else fall through to get character
        ld a, $6B
        call PUTIVC
        call GETIVC
        or a
        ret z                   ; no character
L_F439: ld a, $1B               ; get character (wait if necessary). Return with character in A
        call PUTIVC             ; -- force a-z to upper case.
        ld a, $4B               ; get character
        call PUTIVC
        call GETIVC
L_F446: cp $61                  ; "a"
        ret c
        cp $7B                  ; "z" + 1
        ret nc
        and $5F                 ; force alphabetic to upper case
        ret


GETIVC: in a, (IVCSTA)
        rlca
        jr c, GETIVC
        in a, (IVCDAT)
        ret


L_F457: in a, (UARTLS)
        and $01
        ret z
L_F45C: in a, (UARTLS)
        and $01
        jr z, L_F45C
        in a, (UARTDAT)
        and $7F
        jr L_F446


CMD_A:  ld hl, MSG6
        call PRS
L_F46E: call L_00E9
        sub $31
        jr c, L_F46E
        cp $04
        jr nc, L_F46E
        ld c, $00
L_F47B: ld b, a
        inc b
        xor a
        scf
L_F47F: rla
        djnz L_F47F
        or c
        bit 7, a
        jp L_F063


MSG6:   defb $0D
        defm "Select master Drive (1 or 2) "
        defb $00


CMD_8:  ld hl, MSG7
        call PRS
L_F4AD: call L_00E9
        sub $31
        jr c, L_F4AD
        cp $04
        jr nc, L_F4AD
        ld c, $30
        jr L_F47B


MSG7:   defb $0D
        defm "Select 8\" Drive (1-4) "
        defb $00

MSG8:   defm "  "
        defb $1A, $1B, $44      ; home/clear screen then turn off cursor
        defb $0A, $0A, $0A, $09 ; CR CR CR TAB
        defm "@ MultiBoard Computer System @"
        defb $0D, $0A, $0A, $00

MSG9:   defm "This is spare"    ; never referenced

MSG18:  defb $0D, $0A, $1B, $45 ; turn on cursor
        defm "       SImple MONitor Version 4.2"
        defb $0D, $0A, $00

MSG10:  defm "         GM809/829 present"
        defb $0D, $0A, $00

MSG11:  defm "           GM849 present"
        defb $0D, $0A, $00


L_F56C: xor a
        out ($E4), a            ; turn off all the drives
        ld hl, MSG18            ; SIMON banner
        call PRS
        ld a, $0F
        out ($E5), a
        in a, ($E5)
        rlca
        ld hl, MSG11            ; Detected GM849 disk controller
        jr nc, L_F584
        ld hl, MSG10            ; Detected GM809/829 disk controller
L_F584: call PRS
CMDLOP: ld sp, L_00E6
        ld a, ">"               ; prompt
        call XCHROUT
        call XCHROUT
        ld hl, CMDLOP           ; each command ends with RET which takes it back to CMDLOP
        push hl
        call XCHRIN             ; get single-letter command
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
        jp z, CMD_O             ; out to port
        cp $51
        jp z, CMD_Q             ; query from port
        cp $44
        jp z, CMD_D
        cp $56
        jp z, CMD_V
        cp $38
        jp z, CMD_8
CMDERR: ld hl, MSG12
        jp PRS


MSG12:  defm "  -What?"
        defb $0D, $00


CMD_B:  ld a, ($00EF)
        jp L_F063


        cp $30
        ret c
        cp $3A
        jr c, L_F5F6
        cp $41
        ret c
        cp $47
        ccf
        ret c
        sub $07
L_F5F6: and $0F
        ret


XP4HEX: ld a, h
        call XP2HEX
        ld a, l
XP2HEX: push af
        rrca
        rrca
        rrca
        rrca
        call L_F607
        pop af
L_F607: and $0F
        add a, $90
        daa
        adc a, $40
        daa
        jp XCHROUT


XCRLF:  ld a, $0D
        jp XCHROUT


XSPACE: ld a, $20
        jp XCHROUT


;;; Get ASCII character "0"-"9", "A"-"F" and return as hex value 0-f
;;; Return value in A. C set if bad character
L_F61C: call XCHRIN
        cp $30
        ret c
        cp $3A
        jr c, L_F62F
        cp $41
        ret c
        cp $47
        ccf
        ret c
        sub $07
L_F62F: and $0F
        ret


L_F632: ld hl, $0000
        call L_F61C
        jr nc, L_F640
        cp $20
        jr z, L_F632
        scf
        ret


L_F640: add hl, hl
        ret c
        add hl, hl
        ret c
        add hl, hl
        ret c
        add hl, hl
        ret c
        add a, l
        ld l, a
        call L_F61C
        jr nc, L_F640
        cp $20
        ret z
        cp $0D
        ret z
        scf
        ret


GET16:  call L_F632             ; get 16-bit value in HL (not at end of line)
        jr c, L_F65F
        cp $20
        ret z
L_F65F: pop hl
        jp CMDERR


GET16F: call L_F632             ; get final 16-bit value to HL (expect end-of-line else error)
        jr c, L_F65F
        cp $0D
        ret z
        jr L_F65F


;;; copy from to length (not intelligent so can overwrite source)
CMD_C:  call GET16              ; from address
        ex de, hl
        call GET16              ; to address
        ld b, h
        ld c, l
        call GET16F             ; length
        push bc
        ex (sp), hl
        pop bc
        ex de, hl
        ldir
        ret


;;; go (execute) at address
CMD_G:  call GET16F            ; get 16-bit value in hl
        jp (hl)


;;; fill from length byte
CMD_F:  call GET16
        ex de, hl
        call GET16
        sbc hl, de
        ret c
        ld b, h
        ld c, l
        call GET16F
        ex de, hl
        ld (hl), e
        ld d, h
        ld e, l
        inc de
        ldir
        ret


;;; inspect and modify memory
CMD_S:  call GET16F             ; get address
SLOP:   call XP4HEX             ; print it
        ld a, "-"
        call XCHROUT
        ld a, (hl)
        call XP2HEX             ; report byte value at address
        call XSPACE
        ex de, hl
        call L_F632             ; enter new value or <return> to go to next or - to go back or space to exit?
        ex de, hl
        push af
        cp $0D
        call nz, XCRLF
        pop af
        jr nc, L_F6C6
        cp $0D
        jr z, L_F6C5
        cp "-"
        ret nz
        dec hl                  ; previous memory location
        jr SLOP                 ; loop


L_F6C5: ld e, (hl)
L_F6C6: ld a, d
        or a
        jp nz, CMDERR
        ld (hl), e
        ld a, (hl)
        cp e
        jp nz, CMDERR
        inc hl                  ; next memory location
        jr SLOP                 ; loop


;;; Output (write) to I/O port
CMD_O:  call GET16             ; get port address in HL?
        ld a, h
        or a
        jp nz, CMDERR           ; error: expect port 0-ff therefore H should be 0
        ld c, l
        call GET16F             ; get value in HL terminated in end-of-line
        ld a, h
        or a
        jp nz, CMDERR           ; error: expect value 0-ff therefore H should be 0
        out (c), l              ; write to port
        ret                     ; done


;;; Query (read from) I/O port
CMD_Q:  call GET16F             ; get port address in HL
        ld a, h
        or a
        jp nz, CMDERR           ; error: expect port 0-ff therefore H should be 0
        ld c, l                 ; port in C
        in a, (c)               ; read from port
        call XP2HEX             ; print 8-bit value
        jp XCRLF                ; CR and return (tail-recurse)


;;; Display memory
CMD_D:  call GET16              ; start address
        ex de, hl
        call GET16F             ; number of lines, 16-bytes per line
        ld c, l
        ex de, hl
DADDR: call XP4HEX
        ld b, $10               ; 16 bytes per line
DDATA:  call XSPACE
        ld a, (hl)
        call XP2HEX             ; print byte
        inc hl                  ; next address
        ld a, $09
        cp b
        jr nz, L_F71C
        call XSPACE
        ld a, "-"               ; " - " between first 8 and second 8 bytes
        call XCHROUT
L_F71C: djnz DDATA
L_F71E: call XCRLF
        dec c                   ; line count
        jr nz, DADDR
        ret


;;; Report version
CMD_V:  ld hl, MSG20
        jp PRS                  ; print and return (tail-recurse)


;;; TODO unreachable code. This looks like a fragment of the end of CMD_S somehow left in memory and ending up in the ROM.
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF
        push af
        cp $0D
        call nz, XCRLF
        pop af
        jr nc, L_F746
        cp $0D
        jr z, L_F745
        cp "-"
        ret nz
        dec hl
        jr L_F71E


;;; TODO unreachable code - more of CMD_S from L_F6C5
L_F745: ld e, (hl)
L_F746: ld a, d
        or a
        jp nz, CMDERR
        ld (hl), e
        ld a, (hl)
        cp e
        jp nz, CMDERR
        inc hl
        jr L_F71E


;;; TODO unreachable code - looks like a copy of CMD_O
        call GET16
        ld a, h
        or a
        jp nz, CMDERR
        ld c, l
        call GET16F
        ld a, h
        or a
        jp nz, CMDERR
        out (c), l
        ret


;;; TODO unreachable code - looks like a copy of CMD_Q
        call GET16F
        ld a, h
        or a
        jp nz, CMDERR
        ld c, l
        in a, (c)
        call XP2HEX
        jp XCRLF


;;; TODO unreachable code - looks like a copy of the start of CMD_D
        call GET16
        ex de, hl
        call GET16F             ;?just falls off into FF?


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
; $F0F0 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $F140 CCCCCCCCCCCCCCCCCCCCCCCCC--CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $F190 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $F1E0 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $F230 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCWWWWWWWWWWWWWWWWWWWW
; $F280 WWWWWWCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $F2D0 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCBBBBBCCCCCCCCCCCCCC
; $F320 CCCCCCCCCCCCCCCCC---------CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $F370 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $F3C0 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $F410 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $F460 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBCCCCCCCCC
; $F4B0 CCCCCCCCCCCCBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $F500 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $F550 BBBBBBBBBBBBBBBBBBBBBBBBBBBBCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $F5A0 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCBBBBBBBBBBCCCCCCCCCCCCCCCC
; $F5F0 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $F640 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $F690 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $F6E0 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCBBBBB
; $F730 BBCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $F780 C---------------BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $F7D0 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB

; Labels
;
; $0002 => L_0002         BAUDTAB => $F26C
; $0020 => L_0020         CHRIN   => $F003
; $0028 => L_0028         CHROUT  => $F006
; $0038 => L_0038         CMD2FDC => $F312
; $00E6 => L_00E6         CMD_8   => $F4A7
; $00E9 => L_00E9         CMD_A   => $F468
; $00EC => L_00EC         CMD_B   => $F5E0
; $80F4 => L_80F4         CMD_C   => $F66D
; $AFD0 => L_AFD0         CMD_D   => $F6F9
; $E3E5 => L_E3E5         CMD_F   => $F684
; $E5EC => L_E5EC         CMD_G   => $F680
; $E9E8 => L_E9E8         CMD_O   => $F6D4
; $E9F2 => L_E9F2         CMD_Q   => $F6E8
; $EDE5 => L_EDE5         CMD_S   => $F69B
; $F000 => COLD           CMD_V   => $F725
; $F003 => CHRIN          COLD    => $F000
; $F006 => CHROUT         CRLF    => $F012
; $F009 => P2HEX          GETIVC  => $F44F
; $F00C => P4HEX          L_0002  => $0002
; $F00F => SPACE          L_0020  => $0020
; $F012 => CRLF           L_0028  => $0028
; $F015 => MSG1           L_0038  => $0038
; $F033 => XCOLD          L_00E6  => $00E6
; $F03B => L_F03B         L_00E9  => $00E9
; $F040 => L_F040         L_00EC  => $00EC
; $F063 => L_F063         L_80F4  => $80F4
; $F06D => L_F06D         L_AFD0  => $AFD0
; $F080 => MSG2           L_E3E5  => $E3E5
; $F09B => MSG3           L_E5EC  => $E5EC
; $F0AF => MSG4           L_E9E8  => $E9E8
; $F0BC => MSG5           L_E9F2  => $E9F2
; $F0D8 => L_F0D8         L_EDE5  => $EDE5
; $F0DD => L_F0DD         L_F03B  => $F03B
; $F0E0 => L_F0E0         L_F040  => $F040
; $F0EE => L_F0EE         L_F063  => $F063
; $F0F1 => L_F0F1         L_F06D  => $F06D
; $F0F8 => L_F0F8         L_F0D8  => $F0D8
; $F11B => L_F11B         L_F0DD  => $F0DD
; $F126 => L_F126         L_F0E0  => $F0E0
; $F131 => L_F131         L_F0EE  => $F0EE
; $F137 => L_F137         L_F0F1  => $F0F1
; $F13A => L_F13A         L_F0F8  => $F0F8
; $F14B => L_F14B         L_F11B  => $F11B
; $F15B => L_F15B         L_F126  => $F126
; $F1BA => L_F1BA         L_F131  => $F131
; $F1C8 => L_F1C8         L_F137  => $F137
; $F1D7 => L_F1D7         L_F13A  => $F13A
; $F1E1 => L_F1E1         L_F14B  => $F14B
; $F1ED => L_F1ED         L_F15B  => $F15B
; $F20C => L_F20C         L_F1BA  => $F1BA
; $F218 => L_F218         L_F1C8  => $F1C8
; $F225 => L_F225         L_F1D7  => $F1D7
; $F233 => L_F233         L_F1E1  => $F1E1
; $F243 => L_F243         L_F1ED  => $F1ED
; $F246 => L_F246         L_F20C  => $F20C
; $F26C => BAUDTAB        L_F218  => $F218
; $F286 => L_F286         L_F225  => $F225
; $F2A1 => L_F2A1         L_F233  => $F233
; $F2A6 => L_F2A6         L_F243  => $F243
; $F2B6 => L_F2B6         L_F246  => $F246
; $F2BE => L_F2BE         L_F286  => $F286
; $F2C7 => L_F2C7         L_F2A1  => $F2A1
; $F2DD => L_F2DD         L_F2A6  => $F2A6
; $F2DF => L_F2DF         L_F2B6  => $F2B6
; $F2E2 => L_F2E2         L_F2BE  => $F2BE
; $F2FE => L_F2FE         L_F2C7  => $F2C7
; $F30D => MSG13          L_F2DD  => $F2DD
; $F310 => MSG14          L_F2DF  => $F2DF
; $F312 => CMD2FDC        L_F2E2  => $F2E2
; $F316 => L_F316         L_F2FE  => $F2FE
; $F319 => L_F319         L_F316  => $F316
; $F320 => L_F320         L_F319  => $F319
; $F33A => L_F33A         L_F320  => $F320
; $F33B => L_F33B         L_F33A  => $F33A
; $F348 => L_F348         L_F33B  => $F33B
; $F349 => L_F349         L_F348  => $F348
; $F34E => L_F34E         L_F349  => $F349
; $F355 => L_F355         L_F34E  => $F34E
; $F35B => L_F35B         L_F355  => $F355
; $F361 => L_F361         L_F35B  => $F35B
; $F369 => L_F369         L_F361  => $F361
; $F380 => L_F380         L_F369  => $F369
; $F390 => L_F390         L_F380  => $F380
; $F395 => L_F395         L_F390  => $F390
; $F3A0 => L_F3A0         L_F395  => $F395
; $F3AC => L_F3AC         L_F3A0  => $F3A0
; $F3C1 => L_F3C1         L_F3AC  => $F3AC
; $F3D1 => PRS            L_F3C1  => $F3C1
; $F3DB => L_F3DB         L_F3DB  => $F3DB
; $F3E9 => L_F3E9         L_F3E9  => $F3E9
; $F3F3 => L_F3F3         L_F3F3  => $F3F3
; $F3FC => XCHRIN         L_F40D  => $F40D
; $F3FF => XCHROUT        L_F414  => $F414
; $F40D => L_F40D         L_F41D  => $F41D
; $F413 => PUTIVC         L_F41E  => $F41E
; $F414 => L_F414         L_F42A  => $F42A
; $F41D => L_F41D         L_F439  => $F439
; $F41E => L_F41E         L_F446  => $F446
; $F42A => L_F42A         L_F457  => $F457
; $F439 => L_F439         L_F45C  => $F45C
; $F446 => L_F446         L_F46E  => $F46E
; $F44F => GETIVC         L_F47B  => $F47B
; $F457 => L_F457         L_F47F  => $F47F
; $F45C => L_F45C         L_F4AD  => $F4AD
; $F468 => CMD_A          L_F56C  => $F56C
; $F46E => L_F46E         L_F584  => $F584
; $F47B => L_F47B         L_F5D0  => $F5D0
; $F47F => L_F47F         L_F5F6  => $F5F6
; $F488 => MSG6           L_F607  => $F607
; $F4A7 => CMD_8          L_F61C  => $F61C
; $F4AD => L_F4AD         L_F62F  => $F62F
; $F4BC => MSG7           L_F632  => $F632
; $F4D4 => MSG8           L_F640  => $F640
; $F4FF => MSG9           GET16  => $F657
; $F534 => MSG10          L_F65F  => $F65F
; $F551 => MSG11          GET16F  => $F663
; $F56C => L_F56C         L_F69E  => $F69E
; $F584 => L_F584         L_F6C5  => $F6C5
; $F5D0 => L_F5D0         L_F6C6  => $F6C6
; $F5D6 => MSG12          L_F702  => $F702
; $F5E0 => CMD_B          L_F707  => $F707
; $F5F6 => L_F5F6         L_F71C  => $F71C
; $F5F9 => XP4HEX         L_F71E  => $F71E
; $F5FE => XP2HEX         L_F745  => $F745
; $F607 => L_F607         L_F746  => $F746
; $F612 => XCRLF          MSG1    => $F015
; $F617 => XSPACE         MSG10   => $F534
; $F61C => L_F61C         MSG11   => $F551
; $F62F => L_F62F         MSG12   => $F5D6
; $F632 => L_F632         MSG13   => $F30D
; $F640 => L_F640         MSG14   => $F310
; $F657 => GET16          MSG2    => $F080
; $F65F => L_F65F         MSG3    => $F09B
; $F663 => GET16F         MSG4    => $F0AF
; $F66D => CMD_C          MSG5    => $F0BC
; $F680 => CMD_G          MSG6    => $F488
; $F684 => CMD_F          MSG7    => $F4BC
; $F69B => CMD_S          MSG8    => $F4D4
; $F69E => L_F69E         MSG9    => $F4FF
; $F6C5 => L_F6C5         P2HEX   => $F009
; $F6C6 => L_F6C6         P4HEX   => $F00C
; $F6D4 => CMD_O          PRS     => $F3D1
; $F6E8 => CMD_Q          PUTIVC  => $F413
; $F6F9 => CMD_D          SPACE   => $F00F
; $F702 => L_F702         XCHRIN  => $F3FC
; $F707 => L_F707         XCHROUT => $F3FF
; $F71C => L_F71C         XCOLD   => $F033
; $F71E => L_F71E         XCRLF   => $F612
; $F725 => CMD_V          XP2HEX  => $F5FE
; $F745 => L_F745         XP4HEX  => $F5F9
; $F746 => L_F746         XSPACE  => $F617


; Check these calls manualy: $0038, $F369, $F3A0

