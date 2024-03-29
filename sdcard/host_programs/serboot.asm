;;; NASCOM-resident code for the NAScas serial interface using NAS-SYS 1 or 3
;;;
;;; https://github.com/nealcrook/nascom
;;;
;;; This is the default program loaded across the serial interface after boot.
;;; It is loaded using the "R" command and is relocatable code so that it can
;;; be put in any convenient location.
;;;
;;; It provides a prompt and command loop and acts as a console, relaying
;;; commands to the NAScas hardware and reporting responses.
;;;
;;; By default it is assembled to load at location 0c80 because that is the
;;; start of free RAM when running the NAS-SYS monitors.
;;;
;;; The command loop provides a mechanism whereby this code can relocate
;;; itself and continues to run, from the new location. It will relocate to
;;; any non-overlapping address.
;;;
;;; When executed, it responds with a command prompt:
;;;
;;; NAScas>
;;;
;;; Every command is sent directly to the NAScas hardware across the
;;; serial interface. Type "." to exit the command loop (either at the end
;;; of a line or on a line by itself).
;;;
;;; The command set is documented elsewhere (it is not handled by this program).
;;;
;;; Configuration
;;; -------------
;;;
;;; The NASCOM should be configured for cassette operation with 1 stop bit.
;;;
;;; Protocol
;;; --------
;;;
;;; serboot implements a command loop. When RETURN is pressed, the line (upto
;;; the last non-blank or dot character, and terminated with a NUL (0x00))
;;; is sent to NAScas across the serial interface. NAScas responds with one
;;; of three codes:
;;;
;;; RSDONE - command complete. No response.
;;; RSMOVE hh ll - relocate the address given by following two bytes
;;; RSMSG - print byte string with pager:
;;; - 0x00 : terminate string. Not echoed.
;;; - 0x01 : message paused. Not echoed. Serboot waits for a key press
;;;          which it sends to NAScas
;;; - 0xNN : (any other byte) echoed.
;;;
;;; serboot remembers whether the last command was terminated with a . or not.
;;; If no . then the prompt is displayed for another command. Otherwise,
;;; serboot terminates and returns to NAS-SYS.
;;; A blank line results in a new prompt with no communication with the NAScas
;;; hardware

START:        EQU     $0c80

;;; length of the prompt "NAScas> "
PRLEN:  EQU     8

;;; response values
RSDONE: EQU     0
RSMOVE: EQU     $55
RSMSG:  EQU     $ff


SCAL:   MACRO FOO
        RST 18H
        DB FOO
        ENDM


;;; Equates for communicating with NAS-SYS
PRS:    EQU     $28             ;Restart
RIN:    EQU     $08             ;Restart
ROUT:   EQU     $30             ;Restart
ZMRET:  EQU     $5b             ;SCAL
ZINLIN: EQU     $63             ;SCAL
ZERRM:  EQU     $6b             ;SCAL
ZSRLX:  EQU     $6f             ;SCAL

        ORG     START

;;; print command prompt
newcmd: rst     PRS
        defm    "NAScas> ", 0

        SCAL    ZINLIN          ;DE=start of this line
        ld      hl, PRLEN
        add     hl,de
        ex      de,hl           ;DE=1st char of command

        ld      hl,48 - PRLEN   ;48 char per line
        add     hl,de           ;HL=end of this line (first NUL in margin)

;;; find first non-space, non-dot character; remember whether it is a dot
find:   dec     hl              ;move back by one character
        ld      a,(hl)
        cp      $20             ;space?
        jr      z, find         ;carry on looking

        cp      $2e             ;dot?
        jr      nz, nodot
        dec     hl              ;skip back over the dot (flags unchanged)

nodot:  push    af              ;save Z. Later, exit if Z

;;; now, DE= 1st char of command, HL= last char of command. If the line is blank
;;; or the user has back-spaced over the prompt, will have HL < DE. Respond to
;;; this by ignoring the line and re-issuing the prompt.

        or      a               ;clear carry
        sbc     hl,de
        jr      c, done         ;blank/corrupted prompt. Clear stack and loop

        ld      b, l            ;count is <(48-PRLEN) so fits in 8 bits.
        inc     b               ;length of command

        ex      de,hl           ;HL=1st char of command

;;; ready to send line out. B characters from HL onwards

send:   ld      a,(hl)
        SCAL    ZSRLX           ;send to serial port ONLY
        inc     hl
        djnz    send

;;; nul-terminate
        xor     a
        SCAL    ZSRLX

;;; get response
eol:    RST     RIN
        cp      RSDONE
        jr      z, done         ;ready for next command, if any
        cp      RSMSG
        jr      z, prmsg
        cp      RSMOVE
        jr      z, move
;;; fatal error: print message and exit
        SCAL    ZERRM
        SCAL    ZMRET           ;TEMINATE PROGRAM


;;; RSMOVE: get new address
;;; first, find where current location in memory of START
move:   call    move2
move2:  ld      de,move2 - START;offset from start
        pop     hl
        or      a
        sbc     hl,de           ;HL=current start

        RST     RIN
        ld      e, a            ;low byte
        RST     RIN
        ld      d, a            ;DE=destination

        pop     af              ;recover Z flag
        push    de              ;where to restart
        ld      bc, END-START+1 ;BC=image size
        ldir                    ;move ourself

;;; AF (and so Z) was not affected by ldir. Z tells us whether
;;; to quit or whether to go back for another command. Stack is empty.

        jr      z, exit         ;quit using code at current location
        ret                     ;jump to start of code at new location

xprmsg: RST     ROUT            ;echo and drop through for more

;;; RSMSG: print pageable null-terminated string from NAScas hardware
prmsg:  RST     RIN             ;get character (from serial interface)
        or      a               ;is it NUL?
        jr      z, done         ;yes; ready for next command, if any
        cp      1               ;is it PAUSE
        jr      nz, xprmsg      ;anything else is echoed

;;; pause/pager within RSMSG
        RST     RIN             ;get character (from NASCOM keyboard)
        SCAL    ZSRLX           ;and send to serial port
        jr      prmsg           ;continue with print message

;;; RSDONE: recover Z and either exit or get the next command
done:   pop     af
        jr      nz, newcmd

;;; finished
exit:   SCAL    ZMRET           ;TERMINATE PROGRAM

END:
;;; end
