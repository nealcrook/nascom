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

;;; Macros for using NAS-SYS routines
SCAL:   MACRO FOO
        RST 18H
        DB FOO
        ENDM

;;; Equates for communicating with NAS-SYS and NAS-SYS workspace
ZMRET:  EQU     $5b

        ORG     START

        jp      entry

;;; Defines and low-level subroutines
        include "sd_sub_defs.asm"
        include "sd_sub1.asm"

;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; main program
;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; initialise the PIO and train the interface
entry:  include "sd_sub2.asm"

;;; open a (new) file; auto-pick the file name
lb1:    ld      a, COPEN + 3
        call    putcmd
        xor     a
        call    putval          ;0-length filename => autopick
        call    gorx
        call    getval          ;status
        call    gotx

        ld      hl, $d000       ;start
        ld      bc, $1000       ;4Kbytes

        ld      a, CNWR + 3     ;write
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
