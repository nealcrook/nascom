;;; PolyDos utility: SET DRIVE
;;;
;;; Utility for use with nascom_sdcard
;;; https://github.com/nealcrook/nascom
;;;
;;; Load and execute at 1000
;;;
;;; Uses direct access to the sdcard to change the mounted
;;; drives
;;;
;;; Usage:
;;;
;;; $ SETDRV
;;;
;;; Report the files mounted for each drive
;;;
;;; $ SETDRV n filename
;;; $ SETDRV 1 DRV0.BIN
;;;
;;; Unmount any SDcard file currently associated with drive (FID)
;;; n (0..4) and mount filename.
;;;
;;; 0..3 correspond to PolyDos drives. 4 corresponds to the
;;; file reserved as a print spool (not yet implemented..)
;;;
;;; filename must be a legal FAT "8.3" name.
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

;;; Defines and low-level subroutines
        include "sd_sub_defs.asm"
        include "sd_sub1.asm"

;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; SETDRV
;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



        ;; parse the command line.
setdrv: ld      hl, (CLINP)
        ld      a,(hl)
        or      a
        jp      z, info         ;no arguments, report mounted drives.

        ;; should be drive number
        cp      '0'
        jp      c, baddrv
        cp      '5'
        jr      nc, baddrv

        ;; convert drive number from ASCII to binary and save in d
        sub     a, '0'
        ld      d,a

        ;; expect 1 digit for drive number
        inc     hl
        ld      a,(hl)
        cp      ' '
        jr      nz,baddrv       ;spoke too soon.

        ;; expect a file name
        or      a
        jr      z,badfile       ;line ended too soon

        ;; skip blanks, if any
skip1:  inc     hl
        ld      a, (hl)
        cp      ' '
        jr      z, skip1
        or      a
        jr      z,badfile       ;line ended too soon

        ;; first character of filename
        push    hl              ;remember where it starts
        ld      b,1             ;length of name so far

;;; TODO for bonus marks, check that all the characters are legal...
;;; can report $10 - llegal character

nam:    inc     hl
        ld      a, (hl)
        cp      ' '
        jr      z, badext       ;no extension
        or      a
        jp      z, badext       ;line ended too soon.. no extension
        cp      '.'
        jr      z,gotdot
        inc     b
        jr      nam             ;continue with name

gotdot: ld      a,8
        cp      b
        ld      a,$11           ;error code: too long
        jp      c,exit          ;name >8

        ld      b,0             ;length of extension so far

;;; TODO for bonus marks, check that all the characters are legal...

ext:    inc     hl
        ld      a, (hl)
        cp      ' '
        jr      z, endext       ;reached the end
        or      a
        jr      z, endext       ;reached the end
        inc     b
        jr      ext             ;continue with extension

endext: ld      a,3
        cp      b
        jr      c,badfile       ;extension >3 chars long
        xor     a
        cp      b
        jr      z,badfile       ;extension = 0 chars long

;;; finally, we have a good file name. If it's the last thing on the line
;;; it will have a null terminator but there might be spaces or other stuff after
;;; it. Non-spaces would be illegal but we will simply ignore them. However, we do
;;; need to make sure that the name is null-terminated.

        xor     a
        ld      (hl), a         ;guarantee the name is null-terminated

        pop     hl

;;; we're all ready. D holds the FID we're going to replace, (HL) is the name of the
;;; file to replace it with. If the FID is currently in use, its file will get unmounted
;;; cleanly so there is nothing we need to care about in that regard.

;;; if we COPEN a non-existent file, it will get created with a file size of
;;; 0, which then causes all sorts of Bad Things when you try to use it. The
;;; way to check if a file exists is to COPENR it and error or, if
;;; successfull, COPEN it.

        ld      a,(DDRV)        ;is the directory buffer associated
        cp      d               ;with the drive to be replaced?
        jr      nz, openr       ;no
        ld      a,$ff           ;yes, so
        ld      (DDRV), a       ;invalidate directory buffer

openr:  push    hl              ;preserve pointer to file name
                                ;also need D but nothing's messing with that

        ld      a,COPENR
        or      d               ;merge in the FID

        call    cnam

        ;;; z => error (unlike PolyDos)
        jr      nz, open        ;good! file exists

        ld      a, $30          ;can't find that file
        jr      exit

open:   pop     hl
        ld      a,COPEN
        or      d               ;merge in the FID

        call    cnam

        ;;; z => error (unlike PolyDos)
        jr      nz, ok          ;exit successfully

        ld      a, $23          ;record not found
        jr      exit

;;; missing extension. Report error and exit
badext: ld      a, $14
        jr      exit

;;; missing file name. Report error and exit
badfile:ld      a, $13
        jr      exit

;;; bad drive number. Report error and exit
baddrv: ld      a, $12
        jr      exit

;;; no args => report current mounted files and exit
info:   rst     PRS
        defm    'Files mounted through nascom_sdcard:'
        defb    CR,00

;;; Send INFO command and report the response
        ld      a, CINFO
        call    putcmd
        call    gorx
get:    call    getval
        or      a
        jr      z, done
        rst     ROUT
        jr      get

done:   call    gotx
ok:     xor     a               ;A=0 => no error

;;; come here with A=0 for good exit, else error code in A
exit:   SCAL    ZCKER
        SCAL    ZMRET


;;; SUBROUTINE
;;; come here with command in A (COPEN or COPENR)
;;; filename at (HL)
;;; send command and filename.
;;; return with status in A, flags set accordingly.
cnam:   call    putcmd

sendnam:ld      a,(hl)          ;get char of filename
        call    putval          ;corrupts A
        ld      a,(hl)          ;get it again
        inc     hl              ;point to next character

        or      a               ;did we just send end-of-filename?
        jr      nz,sendnam      ;no, so continue

        call    gorx
        call    getval
        call    gotx            ;preserves A

        or      a               ;set flags on status
        ret


;;; pad to 512bytes to be tidy
size:   equ $ - START
        DS 200h - size, 0ffh
;;; end
