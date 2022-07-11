;;; SIMON version 5.0 (For HD64180). Hitachi HD64180 is a microcontroller that executes
;;; the Z80 instruction set and integrates additional stuff like a memory management unit
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
;;; M                - ?? memory test
;;;
;;; Seems to run from ROM at 0, expects RAM at $8000 (loads and executes boot sector code there)
;;; and RAM at $9000 (uses some scratch locations there). BUT, this code is 8Kbytes in size
;;; (compared with 2Kbytes) with 2 big unused chunks


L_8002: equ $8002               ; entry point of loaded boot sector
L_80F4: equ $80F4

L_90E6: equ $90E6               ; 1st entry in JPTAB1 or JPTAB2 POLL STATUS
L_90E9: equ $90E9               ; 2nd entry in JPTAB1 or JPTAB2 GET CHAR
L_90EC: equ $90EC               ; 3rd entry in JPTAB1 or JPTAB2 PUT CHAR

;;; Ports for GM811/GM813 CPU board

KBD:    equ $B0                 ; keyboard - GM811 only UNUSED HERE

PIOADAT:equ $B4                 ; UNUSED HERE
PIOBDAT:equ $B5                 ; UNUSED HERE
PIOACTL:equ $B6                 ; UNUSED HERE
PIOBCTL:equ $B7                 ; UNUSED HERE

MMAP:   equ $FE                 ; memory mapper - GM813 only
PMOD:   equ $FF                 ; page mode     - GM813 only

UARTDAT:equ $B8                 ; data holding
UARTIE: equ $B9                 ; interrupt enable
UARTII: equ $BA                 ; interrupt identification UNUSED HERE
UARTLC: equ $BB                 ; line control
UARTMC: equ $BC                 ; modem control
UARTLS: equ $BD                 ; line status
UARTMS: equ $BE                 ; modem status             UNUSED HERE


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

        org $0000

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
        defm "29-01-88 "        ; (falls through to print the GG CR also)

MSG19:  defm "GG"               ; magic compared with first 2 bytes of boot sector
        defb $0D, $00


XCOLD:  ld sp, COLD
        ld hl, $FFFF
        xor a
L_003A: dec hl
        cp h
        jr nz, L_003A           ; wait until delay loop has decremented from $ffff to $00ff
        ld a, $83
        ld c, $36
        ld b, $00
        out (c), a              ; port $36: refresh control
        xor a
        ld c, $32
        out (c), a              ; port $32: DMA/wait control
        out (IVCRST), a         ; reset IVC
        ld hl, $FFFF
        xor a
L_0051: dec hl
        cp h
        jr nz, L_0051           ; wait until delay loop has decremented from $ffff to $00ff
        ld a, $01
        out (FDCDRV), a         ; select drive 0/A
        ld b, $05
L_005B: ld hl, $0000
L_005E: dec hl
        ld a, h
        or l
        jr nz, L_005E
        djnz L_005B             ; wait for drive to come up to speed
        ld sp, COLD
        call L_0207
        xor a                   ; TODO wot's appenin?
        ld i, a
        ld a, i
        ld a, $01
        push af
        ld i, a
        pop af
        jr z, L_007B
        ld a, ($90EF)           ; drive select value for boot drive
L_007B: ld ($90EF), a           ; comes here from A and B commands
        push af
        ld a, $F3
        out (SCSCTL), a
        ld a, $E3
L_0085: dec a
        jr nz, L_0085
        ld a, $F7
        out (SCSCTL), a
        ld hl, MSG8             ; clear screen, power-on message
        call PRS
        pop af
        jr nz, L_00F5
        jp L_0165


MSG2:   defm " while loading Boot sector"
        defb $00

MSG3:   defm " during System load"
        defb $00

;;; TODO how is this used?
MSG4:   defb $C0, $D2, $C5, $C1, $C4, $80, $C5, $D2, $D2, $CF, $D2, $C0, $00

MSG5:   defm " - Press any key to repeat<"
        defb $00


X00F0:  ld hl, MSG2             ; (error) while loading boot sector
        jr L_00F8


L_00F5: ld hl, MSG3             ; (error) during System load
L_00F8: push hl
        ld hl, MSG4             ; ??
        call PRS
        pop hl
        call PRS
        ld hl, MSG5             ; press any key to repeat<
L_0106: call PRS
L_0109: call X02BB
X010C:  jr z, L_0110
        jr nc, L_0109
L_0110: call L_031D
X0113:  jr L_0165


;;; TODO how is this used?
MSG15:  defm "<"
        defb $09, $09, $09
        defm "<"
        defb $09, $80, $C9, $EE, $F3, $E5, $F2, $F4, $80, $C4, $E9, $F3, $EB, $80, $E9, $EE, $80, $E4, $F2, $E9, $F6, $E5, $80, $00

MSG16:  defb $A0                ; TODO no reference
        defm "<"
        defb $00


L_0135: ld hl, MSG15
        call PRS
        ld a, ($90EF)           ; get drive
        ld b, $C0
L_0140: inc b
        rrca
        jr nc, L_0140
        ld a, b
        cp $C1
        jr z, L_014B
        sub $10
L_014B: call XCHROUT
        jp PRS                  ; print and return (tail-recurse)


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
        jr L_0188


L_0175: in a, (FDCSTA)
        bit 0, a
        jr nz, L_0175           ; wait until done?
        ld a, $5B
        call CMD2FDC            ; STEP IN?
        ld a, $0B
        call CMD2FDC            ; RESTORE
        call L_01D4
L_0188: or a
        jp nz, X00F0
        ld hl, ($8000)          ; get first 2 bytes from boot sector
        ld de, (MSG19)          ; "GG"
        or a
        sbc hl, de
        call z, X0320           ; if good disk??
        ld a, ($90EF)           ; get drive
        jp z, L_8002            ; enter code loaded from boot sector (first 2 bytes is "magic" eg GG for Gemini)
        ld hl, MSG17
        jp L_0106


;;; TODO how is this used?
MSG17:  defb $09, $80, $C0, $CE, $EF, $80, $F2, $E5, $E3, $EF, $E7, $EE, $E9, $F3, $E1, $E2
        defb $EC, $E5, $80, $C3, $D0, $AF, $CD, $80, $F3, $F9, $F3, $F4, $E5, $ED, $80, $EF
        defb $EE, $80, $F4, $E8, $E9, $F3, $80, $E4, $E9, $F3, $EB, $C0, $80
        defm "<"
        defb $00


L_01D4: ld a, $0B
        call CMD2FDC            ; RESTORE
        ld a, ($90EF)           ; get drive
        and $20
        jr z, L_01E2
        ld a, $01
L_01E2: out (FDCSEC), a
        ld hl, $8000
        ld c, FDCDRV
        ld a, $88
        out (FDCCMD), a         ; READ SECTOR
        ld b, $80
        jr L_01F1               ; why not fall through? Bug, or need slight delay?


L_01F1: in a, (c)               ; data?
        jr z, L_01F1            ; no data
        in a, (FDCDAT)          ; get data
        ld (hl), a              ; store
        inc hl                  ; next location
        djnz L_01F1             ; total of $80 (128) bytes
L_01FB: in a, (c)               ; read and discard remaining bytes, if any
        jr z, L_01FB
        in a, (FDCDAT)
        jp m, L_01FB
        in a, (FDCSTA)
        ret


L_0207: xor a
        ld ($90F0), a           ; record what I/O is used (default to IVC)
        ld hl, JPTAB1
        call CP92E6             ; use JPTAB1 vectors -- use IVC
        in a, (IVCDAT)
        ld a, $1A               ; home/clear screen
        out (IVCDAT), a
        in a, (IVCSTA)
        rrca
        ccf
        ld a, $FF
        ret c
        ld hl, $0000
L_0221: dec hl
        ld a, h
        or l
        scf
        ld a, $FF
        ret z                   ; timeout waiting - maybe no IVC?
        in a, (IVCSTA)
        rrca
        jr c, L_0221
L_022D: ld hl, $0000
        ld a, $1B
        call PUTIVC
X0235:  ld a, $76               ; get version number of IVC software
        call PUTIVC
L_023A: dec hl
        ld a, h
        or l
        jr z, L_022D            ; timeout; try again
        in a, (IVCSTA)
        rlca
        jr c, L_023A            ; wait
        xor a
        in a, (IVCDAT)          ; version number in A
        ret


;;; TODO never come here; looks as though can ONLY use IVC for I/O, in which
;;; case there's lots of unused code here for UART and its I/O vectors.
X0248:  ld hl, JPTAB2           ; use UART for kbd/display
        call CP92E6
        ld a, $03
        out (UARTLC), a
        ld a, $07
        out (UARTMC), a
        ld c, UARTLC
L_0258: ld hl, BAUDTAB
L_025B: ld e, (hl)
        inc hl
        ld d, (hl)
        inc hl
        ld a, d
        or e
        jr z, L_0258
        ld a, $83
        out (c), a              ; allow access to UART baud rate divisor registers
        ld a, e
        out (UARTDAT), a        ; set baud rate divisor lo
        ld a, d
        out (UARTIE), a         ; set baud rate divisor hi
        ld a, $03
        out (c), a              ; restore access to UART data/interrupt registers
        call L_90E9
        cp $0D
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


JPTAB1: jp POLIVC               ; vectored I/O using IVC
        jp GETIVC
        jp PUTIVC
JPTAB2: jp POLSER               ; vectored I/O using UART
        jp GETSER
        jp PUTSER


X02B6:  ld a, ($90F0)           ; says what type of I/O is in use??
        or a
        ret


X02BB:  in a, (FDCDRV)
        inc a
        jr z, L_02FC
        ld a, $D0
        call CMD2FDC            ; FORCE INTERRUPT
X02C5:  ld a, ($90EF)           ; get drive
        out (FDCDRV), a
        ld a, $0B
        out (FDCCMD), a         ; RESTORE
        ld b, $00
L_02D0: djnz L_02D0
        ld hl, $FFFF
        in a, (FDCSTA)
        ld c, a
L_02D8: in a, (FDCSTA)
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
        out ($FB), a            ; What is port FB??
        out ($FC), a            ; What is port FC??
        ld bc, $80F8
        inir
        ld hl, ($8000)          ; get first 2 bytes from boot sector
        ld de, (MSG19)          ; "GG"
        or a
        sbc hl, de
        ret nz                  ; bad disk?
        jp L_8002               ; enter code loaded from boot sector (first 2 bytes is "magic" eg GG for Gemini)


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
        jp L_0514               ; ?did not autoboot; continue to command loop


X033C:  call X02B6
        ld hl, MSG13            ; delete to end of line
        jp z, PRS
        ld hl, MSG14            ; "<"
        jp PRS                  ; print and return (tail-recurse)


MSG13:  defb $1B, $2A, $00      ; delete to end of line

MSG14:  defm "<"
        defb $00


CMD2FDC:out (FDCCMD), a         ; send command in A to FDC then wait then poll status (for completion?)
        ld a, $0F               ; delay loop count for command acceptance
L_0354: dec a
        jr nz, L_0354           ; wait a little while
L_0357: in a, (FDCSTA)          ; read status
        bit 0, a                ; completion?
        jr nz, L_0357           ; not yet.. loop
        ret                     ; done


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
        in a, (SCSCTL)
        and $10
        jr z, L_0378
        pop af
        dec a
        jr nz, L_036B
        jr L_0379


L_0378: pop af
L_0379: ld a, $F7
        out (SCSCTL), a
        ret


X037E:  in a, (SCSCTL)
        and $10
        ld a, $01
        ret nz
L_0385: in a, (SCSCTL)
        rrca
        jr c, L_0385
        ret


X038B:  ld a, $FF
        out (SCSDAT), a
        ld b, $00
L_0391: in a, (SCSDAT)
        djnz L_0391
        ld a, $04
        or a
        ret


X0399:  ld b, $00
L_039B: in a, (SCSCTL)
        or $E0
        inc a
        jr z, L_03A6
        djnz L_039B
        jr X038B


L_03A6: ld a, $FE
        out (SCSDAT), a
        ld a, $F5
        out (SCSCTL), a
        call X036A
X03B1:  pop hl
        call X037E
X03B5:  ld a, (hl)
        cpl
        out (SCSDAT), a
        inc hl
        inc hl
        call X037E
        ld a, ($90EF)           ; get drive
        dec a
        jr z, L_03C6
        ld a, $20
L_03C6: cpl
        out (SCSDAT), a
        ld b, $04
L_03CB: call X037E
        ld a, (hl)
        cpl
        out (SCSDAT), a
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
        in a, (SCSDAT)
        cpl
        ld (hl), a
        ld a, l
        cp $7F
        jr z, L_03E2
        inc hl
        jr L_03E2


L_03F7: in a, (SCSDAT)
        cpl
        ld b, a
        call X037E
        rrca
        jr c, X038B
        in a, (SCSDAT)
        ld a, b
        and $0F
        ret


CMD_A:  ld hl, MSG6             ; select master drive
        call PRS
L_040D: call L_90E9             ; get character
        sub $31
        jr c, L_040D            ; illegal
        cp $04                  ; 1-4 are legal (not 1-2 per message)
        jr nc, L_040D           ; illegal
        ld c, $00
L_041A: ld b, a                 ; common path for CMS_A, CMD_8; C differs
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


CMD_8:  ld hl, MSG7             ; select 8" drive..
        call PRS
L_044C: call L_90E9             ; get character
        sub $31
        jr c, L_044C            ; illegal
        cp $04                  ; 1-4 are legal
        jr nc, L_044C           ; illegal
        ld c, $30
        jr L_041A


MSG7:   defb $0D
        defm "Select 8\" Drive (1-4) "
        defb $00

MSG8:   defm "  "
        defb $1A                ; home/clear screen
        defb $0A, $0A, $0A, $09 ; CR CR CR TAB
        defm "@ MultiBoard Computer System @"
        defb $0D, $0A, $0A, $00

MSG9:   defm "This is spare"    ; never referenced

MSG18:  defb $0D, $0A
        defm "       SImple MONitor Version 5.0 (HD64180)"
        defb $0D, $0A, $00

MSG10:  defm "         GM809/829 present"
        defb $0D, $0A, $00

MSG11:  defm "         GM849/849A present"
        defb $0D, $0A, $00


L_0514: xor a
        out (FDCDRV), a         ; turn off all the drives
        ld hl, MSG18            ; SIMON banner
        call PRS
        ld a, $0F
        out (SCSCTL), a
        in a, (SCSCTL)
        rlca
        ld hl, MSG11            ; detected GM849 disk controller
        jr nc, L_052C
        ld hl, MSG10            ; detected GM809/829 disk controller
L_052C: call PRS
CMDLOP: ld sp, COLD
        ld a, ">"               ; prompt
        call XCHROUT
X0537:  call XCHROUT
        ld hl, CMDLOP           ; each command ends with a RET which takes it back to CMDLOP
        push hl
        call XCHRIN             ; get single-letter command
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
        jp z, CMD_O             ; out to port
        cp $51
        jp z, CMD_Q             ; query from port
        cp $44
        jp z, CMD_D
        cp $56
        jp z, CMD_V
        cp $38
        jp z, CMD_8
        cp $4D
        jp z, CMD_M             ; new cmd not in SIMON 4.2
CMDERR: ld hl, MSG12
        jp PRS                  ; print and return (tail-recurse)


MSG12:  defm "  -What?"
        defb $0D, $00

CMD_B:  ld a, ($90EF)           ; get drive
        jp L_007B


CMD_C:  call GET16              ; get from address in HL
X0596:  ex de, hl
        call GET16              ; get to address in HL
        ld b, h
        ld c, l
        call GET16F             ; get length in HL terminated by end-of-line
X059F:  push bc
        ex (sp), hl
        pop bc
        ex de, hl
        ldir
        ret


;;; Go (execute) at address
CMD_G:  call GET16F             ; get address in HL terminated by end-of-line
        jp (hl)


;;; Fill from length byte
CMD_F:  call GET16
        ex de, hl
        call GET16
        sbc hl, de
        ret c
        ld b, h
        ld c, l
        call GET16F             ; get fill value in HL terminated by end-of-line
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
X05C7:  ld a, $2D
        call XCHROUT
        ld a, (hl)
        call XP2HEX             ; report byte value at address
X05D0:  call XSPACE
X05D3:  ex de, hl
        call L_104C             ; enter new value or <return> to go to next or - to go back or space to exit?
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
        dec hl                  ; previous memory location
        jr SLOP                 ; loop


L_05EB: ld e, (hl)
L_05EC: ld a, d
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
        call GET16F             ; get value in HL terminated by end-of-line
        ld a, h
        or a
        jp nz, CMDERR           ; error: expect value 0-ff therefore H should be 0
        out (c), l              ; write to port
        ret                     ; done


;;; Query (read from) I/O port
CMD_Q:  call GET16F             ; get port address in HL terminated by end-of-line
        ld a, h
        or a
        jp nz, CMDERR           ; error: expect port 0-ff therefore H should be 0
        ld c, l                 ; port in C
        in a, (c)               ; read from port
        call XP2HEX             ; print 8-bit value
        jp XCRLF                ; CR and return (tail-recurse)


MSG21:  defm "     00 01 02 03 04 05 06 07  08 09 0A 0B 0C 0D 0E 0F        ASCII"
        defb $0D, $0A, $00


;;; Display memory
CMD_D:  call GET16F             ; get address in HL terminated by end-of-line
        ld d, h                 ; copy into DE to address for ASCII display
        ld e, l
DADDR: push hl
        ld hl, MSG21
        call PRS
        pop hl
        ld b, $10               ; 16 bytes per line
DADDR2:  push bc
        call XP4HEX
        ld b, $10
HEXDIS: call XSPACE
        ld a, (hl)
        call XP2HEX             ; print byte
        inc hl                  ; next address
        ld a, $09
        cp b
        jr nz, NOSPC
        call XSPACE             ; space between first 8 and second 8 hex bytes
NOSPC:  djnz HEXDIS
        call XSPACE
        call XSPACE
        ld b, $10
ASC:    ld a, (de)
        cp $3C
        jr z, NODIS
        cp $20
        jr nc, ASCDIS
NODIS:  ld a, $2E               ; not displayable.. print "." instead
ASCDIS: call XCHROUT            ; print as ASCII
        inc de
        djnz ASC
        call XCRLF
        pop bc
        djnz DADDR2
        call L_90E9
        cp $1B
        ret z
        call XCRLF
        call XCRLF
        call XCRLF
        jr DADDR


;;; Report version
CMD_V:  ld hl, MSG20
        jp PRS                  ; print and return (tail-recurse)


;;; Part of a memory test?
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

        ;; unused/spare region of EPROM.. but code carries on later..
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
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF


X1000:  cp $30
        ret c
        cp $3A
        jr c, L_1010
        cp $41
        ret c
        cp $47
        ccf
        ret c
        sub $07
L_1010: and $0F
        ret


XP4HEX: ld a, h
        call XP2HEX
        ld a, l
XP2HEX: push af
        rrca
        rrca
        rrca
        rrca
        call L_1021
        pop af
L_1021: and $0F
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
L_1036: call XCHRIN
        cp $30
        ret c
        cp $3A
        jr c, L_1049
        cp $41
        ret c
        cp $47
        ccf
        ret c
        sub $07
L_1049: and $0F
        ret


L_104C: ld hl, COLD
        call L_1036
        jr nc, L_105A
        cp $20
        jr z, L_104C
        scf
        ret


L_105A: add hl, hl
        ret c
        add hl, hl
        ret c
        add hl, hl
        ret c
        add hl, hl
        ret c
        add a, l
        ld l, a
        call L_1036
        jr nc, L_105A
        cp $20
        ret z
        cp $0D
        ret z
        scf
        ret


GET16:  call L_104C             ; get 16-bit value in HL (not at end of line)
        jr c, L_1079
        cp $20
        ret z
L_1079: pop hl
        jp CMDERR


GET16F: call L_104C             ; get final 16-bit value to HL (expect end-of-line else error)
        jr c, L_1079
        cp $0D
        ret z
        jr L_1079


PRS:    ld a, (hl)              ; print 0-terminated string at (HL)
        inc hl                  ; ??with special treatment of 0x80 and others?
        or a
        ret z
        cp $80
        jr nz, L_1091
        ld a, $A0               ; change $80 to $A0??
L_1091: push bc
        ld bc, $1420
        cp $09                  ; TAB translates as "print 20 spaces"
        jr z, L_10A9
        ld bc, $052A
        cp $40                  ; @ translates as "print 5 *"
        jr z, L_10A9
        ld c, $AA               ; ???
        cp $C0                  ; ???
        jr z, L_10A9
        ld b, $01               ; default is to print character in A once
        ld c, a
L_10A9: ld a, c                 ; print character in C, B times
        call XCHROUT
        djnz L_10A9
        pop bc
        jr PRS


XCHRIN: call L_90E9
XCHROUT:cp $3C
        jr z, L_10C3
        cp $0D
        jp nz, L_90EC
        ld a, $0A
        call L_90EC
L_10C3: ld a, $0D
        call L_90EC
        ret


PUTIVC: push af
L_10CA: in a, ($B2)
        rrca
        jr c, L_10CA
        pop af
        out (IVCDAT), a
        ret


PUTSER: push af
L_10D4: in a, (UARTLS)
        and $20
        jr z, L_10D4
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
L_10FC: cp $61                  ; "a"
        ret c
        cp $7B                  ; "z" + 1
        ret nc
        and $5F                 ; force alphabetic to upper case
        ret


INIVC:  in a, (IVCSTA)             ; wait for byte from IVC
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
        jr L_10FC


;;; Memory test?
CMD_M:  ld hl, $0000             ; copy 16Kbytes from ROM to RAM?
        ld de, $0000
        ld bc, $4000
        ldir
        ld a, $01
        ld bc, $0114
        out (c), a              ; port $14
        ld b, $00
L_1132: djnz L_1132             ; pause
        call XCRLF
        ld hl, $0008
        ld b, $02
L_113C: push hl
        push bc
        ld bc, $003A
        ld a, $10
        out (c), a              ; port $3a
        pop bc
        push bc
        ld a, b
        ld bc, $0039
        out (c), a              ; port $39
        ld hl, $00FF
        ld a, (hl)
        ld e, a
        ld a, $CC
        ld b, a
        ld (hl), a
        xor a
        ld a, (hl)
        cp b
        ld a, e
        ld (hl), a
        pop bc
        ld a, b
        ld ($11D1), a
        pop hl
        jr nz, L_11B8
        push bc
        xor a
        ld bc, $0039
        out (c), a              ; port $39
        ld de, $0004
        add hl, de
        push hl
        ld de, $1197            ; write the memory size over the 0000 in the string
        call L_1293
        ld a, $0D
        call L_90EC
        ld hl, MSG22            ; "Checking XXXXK of memory...."
        call PRS
        pop hl
        pop bc
        inc b
        ld a, b
        inc a
        inc a
        inc a
        inc a
        inc a
        inc a
        jr z, L_11B8
        jr L_113C


MSG22:  defm "Checking "
L_1197: defm "0000K of memory......"
        defb $00

MSG23:  defm "completed"
        defb $0D, $00


L_11B8: ld a, ($11D1)
        dec a
        ld ($11D1), a
        ld bc, $003A
        ld a, $10
        out (c), a              ; port $3A
        xor a
        ld bc, $0039
        out (c), a              ; port $39
        ld b, $00
L_11CE: push bc
        ld a, b
        cp $F8
        pop bc
        jr z, L_11FA
        cp $01
        jr nz, L_11DA
        inc b
L_11DA: push bc
        ld bc, $003A            ; port 3A
        ld a, $10
        out (c), a
        pop bc
        push bc
        ld a, b
        ld ($1292), a
        ld bc, $0039
        out (c), a              ; port $39
        call L_120A
        xor a
        ld bc, $0039
        out (c), a              ; port $39
        pop bc
        inc b
        jr L_11CE


L_11FA: call X06C1
        ld hl, MSG23
        call PRS
        xor a
        ld bc, $0114
        out (c), a              ; port $14
        ret


L_120A: xor a
        call L_121E
        ld a, $FF
        call L_121E
        ld a, $55
        call L_121E
        ld a, $AA
        call L_121E
        ret


L_121E: ld hl, COLD
        ld bc, X1000
        ld e, a
L_1225: ld a, (hl)
        ld d, a
        ld a, e
        ld (hl), a
        inc a
        ld a, (hl)
        cp e
        jr z, L_126F
        push bc
        push hl
        push de
        push hl
        ld b, a
        ld hl, MSG24
        call PRS
        ld a, ($1292)
        rra
        rra
        rra
        rra
        and $0F
        call XP2HEX
        pop hl
        ld a, ($1292)
        and $0F
        rlca
        rlca
        rlca
        rlca
        ld c, a
        ld a, h
        and $0F
        or c
        ld h, a
        call XP4HEX
        ld hl, MSG25
        call PRS
        pop de
        ld a, e
        call XP2HEX
        ld hl, MSG26
        call PRS
        ld a, b
        call XP2HEX
        pop hl
        pop bc
L_126F: ld a, d
        ld (hl), a
        inc hl
        dec bc
        ld a, b
        or c
        jr nz, L_1225
        ret


MSG24:  defb $0D
        defm "Error at "
        defb $00

MSG25:  defm " Write "
        defb $00

MSG26:  defm " Read "
        defb $00

        defb $00


L_1293: ld bc, $03E8
        call L_12AA
        ld bc, $0064
        call L_12AA
        ld bc, $000A
        call L_12AA
        ld a, l
        add a, $30
        ld (de), a
        ret


L_12AA: ld a, $2F
        or a
L_12AD: inc a
        sbc hl, bc
        jr nc, L_12AD
        add hl, bc
        ld (de), a
        inc de
        ret

        ;; rest of the 8Kbytes is unused
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
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
        defb $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5
        defb $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5
        defb $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5
        defb $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5
        defb $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5
        defb $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5
        defb $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5
        defb $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5
        defb $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5
        defb $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5
        defb $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5
        defb $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5
        defb $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5
        defb $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5
        defb $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5
        defb $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5
        defb $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5
        defb $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5
        defb $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5
        defb $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5
        defb $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5
        defb $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5
        defb $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5
        defb $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5
        defb $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5
        defb $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5
        defb $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5
        defb $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5
        defb $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5
        defb $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5
        defb $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5
        defb $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5, $E5
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
; $00F0 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBCCCCCCCCCCC
; $0140 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $0190 CCCCCCCCCCCCCCCCCCCCCBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBCCCCCCCCCCCC
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
; $0500 BBBBBBBBBBBBBBBBBBBBCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $0550 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCBBBBBBBBBBCCCCCCCCCCCCCCCCCCC
; $05A0 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $05F0 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $0640 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $0690 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $06E0 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCBBBBBBBBBBBBBBBBBBBBBBBB
; $0730 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $0780 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $07D0 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $0820 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $0870 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $08C0 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $0910 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $0960 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $09B0 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $0A00 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $0A50 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $0AA0 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $0AF0 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $0B40 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $0B90 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $0BE0 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $0C30 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $0C80 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $0CD0 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $0D20 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $0D70 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $0DC0 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $0E10 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $0E60 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $0EB0 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $0F00 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $0F50 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $0FA0 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $0FF0 BBBBBBBBBBBBBBBBCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $1040 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $1090 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $10E0 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $1130 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $1180 CCCCCCCCCCCCCCBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBCCCCCCCCCCCCCCCCCCCCCCCC
; $11D0 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $1220 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $1270 CCCCCCCCBBBBBBBBBBBBBBBBBBBBBBBBBB-CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCBBBBBBBBBB
; $12C0 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $1310 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $1360 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $13B0 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $1400 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $1450 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $14A0 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $14F0 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $1540 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $1590 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $15E0 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $1630 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $1680 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $16D0 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $1720 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $1770 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $17C0 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $1810 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $1860 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $18B0 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $1900 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $1950 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $19A0 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $19F0 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $1A40 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $1A90 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $1AE0 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $1B30 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $1B80 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $1BD0 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $1C20 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $1C70 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $1CC0 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $1D10 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $1D60 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $1DB0 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $1E00 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $1E50 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $1EA0 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $1EF0 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $1F40 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $1F90 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $1FE0 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB

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
; $0115 => MSG15          L_0110  => $0110
; $0132 => MSG16          L_0135  => $0135
; $0135 => L_0135         L_0140  => $0140
; $0140 => L_0140         L_014B  => $014B
; $014B => L_014B         L_0151  => $0151
; $0151 => L_0151         L_0165  => $0165
; $0154 => X0154          L_0175  => $0175
; $0157 => X0157          L_0188  => $0188
; $0165 => L_0165         L_01D4  => $01D4
; $0173 => X0173          L_01E2  => $01E2
; $0175 => L_0175         L_01F1  => $01F1
; $0188 => L_0188         L_01FB  => $01FB
; $01A5 => MSG17          L_0207  => $0207
; $01D4 => L_01D4         L_0221  => $0221
; $01E2 => L_01E2         L_022D  => $022D
; $01F1 => L_01F1         L_023A  => $023A
; $01FB => L_01FB         L_0258  => $0258
; $0207 => L_0207         L_025B  => $025B
; $0221 => L_0221         L_02D0  => $02D0
; $022D => L_022D         L_02D8  => $02D8
; $0235 => X0235          L_02E1  => $02E1
; $023A => L_023A         L_02FA  => $02FA
; $0248 => X0248          L_02FC  => $02FC
; $0258 => L_0258         L_031D  => $031D
; $025B => L_025B         L_0354  => $0354
; $0274 => X0274          L_0357  => $0357
; $0281 => BAUDTAB        L_036B  => $036B
; $029B => CP92E6         L_0378  => $0378
; $02A4 => JPTAB1         L_0379  => $0379
; $02A7 => X02A7          L_0385  => $0385
; $02AA => X02AA          L_0391  => $0391
; $02AD => X02AD          L_039B  => $039B
; $02B0 => X02B0          L_03A6  => $03A6
; $02B3 => X02B3          L_03C6  => $03C6
; $02B6 => X02B6          L_03CB  => $03CB
; $02BB => X02BB          L_03E2  => $03E2
; $02C5 => X02C5          L_03F7  => $03F7
; $02D0 => L_02D0         L_040D  => $040D
; $02D8 => L_02D8         L_041A  => $041A
; $02E1 => L_02E1         L_041E  => $041E
; $02FA => L_02FA         L_044C  => $044C
; $02FC => L_02FC         L_0514  => $0514
; $031D => L_031D         L_052C  => $052C
; $0320 => X0320          L_057D  => $057D
; $0323 => X0323          L_05C4  => $05C4
; $033C => X033C          L_05EB  => $05EB
; $034B => MSG13          L_05EC  => $05EC
; $034E => MSG14          L_0669  => $0669
; $0350 => X0350          L_0673  => $0673
; $0354 => L_0354         L_0679  => $0679
; $0357 => L_0357         L_0689  => $0689
; $035E => X035E          L_0693  => $0693
; $0361 => X0361          L_069C  => $069C
; $036A => X036A          L_069E  => $069E
; $036B => L_036B         L_06D5  => $06D5
; $0378 => L_0378         L_06DC  => $06DC
; $0379 => L_0379         L_070F  => $070F
; $037E => X037E          L_1010  => $1010
; $0385 => L_0385         L_1021  => $1021
; $038B => X038B          L_1036  => $1036
; $0391 => L_0391         L_1049  => $1049
; $0399 => X0399          L_104C  => $104C
; $039B => L_039B         L_105A  => $105A
; $03A6 => L_03A6         L_1071  => $1071
; $03B1 => X03B1          L_1079  => $1079
; $03B5 => X03B5          L_107D  => $107D
; $03C6 => L_03C6         L_1091  => $1091
; $03CB => L_03CB         L_10A9  => $10A9
; $03D6 => X03D6          L_10C3  => $10C3
; $03E2 => L_03E2         L_10C9  => $10C9
; $03F7 => L_03F7         L_10CA  => $10CA
; $0407 => CMD_A          L_10D3  => $10D3
; $040D => L_040D         L_10D4  => $10D4
; $041A => L_041A         L_10E0  => $10E0
; $041E => L_041E         L_10EF  => $10EF
; $0427 => MSG6           L_10FC  => $10FC
; $0446 => CMD_8          L_1105  => $1105
; $044C => L_044C         L_110D  => $110D
; $045B => MSG7           L_1112  => $1112
; $0473 => MSG8           L_1132  => $1132
; $049C => MSG9           L_113C  => $113C
; $04A9 => MSG18          L_11B8  => $11B8
; $04D9 => MSG10          L_11CE  => $11CE
; $04F6 => MSG11          L_11DA  => $11DA
; $0514 => L_0514         L_11FA  => $11FA
; $051D => CMDLOP         L_120A  => $120A
; $052C => L_052C         L_121E  => $121E
; $0537 => X0537          L_1225  => $1225
; $0541 => X0541          L_126F  => $126F
; $057D => L_057D         L_1293  => $1293
; $0583 => MSG12          L_12AA  => $12AA
; $058D => CMD_B          L_12AD  => $12AD
; $0593 => CMD_C          L_8002  => $8002
; $0596 => X0596          L_90E6  => $90E6
; $059F => X059F          L_90E9  => $90E9
; $05A6 => CMD_G          L_90EC  => $90EC
; $05AA => CMD_F          MSG1    => $0015
; $05C1 => CMD_S          MSG10   => $04D9
; $05C4 => L_05C4         MSG11   => $04F6
; $05C7 => X05C7          MSG12   => $0583
; $05D0 => X05D0          MSG13   => $034B
; $05D3 => X05D3          MSG14   => $034E
; $05D7 => X05D7          MSG15   => $0115
; $05EB => L_05EB         MSG16   => $0132
; $05EC => L_05EC         MSG17   => $01A5
; $05FA => CMD_O          MSG18   => $04A9
; $060E => CMD_Q          MSG19   => $002F
; $061F => MSG21          MSG2    => $0098
; $0664 => CMD_D          MSG20   => $0025
; $0669 => L_0669         MSG21   => $061F
; $0673 => L_0673         MSG22   => $118E
; $0679 => L_0679         MSG23   => $11AD
; $0689 => L_0689         MSG24   => $1278
; $0693 => L_0693         MSG25   => $1283
; $069C => L_069C         MSG26   => $128B
; $069E => L_069E         MSG3    => $00B3
; $06BB => CMD_V          MSG4    => $00C7
; $06C1 => X06C1          MSG5    => $00D4
; $06D5 => L_06D5         MSG6    => $0427
; $06DC => L_06DC         MSG7    => $045B
; $070F => L_070F         MSG8    => $0473
; $1000 => X1000          MSG9    => $049C
; $1010 => L_1010         P2HEX   => $0009
; $1013 => XP4HEX         P4HEX   => $000C
; $1018 => XP2HEX         PRS     => $1087
; $1021 => L_1021         SPACE   => $000F
; $102C => XCRLF          X006B   => $006B
; $1031 => XSPACE         X00F0   => $00F0
; $1036 => L_1036         X010C   => $010C
; $1049 => L_1049         X0113   => $0113
; $104C => L_104C         X0154   => $0154
; $105A => L_105A         X0157   => $0157
; $1071 => L_1071         X0173   => $0173
; $1079 => L_1079         X0235   => $0235
; $107D => L_107D         X0248   => $0248
; $1087 => PRS            X0274   => $0274
; $1091 => L_1091         X02A7   => $02A7
; $10A9 => L_10A9         X02AA   => $02AA
; $10B2 => XCHRIN         X02AD   => $02AD
; $10B5 => XCHROUT        X02B0   => $02B0
; $10C3 => L_10C3         X02B3   => $02B3
; $10C9 => L_10C9         X02B6   => $02B6
; $10CA => L_10CA         X02BB   => $02BB
; $10D3 => L_10D3         X02C5   => $02C5
; $10D4 => L_10D4         X0320   => $0320
; $10E0 => L_10E0         X0323   => $0323
; $10EF => L_10EF         X033C   => $033C
; $10FC => L_10FC         X0350   => $0350
; $1105 => L_1105         X035E   => $035E
; $110D => L_110D         X0361   => $0361
; $1112 => L_1112         X036A   => $036A
; $111E => CMD_M          X037E   => $037E
; $1132 => L_1132         X038B   => $038B
; $113C => L_113C         X0399   => $0399
; $118E => MSG22          X03B1   => $03B1
; $11AD => MSG23          X03B5   => $03B5
; $11B8 => L_11B8         X03D6   => $03D6
; $11CE => L_11CE         X0537   => $0537
; $11DA => L_11DA         X0541   => $0541
; $11FA => L_11FA         X0596   => $0596
; $120A => L_120A         X059F   => $059F
; $121E => L_121E         X05C7   => $05C7
; $1225 => L_1225         X05D0   => $05D0
; $126F => L_126F         X05D3   => $05D3
; $1278 => MSG24          X05D7   => $05D7
; $1283 => MSG25          X06C1   => $06C1
; $128B => MSG26          X1000   => $1000
; $1293 => L_1293         XCHRIN  => $10B2
; $12AA => L_12AA         XCHROUT => $10B5
; $12AD => L_12AD         XCOLD   => $0033
; $8002 => L_8002         XCRLF   => $102C
; $90E6 => L_90E6         XP2HEX  => $1018
; $90E9 => L_90E9         XP4HEX  => $1013
; $90EC => L_90EC         XSPACE  => $1031
