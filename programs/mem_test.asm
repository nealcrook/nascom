;;; test program for NASCOM workspace & video memory
;;;
;;; design goals:
;;; - ROM-able
;;; - relocatable
;;; - use no workspace RAM
;;; - use no stack
;;; - allow 'scope debug of issues in workspace RAM (0x0C00-0x0FFF)
;;;                                   and video RAM (0x0800-0x0BFF)
;;;
;;; Write 00 ff aa 55 to locations 0C00-0C03 then
;;; read them back.
;;; Do the same to locations 0800-0803
;;; Increment low byte of both address and loop
;;; (so, cycle through addresses 0C00-0CFF and 0800-0BFF).
;;; Before each group of 4 reads, do an OUT (I/O instruction)
;;; to port 3 and port 0 respectively
;;;
;;; 1/ Make sure the code is looping
;;; - Use 'scope to look for pulses on port3 and port 0 decode
;;;   IC36/12, IC36/9
;;; If not, remove other stuff on the data bus: PIO, UART,
;;; buffers IC47, IC28, IC40, IC41, second eprom IC39. This
;;; should allow you to narrow down any bad chips
;;;
;;; 2/ Test video RAM (chips/pins are for N1):
;;; - Set 'scope ch1 to trigger on data bus buffer enable
;;;   IC45/8 or IC28/1
;;; Expect to see a group of 4 low-going pulses
;;; - Use 'scope ch2 to probe along IC20/12..IC27/12
;;; Expect to see stable value while enable is low: on each
;;; chip, 0 for 2 of the reads and 1 for the other 2 (in
;;; accordance with the data pattern 00 ff aa 55 and depending
;;; on the bit position)
;;;
;;; 3/ Test workspace RAM (chips/pins are for N1):
;;; As above but
;;; - Set 'scope ch1 to trigger on data bus buffer enable
;;;   IC45/6 or IC47/1
;;; - Use 'scope ch2 to probe along IC48/12..IC55/12
;;;
;;; The National Semiconductor 2102 RAMs used on the N1 seem
;;; particularly susceptible to failure.
;;;
;;; If any bit(s) seem bad, remove buffers IC28, IC47 to make
;;; sure that the buffer is not responsible. Change any faulty
;;; RAM chips. (re)insert data bus buffers IC28, IC47 and
;;; check data for video RAM and workspace RAM on the CPU data
;;; bus pins.
;;;
;;; REMEMBER: NO POWER-ON RESET ON NASCOM 1; YOU NEED TO RESET IT!!
;;;
        org 0                   ;but relocatable
start:  ld hl, 0xc00            ;start of workspace RAM
        ld bc, 0x800            ;start of video     RAM

loop:   ld (hl), 0x00           ;write to workspace RAM
        inc l
        ld (hl), 0xff
        inc l
        ld (hl), 0xaa
        inc l
        ld (hl), 0x55
        dec l
        dec l
        dec l                   ;back where we started

        ;; write to port 3 indicates the start of 4 workspace reads
        out (3),a               ;port 3 is unused but decoded on IC36/9 (N1)
        ld a, (hl)              ;expect 0x00
        inc l
        ld a, (hl)              ;expect 0xff
        inc l
        ld a, (hl)              ;expect 0xaa
        inc l
        ld a, (hl)              ;expect 0x55
        inc l                   ;to next group of 4

        ld d,h                  ;save ws address in de
        ld e,l
        ld h,b                  ;restore video address from bc
        ld l,c

        ld (hl), 0x00           ;write to video RAM
        inc l
        ld (hl), 0xff
        inc l
        ld (hl), 0xaa
        inc l
        ld (hl), 0x55
        dec l
        dec l
        dec l                   ;back where we started

        ;; write to port 0 indicates the start of 4 video reads
        out (0),a               ;port 0 is decoded on IC36/12 (N1)
        ld a, (hl)              ;expect 0x00
        inc l
        ld a, (hl)              ;expect 0xff
        inc l
        ld a, (hl)              ;expect 0xaa
        inc l
        ld a, (hl)              ;expect 0x55
        inc l                   ;to next group of 4

        ld b,h                  ;save video address in bc
        ld c,l
        ld h,d                  ;restore ws address from de
        ld l,e

        jr loop

end:
size:   equ     end - start
        defs    1024 - size
