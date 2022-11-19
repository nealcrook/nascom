;;; SIMON version 4.5s
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
        defm "10-03-87 "        ; (falls through to print the mG CR also)

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
        jp L_F14D

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
L_F0F8: call L_F2E1
        jr L_F14D


;;; TODO how is this used? The < is printed literally, the $09 expand to 20 spaces each, the $80 is converted to
;;; $A0
MSG15:  defm "<"
        defb $09, $09, $09
        defm "<"
        defb $09, $80, $C9, $EE, $F3, $E5, $F2, $F4, $80, $C4, $E9, $F3, $EB, $80, $E9, $EE, $80
        defb $E4, $F2, $E9, $F6, $E5, $80, $00

MSG16:  defb $A0                ;TODO no reference
        defm "<"
        defb $00

L_F11D: ld hl, MSG15
        call PRS
        ld a, ($00EF)           ; get drive
        ld b, $C0
L_F128: inc b
        rrca
        jr nc, L_F128
        ld a, b
        cp $C1
        jr z, L_F133
        sub $10
L_F133: call XCHROUT
        jp PRS                  ; print and return (tail-recurse)


L_F139: call L_F11D
L_F13C: call WOTIO
        call z, L_F11D          ; if IVC
        call CLEAN
        call L_F2E1
        call CLEAN
        jr z, L_F13C
L_F14D: ld sp, STACK
        call CLEAN
        jr z, L_F139
        inc a
        jr z, L_F15D
        call L_F39A
        jr L_F170


L_F15D: in a, (FDCSTA)
        bit 0, a
        jr nz, L_F15D           ; wait until done?
        ld a, $5B
        call CMD2FDC            ; STEP IN?
        ld a, $0B
        call CMD2FDC            ; RESTORE
        call RDSEC0             ; load sector 0 to RAM at 0
L_F170: or a
        jp nz, L_F0D8
        ld hl, ($0000)          ; get first 2 bytes from boot sector
        ld de, (MSG19)          ; "GG"
        or a
        sbc hl, de
        call z, L_F2E4          ; if good disk??
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
        jr z, L_F1CA            ; drive selected (how is this flagged??)
        ld a, $01               ; no drive selected, use default
L_F1CA: out (FDCSEC), a
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
L_F1E3: in a, (c)               ; read and discard remaining bytes, if any
        jr z, L_F1E3
        in a, (FDCDAT)
        jp m, L_F1E3
        in a, (FDCSTA)
        ret


;;; Initialise I/O: serial or IVC
INITIO: in a, ($BE)
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
L_F20E: dec hl
        ld a, h
        or l
        scf
        ld a, $FF
        ret z                   ; timeout waiting - maybe no IVC?
        in a, (IVCSTA)
        rrca
        jr c, L_F20E
L_F21A: ld hl, $0000
        ld a, $1B
        call PUTIVC
        ld a, $76               ; get version number of IVC software
        call PUTIVC
L_F227: dec hl
        ld a, h
        or l
        jr z, L_F21A            ; timeout; try again
        in a, (IVCSTA)
        rlca
        jr c, L_F227            ; wait
        xor a
        in a, (IVCDAT)          ; version number in A
        ret


SERIO:  ld hl, JPTAB2           ; use UART for kbd/display
        call CP92E6
        ld a, $03
        out ($BB), a
        ld a, $07
        out ($BC), a
        ld c, $BB

L_F245:
        ld hl, BAUDTAB

L_F248:
        ld e, (hl)
        inc hl
        ld d, (hl)
        inc hl
        ld a, d
        or e
        jr z, L_F245
        ld a, $83
        out (c), a
        ld a, e
        out ($B8), a
        ld a, d
        out ($B9), a
        ld a, $03
        out (c), a
        call IOGET
        cp $0D
        jr nz, L_F248
        call IOGET
        cp $0D
        jr nz, L_F248
        or a
        ret


BAUDTAB:
        defw $000D, $0011, $001A, $0023, $0034, $003F, $0045, $0068, $00D0, $01A1, $0341, $0470, $0000

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
L_F2B8: djnz L_F2B8
        ld hl, $D000
        in a, (FDCSTA)
        ld c, a
L_F2C0: in a, (FDCSTA)
        xor c
        and $02
        jr z, L_F2C9
        ld b, $FF
L_F2C9: dec l
        jr nz, L_F2C0
        call L_F2E4
        or a
        scf
        ret nz
        dec h
        jr nz, L_F2C0
        ld a, b
        or a
        ret nz
        call L_F322
        jr nz, L_F2DF
        inc a
        ret


L_F2DF: xor a
        ret


L_F2E1: call L_F300
L_F2E4: call IOPOLL
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
        call L_F300
        jp L_F565               ; ?did not autoboot: continue to command loop


L_F300: call WOTIO
        ld hl, MSG13            ; delete to end of line
        jp z, PRS               ; for IVC, tail-recurse to print MSG13
        ld hl, MSG14            ; "<"
        jp PRS                  ; print serial, tail-recurse to print MSG14


MSG13:  defb $1B, $2A, $00      ; delete to end of line

MSG14:  defm "<"
        defb $00


CMD2FDC:out (FDCCMD), a         ; send command in A to FDC then wait then poll status (for completion?)
        ld a, $0A               ; delay loop count for command acceptance
L_F318: dec a
        jr nz, L_F318           ; wait a little while
L_F31B: in a, (FDCSTA)          ; read status
        bit 0, a                ; completion?
        jr nz, L_F31B           ; not yet.. loop
        ret                     ; done


L_F322: call L_F35D
        nop
        nop
        nop
        nop
        nop
        nop
        jp L_F3A6


L_F32E: xor a
L_F32F: push af
        in a, (SCSCTL)
        and $10
        jr z, L_F33C
        pop af
        dec a
        jr nz, L_F32F
        jr L_F33D


L_F33C: pop af
L_F33D: ld a, $F7
        out (SCSCTL), a
        ret


L_F342: in a, (SCSCTL)
        and $10
        ld a, $01
        ret nz
L_F349: in a, (SCSCTL)
        rrca
        jr c, L_F349
        ret


L_F34F: ld a, $FF
        out (SCSDAT), a
        ld b, $00
L_F355: in a, (SCSDAT)
        djnz L_F355
        ld a, $04
        or a
        ret


L_F35D: ld b, $00
L_F35F: in a, (SCSCTL)
        or $E0
        inc a
        jr z, L_F36A
        djnz L_F35F
        jr L_F34F


L_F36A: ld a, $FE
        out (SCSDAT), a
        ld a, $F5
        out (SCSCTL), a
        call L_F32E
        pop hl
        call L_F342
        ld a, (hl)
        cpl
        out (SCSDAT), a
        inc hl
        inc hl
        call L_F342
        ld a, ($00EF)           ; get drive
        dec a
        jr z, L_F38A
        ld a, $20
L_F38A: cpl
        out (SCSDAT), a
        ld b, $04
L_F38F: call L_F342
        ld a, (hl)
        cpl
        out (SCSDAT), a
        inc hl
        djnz L_F38F
        jp (hl)


L_F39A: call L_F35D
        ex af, af'
        nop
        nop
        nop
        ld bc, $2100
        nop
        nop
L_F3A6: call L_F342
        rrca
        jr c, L_F34F
        rrca
        jr nc, L_F3BB
        in a, (SCSDAT)
        cpl
        ld (hl), a
        ld a, l
        cp $7F
        jr z, L_F3A6
        inc hl
        jr L_F3A6


L_F3BB:
        in a, ($E6)
        cpl
        ld b, a
        call L_F342
        rrca
        jr c, L_F34F
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
        jr z, L_F407
        cp $0D
        jp nz, IOPUT
        ld a, $0A
        call IOPUT
L_F407: ld a, $0D
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
L_F418: in a, ($BD)
        and $20
        jr z, L_F418
        pop af
        and $7F
        out ($B8), a
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
L_F440: cp $61                  ; "a"
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


POLSER: in a, ($BD)             ; check for character from serial
        and $01
        ret z
GETSER: in a, ($BD)             ; block, waiting for character from serial
        and $01
        jr z, GETSER
        in a, ($B8)
        and $7F
        jr L_F440


CMD_A:  ld hl, MSG6             ; select master drive
        call PRS
L_F468: call IOGET              ; get character
        sub $31
        jr c, L_F468            ; illegal
        cp $04                  ; 1-4 are legal (not 1-2 per message)
        jr nc, L_F468           ; illegal
        ld c, $00
L_F475: ld b, a                 ; common path for CMD_A, CMD_8; C differs
        inc b
        xor a
        scf
L_F479: rla
        djnz L_F479
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
        jr L_F475


MSG7:   defb $0D
        defm "Select 8\" Drive (1-4) "
        defb $00

MSG8:   defm "  "
        defb $1A, $0A, $0A, $0A, $09
        defm "@ MultiBoard Computer System @"
        defb $0D, $0A, $0A, $00

MSG9:   defm "This is spare"    ; never referenced

MSG18:  defb $0D, $0A
        defm "       SImple MONitor Version 4.4"
        defb $0D, $0A, $00

MSG10:  defm "         GM809/829 present"
        defb $0D, $0A, $00

MSG11:  defm "         GM849/849A present"
        defb $0D, $0A, $00


L_F565: xor a
        out (FDCDRV), a         ; turn off all the drives
        ld hl, MSG18            ; SIMON banner
        call PRS
        ld a, $0F
        out (SCSCTL), a
        in a, (SCSCTL)
        rlca
        ld hl, MSG11            ; detected GM849 disk controller
        jr nc, L_F57D
        ld hl, MSG10            ; detected GM809/829 disk controller
L_F57D: call PRS
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
        jr c, L_F5EF
        cp $41
        ret c
        cp $47
        ccf
        ret c
        sub $07
L_F5EF: and $0F
        ret


XP4HEX: ld a, h
        call XP2HEX
        ld a, l
XP2HEX: push af
        rrca
        rrca
        rrca
        rrca
        call L_F600
        pop af
L_F600: and $0F
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
L_F615: call XCHRIN
        cp $30
        ret c
        cp $3A
        jr c, L_F628
        cp $41
        ret c
        cp $47
        ccf
        ret c
        sub $07
L_F628: and $0F
        ret


L_F62B: ld hl, $0000
        call L_F615
        jr nc, L_F639
        cp $20
        jr z, L_F62B
        scf
        ret


L_F639: add hl, hl
        ret c
        add hl, hl
        ret c
        add hl, hl
        ret c
        add hl, hl
        ret c
        add a, l
        ld l, a
        call L_F615
        jr nc, L_F639
        cp $20
        ret z
        cp $0D
        ret z
        scf
        ret


GET16: call L_F62B              ; get 16-bit value in HL (not at end of line)
        jr c, L_F658
        cp $20
        ret z
L_F658: pop hl
        jp CMDERR


GET16F: call L_F62B             ; get final 16-bit value to HL (expect end-of-line else error)
        jr c, L_F658
        cp $0D
        ret z
        jr L_F658


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
        call L_F62B             ; enter new value or <return> to go to next or - to go back or space to exit?
        ex de, hl
        push af
        cp $0D
        call nz, XCRLF
        pop af
        jr nc, L_F6BF
        cp $0D
        jr z, L_F6BE
        cp "-"
        ret nz
        dec hl                  ; previous memory location
        jr SLOP                 ; loop


L_F6BE: ld e, (hl)
L_F6BF: ld a, d
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
        jr nz, L_F715
        call XSPACE
        ld a, "-"               ; " - " between first 8 and second 8 bytes
        call XCHROUT
L_F715: djnz DDATA
L_F717: call XCRLF
        dec c                   ; line count
        jr nz, DADDR
        ret


;;; Report version
CMD_V:  ld hl, MSG20
        jp PRS                  ; print and return (tail-recurse)


;;; The rest of the ROM image is unreachable code. It looks like a "high tide mark" of older assembly runs
;;; that have been left in memory and which ended up in the ROM.

        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF

;;; TODO unreachable code. This looks like a fragment of the end of CMD_S
        push af
        cp $0D
        call nz, XCRLF
        pop af
        jr nc, L_F73F
        cp $0D
        jr z, L_F73E
        cp $2D
        ret nz
        dec hl
        jr L_F717


;;; TODO unreachable code - more of CMD_S
L_F73E: ld e, (hl)
L_F73F: ld a, d
        or a
        jp nz, CMDERR
        ld (hl), e
        ld a, (hl)
        cp e
        jp nz, CMDERR
        inc hl
        jr L_F717

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

;;; looks like a copy of CMD_O
        call GET16F
        ld a, h
        or a
        jp nz, CMDERR
        ld c, l
        in a, (c)
        call XP2HEX
        jp XCRLF

;;; looks like a copy of CMD_D
        call GET16
        ex de, hl
        call GET16F
        ld c, l
        ex de, hl
        call XP4HEX
        ld b, $10
