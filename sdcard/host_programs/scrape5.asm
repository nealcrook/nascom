;;; PolyDos utility: SCRAPE5 Copy CP/M 512-byte/sector disks
;;; to SDcard.
;;;
;;; Utility for use with nascom_sdcard
;;; https://github.com/nealcrook/nascom
;;;
;;; Load and execute at 1000
;;; SCRAPE.asm copies 256-byte/sector disks using PolyDos SCALs
;;; routines to do the disk access. In contrast, SCRAPE5.asm
;;; copies 512-byte/sector disks. Therefore, it cannot use PolyDos
;;; SCALs but must contain its own disk access code.
;;;
;;; This can be run from PolyDos (floppy disk or SDcard version)
;;; or run "barefoot" on the hardware. It accesses nascom_sdcard
;;; but initialises it first. This means that the drives may be
;;; reassigned and so it may be necessary to reboot after exiting
;;; this program.
;;;
;;; Prompts for a disk in drive 0 then copies all of its sectors
;;; to an SDcard image with an auto-selected file name of the
;;; form NASxxx.BIN (where xxx is a 3 digit decimal number: 000,
;;; 001 and so on).
;;;
;;; The disk access code is adapted from the PolyDos ROM code and
;;; is a reformated copy of code that I put together long, long
;;; ago.
;;;
;;; Format is 35 track DSDD disk with 10 sectors per side, each
;;; of 512 bytes (so 35*10*2*512=358,400 bytes per disk).
;;;
;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

START:  EQU     $1000
BUFFER: EQU     $2000

; Commands for the SDcard interface
FID:          EQU     $0        ;0, 1, 2, 3 or 4
CNOP:         EQU     $80       ;no-operation
CRES:         EQU     $81       ;restore state
CSAV:         EQU     $82       ;save state
CLOOP:        EQU     $83       ;loopback
CDIR:         EQU     $84       ;directory
CSTAT:        EQU     $85       ;command status

COPEN:        EQU     $10 + FID
COPENR:       EQU     $18 + FID
CSEEK:        EQU     $20 + FID ;seek by byte offset
CTSEEK:       EQU     $28 + FID ;seek by track/sector offset
CSRD:         EQU     $30 + FID
CNRD:         EQU     $38 + FID
CSWR:         EQU     $40 + FID
CNWR:         EQU     $48 + FID
CSZRD:        EQU     $60 + FID
CCLOSE:       EQU     $68 + FID

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

RIN:    EQU     $8
PRS:    EQU     $28
ROUT:   EQU     $30
RDEL:   EQU     $38

;;; Equates for NAS-SYS SCALs
ZMRET:  EQU     $5b
ZTBCD3: EQU     $66
ZCRLF:  EQU     $6a
ZERRM:  EQU     $6b
;;; Equates for NAS-SYS workspace
ARGN:   EQU     $0c0b
ARG1:   EQU     $0c0c
ARG2:   EQU     $0c0e
ARG3:   EQU     $0c10
ARG4:   EQU     $0c12

        ORG     START
        jp      scrape

;;; Low-level subroutines
        include "sd_sub1.asm"

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

;;; Training sequence gets the protocol to a known state and enables
;;; processing of NASdsk commands in the Arduino command loop.
        ld      b, 8            ;number of times to do it
train:	ld      a, CNOP
	call    putcmd
        djnz    train
        ret

;;; open a file for READ. Fatal error on fail, return on
;;; success.
;;; filename is CPMxxx.BIN where xxx comes from low
;;; 12 bits of (HL) and (HL+1) converted from bin to ASCII
;;; corrupts: HL, AF, DE
fopenr: ld      a, COPENR
        call    putcmd
        jr      fman

;;; open a file. Fatal error on fail, return on success.
;;; Carry=0 -> auto-pick filename
;;; Carry=1 -> filename is CPMxxx.BIN where xxx comes from low
;;; 12 bits of (HL) and (HL+1) converted from bin to ASCII
;;; corrupts: HL, AF, DE
fopen:  push    af              ;preserve C
        ld      a, COPEN
        call    putcmd

        pop     af
        jr      nc,fauto

fman:   ld      a,'N'
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
        rst     ROUT
        inc     de
        jr      mexit

mex1:   SCAL    ZCRLF
        SCAL    ZMRET

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
;;; SCRAPE
;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

scrape: rst     PRS
        defm    'Insert disk then press ENTER, or SPACE to quit'
        defb    0
        rst     RIN
        cp      ' '
        jr      nz, go
        SCAL    ZMRET

go:     SCAL    ZCRLF
        call    hwinit

        or      a               ;C=0
        call    fopen           ;open new file, auto-pick the name

        ld      c,0
        ld      hl,35*10*2
;;; hl = number of sectors on drive 0

        rst     PRS
        defm    'Sectors to copy: 0x'
        defb    0
        SCAL    ZTBCD3
        SCAL    ZCRLF

;;; sectors are 512 bytes (0x200) each. Tried reading 8 at a time
;;; but the whole disk is NOT a xple of 8, leading to a messy
;;; end condition. Overall, easier to just read 2 at a time (all
;;; disks have an even number of sectors..)
;;; and buffer them in RAM. However, to be fast I'll
;;; do 10 (0xa) at a time.

        ld      de,0            ;start at 1st sector

nxtblk: push    hl              ;total #sectors
        ld      bc,$a00         ;a is #sectors, 0 is drive number
        ld      hl,BUFFER       ;where to put it

        call    DRD
        ld      a,'*'           ;BAD reads
        jr      nz, report
        ld      a,'.'           ;GOOD reads
report: rst     ROUT

        ;; hl, bc unchanged

        ld      bc, $1400       ;the number of bytes to write out to SD

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

        inc     de              ;increment sector count by
        inc     de              ;the number we've just copied
        inc     de
        inc     de
        inc     de

        inc     de
        inc     de
        inc     de
        inc     de
        inc     de              ;crude but effective!

        ;; we're done if hl=de
        pop     hl
        ld      a,h
        cp      d
        jr      nz, nxtblk
        ld      a,l
        cp      e
        jr      nz, nxtblk

        SCAL    ZCRLF
        jp      scrape

;;; exit messages
eopen:  DB "File open failed",0
ewrt:   DB "Write failed",0


;----------------------------------------------
;
; CHOPPED PD2 SOURCE FOR READING
; 35-TRACK, 512-BYTE/SECTOR DSDD DISKS
; TRACKS ARE 0 TO 34
; SECTORS ARE 0 TO 9, EACH OF 512 BYTES:
; AFTER 10 SECTORS ON SIDE 0 GET THE 10 ON
; SIDE 1 BEFORE STEPPING: IE 10K PER TRACK
;
;----------------------------------------------


MAXDRV:	EQU	7



; Disk read
;----------------------------------------------
; Entry: HL:  Memory address
;	 DE:  Disk address
;	 B:   Number of sectors
;	 C:   Drive
; Exit:  HL:  Unchanged
;	 DE:  Unchanged
;	 BC:  Unchanged
;	 AF:  Status
;----------------------------------------------

DRD:	XOR	A		;A=0 => read
	PUSH	DE		;Save
	PUSH	BC
	PUSH	HL
	CALL	RWSCTS		;Do read/write
	POP	HL		;Restore
	POP	BC
	POP	DE
	RET

;----------------------------------------------
;
;	Disk Driver Routines Section
;
;	Routines will control a Gemini G809
;	FDC card (Western Digital 1797 floppy
;	disk controller chip) with up to four
;	Pertec FD250 5.25" floppy disk drives
;
;----------------------------------------------


; Port definitions

CMDREG:	EQU	0E0H	;1797 command register
STSREG:	EQU	0E0H	;1797 status register
TRKREG:	EQU	0E1H	;1797 track register
SECREG:	EQU	0E2H	;1797 sector register
DATREG:	EQU	0E3H	;1797 data register
STPORT:	EQU	0E4H	;G809 status port
DRPORT:	EQU	0E4H	;G809 drive select port

; 1797 commands

CRSTOR:	EQU	00BH	;Restore
FSEEK:	EQU	01BH	;Seek track - avoid name clash
CSTEP:	EQU	03BH	;Step one track
CRDSEC:	EQU	088H	;Read sectors
CWRSEC:	EQU	0A8H	;Write sectors
CRDADR:	EQU	0C0H	;Read address
CCLEAR:	EQU	0D0H	;Force interrupt

; Workspace (in PolyDos area)

DSKWSP: EQU     0C07DH
DRVCOD: EQU     0C002H

IDHEAD:	EQU	DSKWSP

; Initialize disk drivers and select drive C

INIT:	CALL	CNVCOD		;Convert drive code
	CALL	CLEAR		;Clear 1797
	CALL	MOTON		;Start motors
	LD	A,CRSTOR	;Restore R/W head
	CALL	C1797
	JP	TSTDSK		;Test for disk


; Read or write B sectors starting at sector DE
; on drive C to or from memory starting at HL.
; A=0 indicates read, A=-1 indicates write

RWSCTS:	PUSH	AF              ;Save R/W flag
	CALL	DRSEL           ;Select drive
	JR	NZ,RWS3         ;Error => skip
        CALL    CNVSAD          ;Convert sector addr
	CALL	MOTON;Start motors
RWS1:	POP	AF;Restore R/W flag
	PUSH	AF
	CALL	RWSR;Read/Write one sector
	JR	NZ,RWS3;Error => skip
	DEC	B;Decrement count
	JR	Z,RWS3;Done => skip
	INC	H;Calculate next addr
	INC	H
	INC	E;Increment sector nbr
	LD	C,10*2          ;(Double density size)
RWS2:	LD	A,E;Get sector nbr
	CP	C;Too big?
	JR	C,RWS1;No => skip
	LD	E,0;Clear sector nbr
	INC	D;Increment track nbr
	LD	A,D;Get track nbr
	CP	35;Too big?
	JR	C,RWS1;No => skip
	LD	A,29H;Error 29
RWS3:	POP	HL;Adjust
	OR	A;Status to Z flag
	RET

; Convert drive number in C to a drive code

CNVCOD:	PUSH	BC		;Save BC
	LD	B,C		;Drive number to B
	LD	A,C		;and to C
	AND	4		;Isolate density
	RLCA			;Move to bit 4
	RLCA
	LD	C,A		;Put in C
	LD	A,B		;Isolate drive number
	AND	3
	INC	A		;Make 1-4
	LD	B,A		;Put in B
	XOR	A		;Set bit B in A
	SCF
CC1:	RLA
	DJNZ	CC1
	OR	C		;Include density
	LD	(DRVCOD),A	;Save as drive code
	POP	BC		;Restore BC
	RET

; Convert a sector address in DE into a track
; number in D and a sector number in E

CNVSAD:	PUSH	HL		;Save
	PUSH	BC
	LD	H,D		;Put sector addr in HL
	LD	L,E
	LD	A,(DRVCOD)	;Get drive code
	LD	BC,10*2		;(Double density size)
CSA1:	LD	A,-1		;Track counter
CSA2:	INC	A		;Increment track nbr
	CP	34+1		;Overflow?
	JR	NC,CSA3		;Yes => skip
	OR	A		;Subtract track size
	SBC	HL,BC
	JR	NC,CSA2		;No carry => repeat
	ADD	HL,BC		;Adjust
	LD	D,A		;Pick up track
	LD	E,L		;Pick up sector
	XOR	A		;No error
	JR	CSA4
CSA3:	LD	A,26H		;Error 26
CSA4:	POP	BC		;Restore
	POP	HL
	OR	A		;Status to Z flag
	RET

; Delay for B milliseconds. Set up for 4MHz
; clock without wait states. The delay value
; need not be modified for slower clock rates.
; Note, however, that the minimum clock rate
; is 2MHz without wait states.

DELAY:	LD	A,94
	RST	RDEL
	DJNZ	DELAY
	RET

; Clear the 1797

CLEAR:	LD	A,CCLEAR

; Do a 1797 type I command

C1797:	OUT	(CMDREG),A	;Output command
	LD	A,10		;Small delay
C1A:	DEC	A
	JR	NZ,C1A
C1B:	IN	A,(STSREG)	;Done?
	RRA
	JR	C,C1B		;No => wait
	RET

; Keep drive motors running

MOTON:	LD	A,(DRVCOD)	;Get drive code
	OUT	(DRPORT),A	;Start drive
MO1:	IN	A,(STSREG)	;Running?
	RLA
	JR	C,MO1		;No => wait
	RET

; Test that a disk is present in selected drive

TSTDSK:	PUSH	BC		;Save BC
	CALL	MOTON		;Start motors
	LD	B,100		;In case head loading
	CALL	DELAY
	LD	A,CRDADR	;Do a read address
	OUT	(CMDREG),A
	LD	C,150		;Must complete in 150ms
TD1:	LD	B,1		;Delay one ms
	CALL	DELAY
	IN	A,(STSREG)	;Done?
	BIT	0,A
	JR	Z,TD2		;Yes => skip
	DEC	C		;Timeout?
	JR	NZ,TD1		;No => retry
TD2:	CALL	CLEAR		;Clear 1797
	XOR	A		;No error
	INC	C		;Timeout?
	DEC	C
	JR	NZ,TD3		;No => skip
	LD	(DRVCOD),A	;No drive selected
	LD	A,27H		;Error 27
TD3:	POP	BC		;Restore BC
	OR	A		;Status to Z flag
	RET

; Select drive C

DRSEL:	LD	A,MAXDRV	;Too big?
	CP	C
	LD	A,28H		;(Error 28 if so)
	RET	C		;Yes => return
	PUSH	BC		;Save BC
	LD	A,(DRVCOD)	;Get current drive code
	LD	B,A		;Put in B
	CALL	CNVCOD		;Convert new drive code
	LD	C,A		;Put in C
	CALL	MOTON		;Start motors
	LD	A,B		;Drive already selected?
	SUB	C
	JR	Z,DRS1		;Yes => bye
	CALL	TSTDSK		;Test for disk
	JR	NZ,DRS1		;Error => skip
	PUSH	HL		;Save
	PUSH	DE
	IN	A,(TRKREG)	;Get track nbr
	LD	D,A		;Put in D
	LD	E,0		;Dummy sector
	LD	HL,IDHEAD	;Read ID header
	LD	A,1
	CALL	RWSR
	POP	DE		;Restore
	POP	HL
	LD	A,27H		;(In case error)
	JR	NZ,DRS1		;Error => skip
	LD	A,(IDHEAD)	;Pick up track
	OUT	(TRKREG),A	;Give it to 1797
	XOR	A		;No error
DRS1:	POP	BC		;Restore
	OR	A		;Status to Z flag
	RET

; Seek track D

SEEKTR:	IN	A,(TRKREG)	;There already?
	CP	D
	RET	Z		;Yes => bye
	LD	A,D		;Seek track
	OUT	(DATREG),A
	LD	A,FSEEK
	CALL	C1797
	PUSH	BC		;Additional delay
	LD	B,20
	CALL	DELAY
	POP	BC
	RET

; Read/Write sector E to/from memory
; A=0:  Read sector
; A=1:  Read address
; A=-1: Write sector

RDWR:	PUSH	BC		;Save
	PUSH	DE
	PUSH	HL
	LD	C,A		;Put R/W flag in C
	LD	D,10;(10 sectors/track/side)
RW0:	LD	A,E		;Get sector number
	LD	B,0		;(Side 0 flag)
	CP	D		;On side 0?
	JR	C,RW1		;Yes => skip
	SUB	D		;Adjust
	LD	B,2		;Side 1 flag
RW1:	OUT	(SECREG),A	;Output sector number
	CALL	MOTON		;Keep motors running
	INC	C		;Write sector?
	JR	NZ,RW4		;No => skip
	LD	C,STPORT	;Point to STPORT
	LD	A,CWRSEC	;Get command
	OR	B		;Include side
	OUT	(CMDREG),A	;Output command
RW2:	LD	A,(HL)		;Get next byte ready
	INC	HL
RW3:	IN	B,(C)		;Read status
	JR	Z,RW3		;No requests => loop
	JP	P,RW6		;Jump on INTRQ
	OUT	(DATREG),A	;Output byte
	JR	RW2		;Go get next
RW4:	DEC	C		;Read sector?
	LD	A,CRDSEC	;(Read sector command)
	JR	Z,RW7		;Yes => skip
	LD	A,CRDADR	;Read address command
RW7:	LD	C,STPORT	;Point to STPORT
	OR	B		;Include side
	OUT	(CMDREG),A	;Output command
RW5:	IN	B,(C)		;Read status
	JR	Z,RW5		;No requests => loop
	JP	P,RW6		;Jump on INTRQ
	IN	A,(DATREG)	;Read byte
	LD	(HL),A		;Save it
	INC	HL		;Point to next
	JR	RW5
RW6:	IN	A,(STSREG)	;Read status
	OR	A		;Status to Z flag
	POP	HL		;Restore
	POP	DE
	POP	BC
	RET

; Read/Write sector E from track D with up to
; eight retries

RWSR:	PUSH	BC		;Save
	LD	B,A		;Put R/W flag in B
RWR0:	LD	C,8		;Set retry count
RWR1:	CALL	SEEKTR		;Seek track D
RWR2:	LD	A,B		;Get R/W flag
	CALL	RDWR		;Do read/write
	JR	Z,RWR7		;No error => done
	DEC	C		;Done 8 retries?
	JR	Z,RWR4		;Yes => skip
	BIT	0,A		;Drive not ready?
	LD	A,20H		;(Error 20 if so)
	JR	NZ,RWR7		;Yes => skip
	BIT	0,C		;Odd retry?
	JR	NZ,RWR2		;Yes => skip
	LD	A,CSTEP		;Load step command
	BIT	1,C		;2nd or 6th retry?
	JR	NZ,RWR3		;No => skip
	LD	A,CRSTOR	;Load restore command
RWR3:	CALL	C1797		;Do command
	JR	RWR1		;Go retry
RWR4:	LD	B,1FH		;Compute error code
RWR5:	INC	B
	RLA
	JR	NC,RWR5
	CALL	CLEAR		;Clear 1797
	LD	A,B		;Put code in A
RWR7:	POP	BC		;Restore
	OR	A		;Status to Z flag
	RET



;;; pad to 1024bytes
size:   equ $ - START
        DS 400h - size, 0ffh
;;; end
