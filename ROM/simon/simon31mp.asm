;;; SIMON version 3.1mp
;;;
;;; Source recreated by disassembly; all comments inferred from code inspection
;;;
;;; 2Kbyte ROM decoded at address $F000
;;; Can boot automatically if disk present, else enter command-loop supporting these commands:
;;;
;;; B                - boot
;;; C ffff tttt cccc - copy cccc bytes from ffff to tttt. Can overwrite if regions overlap
;;; E aaaa           - execute at address aaaa
;;; F ffff cccc vv   - fill from ffff for cccc bytes with value vv
;;; M aaaa           - inspect and modify memory at address aaaa
;;; S aaaa           - inspect and modify memory at address aaaa
;;; O pp vv          - output (write) value vv to I/O port pp
;;; Q pp             - query (read) value from I/O port pp
;;; T ffff cc        - tabulate from ffff - cc lines of 16 bytes-per-line

BOOTGO: equ $0002               ; entry point of loaded boot sector
STACK:  equ $00FE               ; stack grows down from here

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
;;; 0x00FE, 0x00FF simon workspace. Initialised to 0x1000

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

MSG20:  defm " 26-10-82"        ; TODO never referenced

MSG19:  defm "GG"               ; magic compared with first 2 bytes of boot sector

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
        call USEIVC             ; Will execute at FXXX instead of 0XXX
        call nz, L_F52F
        call z, L_F1CA
        ld hl, MSG8             ; clear screen, power-on message
        call PRS
        ld a, i                 ; TODO wot's appenin?
        ld a, $FF
        ld i, a
        jp z, L_F12F
        jr L_F09F


MSG2:   defm " while loading Boot sector"
        defb $00

L_F085: ld hl, MSG2
        push hl
        jr L_F0D2


MSG3:   defm " during System load"
        defb $00

L_F09F: ld hl, MSG3
        push hl
        jr L_F0D2

;;; TODO how is this used?
MSG4:   defb $AA, $AA, $AA, $D2, $C5, $C1, $C4, $80, $C5, $D2, $D2, $CF, $D2, $AA, $AA, $AA, $00

MSG5:   defm " - Press any key to repeat<"
        defb $00

L_F0D2: ld hl, MSG4             ; ??
        call PRS
        pop hl
        call PRS
        ld hl, MSG5             ; - Press any key to repeat<
L_F0DF: call PRS
L_F0E2: call L_F1EA
        jr z, L_F0E9
        jr nc, L_F0E2

L_F0E9: call L_F222
        jr L_F12F


;;; TODO how is this used?
MSG15:  defm "             "
        defb $80, $C9, $EE, $F3, $E5, $F2, $F4, $80, $C4, $E9, $F3, $EB, $80, $E9, $EE, $80
        defb $E4, $F2, $E9, $F6, $E5, $80, $C1, $80
        defm "<"
        defb $00

L_F115: ld hl, MSG15
        call PRS
L_F11B: call USEIVC
        ld hl, MSG15
        call z, PRS
        call L_F1EA
        call L_F222
        call L_F1EA
        jr z, L_F11B
L_F12F: ld sp, STACK
        call L_F1EA
        jr z, L_F115
        inc a
        jr z, L_F13F
        call L_F2AB
        jr L_F152


L_F13F: in a, (FDCSTA)
        bit 0, a
        jr nz, L_F13F           ; wait until done
        ld a, $5B
        call CMD2FDC            ; STEP IN?
        ld a, $0B
        call CMD2FDC            ; RESTORE
        call RDSEC0             ; load sector 0 to RAM at 0
L_F152: or a
        jp nz, L_F085
        ld hl, ($0000)          ; get first 2 bytes from boot sector
        ld de, (MSG19)          ; "GG"
        or a
        sbc hl, de
        jp z, BOOTGO            ; if good disk??
        ld hl, MSG17            ; ??wot??
        jp L_F0DF


;;; TODO how is this used
MSG17:  defm "        "
        defb $80, $AA, $AA, $AA, $CE, $EF, $80, $C7, $C5, $CD, $C9, $CE, $C9, $80, $C3, $D0, $AF, $CD, $80, $F3, $F9, $F3, $F4, $E5, $ED, $80, $EF, $EE, $80, $F4, $E8, $E9, $F3, $80, $E4, $E9, $F3, $EB, $80, $AA, $AA, $AA, $80
        defm "<"
        defb $00


RDSEC0: ld a, $0B
        call CMD2FDC
        ld a, $00
        out (FDCSEC), a
        ld hl, $0000
        ld c, FDCDRV
        ld a, $88
        out (FDCCMD), a
        ld b, $80
        jr LDSEC                ; why not fall through? Bug, or need slight delay?


LDSEC:  in a, (c)               ; data byte available?
        jr z, LDSEC             ; not yet
        in a, (FDCDAT)          ; get data
        ld (hl), a              ; store
        inc hl                  ; next location
        djnz LDSEC              ; total of $80 (128) bytes
L_F1BE: in a, (c)               ; read and discard remaining bytes, if any
        jr z, L_F1BE
        in a, (FDCDAT)
        jp m, L_F1BE
        in a, (FDCSTA)
        ret


L_F1CA: in a, (IVCDAT)
        ld a, $1A               ; home/clear screen
        out (IVCDAT), a
L_F1D0: ld hl, $0000
        ld a, $1B
        call PUTXXX
        ld a, $76
        call PUTXXX
L_F1DD: dec hl
        ld a, h
        or l
        jr z, L_F1D0            ; timeout; try again
        in a, (IVCSTA)
        rlca
        jr c, L_F1DD            ; wait
        in a, (IVCDAT)          ; version number in A
        ret


L_F1EA: ld a, $D0
        call CMD2FDC
        ld a, $01
        out (FDCDRV), a
        ld a, $0B
        out (FDCCMD), a         ; RESTORE
        ld b, $28
L_F1F9: djnz L_F1F9
        ld hl, $D000
        in a, (FDCSTA)
        ld c, a
L_F201: in a, (FDCSTA)
        xor c
        and $02
        jr z, L_F20A
        ld b, $FF
L_F20A: dec l
        jr nz, L_F201
        call L_F230
        or a
        scf
        ret nz
        dec h
        jr nz, L_F201
        ld a, b
        or a
        ret nz
        call L_F25C
        jr nz, L_F220
        inc a
        ret


L_F220: xor a
        ret


L_F222: call USEIVC
        ld hl, MSG13
        jr z, L_F22D
        ld hl, MSG21
L_F22D: call PRS
L_F230: call PUTE6B
        or a
        ret z                   ; no key pressed
        call PUTE4B
        cp $13
        ld a, $01
        ret nz
        ld hl, MSG13
        call USEIVC
        call z, PRS
        jp L_F2FB


MSG13:  defb $1B                ; delete to end of line
        defm "*"
        defb $00


MSG21:  defb $0D, $00


CMD2FDC:out (FDCCMD), a         ; send command in A to FDC then wait then poll status (for completion?)
        ld a, $0A               ; delay loop count for command acceptance
L_F252: dec a
        jr nz, L_F252           ; wait a little while
L_F255: in a, ($E0)             ; read status
        bit 0, a                ; completion?
        jr nz, L_F255           ; not yet.. loop
        ret                     ; done


L_F25C: ld hl, $0100
        ld ($00FE), hl
        call L_F290
        nop
        nop
        nop
        nop
        nop
        nop
        call L_F2B7
        ld ($00FE), a
        ld ($00FF), a
        ret


L_F275: ld a, ($00FE)
        add a, $FF
        ret c
        ld c, $00

L_F27D: in a, (SCSCTL)
        rrca
        ret nc
        dec c
        jr nz, L_F27D
        ld a, ($00FF)
        or a
        jr z, L_F27D
        scf
        ret


L_F28C: ld a, $04
        or a
        ret


L_F290: in a, (SCSCTL)
        inc a
        jr nz, L_F28C
        ld a, $FE
        out (SCSDAT), a
        ld a, $FC
        out (SCSCTL), a
        pop hl
        ld b, $06
L_F2A0: call L_F275
        ld a, (hl)
        cpl
        out (SCSDAT), a
        inc hl
        djnz L_F2A0
        jp (hl)


L_F2AB: call L_F290
        ex af, af'
        nop
        nop
        nop
        ld bc, $2104
        nop
        nop
L_F2B7: call L_F275
        rrca
        jr c, L_F28C
        rrca
        jr nc, L_F2D3
        in a, (SCSDAT)
        cpl
        ld (hl), a
        ld a, l
        cp $7F
        jr z, L_F2B7
        inc hl
        jr L_F2B7


;;; TODO unreachable?
        ld a, (hl)
        cpl
        out (SCSDAT), a
        inc hl
        jr L_F2B7


L_F2D3: in a, (SCSDAT)
        cpl
        push af
        call L_F275
        in a, (SCSDAT)
        pop af
        or a
        ret


MSG18:  defb $0D, $0A, $1B
        defm "E       SImple MONitor"
        defb $0D, $0A, $00

L_F2FB: xor a
        out (FDCDRV), a
        ld i, a
        ld hl, MSG18
        call PRS
CMDLOP: ld sp, STACK
        ld a, ">"               ; prompt
        call XCHROUT
        call XCHROUT
        ld hl, CMDLOP           ; each command ends with RET which takes it back to CMDLOP
        push hl
        call XCHRIN             ; get single-letter command
        cp $42
        jp z, XCOLD
        cp $43
        jp z, CMD_C
        cp $45
        jp z, CMD_E
        cp $46
        jp z, CMD_F
        cp $4D
        jp z, CMD_M
        cp $4F
        jp z, CMD_O             ; out to port
        cp $51
        jp z, CMD_Q             ; query from port
        cp $54
        jp z, CMD_T

CMDERR: ld hl, MSG12
        jr PRS                  ; print and return (tail-recurse)


MSG12:  defm "  -What?"
        defb $0D, $00

XF34F:  cp $30                  ; TODO what is this for and how does it get executed?
        ret c
        cp $3A
        jr c, L_F35F
        cp $41
        ret c
        cp $47
        ccf
        ret c
        sub $07
L_F35F: and $0F
        ret


PRS:    ld a, (hl)              ; print 0-terminated string at (HL)
        or a                    ; ??with special treatment of 0x80 and othere?
        ret z
        cp $80
        jr nz, PRS1
        ld a, $A0
PRS1:   push bc
        ld b, a
        call USEIVC
        ld a, b
        pop bc
        jr z, PRS2
        and $7F
PRS2:   call XCHROUT
        inc hl
        jr PRS


XP4HEX: ld a, h
        call XP2HEX
        ld a, l
XP2HEX: push af
        rrca
        rrca
        rrca
        rrca
        call L_F38A
        pop af
L_F38A: and $0F
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
L_F39F: call XCHRIN
        cp $30
        ret c
        cp $3A
        jr c, L_F3B2
        cp $41
        ret c
        cp $47
        ccf
        ret c
        sub $07
L_F3B2: and $0F
        ret


L_F3B5: ld hl, $0000
        call L_F39F
        jr nc, L_F3C3
        cp $20
        jr z, L_F3B5
        scf
        ret


L_F3C3: add hl, hl
        ret c
        add hl, hl
        ret c
        add hl, hl
        ret c
        add hl, hl
        ret c
        add a, l
        ld l, a
        call L_F39F
        jr nc, L_F3C3
        cp $20
        ret z
        cp $0D
        ret z
        scf
        ret


GET16:  call L_F3B5             ; get 16-bit value in HL (not at end of line)
        jr c, L_F3E2
        cp $20
        ret z
L_F3E2: pop hl
        jp CMDERR


GET16F: call L_F3B5             ; get final 16-bit value to HL (expect end-of-line else error)
        jr c, L_F3E2
        cp $0D
        ret z
        jr L_F3E2


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


;;; execute at address(G -> Go in later versions)
CMD_E:  call GET16F            ; get address in HL terminated by end-of-line
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


;;; Inspect and modify memory (S in later versions)
CMD_M:  call GET16F             ; get address in HL terminated by end-of-line
SLOP:   call XP4HEX             ; print it
        ld a, "-"
        call XCHROUT
        ld a, (hl)
        call XP2HEX             ; report byte value at address
        call XSPACE
        ex de, hl
        call L_F3B5             ; enter new value or <return> to go to next or - to go back or space to exit?
        ex de, hl
        push af
        cp $0D
        call nz, XCRLF
        pop af
        jr nc, L_F449
        cp $0D
        jr z, L_F448
        cp "-"
        ret nz
        dec hl                  ; previous memory location
        jr SLOP                 ; loop


L_F448: ld e, (hl)
L_F449: cp $0D
        ld a, $0D
        call nz, XCHROUT
        ld a, d
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


;;; Display memory (D in later versions)
CMD_T:  call GET16              ; start address
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
        jr nz, L_F4A6
        call XSPACE
        ld a, "-"               ; " - " between first 8 and second 8 bytes
        call XCHROUT
L_F4A6: djnz DDATA
        call XCRLF
        dec c                   ; line count
        jr nz, DADDR
        ret


XCHRIN: call PUTE4B
XCHROUT:cp $3C
        jr z, PUTCR
        cp $0D
        jr nz, PUTXXX
        call PUTXXX
        ld a, $0A
        call PUTXXX
        ld a, $0D
        ret


PUTCR:  ld a, $0D
PUTXXX: push af
        call USEIVC
        jr nz, PUTSER
PUTIVC: in a, ($B2)
        rrca
        jr c, PUTIVC
        pop af
        out ($B1), a
        ret


PUTSER: in a, ($BD)
        and $20
        jr z, PUTSER
        pop af
        out ($B8), a
        ret


PUTE6B: call USEIVC
        jr nz, L_F4F3
        ld a, $1B
        call PUTXXX
        ld a, $6B
        call PUTXXX
        call GETIVC
        ret


L_F4F3: in a, ($BD)
        and $01
        ret z
        ld a, $FF
        ret


PUTE4B: call USEIVC
        jr nz, GETSER
        ld a, $1B
        call PUTXXX
        ld a, $4B
        call PUTXXX
        call GETIVC
        jr L_F519


GETSER: in a, ($BD)
        and $01
        jr z, GETSER
        in a, ($B8)
        and $7F
L_F519: cp $61
        ret c
        cp $7B
        ret nc
        and $5F
        ret


GETIVC: in a, ($B2)
        rlca
        jr c, GETIVC
        in a, ($B1)
        ret


;;; If Z set IVC is selected
USEIVC: in a, ($BE)
        and $40
        ret


L_F52F: ld a, $03
        out ($BB), a
        ld a, $07
        out ($BC), a
        ld c, $BB
L_F539: ld hl, BAUDTAB
L_F53C: ld e, (hl)
        inc hl
        ld d, (hl)
        inc hl
        ld a, d
        or e
        jr z, L_F539
        ld a, $83
        out (c), a
        ld a, e
        out ($B8), a
        ld a, d
        out ($B9), a
        ld a, $03
        out (c), a
        call PUTE4B
        cp $0D
        jr nz, L_F53C
        call PUTE4B
        cp $0D
        jr nz, L_F53C
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


MSG8:
        defm "  "
        defb $1A, $1B
        defm "D"
        defb $0A, $0A, $0A
        defm "                  ****  Gemini Galaxy 1 ****"
        defb $0D, $0A, $0A, $00

        ; Unused
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
        defb $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
