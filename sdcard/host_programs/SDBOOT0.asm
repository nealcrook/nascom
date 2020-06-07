;;; Support program for testing sd_boot program on NASCOM SDcard
;;; https://github.com/nealcrook/nascom
;;;
;;; pad to 512 bytes and store in a file named SDBOOT0.DSK on
;;; the SDcard.
;;;
;;; This code is loaded by the utility sd_boot as a test of
;;; the CMD_PBOOT command.
;;;

START:        EQU     $1000

SCAL:   MACRO FOO
        RST 18H
        DB FOO
        ENDM

RIN:    EQU     $8
PRS:    EQU     $28
ROUT:   EQU     $30
RDEL:   EQU     $38
;;; Equates for NAS-SYS SCALs
ZMRET:  EQU     $5b

        ORG     START

;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; main program
;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

entry:  rst     PRS
        defm    'If you see this message it means that the',$0d
        defm    'CMD_PRESTORE command worked successfully.',$0d
        defb    0

        ;; back to NAS-SYS
        SCAL    ZMRET

;;; pad binary to 1024 bytes
SIZE:   EQU     $ - $1000
PAD:    EQU     1024 - SIZE
        DS      PAD, $ff

;;; end
