;;; Z80 assembler routine for nascom_sdcard HW setup and train
;;; https://github.com/nealcrook/nascom
;;;
;;; Common code to be included like this:
;;;          jp entry
;;;          include "sd_sub_defs.asm"
;;;          include "sd_sub1.asm"
;;;
;;; entry:
;;;          include "sd_sub2.asm"
;;;          <continues>
;;;
;;; or like this:
;;;
;;; Common code to be included like this:
;;;          jp entry
;;;          include "sd_sub_defs.asm"
;;;          include "sd_sub1.asm"
;;; hwinit:
;;;          include "sd_sub2.asm"
;;;          ret
;;;
;;; entry:   call hwinit
;;;
;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; setup: initialise the PIO and the interface.
;;; By experiment, the output word has to be the next thing
;;; written, not simply the next thing written to that port.
        call    a2out           ;port A to outputs
        ld      a, $cf          ;"control" mode
        out     (PIOBC), a
        ld	a,1
        out     (PIOBC), a      ;port B LSB is input
        out     (PIOBD), a      ;init outputs H2T=0, CMD=0

;;; Training sequence gets the protocol to a known state and enables
;;; processing of NASdsk commands in the Arduino command loop.
        ld      b, 8            ;number of times to do it
train:	ld      a, CNOP
	call    putcmd
        djnz    train
;;; FALL-THROUGH

;;; end
