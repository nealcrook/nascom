;;; PolyDos utility: SET DRIVE
;;;
;;; Utility for use with nascom4
;;; https://github.com/nealcrook/nascom4
;;;
;;; Load and execute at 1000
;;;
;;; (this is different from the utility of the same name
;;; for use with nascom_sdcard)
;;;
;;; There 16 logical disks on the SDcard (0-F) and 4 drives
;;; (0-3). At boot time, disks 0-3 are associated with drives
;;; 0-3. This utility reports what disk is mapped to each
;;; drive, and allows the mapping to be changed.
;;;
;;; Usage:
;;;
;;; $ SETDRV
;;;
;;; Report the files mounted for each drive
;;;
;;; $ SETDRV n m
;;;
;;; Associate disk m with drive n
;;;
;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

START:  EQU     $1000
BUFFER: EQU     $2000

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

;;; Equates for PolyDos SCALs
ZCKER:  EQU     $8a
;;; Equates for NAS-SYS SCALs
ZMRET:  EQU     $5b
ZTBCD3: EQU     $66
ZCRLF:  EQU     $6a
ZERRM:  EQU     $6b
ZNUM:   EQU     $64
;;; Equates for PolyDos workspace
CLINP:  EQU     $c019
CLIN:   EQU     $c01b
DDRV:   EQU     $c001
DSKWSP: EQU     $c07d

;;; Equates for NAS-SYS workspace
ARGN:   EQU     $0c0b
ARG1:   EQU     $0c0c
ARG2:   EQU     $0c0e
ARG3:   EQU     $0c10
ARG4:   EQU     $0c12
NUMV:   EQU     $0c21
;;; Equates for PolyDOS SCALs
ZDSIZE: equ     $80
ZDRD:   equ     $81
;;; Equates for this program
CR:     EQU     $0d

        ORG     START
        jp      setdrv

;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; SETDRV
;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        ;; parse the command line.
setdrv: ld      de, (CLINP)
        ld      a,(de)
        or      a
        jp      z, info         ;no arguments, report mounted drives.

        ;; should be drive number 0-3
        SCAL    ZNUM
        jr      c, badchar
        ld      hl, (NUMV)
        ld      a,h
        jr      nz, baddrv      ;too big
        ld      a,l
        cp      4
        jr      nc, baddrv      ;too big

        ;; save drive in b
        ld      b,l

        ;; should be a disk number 0-f
        SCAL    ZNUM
        jr      c, badchar
        ld      hl, (NUMV)
        ld      a,h
        jr      nz, baddsk      ;too big
        ld      a,l
        cp      $10
        jr      nc, baddsk      ;too big

        ld      c,l
        ;; Don't care if there are extra characters on the line; we have what we need:
        ;; drive number in b
        ;; disk  number in c

        ld      a,(DDRV)        ;is the directory buffer associated
        cp      b               ;with the drive to be replaced?
        jr      nz, cont        ;no
        ld      a,$ff           ;yes, so
        ld      (DDRV), a       ;invalidate directory buffer

cont:   inc     b               ;change from 0-3 to 1-4
        ld      hl,DSKWSP-1     ;always going to increment hl at least 1 time

getloc: inc     hl              ;do this 1 time for drive 0, 2 times for drive 1, etc.
        djnz    getloc          ;to get DSKWSP for drive 0, DSKWSP+1 for drive 1, etc

        ld      (hl),c          ;associate disk with drive
        SCAL    ZMRET           ;successful exit

;;; too many/too few parameters. Report error and exit
badchar:ld      a, $02
        jp      errexit

;;; bad disk address (kinda mis-using this, but seems appropriate). Report error and exit
baddsk:ld      a, $26
        jp      errexit

;;; missing/bad drive number. Report error and exit
baddrv: ld      a, $12

;;; come here with error code in A
errexit:SCAL    ZCKER
        SCAL    ZMRET

;;; no args => report current mounted files and exit
info:   rst     PRS
        ;;       012345678901234567890123456789012345678901234567
        defm    '16 logical disks are available (0-9, A-F).'
        defb    CR
        defm    'Map drive n to disk m like this:'
        defb    CR,CR
        defm    'SETDRV n m'
        defb    CR,CR
        defb    'Current mappings:'
        defb    CR,0

        ld      hl, DSKWSP      ;disk in drive 0
        ld      b,'0'           ;name of 1st drive
info1:  rst     PRS             ;print 1 entry
        defm    'Drive '
        defb    0
        ld      a, b
        rst     ROUT
        rst     PRS
        defm    ' - Disk '
        defb    0
        ld      a, (hl)
        add     a, $30          ;0->'0'
        cp      $3a             ;greater than 9?
        jr      c, ascok        ;no
        add     a, $7           ;a-f -> 'A'-'F'
ascok:  rst     ROUT
        SCAL    ZCRLF

        inc     b
        inc     hl
        ld      a, '4'          ;non-existent drive
        cp      b
        jr      nz, info1       ;continue until drives 0-3 all done.
        SCAL    ZMRET           ;successful exit

;;; pad to 512bytes to be tidy
size:   equ $ - START
        DS 200h - size, 0ffh
;;; end
