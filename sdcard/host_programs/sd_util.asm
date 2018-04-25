;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; ROMable utilities for accessing an arduino-based nascom_sdcard
;;; device attached to the NASCOM PIO.
;;;
;;; Assemble at address xxx0, (optionally) burn to EPROM.
;;;
;;; Provides 5 different utilites, all invoked from NAS-SYS at
;;; different offsets from the start address.
;;;
;;; 1) CHECKSUM
;;;
;;; E xxx0 ssss eeee
;;;
;;; Compute checksum of memory from ssss to eeee inclusive.
;;; Checksum is the sum of all bytes and is reported as a
;;; 16-bit value. Carry off the MSB is lost/ignored.
;;;
;;; 2) READ FILE
;;;
;;; E xxx3 ssss nnn
;;;
;;; Where nnn are exactly 3 decimal digits (000..999).
;;;
;;; - Locate file NASnnn.BIN
;;; - Load it to memory starting at address ssss
;;; - Report the file size
;;; FEATURE: reading a non-existent file creates that file,
;;; with size 0 bytes. Fixing this would require new cmds.
;;;
;;; 3) WRITE FILE
;;;
;;; E xxx6 ssss eeee [nnn]<-optional
;;;
;;; If nnn - exactly 3 decimal digits (000..999):
;;; - Create file NASnnn.BIN
;;; - Save memory from ssss to eeee inclusive to the file
;;;
;;; Without nnn:
;;; - Auto-pick next free file name in the form NASnnn.BIN
;;; - Save memory from ssss to eeee inclusive to the file
;;;
;;; 4) SCRAPE DISK
;;;
;;; E xxx9 [nnn]<-optional
;;;
;;; If nnn - exactly 3 decimal digits (000..999).
;;; - Create file NASnnn.BIN
;;; - Read all sectors of drive 0 and write them to the file
;;;
;;; Without nnn:
;;; - Auto-pick next free file name in the form NASnnn.BIN
;;; - Read all sectors of drive 0 and write them to the file
;;;
;;; This will ONLY work if the system has been booted into
;;; Polydos, so that the Polydos SCAL table is available.
;;;
;;; 5) BOOT
;;;
;;; E xxxc [n]
;;;
;;; Relies on auto-restore of files on the Arduino device.
;;; Without n, accesses drive 0. With n, accesses drive n
;;; (n=0..3). Seek to start of drive image, Load first 256 bytes
;;; (probably 128 is all that's required) into memory at address
;;;  CPMLD, jump to CPMLD.
;;;
;;; Intended as a proof-of-concept boot-strap loader for CP/M but
;;; it cannot actually boot CP/M unless the memory map is changed
;;; to provide RAM at address 0
;;;
;;; https://github.com/nealcrook/nascom
;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

START:  EQU     $b800
CPMLD:  EQU     $2000

; Commands for the SDcard interface
FID:          EQU     $0        ;0, 1, 2, 3 or 4
CNOP:         EQU     $80       ;no-operation
CRES:         EQU     $81       ;restore state
CSAV:         EQU     $82       ;save state
CLOOP:        EQU     $83       ;loopback
CDIR:         EQU     $84       ;directory
CSTAT:        EQU     $85       ;command status

COPEN:        EQU     $10 + FID
CCLOSE:       EQU     $18
CSEEK:        EQU     $20 + FID ;seek by byte offset
CTSEEK:       EQU     $28 + FID ;seek by track/sector offset
CSRD:         EQU     $30 + FID
CNRD:         EQU     $38 + FID
CSWR:         EQU     $40 + FID
CNWR:         EQU     $48 + FID
CSZRD:        EQU     $60 + FID

; Equates for NASCOM I/O -- the Z80 PIO registers
PIOAD:        EQU      $4
PIOBD:        EQU      $5
PIOAC:        EQU      $6
PIOBC:        EQU      $7

;;; Macros for using NAS-SYS routines
SCAL:   MACRO FOO
        RST 18H
        DB FOO
        ENDM

RCAL:   MACRO FOO
        RST 10H
        DB FOO - $ - 1
        ENDM

RIN:    MACRO
        RST 8
        ENDM

ROUT:   MACRO
        RST $30
        ENDM

PRS:    MACRO
        RST $28
        ENDM

;;; Equates for NAS-SYS SCALs
MRET:   EQU     $5b
TBCD3:  EQU     $66
CRLF:   EQU     $6a
ERRM:   EQU     $6b
;;; Equates for NAS-SYS workspace
ARGN:   EQU     $0c0b
ARG1:   EQU     $0c0c
ARG2:   EQU     $0c0e
ARG3:   EQU     $0c10
ARG4:   EQU     $0c12
;;; Equates for PolyDOS SCALs
DSIZE:  equ     $80
DRD:    equ     $81

        ORG     START

        jp      csum
        jp      rdfile
        jp      wrfile
        jp      scrape
        jp      boot

;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; subroutines -- putting them at the start means I don't have to
;;; re-type this part of the program
;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; assume: currently in OUTPUT
;;; command is in A
;;; send command, toggle handshake, wait for handshake in to match
;;; to show that target has received it.
;;; corrupts: A,F
putcmd: out     (PIOAD), a      ;send command
        in      a, (PIOBD)
        or      4               ;CMD=1
        jr      pvx             ;common code for cmd/data


;;; assume: currently in OUTPUT
;;; value is in A
;;; send value, toggle handshake, wait for handshake in to match
;;; to show that target has received it.
;;; corrupts: A,F
putval: out     (PIOAD), a      ;send value
pv0:    in      a, (PIOBD)
        and     $fb             ;CMD=0

pvx:    xor     2               ;toggle H2T
        out     (PIOBD), a

        ;; fall-through and subroutine
        ;; wait until handshakes match
        ;; corrupts A,F
waitm:  in      a, (PIOBD)      ;get status
        and     3               ;look at handshakes
        jr      z, wdone        ;both 0 => done
        cp      3               ;both 1
        jr      nz, waitm       ;not both 1 => wait
wdone:  ret			;done


;;; assume: currently in OUTPUT. Go to INPUT
;;; leave CMD=0 (but irrelevant)
;;; corrupts: A,F
gorx:   ld      a, $cf          ;"control" mode
        out     (PIOAC), a
        ld      a, $ff
        out     (PIOAC), a      ;port A all input
        jr      getend


;;; assume: currently in INPUT. Go to OUTPUT
;;; leave CMD bit unchanged
;;; corrupts: NOTHING
gotx:   push    af
        call    waitm           ;wait for hs to match
        pop     af

        ;; fall-through and subroutine
        ;; set port A to output
        ;; corrupts nothing
a2out:  push    af
        ld      a, $cf          ;"control" mode
        out     (PIOAC), a
        xor     a               ;A=0
        out     (PIOAC), a      ;port A all output
        pop     af
        ret


;;; assume: currently in INPUT
;;; get a byte; return it in A
;;; corrupts: A,F
getval: call    waitm           ;wait for hs to match
        in      a, (PIOAD)      ;get data byte

        ;; fall-through and subroutine
        ;; toggle H2T.
getend: push    af
        in      a, (PIOBD)
        xor     2               ;toggle H2T
        out     (PIOBD), a
        pop     af
        ret

;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; more subroutines, just for these utilities.
;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; setup: initialise the PIO and the interface.
;;; By experiment, the output word has to be the next thing
;;; written, not simply the next thing written to that port.
hwinit: call    a2out           ;port A to outputs
        ld      a, $cf          ;"control" mode
        out     (PIOBC), a
        ld	a,1
        out     (PIOBC), a      ;port B LSB is input
        out     (PIOBD), a      ;init outputs H2T=0, CMD=0

;;; train the interface? May not need this any more.
        ld      b, 8            ;number of times to do it
train:	ld      a, CNOP
	call    putcmd
        djnz    train
        ret

;;; open a file. Fatal error on fail, return on success.
;;; Carry=0 -> auto-pick filename
;;; Carry=1 -> filename is NASxxx.BIN where xxx comes from low
;;; 12 bits of (HL) and (HL+1) converted from bin to ASCII
;;; corrupts: HL, AF, DE
fopen:  push    af              ;preserve C
        ld      a, COPEN
        call    putcmd

        pop     af
        jr      nc,fauto

        ld      a,'N'
        call    putval
        ld      a,'A'
        call    putval
        ld      a,'S'
        call    putval

;;; number in HL used as xxx part of file name
        ld      a,h
        and     0fh             ;ms digit
        add     30h             ;convert to ASCII
        call    putval
        ld      a,l
        rra                     ;shift nibble down
        rra
        rra
        rra
        and     0fh             ;mid digit
        add     30h             ;convert to ASCII
        call    putval
        ld      a,l
        and     0fh             ;ls digit
        add     30h             ;convert to ASCII
        call    putval

;;; extension
        ld      a,'.'
        call    putval
        ld      a,'B'
        call    putval
        ld      a,'I'
        call    putval
        ld      a,'N'
        call    putval

fauto:  xor     a
        call    putval          ;0-length/end of filename
        ;; get status, return if OK, msg/exit on error
        ld      de,eopen
        jr      t2rs2t


;;; go from tx to rx, get status then go to tx.
;;; Interpret status byte; on error, print message at (DE)
;;; then exit. On success, return.
;;; corrupts: AF
t2rs2t: call    gorx

;;; FALL-THROUGH and subroutine
;;; get status then go to tx.
;;; Interpret status byte; on error, print message at (DE)
;;; then exit. On success, return.
;;; corrupts: AF
rs2t:   call    getval          ;status
        call    gotx            ;does not affect A
        or      a               ;update flags
        jr      z,mexit
        ret

;;; Exit with message. Can be used for successful or error/fatal
;;; exit. (DE) is null-terminated string (possibly 0-length).
;;; Print string then CR then return to NAS-SYS.
;;; Come here by CALL or JP/JR -- NAS-SYS will clean up the
;;; stack if necessary.
mexit:  ld      a,(de)
        or      a
        jr      z, mex1
        ROUT
        inc     de
        jr      mexit

mex1:   SCAL CRLF
        SCAL MRET

;;; Start address in (ARG2), end address in (ARG3). Exit with
;;; HL=start, BC=byte count.
;;; corrupts: AF
e2len:  ld      de,(ARG2)       ;start address
        ld      hl,(ARG3)       ;end address
        ;; compute end - start + 1
        or      a               ;clear carry flag
        sbc     hl,de
        inc     hl              ;byte count in hl
        ld      b,h
        ld      c,l             ;byte count in bc

        ld      hl,(ARG2)       ;start address in hl
        ret

;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; CSUM
;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
csum:   ld      de,earg
        ld      a,(ARGN)
        cp      3               ;expect 3 arguments
        jp      nz, mexit

        call    e2len           ;hl=start, bc=count
        ld      d,0
        ld      e,d             ;accumulate in de

c1:     ld      a,b             ;is byte count zero?
        or      c
        jr      z,cdone         ;if so, we're done

        ld      a,e             ;get lo accumulator
        add     a,(hl)          ;add next byte
        jr      nc,c2
        inc     d               ;carry to hi accumlator
c2:     ld      e,a             ;store lo accumulator
        inc     hl              ;next byte
        dec     bc
        jr      c1              ;loop

cdone:  ld      h,d             ;move sum from de to hl
        ld      l,e

        SCAL    TBCD3           ;print hl
        SCAL    CRLF
        SCAL    MRET            ;done.

;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; WRFILE
;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

wrfile: call    hwinit

        ld      de,earg         ;error message for fail
        ld      a,(ARGN)
        cp      3               ;expect 3 or 4 arguments
        jr      z,wopen         ;3 arguments, C=0 -> autopick
        cp      4               ;4 arguments?
        jp      nz, mexit       ;no, so fail
        ld      hl, (ARG4)      ;hl is number for file name
        scf                     ;C=1 -> use hl for file name

wopen:  call    fopen
        call    e2len           ;hl=start, bc=count

        ld      a, CNWR         ;write
        call    putcmd
        ld      a, c            ;length in bytes, LS first
        call    putval
        ld      a, b
        call    putval
        xor     a
        call    putval
        xor     a
        call    putval

        ;; data transfer
wnext:  ld      a, (hl)
        call    putval
        inc     hl
        dec     bc
        ld      a,b
        or      c
        jr      nz, wnext

        ;; get status, return if OK, msg/exit on error
        ld      de,ewrt
        call    t2rs2t

        ld      de,eok
        jp      mexit           ;done

;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; RDFILE
;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

rdfile: call    hwinit

        ld      de,earg
        ld      a,(ARGN)
        cp      3               ;expect 3 arguments
        jp      nz, mexit

        ld      hl,(ARG3)
        scf
        call    fopen           ;open file by name

;;; get the file size and read it all
        ld      a, CSZRD        ;read size and data
        call    putcmd
        call    gorx
        call    getval
        ld      c, a            ;length, LS byte
        call    getval
        ld      b, a            ;length
        ;; require the next two to be zero
        ld      de,e2big
        call    getval
        ld      h, a
        call    getval
        or      h
        jp      nz, mexit

        push    bc              ;save file size
        ld      hl, (ARG2)      ;destination

        ;; data transfer - maybe 0 bytes
rnext:  ld      a,b
        or      c
        jr      z, rdone

        call    getval          ;data byte
        ld      (hl), a         ;store it
        inc     hl
        dec     bc
        jr      rnext

        ;; get status or die
rdone:  ld      de,erd
        call    rs2t

        pop     hl              ;file size
        SCAL    TBCD3           ;display file size
        ld      de,ebyte
        jp      mexit           ;done

;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; SCRAPE
;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

scrape: call    hwinit

        or      a               ;C=0
        call    fopen           ;open new file, auto-pick the name

        ld      c,0
        SCAL    DSIZE
;;; hl = number of sectors on drive 0

;;; sectors are 256 bytes (0x100) each. Tried reading 8 at a time
;;; but the whole disk is NOT a xple of 8, leading to a messy
;;; end condition. Overall, easier to just read 2 at a time (all
;;; disks have an even number of sectors..)
;;; and buffer them in RAM at $1000.

        ld      de,0            ;start at 1st sector

nxtblk: push    hl              ;total #sectors
        ld      bc,$200         ;2 is #sectors, 0 is drive number
        ld      hl,$1000        ;where to put it

        SCAL    DRD             ;TODO Check/report exit status

        ld      a,'.'           ;show progress - could do * for error?
        ROUT

        ;; hl, bc unchanged
        ;; bc = $200 - the number of bytes to write out to SD
        ;; need to fix c if using drive 1 etc.

        ld      a, CNWR         ;write
        call    putcmd
        ld      a, c            ;length in bytes, LS first
        call    putval
        ld      a, b
        call    putval
        xor     a
        call    putval
        xor     a
        call    putval

        ;; data transfer
snext:  ld      a, (hl)
        call    putval
        inc     hl
        dec     bc
        ld      a,b
        or      c
        jr      nz, snext

        ;; get status, return if OK, msg/exit on error
        push    de
        ld      de,ewrt
        call    t2rs2t
        pop     de

        ;; we're done if hl=de
        pop     hl
        ld      a,h
        cp      d
        jr      nz, nxt1
        ld      a,l
        cp      e
        jr      nz, nxt1
        ld      de,eok
        jp      mexit           ;done

nxt1:   inc     de              ;increment sector count
        inc     de              ;by the number we've copied
        jr      nxtblk

;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; BOOT
;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

boot:   call    hwinit

;;; If 2 arguments get drive number
        ld      b,0             ;default is drive 0
        ld      a,(ARGN)
        cp      2
        jr      nz,b1
        ld      a,(ARG2)        ;low byte
        ld      b,a             ;save for later

;;; In theory, disk is already open.
;;; For ruggedness, seek to 0 or die in the attempt
b1:     add     CSEEK           ;add FID for drive number
        call    putcmd
        xor     a
        call    putval
        xor     a
        call    putval
        xor     a
        call    putval
        xor     a
        call    putval

        ld      de,enofil       ;check status; exit on error
        call    t2rs2t

;;; read 256 bytes
        ld      a,b             ;get FID
        add     CNRD
        call    putcmd
        xor     a
        call    putval          ;00
        inc     a
        call    putval          ;1000
        xor     a
        call    putval          ;001000
        xor     a
        call    putval          ;0000.0100 bytes, please
        call    gorx
        ld      hl,CPMLD
        ld      bc,0100H

        ;; data transfer
b2:     call    getval          ;data byte
        ld      (hl), a         ;store it
        inc     hl
        dec     bc
        ld      a,b
        or      c
        jr      nz, b2

        ld      de,erd
        call    rs2t            ;check read was OK

        PRS
        DB      "Go to CP/M..",0
        jp      CPMLD


;;; exit messages
eopen:  DB "File open failed",0
enofil: DB "No file to open",0
earg:   DB "Wrong number of arguments",0
ewrt:   DB "Write failed",0
erd:    DB "Read failed",0
e2big:  DB "File too big",0
ebyte:  DB "Bytes "             ;FALL-THROUGH
eok:    DB "OK", 0

;;; pad to 1Kbytes
size:   equ $ - START
        DS 400h - size, 0ffh
;;; end
