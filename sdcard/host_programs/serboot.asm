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
        ld      hl,48           ;characters per line
        add     hl,de           ;HL=end of this line (first NUL in margin)

;;; find first non-space, non-dot character. Remember whether
;;; it was a dot
find:   dec     hl              ;move back by one character
        ld      a,(hl)
        cp      $20             ;space?
        jr      z, find         ;carry on looking

        cp      $2e             ;dot?
        jr      nz, nodot
        dec     hl              ;skip back over the dot

nodot:  push    af              ;save Z. Later, loop if Z


;;; now, hl-de is the number of characters on the line. First PRLEN characters
;;; should be the prompt, but the user could have been naughty and back-spaced
;;; over them. Don't give the user the satisfaction of seeing us crash but
;;; detect that situation and treat it with distain.

;;; BUG1: actually num char is hl-de+1 so need to increment hl by 1.
        
        or      a               ;clear carry
        sbc     hl,de
        ld      a,l             ;count must be <49 so will definitely fit in 8-bits
        cp      PRLEN-1
        jr      c,done          ;blank line or corrupted prompt. Need to clean stack

        ld      l,PRLEN
        ;; h=0 from above
        add     hl,de           ;first char of command
        or      a
        sbc     a,PRLEN
        ld      b,a

;;; ready to send line out. B characters from HL onwards

send:   ld      a,(hl)
        rst     ROUT            ;echo TODO should be to serial port
        inc     hl
        djnz    send

;;; wait for response
eol:    SCAL     ZIN            ;TODO does this include serial port?
        jr      nc, eol         ;TODO or maybe just use rst RIN

        cp      RSDONE
        jr      z, done         ;ready for next command, if any
        cp      RSMSG
        jr      z, prmsg
        cp      RSMOVE
        jr      nz, fatal       ;something's wrong

;;; get new address
newl:   SCAL    ZIN
        jr      nc, newl        ;low byte
        ld      a, e
newh:   SCAL    ZIN
        jr      nc, newh        ;high byte
        ld      a, d

        pop     af              ;recover Z flag
        push    de              ;where to restart
        ld      hl, START       ;current start
        ld      bc, END-START+1 ;image size
        ldir                    ;move ourself

        ;; Z was preserved
        jr      nz, exit        ;quit using current code

;;; restart from the code in its new location, and get a new command
        ret

;;; print null-terminated string from sdcard
prmsg:  SCAL    ZIN
        jr      nc, prmsg

        or      a               ;is it NUL?
        jr      z, done         ;yes; ready for next command, if any
        rst     ROUT
        jr      prmsg           ;carry on with string

;;; Recover Z and either exit or get the next command
done:   pop     af
        jr      z, newcmd

;;; finished
exit:   SCAL    ZMRET

;;; fatal error
fatal:  SCAL    ZERRM
        SCAL    ZMRET
END:
;;; end
