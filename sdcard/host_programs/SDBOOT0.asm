;;; Support program for testing sd_boot program on NASCOM SDcard
;;; https://github.com/nealcrook/nascom
;;;
;;; pad to 512 bytes and store in a file named SDBOOT0.DSK on
;;; the SDcard.
;;;
;;; This code is loaded by the utility sd_boot as a test of
;;; the CMD_PBOOT command.
;;;
;;; by adding a data table to the end of this program you
;;; can append ROM images to it and have them copied to
;;; the desired place in memory.
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
ZERRM:  EQU     $6b
ZMRET:  EQU     $5b

; Commands for the SDcard interface
FID:          EQU     $0
CNOP:         EQU     $80       ;no-operation
CSEEK:        EQU     $20 + FID ;seek by byte offset
CNRD:         EQU     $38 + FID ;read bytes

; Equates for NASCOM I/O -- the Z80 PIO registers
PIOAD:        EQU      $4
PIOBD:        EQU      $5
PIOAC:        EQU      $6
PIOBC:        EQU      $7

        ORG     START

        jp      entry
        DS      5, $0           ; pad to xple of 8

;;; An arbitrary set of ROM images are appended to this binary in order to form the
;;; "boot disk image". This data structure describes what's present and controls,
;;; on an entry-by-entry basis, whether it should be loaded into memory. It's at a
;;; Known place in memory so that it can be patched.
;;;
;;; sector size is 512 bytes. Each entry here is 8 bytes
;;; The low byte of the 32-bit byte offset has a double-meaning. Since all the ROM images are
;;; multiples of 1K, the low byte should always be 0. Therefore..
;;; value of  0 means: load this image
;;; value of  1 means: skip this image
;;; value of ff means: no more images
copy:
        ;; RAM-based NASDOS: 4Kbytes at C000
        defb    $00, $02, $00, $00 ;32-bit byte offset to start of image, low byte first
        defw    $1000              ;16-bit byte count to transfer, low byte first
        defw    $c000              ;16-bit destination address, low byte first
        ;; space for more images..
        ds      8, $ff
        ds      8, $ff
        ds      8, $ff
        ds      8, $ff
        ds      8, $ff
        ds      8, $ff
        ds      8, $ff
        ds      8, $ff
        ds      8, $ff
        ds      8, $ff
        ds      8, $ff
        ds      8, $ff
        ds      8, $ff
        ds      8, $ff
        ds      8, $ff
        defb    $ff             ; end of table

;;; Low-level subroutines
        include "sd_sub1.asm"

;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; main program
;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

entry:  rst     PRS
        defm    'If you see this message it means that the',$0d
        defm    'CMD_PRESTORE command worked successfully.',$0d
        defb    0

;;; now process the copy list. Remember, the images are not present
;;; in memory yet: they are in the disk image. They need to be pulled in
;;; by using NASdsk commands. The NASdsk interface is already initialised
;;; (it was used to get us here) and the disk with FID=0 is mounted.
;;; Just need to seek and read/load.

;;; should not need this..
        ld      b, 8            ;number of times to do it
train:	ld      a, CNOP
	call    putcmd
        djnz    train


        ld      hl, copy - 8    ;first time
next:   ld      de, 8
        or      a               ;clear carry
        adc     hl, de          ;skip to next entry
next1:  ld      a,(hl)          ;fetch seek ls byte
        cp      $ff
        jr      z, exit         ;no more to do
        or      a
        jr      nz, next        ;skip to next entry

;;; process copy table entry at HL
        ld      a, CSEEK
        call    putcmd

        ld      a, (hl)         ;fetch seek ls byte (again)
        call    putval          ;seek ls byte
        inc     hl
        ld      a, (hl)
        call    putval          ;seek
        inc     hl
        ld      a, (hl)
        call    putval          ;seek
        inc     hl
        ld      a, (hl)
        call    putval          ;seek ms byte
        inc     hl
        call    gorx
        call    getval
        call    gotx
        or      a
        jr      z, error        ;fatal! Seek error

        ld      a, CNRD
        call    putcmd
        ld      a, (hl)
        ld      c, a
        call    putval          ;size ls byte
        inc     hl
        ld      a, (hl)
        ld      b, a
        call    putval          ;size
        inc     hl
        xor     a
        call    putval          ;size
        call    putval          ;size ms byte
        call    gorx
        ld      e, (hl)
        inc     hl
        ld      d, (hl)         ;destination in DE
        inc     hl              ;point to next entry in copy table

        ;; data transfer: byte count in BC, destination in DE
data:   call    getval          ;data byte
        ld      (de), a         ;store it
        inc     de
        dec     bc
        ld      a,b
        or      c
        jr      nz, data        ;process next byte

        ;; get status
        call    getval
        call    gotx

        or      a               ;flags reflect status of read
        jr      nz, next1       ;process next entry in copy table

        ;; fatal! Read error

error:  SCAL    ZERRM
        ;; back to NAS-SYS
exit:   SCAL    ZMRET


;;; pad binary to 512 bytes
SIZE:   EQU     $ - START
PAD:    EQU     512 - SIZE
        DS      PAD, $ff

;;; end
