;;; Support program for testing dskboot program on NASCOM SDcard
;;; https://github.com/nealcrook/nascom
;;;
;;; Loaded via dskboot, like this:
;;; NAScas> RS DSKBOOT.CAS
;;; NAScas> .
;;; R
;;; E C80 <optional args -- see below>
;;;
;;; This program (SDBOOT0.asm) is used to create a disk image
;;; which should be named SDBOOT0.DSK on the SDcard.
;;;
;;; - SDBOOT0.asm assembles to a 512-byte binary.
;;; - One or more NASCOM ROM images (in binary format) should
;;;   be appended to the end of it.
;;; - A data structure in the SDBOOT0 binary is configured
;;;   (in the .asm) or patched (in the binary) to describe the
;;;   appended ROM images.
;;; - The data structure also contains a 16-bit bit-map which
;;;   controls the set of ROM images that are to be loaded
;;; - Finally, the data structure contains an execution address
;;;   which allows one of the images to be executed, or
;;;   allows a clean return to NAS-SYS.
;;;
;;; The arguments to dskboot can be used to override the
;;; load bit-map and the execution address:
;;;
;;; E C80            - use settings in the SDBOOT0 binary
;;; E C80 aaaa       - load bitmap aaaa and return to NAS-SYS
;;; E C80 aaaa bbbb  - load bitmap aaaa and execute at bbbb

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

;;; Equates for NAS-SYS workspace
ARGN:   EQU     $0c0b
ARG1:   EQU     $0c0c
ARG2:   EQU     $0c0e
ARG3:   EQU     $0c10

;;; Defines
        include "sd_sub_defs.asm"

        ORG     START

        jp      entry
        nop
ldmap:  DW      $0002           ; map of ROM images to load. LSB=image 0, MSB=image 15
exitjp: DW      $0000           ; where to go on termination. 0 means "rst mret" - back to NAS-SYS.

;;; An arbitrary set of ROM images are appended to this binary in order to form the
;;; "boot disk image". This data structure describes what's present.
;;; It's at a Known place in memory so that it can be patched.
;;; The LDMAP above (or a command-line argument) determines which, if any, of the
;;; ROM images are loaded.
;;;
;;; There are 16 entries here; each entry is 8 bytes.
;;; The low byte of the 32-bit byte offset should always be 0. A value of $ff is
;;; used to mark the end of the table.
;;; This image is 512 (0x200) bytes in size, so the first appended ROM will have
;;; an offset of 0x0000.0200
copy:
        ;; Image 0: NASDOS original 4Kbytes at D000
        defb    $00, $02, $00, $00 ;32-bit byte offset to start of image, low byte first
        defw    $1000              ;16-bit byte count to transfer, low byte first
        defw    $d000              ;16-bit destination address, low byte first
        ;; Image 1: NASDOS for nascom_sdcard 4Kbytes at D000
        defb    $00, $12, $00, $00 ;32-bit byte offset to start of image, low byte first
        defw    $1000              ;16-bit byte count to transfer, low byte first
        defw    $d000              ;16-bit destination address, low byte first
        ;; Image 2: PolyDos 2: 2Kbytes at D000
        defb    $00, $22, $00, $00 ;32-bit byte offset to start of image, low byte first
        defw    $0800              ;16-bit byte count to transfer, low byte first
        defw    $d000              ;16-bit destination address, low byte first
        ;; Image 3: PolyDos for nascom_sdcard: 2Kbytes at D800
        defb    $00, $2a, $00, $00 ;32-bit byte offset to start of image, low byte first
        defw    $0800              ;16-bit byte count to transfer, low byte first
        defw    $d800              ;16-bit destination address, low byte first
        ;; Image 4: ZEAP (ROM version): 4Kbytes at D000
        defb    $00, $32, $00, $00 ;32-bit byte offset to start of image, low byte first
        defw    $1000              ;16-bit byte count to transfer, low byte first
        defw    $d000              ;16-bit destination address, low byte first
        ;; Image 5: NASCOM ROM BASIC (ROM version): 8Kbytes at E000
        defb    $00, $42, $00, $00 ;32-bit byte offset to start of image, low byte first
        defw    $2000              ;16-bit byte count to transfer, low byte first
        defw    $e000              ;16-bit destination address, low byte first
        ;; Image 6: PolyData PASCAL (ROM version): 12Kbytes at D000
        defb    $00, $62, $00, $00 ;32-bit byte offset to start of image, low byte first
        defw    $3000              ;16-bit byte count to transfer, low byte first
        defw    $d000              ;16-bit destination address, low byte first
        ;; Image 7: NAS-PEN (ROM version): 2Kbytes at B800
        defb    $00, $92, $00, $00 ;32-bit byte offset to start of image, low byte first
        defw    $0800              ;16-bit byte count to transfer, low byte first
        defw    $b800              ;16-bit destination address, low byte first

        ;; space for more images..
        ds      8, $ff          ; Image 8
        ds      8, $ff          ; Image 9
        ds      8, $ff          ; Image 10
        ds      8, $ff          ; Image 11
        ds      8, $ff          ; Image 12
        ds      8, $ff          ; Image 13
        ds      8, $ff          ; Image 14
        ds      8, $ff          ; Image 15
        defb    $ff             ; end of table

;;; Low-level subroutines
        include "sd_sub1.asm"

;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; main program
;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

entry:  rst     PRS
        defm    'Start SDBOOT0..',$0d
        defb    0

;;; should not need this..
        ld      b, 8            ;number of times to do it
train:	ld      a, CNOP
	call    putcmd
        djnz    train

;;; Use (ARG2) as temporary storage for the load map. If dskboot
;;; was invoked with 1 argument, (ARG2) was not supplied on the
;;; command line (the dskboot invocation) so copy it from the
;;; SDBOOT0 binary.
        ld      a,(ARGN)
        cp      1
        jr      nz, gotmap
;;; 1 argument to dskboot invocation => (ARG2) is not valid
        ld      hl, (ldmap)
        ld      (ARG2), hl
gotmap:

;;; Process the copy list. Remember, the images are not present
;;; in memory yet: they are in the disk image. They need to be pulled in
;;; using NASdsk commands. The NASdsk interface is already initialised
;;; (it was used to get us here) and the disk with FID=0 is mounted.
;;; Just need to seek and read/load.
        ld      hl, copy - 8    ;first time
next:   ld      de, 8
        or      a               ;clear carry
        adc     hl, de          ;skip to next entry
next1:  ld      a,(hl)          ;fetch seek ls byte
        cp      $ff
        jr      z, done         ;no more to do

;;; shift (ARG2) right and use LSB to decide whether to load this image
        push    hl
        ld      hl, (ARG2)
        rr      h
        rr      l
        ld      (ARG2), hl
        pop     hl
        jr      nc, next        ;0 - skip this image

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

;;; After loading all the images, jump to (ARG3) if valid, or to
;;; (exitjp) otherwise.
done:   ld      hl, (ARG3)
        ld      a, (ARGN)
        cp      3
        jp      z, gotdest
        ld      hl, (exitjp)
gotdest:ld      a, h
        or      l
;;; go!
        jr      z, exit         ;convert destination of 0 to NAS-SYS warm start
        push    hl
        ret

;;; pad binary to 512 bytes
SIZE:   EQU     $ - START
PAD:    EQU     512 - SIZE
        DS      PAD, $ff

;;; end
