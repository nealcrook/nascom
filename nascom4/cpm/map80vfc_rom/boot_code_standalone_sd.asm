;;; Stand-alone boot code to initialise the MAP80 VFC and load/execute
;;; boot sector code from supposed CP/M image on SDcard.
;;;
;;; With a "normal" floppy disk system, the MAP80 VFC appears in
;;; the memory map at address 0 and the NASCOM4 SBR menu entry ends
;;; with a jump to address 0 which executes the boot code in the
;;; MAP80 VFC ROM.
;;;
;;; When booting CP/M from the SDcard, that normal MAP80 VFC ROM boot
;;; code is no use. There is a modified MAP80 VFC ROM that contains
;;; SDcard boot code, but the ROM image is coded into the FPGA *and*
;;; I want the capability to choose floppy or SDcard boot. Therefore,
;;; this program..
;;;
;;; This program is loaded into RAM at E000 by the SBR in the usual
;;; way, and the MAP80 VFC appears in the memory map at address 0.
;;; The NASCOM4 SBR menu entry ends with a jump to address E000 which
;;; executes this boot code, instead of the boot code in the MAP80 VFC ROM.
;;;
;;; This program copies, as much as possible, the boot code from
;;; the MAP80 VFC ROM.
;;;
;;; 1/ Use the NASCOM4 SDcard controller to load 1 block (512 bytes)
;;; from the 1st sector of the 1st virtual disk (block $8400) to
;;; RAM at $c00.
;;;
;;; 2/ Check that the loaded code has a magic fingerprint that identifies
;;; it as a system image and, if so, jump to $c02.
;;;
;;; This code also initialises the VFC and its workspace; the code for
;;; that is unchanged from the original.
;;;

VFCINIT: equ $0023               ;outside this image
ENTRY:   equ $0C02               ;entry point of loaded code

;SDcontroller ports
SDDATA: EQU 010H		;R/W
SDSTAT: EQU 011H		;RO
SDCTRL: EQU 011H		;WO
SDLBA0: EQU 012H		;WO
SDLBA1: EQU 013H		;WO
SDLBA2: EQU 014H		;WO

        org $E000

BOOT1:
        ld sp, $1000
        xor a

;;; Set VFC workspace and call init
        ld ix, $0C00
        call VFCINIT
        ld hl, MSGBOOT

;;; Enable VFC video RAM (at $0800)

VIDRAM:
        ld a, $01
        out ($EC), a

;;; $0800 is top-left corner of VDU and the literal 7 is the length
;;; of each of the message strings. LDIR copies the string
        ld de, $0800
        ld bc, $0007
        ldir
        ex de, hl
        ld bc, $07C9

;;; The screen is 25*80=2000 locations subtract 7 for the
;;; message string is 1993 = 0x7c9, so this is clearing the screen - filling it with spaces

CLS:
        ld (hl), $20
        inc hl
        dec bc
        ld a, b
        or c
        jr nz, CLS

;;; keep ROM enabled at 0, disable the video RAM, so that system RAM appears
        xor a
        out ($EC), a

;;; initialise SDcard controller
        ld      hl, 0
initsd: dec     hl
        ld      a,h
        or      l
        jr      z, ERRDSK       ;timeout
        in      a,(SDSTAT)
        cp      $80
        jr      nz, initsd      ;wait until SDcard is ready

        ld      a,0             ;SDcard block address $00.8400
        out     (SDLBA2), a     ;coded like this to make it patchable
        ld      a,$84
        out     (SDLBA1), a
        ld      a,0
        out     (SDLBA0), a

        xor     a
        out     (SDCTRL), a     ;READ command

        ld      hl, $c00        ;data destination

datloop: in     a,(SDSTAT)
        cp      $80
        jr      z, SYSDSK      ;all bytes loaded
        cp      $e0
        jr      nz, datloop     ;wait for next byte
        in      a,(SDDATA)      ;[NAC HACK 2021Aug03] set up C for data port
        ld      (hl),a
        inc     hl
        jr      datloop

;;; ensure that the image look good (check "magic signature")
SYSDSK:
        ld hl, ($0C00)
        ld de, $3038
        or a
        sbc hl, de
        jp z, ENTRY
        ld hl, MSGSYS
        jr VIDRAM

ERRDSK:
        ld hl, MSGDSK
        jr VIDRAM

;;; assembler doesn't allow forward references in this calculation so only allows
;;; padding at the end; not what we want. If this number is wrong, the manipulate_vfc_rom
;;; script will detect/report the problem.
        DS 54, $00

MSGBOOT:
        defm "LSDBOOT"

MSGDSK:
        defm "DISK ??"

MSGSYS:
        defm "SYSTEM?"

MSGERR:
        defm "ERROR ?"          ;not used for SDcard code

END:    equ $

;;; pad to 1 block (512 bytes) for tidyness.
SIZE:   equ END - BOOT1
PAD1:   equ 200h - SIZE
        DS PAD1, 0
