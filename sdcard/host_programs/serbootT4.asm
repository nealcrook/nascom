;;; NASCOM-resident code for the NAScas serial interface using NASBUG T4
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
;;; By default it is assembled to load at location 0c50 because that is the
;;; start of free RAM when running the NASBUG T4 monitor.
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

START:        EQU     $0c50

;;; length of the prompt "NAScas> "
PRLEN:  EQU     8

;;; response values
RSDONE: EQU     0
RSMOVE: EQU     $55
RSMSG:  EQU     $ff

;;; Equates for NASBUG T4 characters
T4CR:   EQU     $1f

;;; Restarts into NASBUG T4
T4RET:  EQU     $8              ;Return to monitor
PRS:    EQU     $28             ;Print string until NULL
ROUT:   EQU     $30             ;Output character in A

;;; Addresses for calls into NASBUG T4
SLROUT: EQU     $005e           ;Output to UART only
TIN:    EQU     $04f2           ;Input from keyboard or UART

;;; Addresses of NASBUG T4 workspace
CURSOR: EQU     $0c18

        ORG     START

;;; print command prompt
newcmd: rst     PRS
        defm    "NAScas> ", 0

        ;; imitate the NAS-SYS ZINLIN call: get an input line and finish with DE
        ;; addressing the start of the line
inlin:  call    TIN             ;get character
        rst     ROUT            ;echo to display
        cp      T4CR            ;end of line?
        jr      nz,inlin        ;no; continue
        ;; Got a line, and cursor is at the start of the next line
        ld      hl, (CURSOR)
        ld      de, -64         ;video RAM stride is 64 so this moves us up a line to the command
        add     hl,de
        ex      de,hl           ;DE=start of command in video RAM

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
        call    SLROUT          ;send to serial port ONLY
        inc     hl
        djnz    send

;;; nul-terminate
        xor     a
        call    SLROUT

;;; get response
eol:    call    TIN             ;get character
        cp      RSDONE
        jr      z, done         ;ready for next command, if any
        cp      RSMSG
        jr      z, prmsg
        cp      RSMOVE
        jr      z, move
;;; fatal error: print message and exit
        rst     PRS
        defm    "Error"
        defb    T4CR,0
        rst     T4RET           ;TERMINATE PROGRAM


xprmsg: RST     ROUT            ;echo and drop through for more

;;; RSMSG: print pageable null-terminated string from NAScas hardware
prmsg:  call    TIN             ;get character (from serial interface)
        or      a               ;is it NUL?
        jr      z, done         ;yes; ready for next command, if any
        cp      1               ;is it PAUSE
        jr      nz, xprmsg      ;anything else is echoed

;;; pause/pager within RSMSG
        call    TIN             ;get character (from NASCOM keyboard)
        call    SLROUT          ;and send to serial port
        jr      prmsg           ;continue with print message

;;; RSDONE: recover Z and either exit or get the next command
done:   pop     af
        jr      nz, newcmd

;;; finished
exit:   RST     T4RET           ;TERMINATE PROGRAM


;;; RSMOVE: get new address
;;; first, find where current location in memory of START
move:   call    move2
move2:  ld      de,move2 - START;offset from start
        pop     hl
        or      a
        sbc     hl,de           ;HL=current start

        call    TIN
        ld      e, a            ;low byte
        call    TIN
        ld      d, a            ;DE=destination

        pop     af              ;recover Z flag
        push    de              ;where to restart
        ld      bc, END-START+1 ;BC=image size
        ldir                    ;move ourself

;;; AF (and so Z) was not affected by ldir. Z tells us whether
;;; to quit or whether to go back for another command. Stack is empty.

        jr      z, exit         ;quit using code at current location
        ret                     ;jump to start of code at new location

END:
;;; end
