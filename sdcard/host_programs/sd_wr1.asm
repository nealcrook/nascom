;;; Utility for testing write to SD.
;;;
;;; Assemble at address xxxx and invoke from
;;; NAS-SYS like this:
;;;
;;; E xxxx
;;;
;;; The file is auto-chosen. The start and count are hard-coded
;;; in the program.
;;;
;;; 0x7d bytes

START:        EQU     $0c80

; Commands for the SDcard interface
FID:          EQU     $3
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

;;; Equates for communicating with NAS-SYS and NAS-SYS workspace
MRET:   EQU     $5b

        ORG     START

        jp      entry

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
;;; main program
;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; initialise the PIO
;;; by experiment, the output word has to be the next thing
;;; written, not simply the next thing written to that port.
entry:  call    a2out           ;port A to outputs
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


;;; open a (new) file; auto-pick the file name
lb1:    ld      a, COPEN
        call    putcmd
        xor     a
        call    putval          ;0-length filename => autopick
        call    gorx
        call    getval          ;status
        call    gotx

        ld      hl, $d000       ;start
        ld      bc, $1000       ;4Kbytes

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
next:   ld      a, (hl)
        call    putval
        inc     hl
        dec     bc
        ld      a,b
        or      c
        jr      nz, next

        ;; get status
        call    gorx
        call    getval
        call    gotx

        ;; back to NAS-SYS (ought to close..)
        SCAL    MRET

;;; end
