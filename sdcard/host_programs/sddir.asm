;;; PolyDos utility: SDDIR
;;;
;;; Utility for use with nascom_sdcard
;;; https://github.com/nealcrook/nascom
;;;
;;; Load and execute at 1000
;;; Intended to be loaded onto PolyDos virtual disk and executed
;;; from there. Performs direct access to the SDcard and reports
;;; the files in the root directory of the SDcard, with pager.
;;;
;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

START:  EQU     $1000

; Commands for the SDcard interface
FID:          EQU     $0        ;0, 1, 2, 3 or 4
CNOP:         EQU     $80       ;no-operation
CRES:         EQU     $81       ;restore state
CSAV:         EQU     $82       ;save state
CLOOP:        EQU     $83       ;loopback
CDIR:         EQU     $84       ;directory
CSTAT:        EQU     $85       ;command status
CINFO:        EQU     $86       ;info on mounted drives
CSTOP:        EQU     $87       ;stop processing commands

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

;;; Equates for NAS-SYS SCALs
ZMRET:  EQU     $5b

;;; Equates for this program
LINES:  EQU     14
CR:     EQU     $0d
CH:     EQU     $17             ;cursor home??

        ORG     START
        jp      sddir

;;; Low-level subroutines
        include "sd_sub1.asm"


;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; SDDIR
;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

sddir:  rst     PRS
        defm    'Files on root directory of nascom_sdcard:'
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

        cp      CR
        call    z,page

        rst     ROUT
        jr      get

done:   call    gotx
        SCAL    ZMRET

;;; pager: count down lines in b. After screen-full get the user
;;; to press a key to continue.
page:   push    af
        djnz    cont
        rst     PRS
        defm    'Press [SPACE] to continue'
        defb    CH,0            ;TODO does that do a "home"?
wfspc:  rst     RIN             ;wait for keystroke
        cp      $20
        jr      nz, wfspc       ;so mean, we insist on a "space"

        ld      b, LINES        ;reload
cont:   pop     af
        ret




;;; pad to 256bytes
size:   equ $ - START
        DS 100h - size, 0ffh
;;; end
