;;; Utility for testing loopback to nascom_sdcard
;;; https://github.com/nealcrook/nascom
;;;
;;; All of the basic subroutines are tested
;;; here..
;;;
;;; Assemble at address xxxx and invoke from
;;; NAS-SYS like this:
;;;
;;; E xxxx
;;;
;;; Prints "." for each successful cycle of 256 values, "x"
;;; for error.
;;;

START:        EQU     $0c80

;;; Equates for communicating with NAS-SYS and NAS-SYS workspace
ROUT:   EQU     $30

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

        ld      a, "*"
        rst     ROUT

;;; send loopback command -- loops forever
lb1:    ld      b, 0
lb2:    ld      a, CLOOP
        call    putcmd
        ld      a, b
        call    putval
        call    gorx
        call    getval
        call    gotx            ;preserves AF
        cpl                     ;comes back inverted so make it right
        cp      b
        jr      nz, bad
        ;; value was OK, carry on
lb3:    djnz    lb2
        ;; one pass completed no errors
        ld      a, "."
lb4:    rst     ROUT
        jr      lb1

;;; abort pass with error
bad:    ld      a, "x"
        jr      lb4

;;; end
