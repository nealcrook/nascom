;;; Support program for testing dskboot program on NASCOM SDcard
;;; https://github.com/nealcrook/nascom
;;;
;;; Loaded via dskboot, like this:
;;; NAScas> AUTOBOOT 0
;;; NAScas> RF DSKBOOT.GO.
;;; R
;;; E C80            - use settings in the SDBOOT0 binary
;;; E C80 aaaa       - load bitmap aaaa and return to NAS-SYS
;;; E C80 aaaa bbbb  - load bitmap aaaa and execute at bbbb
;;;
;;; After reset, use R again to reload DSKBOOT. Don't try
;;; to execute from the SDBOOT0 entry address, because DSKBOOT
;;; initialises the parallel interface but this code does not.
;;;
;;; The script make_sdboot0.dsk assembles this program (SDBOOT0.asm)
;;; and creates a file SDBOOT0.DSK which should be copied to
;;; the SDcard.
;;;
;;; - SDBOOT0.asm assembles to a 512-byte binary.
;;; - Upto 16 memory images (in binary format) are appended
;;;   to it to form the "disk" image.
;;; - A data structure in the SDBOOT0 binary is configured
;;;   (in the .asm) or patched (in the binary) to describe the
;;;   appended ROM images. Each entry in the data structure
;;;   describes the size and load address of the image
;;; - A 16-bit bitmap is used to specify any combination of
;;;   images for loading from the "disk" image to memory

;;; putting it here allows it to load images at $1000
START:  EQU     $0d00

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
;;; (Patchable) default arguments to DSKBOOT if none are given on command line
ldmap:  DW      $0028           ; map of ROM images to load. LSB=image 0, MSB=image 15
exitjp: DW      $d800           ; where to go on termination. 0 means "rst mret" - back to NAS-SYS.

;;; An arbitrary set of images are appended to this binary to form the
;;; "boot disk image". This data structure describes what's present.
;;; It end up at a Known place in memory so that it can be patched.
;;; The LDMAP above (or a command-line argument) determines which, if any, of the
;;; images are loaded into the NASCOM's memory.
;;;
;;; There are 16 entries here; each entry is 8 bytes.
;;; This image is 512 (0x200) bytes in size, so the first appended ROM will have
;;; an offset of 0x0000.0200
;;; The (32-bit) offset and (16-bit) byte count can have any values - do not need
;;; to be aligned to underlying sector size/alignment, but to make things
;;; easier to follow they are (or have been padded).
copy:
        ;; Bitmap mask $0001: NASDOS original 4Kbytes at D000
        defb    $00, $02, $00, $00 ;32-bit byte offset to start of image, low byte first
        defw    $1000              ;16-bit byte count to transfer, low byte first
        defw    $d000              ;16-bit destination address, low byte first
        ;; Bitmap mask $0002: NASDOS for nascom_sdcard 4Kbytes at D000
        defb    $00, $12, $00, $00 ;32-bit byte offset to start of image, low byte first
        defw    $1000              ;16-bit byte count to transfer, low byte first
        defw    $d000              ;16-bit destination address, low byte first
        ;; Bitmap mask $0004: PolyDos 2: 2Kbytes at D000
        defb    $00, $22, $00, $00 ;32-bit byte offset to start of image, low byte first
        defw    $0800              ;16-bit byte count to transfer, low byte first
        defw    $d000              ;16-bit destination address, low byte first
        ;; Bitmap mask $0008: PolyDos for nascom_sdcard: 2Kbytes at D800
        defb    $00, $2a, $00, $00 ;32-bit byte offset to start of image, low byte first
        defw    $0800              ;16-bit byte count to transfer, low byte first
        defw    $d800              ;16-bit destination address, low byte first
        ;; Bitmap mask $0010: ZEAP (ROM version): 4Kbytes at D000
        defb    $00, $32, $00, $00 ;32-bit byte offset to start of image, low byte first
        defw    $1000              ;16-bit byte count to transfer, low byte first
        defw    $d000              ;16-bit destination address, low byte first
        ;; Bitmap mask $0020: NASCOM ROM BASIC (ROM version): 8Kbytes at E000
        defb    $00, $42, $00, $00 ;32-bit byte offset to start of image, low byte first
        defw    $2000              ;16-bit byte count to transfer, low byte first
        defw    $e000              ;16-bit destination address, low byte first
        ;; Bitmap mask $0040: PolyData PASCAL (ROM version): 12Kbytes at D000
        defb    $00, $62, $00, $00 ;32-bit byte offset to start of image, low byte first
        defw    $3000              ;16-bit byte count to transfer, low byte first
        defw    $d000              ;16-bit destination address, low byte first
        ;; Bitmap mask $0080: NAS-PEN (ROM version): 2Kbytes at B800
        defb    $00, $92, $00, $00 ;32-bit byte offset to start of image, low byte first
        defw    $0800              ;16-bit byte count to transfer, low byte first
        defw    $b800              ;16-bit destination address, low byte first
        ;; Bitmap mask $0100: DIS/DEBUG (ROM version): 4Kbytes at C000
        defb    $00, $9a, $00, $00 ;32-bit byte offset to start of image, low byte first
        defw    $1000              ;16-bit byte count to transfer, low byte first
        defw    $c000              ;16-bit destination address, low byte first
        ;; Bitmap mask $0200: NAS-FORTH (RAM version): 10Kbytes at 1000
        defb    $00, $aa, $00, $00 ;32-bit byte offset to start of image, low byte first
        defw    $2800              ;16-bit byte count to transfer, low byte first
        defw    $1000              ;16-bit destination address, low byte first
        ;; Bitmap mask $0400: ZEN and its source (RAM version): 27Kbytes at 1000
        defb    $00, $d2, $00, $00 ;32-bit byte offset to start of image, low byte first
        defw    $6C00              ;16-bit byte count to transfer, low byte first
        defw    $1000              ;16-bit destination address, low byte first

        ;; space for more images..
        ds      8, $ff          ; Bitmap mask $0800
        ds      8, $ff          ; Bitmap mask $1000
        ds      8, $ff          ; Bitmap mask $2000
        ds      8, $ff          ; Bitmap mask $4000
        ds      8, $ff          ; Bitmap mask $8000

;;; Low-level subroutines
        include "sd_sub1.asm"

;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; main program
;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

entry:  rst     PRS
        defm    'Start SDBOOT0..',$0d
        defb    0

;;; Got here via dskboot so interface will be ready and trained
;;; (Can't re-execute from reset because PIO will not be set up).

        ld      hl, copy - 8    ;will point to image table

;;; If dskboot was invoked with 1 argument, load map was not supplied
;;; on the command line so use default value
        ld      bc, (ldmap)     ;map from default
        ld      a, (ARGN)
        cp      1
        jr      z, gotmap
        ld      bc, (ARG2)      ;map from command line
gotmap: push    bc

;;; Process the load map. Remember, the images are not present
;;; in memory yet: they are in the disk image. They need to be pulled in
;;; using NASdsk commands. The NASdsk interface is already initialised
;;; (it was used to get us here) and the disk with FID=0 is mounted.
;;; Just need to seek and read/load.
next:   ld      de, 8
        or      a
        adc     hl, de          ;next entry in image table

next1:  pop     bc              ;remaining part of map
        ld      a, b
        or      c
        jr      z, done         ;no more images to load

        srl     b               ;inspect LSB
        rr      c
        push    bc              ;ready for next time
        jr      nc, next        ;do not load

;;; load image specified by table entry at HL. Loop back
;;; to next1 with HL advanced to NEXT entry in image table
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

;;; After loading all the images, either
;;; - return to NAS-SYS
;;; - use the default start associated with the default map
;;; - use the explicit start address
done:   ld      hl, (ARG3)
        ld      a, (ARGN)
        cp      3
        jr      z, gotdest
        cp      2
        jr      z, exit
        ld      hl, (exitjp)
gotdest:ld      a, h
        or      l
        jr      z, exit         ;convert destination of 0 to NAS-SYS warm start
        jp      (hl)            ;go!

;;; pad binary to 512 bytes
SIZE:   EQU     $ - START
PAD:    EQU     512 - SIZE
        DS      PAD, $ff

;;; end
