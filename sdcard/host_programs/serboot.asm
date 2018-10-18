;;; Boot/command-line Utility for nascom_sdcard
;;; serial interface
;;;
;;; https://github.com/nealcrook/nascom
;;;
;;; This is the default program loaded across the serial
;;; interface after boot. It is loaded using the "R"
;;; command and is relocatable code so that it can be put
;;; in any convenient location.
;;;
;;; It provides a prompt and command loop and acts as a
;;; console, relaying commands to the nascom_sdcard and
;;; reporting responses.
;;;
;;; By default it is assembled to load at location 0c80
;;; because there is RAM there on NASCOM 1 and NASCOM 2
;;; systems.
;;;
;;; The command loop provides a mechanism whereby this code
;;; relocates itself and continues to run, from the new
;;; location. It will relocate to any non-overlapping
;;; address.
;;;
;;; When executed, it responds with a command prompt:
;;;
;;; SDcard>
;;;
;;; Every command is sent directly to the nascom_sdcard
;;; hardware across the serial interface. Type "." to exit
;;; the command loop (either at the end of a line or on a
;;; line by itself).
;;;
;;; The command set is documented elsewhere (it is not
;;; handled by this program).
;;;
;;; Configuration
;;; -------------
;;;
;;; The NASCOM should be configured for cassette
;;; operation with 1 stop bit. Various baud rates are
;;; supported. The baud rate is set by a jumper on the
;;; nascom_sdcard, and a configuration file on the SDcard
;;; determines the baud rates associated with the jumper
;;; settings.
;;;
;;; Protocol
;;; --------
;;;
;;; There is a command loop. When RETURN is pressed, the
;;; command is send on the serial interface. The command
;;; is the whole line upto the last non-blank or dot character.
;;; The line is terminated with a NUL (0x00).
;;;
;;; nascom_sdcard responds with one of three codes:
;;; RSDONE - command complete. No response.
;;; RSMOVE hh ll - relocate the address given by following
;;; two bytes
;;; RSMSG - print NUL-terminated text.
;;;
;;; This code remembers whether the last command was terminated
;;; with a . or not. If no . then the prompt is displayed
;;; for another command. Otherwise, the program returns to
;;; NAS-SYS.
;;; A blank line results in a new prompt with no communication
;;; with nascom_sdcard.
;;;

START:        EQU     $0c80

;;; length of the prompt "SDcard> "
PRLEN:  EQU     8

;;; response values
RSDONE: EQU     0
RSMOVE: EQU     $55
RSMSG:  EQU     $ff


SCAL:   MACRO FOO
        RST 18H
        DB FOO
        ENDM


;;; Equates for communicating with NAS-SYS and NAS-SYS workspace
PRS:    EQU     $28
RIN:    EQU     $08
ROUT:   EQU     $30
ZMRET:  EQU     $5b
ZIN:    EQU     $62
ZINLIN: EQU     $63
ZCRLF:  EQU     $6a
ZERRM:  EQU     $6b

        ORG     START

;;; print command prompt
newcmd: rst     PRS
        defm    "SDcard> ", 0

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

;;; now, DE= 1st char of command, HL= last char of command. BUT, if the user
;;; has back-spaced over the prompt, could have HL < DE. Cope with this by
;;; ignoring the line and re-issuing the prompt.

        or      a               ;clear carry
        sbc     hl,de
        jr      z, done         ;blank line. Clean the stack and repeat prompt
        jr      c, done         ;corrupted prompt. Clean the stack and repeat prompt

        ld      b, l            ;count is <(48-PRLEN) so fits in 8 bits.
        inc     b               ;length of command

        ex      de,hl           ;HL=1st char of command

;;; ready to send line out. B characters from HL onwards

send:   ld      a,(hl)
        rst     ROUT            ;echo TODO should be to serial port
        inc     hl
        djnz    send

;;; nul-terminated
        xor     a
        rst     ROUT            ;echo TODO should be to serial port

;;; TODO for debug only
        SCAL    ZCRLF


;;; wait for response
eol:    RST     RIN
        cp      RSDONE
        jr      z, done         ;ready for next command, if any
        cp      RSMSG
        jr      z, prmsg
        cp      RSMOVE
        jr      nz, fatal       ;something's wrong

;;; RSMOVE: get new address
        RST     RIN
        ld      a, e            ;low byte
        RST     RIN
        ld      a, d            ;high byte

        pop     af              ;recover Z flag
        push    de              ;where to restart
        ld      hl, START       ;current start
        ld      bc, END-START+1 ;image size
        ldir                    ;move ourself

        ;; AF (and so Z) was not affected by ldir
        jr      z, exit         ;quit using current code

;;; restart from the code in its new location, and get a new command
        ret

;;; print null-terminated string from sdcard
prmsg:  RST     RIN
        or      a               ;is it NUL?
        jr      z, done         ;yes; ready for next command, if any
        rst     ROUT
        jr      prmsg           ;carry on with string

;;; Recover Z and either exit or get the next command
done:   pop     af
        jr      nz, newcmd

;;; finished
exit:   SCAL    ZMRET

;;; fatal error
fatal:  SCAL    ZERRM
        SCAL    ZMRET
END:
;;; end
