;;; Z80 assembler defines for use with nascom_sdcard
;;; https://github.com/nealcrook/nascom
;;;
;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Commands for the SDcard interface
FID:          EQU     $0        ;0, 1, 2, 3 or 4
CNOP:         EQU     $80       ;no-operation
CRES:         EQU     $81       ;restore state (deprecated; use PRES)

CLOOP:        EQU     $83       ;loopback
CDIR:         EQU     $84       ;directory
CSTAT:        EQU     $85       ;command status
CINFO:        EQU     $86       ;info on mounted drives
CSTOP:        EQU     $87       ;stop interface (require reset)

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

PID:          EQU     $0        ;0, 1, 2, 3 (Profile)
PBOOT:        EQU     $70 + PID
PRES:         EQU     $78 + PID

; Equates for NASCOM I/O -- the Z80 PIO registers
PIOAD:        EQU      $4
PIOBD:        EQU      $5
PIOAC:        EQU      $6
PIOBC:        EQU      $7

;;; end
