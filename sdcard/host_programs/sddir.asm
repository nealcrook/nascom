;;; PolyDos utility: SDDIR
;;;
;;; Utility for use with nascom_sdcard
;;; https://github.com/nealcrook/nascom
;;;
;;; Load and execute at 1000
;;; Intended to be loaded onto PolyDos virtual disk and executed
;;; from there. Performs direct access to the SDcard and reports
;;; the files in the root directory of the SDcard, with pager
;;; and early abort.
;;;
;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

START:  EQU     $1000

; Commands for the SDcard interface
CNOP:         EQU     $80       ;no-operation
CDIR:         EQU     $84       ;directory

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

;;; Equates for NAS-SYS SCALs
ZMRET:  EQU     $5b

;;; Equates for this program
LINES:  EQU     14
CR:     EQU     $0d
CH:     EQU     $17             ;cursor home

        ORG     START
        jp      sddir

;;; Low-level subroutines
        include "sd_sub1.asm"

;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; SDDIR
;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

sddir:  rst     PRS
        defm    'Files on SDcard:'
        defb    CR,00

        ;; PolyDos is already running, from SDcard, so no need
        ;; to do any HW setup.
        ld      a, CDIR
        call    putcmd
        call    gorx

        ld      b, LINES

get:    call    getval
        or      a
        jr      z, done

        rst     ROUT
        cp      CR
        jr      nz, get

;;; pager: count down lines in b. After screen-full get the user
;;; to press a key to continue or abort.
        djnz    get             ;no need to page yet

;;; page
        rst     PRS
        defm    'Press [SPACE] to continue'
        defb    CH,0
        rst     RIN             ;wait for keystroke
        push    af
        rst     PRS             ;overstrike spaces to clear pager message
        defm    '                         '
        defb    CH,0
        pop     af
        cp      $20             ;was it a space?
        jr      nz, drain       ;some other key; end of display

        ld      b, LINES        ;reload for next screen's-worth
        jr      get

;;; discard all remaining bytes (then exit)
drain:  call    getval
        or      a
        jr      nz, drain

;;; branch here or fall through; tidy up and exit.
done:   call    gotx
        SCAL    ZMRET

;;; pad to 256bytes
size:   equ $ - START
        DS 100h - size, 0ffh
;;; end
