;;; Utility for testing write to nascom_sdcard
;;; https://github.com/nealcrook/nascom
;;;
;;; Assemble at address xxxx and invoke from
;;; NAS-SYS like this:
;;;
;;; E xxxx
;;;
;;; The file is auto-chosen. The start and count are
;;; hard-coded in the program.
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

;;; Equates for communicating with NAS-SYS and NAS-SYS workspace
ZMRET:  EQU     $5b

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
        SCAL    ZMRET

;;; end
