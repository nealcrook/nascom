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

BOOTGO: equ $0002               ; entry point of loaded boot sector
STACK:  equ $00E6               ; stack grows down from here
IOPOLL: equ $00E6               ; 1st entry in JPTAB1 or JPTAB2 POLL STATUS
IOGET:  equ $00E9               ; 2nd entry in JPTAB1 or JPTAB2 GET CHAR
IOPUT:  equ $00EC               ; 3rd entry in JPTAB1 or JPTAB2 PUT CHAR

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
        out (FDCDRV), a         ; select drive 0/A
        ld d, $40               ; count ??of mapper pages to init??
CLOP1:  ld bc, $F0FE            ; B=?? C= port for MMAP
        ld e, $0F               ; value?
CLOP2:  out (c), e              ; initialise memory mapper
        dec e
        ld a, b
        sub $10
        ld b, a
        jr nc, CLOP2            ; continue
        dec d
        jr nz, CLOP1            ; 0x64 = 40
        ld a, $11               ; value?
        out (PMOD), a           ; page-mode register
        ld sp, STACK
        call INITIO             ; Will execute at FXXX instead of 0XXX
                                ; BUT: how does the ROM get disabled so that the
                                ; stack at $000E6 can be used??
        ld a, i                 ; 
        ld a, $01               ; 
        push af                 ; TODO wot's appenin? could this be some kind of warm/cold check?
        ld i, a                 ; 
        pop af                  ; 
        jr z, L_F063            ; 
        ld a, ($00EF)           ; drive select value for boot drive
L_F063: ld ($00EF), a           ; comes here from A and B commands
        push af
        ld a, $F3
        out (SCSCTL), a
        ld a, $09
L_F06D: dec a
        jr nz, L_F06D
        ld a, $F7
        out (SCSCTL), a
        ld hl, MSG8             ; clear screen, power-on message
        call PRS
        pop af
        jr nz, L_F0DD
        jp L_F14B

MSG2:   defm " while loading Boot sector"
        defb $00

MSG3:   defm " during System load"
        defb $00

;;; TODO how is this used?
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
        ld hl, MSG5             ; - Press any key to repeat<
L_F0EE: call PRS
L_F0F1: call CLEAN
        jr z, L_F0F8
        jr nc, L_F0F1
L_F0F8: call L_F2DF
        jr L_F14B


;;; TODO how is this used?
MSG15:  defb $1B, $2A           ; delete to end of line
        defm "<"
        defb $09, $80, $C9, $EE, $F3, $E5, $F2, $F4, $80, $C4, $E9, $F3, $EB, $80, $E9, $EE, $80, $E4, $F2, $E9, $F6, $E5, $80, $00

MSG16:  defb $A0                ;TODO no reference
        defm "<"
        defb $00

L_F11B: ld hl, MSG15
        call PRS
        ld a, ($00EF)           ; get drive
        ld b, $C0
L_F126: inc b
        rrca
        jr nc, L_F126
        ld a, b
        cp $C1
        jr z, L_F131
        sub $10
L_F131: call XCHROUT
        jp PRS                  ; print and return (tail-recurse)


L_F137: call L_F11B
L_F13A: call WOTIO
        call z, L_F11B          ; if IVC
        call CLEAN
        call L_F2DF
        call CLEAN
        jr z, L_F13A
L_F14B: ld sp, STACK
        call CLEAN
        jr z, L_F137
        inc a
        jr z, L_F15B
        call L_F3A0
        jr L_F16E


L_F15B: in a, (FDCSTA)
        bit 0, a
        jr nz, L_F15B           ; wait until done?
        ld a, $5B
        call CMD2FDC            ; STEP IN?
        ld a, $0B
        call CMD2FDC            ; RESTORE
        call RDSEC0             ; load sector 0 to RAM at 0
L_F16E: or a
        jp nz, L_F0D8
        ld hl, ($0000)          ; get first 2 bytes from boot sector
        ld de, (MSG19)          ; "GG"
        or a
        sbc hl, de
        call z, L_F2E2          ; if good disk??
        ld a, ($00EF)           ; get drive
        jp z, BOOTGO            ; enter code loaded from boot sector (first 2 bytes is "magic" eg GG for Gemini)
        ld hl, MSG17            ; ??wot??
        jp L_F0EE


;;; TODO how is this used?
MSG17:  defb $09, $80, $C0, $CE, $EF, $80, $F2, $E5, $E3, $EF, $E7, $EE, $E9, $F3, $E1, $E2
        defb $EC, $E5, $80, $C3, $D0, $AF, $CD, $80, $F3, $F9, $F3, $F4, $E5, $ED, $80, $EF
        defb $EE, $80, $F4, $E8, $E9, $F3, $80, $E4, $E9, $F3, $EB, $C0, $80
        defm "<"
        defb $00


RDSEC0: ld a, $0B
        call CMD2FDC            ; RESTORE
        ld a, ($00EF)           ; get drive
        and $20
        jr z, L_F1C8            ; drive selected (how is this flagged??)
        ld a, $01               ; no drive selected, use default
L_F1C8: out (FDCSEC), a
        ld hl, $0000
        ld c, FDCDRV            ; ?fast access to FDC data-available flag?
        ld a, $88
        out (FDCCMD), a         ; READ SECTOR
        ld b, $80
        jr LDSEC                ; why not fall through? Bug, or need need slight delay?


LDSEC:  in a, (c)               ; data byte available?
        jr z, LDSEC             ; not yet
        in a, (FDCDAT)          ; get data
        ld (hl), a              ; store
        inc hl                  ; next location
        djnz LDSEC              ; total of $80 (128) bytes
L_F1E1: in a, (c)               ; read and discard remaining bytes, if any
        jr z, L_F1E1
        in a, (FDCDAT)
        jp m, L_F1E1
        in a, (FDCSTA)
        ret


;;; Initialise I/O: serial or IVC
INITIO: in a, (UARTMS)
        and $40                 ; ??check board link??
        ld ($00F0), a           ; record what I/O is in use
        jr nz, SERIO
        ld hl, JPTAB1           ; use IVC for kbd/display
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


SERIO:  ld hl, JPTAB2           ; use UART for kbd/display
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
        out (c), a              ; allow access to UART baud rate divisor registers
        ld a, e
        out (UARTDAT), a        ; set baud rate divisor lo
        ld a, d
        out (UARTIE), a         ; set baud rate divisor hi
        ld a, $03
        out (c), a              ; restore access to UART data/interrupt registers
        call IOGET
        cp $0D
        jr nz, L_F246
        call IOGET
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


CP92E6: ld de, IOPOLL           ; copy 9 bytes (3 x JP XXXX) to $00E6
        ld bc, $0009
        ldir
        ret


JPTAB1: jp POLIVC               ; vectored I/O using IVC
        jp GETIVC
        jp PUTIVC
JPTAB2: jp POLSER               ; vectored I/O using UART
        jp GETSER
        jp PUTSER


WOTIO:  ld a, ($00F0)           ; return Z if IVC in use, NZ for serial
        or a
        ret


;;; clean up: abort any command in progress, restore the drive. ???what else
CLEAN:  ld a, $D0               ; FORCE INTERRUPT
        call CMD2FDC
        ld a, ($00EF)           ; get drive
        out (FDCDRV), a
        ld a, $0B
        out (FDCCMD), a         ; RESTORE
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
L_F2E2: call IOPOLL
        or a
        ret z                   ; no key pressed
        and $1F
        cp $01
        jp z, CMD_A
        cp $18
        jp z, CMD_8
        cp $13
        ld a, $01
        ret nz
        call L_F2FE
        jp L_F56C               ; ?did not autoboot: continue to command loop


L_F2FE: call WOTIO
        ld hl, MSG13            ; delete to end of line
        jp z, PRS               ; for IVC, tail-recurse to print MSG13
        ld hl, MSG14            ; "<"
        jp PRS                  ; for serial, tail-recurse to print MSG14


MSG13:  defb $1B, $2A, $00      ; delete to end of line

MSG14:  defm "<"
        defb $00


CMD2FDC:out (FDCCMD), a         ; send command in A to FDC then wait then poll status (for completion?)
        ld a, $0A               ; delay loop count for command acceptance
L_F316: dec a
        jr nz, L_F316           ; wait a little while
L_F319: in a, (FDCSTA)          ; read status
        bit 0, a                ; completion?
        jr nz, L_F319           ; not yet.. loop
        ret                     ; done


L_F320: ld a, $55
        out (SCSDAT), a
        in a, (SCSDAT)
        cpl
        out (SCSDAT), a
        ld b, a
        in a, (SCSDAT)
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
        in a, (SCSCTL)
        and $10
        jr z, L_F348
        pop af
        dec a
        jr nz, L_F33B
        jr L_F349


L_F348: pop af
L_F349: ld a, $F7
        out (SCSCTL), a
        ret


L_F34E: in a, (SCSCTL)
        and $10
        ld a, $01
        ret nz
L_F355: in a, (SCSCTL)
        rrca
        jr c, L_F355
        ret


L_F35B: ld a, $FF
        out (SCSDAT), a
        ld b, $00
L_F361: in a, (SCSDAT)
        djnz L_F361
        ld a, $04
        or a
        ret


L_F369: in a, (SCSCTL)
        or $E0
        inc a
        jr nz, L_F35B
        ld a, $FE
        out (SCSDAT), a
        ld a, $F5
        out (SCSCTL), a
        call L_F33A
        pop hl
        call L_F34E
        ld a, (hl)
L_F380: cpl
        out (SCSDAT), a
        inc hl
        inc hl
        call L_F34E
        ld a, ($00EF)           ; get drive
        dec a
        jr z, L_F390
        ld a, $20
L_F390: cpl
        out (SCSDAT), a
        ld b, $04
L_F395: call L_F34E
        ld a, (hl)
        cpl
        out (SCSDAT), a
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
        in a, (SCSDAT)
        cpl
        ld (hl), a
        ld a, l
        cp $7F
        jr z, L_F3AC
        inc hl
        jr L_F3AC


L_F3C1: in a, (SCSDAT)
        cpl
        ld b, a
        call L_F34E
        rrca
        jr c, L_F35B
        in a, (SCSDAT)
        ld a, b
        and $0F
        ret


PRS:    ld a, (hl)              ; print 0-terminated string at (HL)
        inc hl                  ; ??with special treatment of 0x80 and others?
        or a
        ret z
        cp $80
        jr nz, PRS1
        ld a, $A0               ; change $80 to $A0??
PRS1:   push bc
        ld bc, $1420
        cp $09                  ; TAB translates as "print 20 spaces"
        jr z, PRS2
        ld bc, $052A
        cp $40                  ; @ translates as "print 5 *"
        jr z, PRS2
        ld c, $AA               ; ???
        cp $C0                  ; ???
        jr z, PRS2
        ld b, $01               ; default is to print character in A once
        ld c, a
PRS2:   ld a, c                 ; print character in C, B times
        call XCHROUT
        djnz PRS2
        pop bc
        jr PRS


XCHRIN: call IOGET              ; get character and fall-through to echo
XCHROUT:cp $3C
        jr z, L_F40D
        cp $0D
        jp nz, IOPUT
        ld a, $0A
        call IOPUT
L_F40D: ld a, $0D
        call IOPUT
        ret


PUTIVC: push af
PUTI1:  in a, (IVCSTA)
        rrca
        jr c, PUTI1
        pop af
        out (IVCDAT), a
        ret


PUTSER: push af
PUTS1:  in a, (UARTLS)
        and $20
        jr z, PUTS1
        pop af
        and $7F
        out (UARTDAT), a
        ret


POLIVC: ld a, $1B               ; check IVC keyboard status return with Z if no character
        call PUTIVC             ; else fall through to get character
        ld a, $6B
        call PUTIVC
        call INIVC
        or a
        ret z                   ; no character
GETIVC: ld a, $1B               ; get character from IVC kbd (wait if necessary). Return with character in A
        call PUTIVC             ; -- force a-z to upper case.
        ld a, $4B               ; get character
        call PUTIVC
        call INIVC
L_F446: cp $61                  ; "a"
        ret c
        cp $7B                  ; "z" + 1
        ret nc
        and $5F                 ; force alphabetic to upper case
        ret


INIVC:  in a, (IVCSTA)          ; wait for byte from IVC
        rlca
        jr c, INIVC
        in a, (IVCDAT)
        ret


POLSER: in a, (UARTLS)          ; check for character from serial
        and $01
        ret z
GETSER: in a, (UARTLS)          ; block, waiting for character from serial
        and $01
        jr z, GETSER
        in a, (UARTDAT)
        and $7F
        jr L_F446


CMD_A:  ld hl, MSG6             ; select master drive
        call PRS
L_F46E: call IOGET              ; get character
        sub $31
        jr c, L_F46E            ; illegal
        cp $04                  ; 1-4 are legal (not 1-2 per message)
        jr nc, L_F46E           ; illegal
        ld c, $00
L_F47B: ld b, a                 ; common path for CMD_A, CMD_8; C differs
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


CMD_8:  ld hl, MSG7             ; select 8" drive..
        call PRS
CMD81:  call IOGET              ; get character
        sub $31
        jr c, CMD81             ; illegal
        cp $04                  ; 1-4 are legal
        jr nc, CMD81            ; illegal
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
        out (FDCDRV), a         ; turn off all the drives
        ld hl, MSG18            ; SIMON banner
        call PRS
        ld a, $0F
        out (SCSCTL), a
        in a, (SCSCTL)
        rlca
        ld hl, MSG11            ; detected GM849 disk controller
        jr nc, L_F584
        ld hl, MSG10            ; detected GM809/829 disk controller
L_F584: call PRS
CMDLOP: ld sp, STACK
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
        jp PRS                  ; print and return (tail-recurse)


MSG12:  defm "  -What?"
        defb $0D, $00


CMD_B:  ld a, ($00EF)           ; get drive
        jp L_F063


        cp $30                  ; TODO what is this for and how does it get executed?
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
CMD_G:  call GET16F            ; get address in HL terminated by end-of-line
        jp (hl)


;;; fill from length byte
CMD_F:  call GET16              ; get from address in HL
        ex de, hl
        call GET16              ; get length in HL
        sbc hl, de
        ret c
        ld b, h
        ld c, l
        call GET16F             ; get fill-value in HL terminated by end-of-line
        ex de, hl
        ld (hl), e
        ld d, h
        ld e, l
        inc de
        ldir
        ret


;;; Inspect and modify memory
CMD_S:  call GET16F             ; get address in HL terminated by end-of-line
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
CMD_O:  call GET16              ; get port address in HL
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
CMD_Q:  call GET16F             ; get port address in HL terminated in end-of-line
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
DADDR:  call XP4HEX
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


;;; The rest of the ROM image is unreachable code. It looks like a "high tide mark" of older assembly runs
;;; that have been left in memory and which ended up in the ROM.

;;; This looks like a fragment of the end of CMD_S
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

;;; more of CMD_S
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

;;; looks like a copy of CMD_O
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

;;; looks like a copy of CMD_Q
        call GET16F
        ld a, h
        or a
        jp nz, CMDERR
        ld c, l
        in a, (c)
        call XP2HEX
        jp XCRLF

;;; looks like a copy of the start of CMD_D
        call GET16
        ex de, hl
        call GET16F

        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
