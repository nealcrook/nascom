;;; Utility for testing loopback to nascom_sdcard
;;; https://github.com/nealcrook/nascom
;;;
;;; All of the basic subroutines are tested
;;; here..
;;;
;;; Assemble at address xxxx and invoke from
;;; NAS-SYS like this:
;;;
;;; E xxxx
;;;
;;; Prints "." for each successful cycle of 256 values, "x"
;;; for error.
;;;

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

;;; Equates for communicating with NAS-SYS and NAS-SYS workspace
ROUT:   EQU     $30

        ORG     START

        jp      entry

;;; Low-level subroutines
        include "sd_sub1.asm"

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
        ld      a, "*"
        rst     ROUT

;;; send loopback command -- loops forever
lb1:    ld      b, 0
lb2:    ld      a, CLOOP
        call    putcmd
        ld      a, b
        call    putval
        call    gorx
        call    getval
        call    gotx            ;preserves AF
        cpl                     ;comes back inverted so make it right
        cp      b
        jr      nz, bad
        ;; value was OK, carry on
lb3:    djnz    lb2
        ;; one pass completed no errors
        ld      a, "."
lb4:    rst     ROUT
        jr      lb1

;;; abort pass with error
bad:    ld      a, "x"
        jr      lb4

;;; end
