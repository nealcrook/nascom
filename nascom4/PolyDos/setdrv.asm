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
setdrv: ld      hl, (CLINP)
        ld      a,(hl)
        or      a
        jp      z, info         ;no arguments, report mounted drives.

        ;; should be drive number 0-4
        cp      '0'
        jp      c, baddrv
        cp      '5'
        jr      nc, baddrv

        ;; convert drive number from ASCII to binary and save in d
        sub     a, '0'
        ld      d,a

        ;; expect 1 digit for drive number, then at least 1 blank
        inc     hl
        ld      a,(hl)
        cp      ' '
        jr      nz,baddrv       ;spoke too soon.

        ;; skip blanks, if any
skip1:  inc     hl
        ld      a, (hl)
        cp      ' '
        jr      z, skip1
        or      a
        jr      z,badfile       ;line ended too soon

        ;; should be a disk number '0'-'F', convert to binary
        sub     a, '0'          ;0-9 and $11-$16
        cp      0
        jr      c, badfile
        cp      $a
        jr      c, diskok       ;0-9, already converted
        cp      $11
        jr      c, badfile      ;too small to be A
        cp      $17
        jr      nc, badfile     ;too big to be F
        sub     a, $7           ;$11-$16 become $A-$F

        ;; expect 1 digit for disk number, then at least 1 blank
        inc     hl
        ld      a,(hl)
        cp      ' '
        jr      nz,baddrv       ;spoke too soon.


        ;; Don't care if there are extra characters on the line. We have what
        ;; we need:
        ;; drive number in D
        ;; disk number in ???
diskok: 



;;; TODO stuff below needs update..


        ld      a,(DDRV)        ;is the directory buffer associated
        cp      d               ;with the drive to be replaced?
        jr      nz, cont        ;no
        ld      a,$ff           ;yes, so
        ld      (DDRV), a       ;invalidate directory buffer

cont:
        ;;; z => error (unlike PolyDos)
        jp      nz, ok          ;exit successfully


        jp      exit




;;; missing file name (disk number). Report error and exit
badfile:ld      a, $13
        jp      exit

;;; bad drive number. Report error and exit
baddrv: ld      a, $12
        jp      exit

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
        add     a, $11          ;a-f -> 'A'-'F'
ascok:  rst     ROUT
        SCAL    ZCRLF

        inc     b
        inc     hl
        ld      a, '4'          ;non-existent drive
        cp      b
        jr      nz, info1       ;continue until drives 0-3 all done.

ok:     xor     a               ;A=0 => no error

;;; come here with A=0 for good exit, else error code in A
exit:   SCAL    ZCKER
        SCAL    ZMRET




;;; pad to 512bytes to be tidy
size:   equ $ - START
        DS 200h - size, 0ffh
;;; end
