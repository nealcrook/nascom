;;; PolyDos utility: SDOFF
;;;
;;; Utility for use with nascom_sdcard
;;; https://github.com/nealcrook/nascom
;;;
;;; Load and execute at $BC00
;;; Shuts down the SDcard so that it (should be) quiescent on the
;;; PIO and allow some other piece of hardware (eg, EPROM
;;; programmer) to operate.
;;;
;;; Obviously, before running this program you need to get
;;; everything you need into memory.
;;;
;;; In order to restart the SDcard you need to reset it then
;;; reset the NASCOM and re-boot PolyDos. Even if you have (eg)
;;; uploaded an EPROM to RAM, it should be possible to restart
;;; and then save the EPROM image with no risk of corruption.
;;;
;;; An alternative to this scheme would be a command that makes
;;; the ARDUINO poll waiting for a specific sequence - but you'd
;;; need to have no adjacent repeating characters and to send
;;; them slowly so that the ARDUINO can oversample them.
;;;
;;; This program includes the sd_sub1.asm but only uses one of its
;;; routines. However, it still fits in a single sector so there
;;; is no benefit in making it smaller.
;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

START:  EQU     $c80

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
ZCRLF:  EQU     $6a

        ORG     START
        jp      sdoff

;;; Defines and low-level subroutines
        include "sd_sub_defs.asm"
        include "sd_sub1.asm"

;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; SDOFF
;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

sdoff:  ld      a,CSTOP
        call    putcmd

        rst     PRS
        defm    'nascom_sdcard stopped. Reset the Arduino to restart.'
        defb    0
        SCAL    ZCRLF
        SCAL    ZMRET

;;; pad to 256bytes
size:   equ $ - START
        DS 100h - size, 0ffh
;;; end
