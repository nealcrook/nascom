;;; Utility for testing read from nascom_sdcard
;;; https://github.com/nealcrook/nascom
;;;
;;; Assemble at address xxxx and invoke from
;;; NAS-SYS like this:
;;;
;;; E xxxx
;;;
;;; The file name and the load address are hard-coded
;;; in the program.
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

;;; open a file by name, for READ
lb1:    ld      a, COPENR + 3
        call    putcmd
        ld      hl, name        ;point to the name
fnam:   ld      a,(hl)          ;send the name
        push    af
        call    putval          ;corrupts a
        pop     af
        inc     hl              ;does not affect flags
        or      a
        jr      nz, fnam        ;carry on until end of name

        call    gorx
        call    getval          ;status
        call    gotx

;;; get the file size and read it all
        ld      a, CSZRD + 3    ;read size and data
        call    putcmd
        call    gorx
        call    getval
        ld      c, a            ;length, LS byte
        call    getval
        ld      b, a            ;length
        ;; ignore the next two!!
        call    getval
        call    getval

        ld      hl, $1000       ;destination

        ;; data transfer
next:   call    getval          ;data byte
        ld      (hl), a         ;store it
        inc     hl
        dec     bc
        ld      a,b
        or      c
        jr      nz, next

        ;; get status
        call    getval
        call    gotx

        ;; back to NAS-SYS (ought to close..)
        SCAL    ZMRET

        ;; 4e 41 53 30 30 30 2e 42 49 4e 00
name:   db      "NAS000.BIN",0

;;; end
