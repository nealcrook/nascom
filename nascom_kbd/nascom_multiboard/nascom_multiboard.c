// Code for "Nascom Multiboard",                                   -*- c -*-
// a PCB containing a Raspberry Pi Pico, some level-shifters and various connectors.
//
// foofoobedoo@gmail.com
//
// TODO: demonstrate functionality of:
// DONE mode[2:0] inputs at reset
// DONE LEDs
// DONE Pico hard reset button
// DONE Warm Reset & NMI soft input buttons
//      VGA output
// DONE Serial output via Pi Pico USB
//      Serial output via serial->usb adaptor
//      uSD read/write and FAT file system
// DONE PS/2 keyboard
//      12v->5V regulator
//      Gemini serial keyboard interface TODO can it accept 5V levels or does it need 12V? Need protection on my board
//      Gemini parallel keyboard interface
//      Gemini parallel keyboard interface with strobe inversion
//      Nascom scanned keyboard interface
//      Nascom serial port interface
//
// Debug/Console output: $ minicom -b 115200 -o -D /dev/ttyACM0
//
// TODO implement hex keypad in N4 VHDL
//
// REV A Board/design bugs:
// 1. failed to mark IC type for the two 74LVC244 parts
// 2. the "WARM RESET" and "NMI" push-buttons are connected directly to the Pi, but
//    the same Pi inputs are driven from level-shifter outputs. This was deliberate
//    so that the buttons could be used without the need to fit the level shifters,
//    but maybe I should have added some wire links so that the buttons could be usable
//    in either case.
// 3. the "VSYS" should have been the local source of 5V; the net labelled +5V
//    then connects to all the things that *supply* (eg, supply from Nascom).
//    The only on-board *user* of 5V is the PS/2 keyboard, so J4/2 can be wired
//    to VSYS (band end of diode) rather than to J4/1.


#include <stdio.h>
#include "pico/stdlib.h"
#include "hardware/gpio.h"
#include "pico/binary_info.h"
#include "pico/multicore.h"

// Pin assignment - outputs unless stated
const uint P_PICO_LED = 25;
//
const uint P_MODE2 = 26; // in briefly after reset, shared
const uint P_MODE1 = 22; // in briefly after reset, shared
const uint P_MODE0 = 21; // in briefly after reset, shared
//
const uint P_WRST_BTN = 11; // in
const uint P_NMI_BTN  = 12; // in
//
const uint P_SDACT_LED = 1;
const uint P_HALT_LED  = 2;
const uint P_DRIVE_LED = 0;
//
const uint P_VGA_VSYNC = 26; // shared
const uint P_VGA_HSYNC = 22; // shared
const uint P_VGA_VID =   21; // shared
//
const uint P_PS2_CLK = 15; // in
const uint P_PS2_DAT = 16; // in
//
const uint P_SER_TXD = 27;
const uint P_SER_RXD = 28; // in
//
const uint P_SDCS  = 17;
const uint P_SDDO  = 18;
const uint P_SDCLK = 19;
const uint P_SDDI  = 20; // in
//
const uint P_KBD_D7 = 7; // shared: D7 for parallel kbd, NMI for NASCOM kbd
const uint P_KBD_NNMI = 7;
const uint P_KBD_D6 = 6;
const uint P_KBD_D5 = 5;
const uint P_KBD_D4 = 4;
const uint P_KBD_D3 = 3;
const uint P_KBD_D2 = 2; // shared, also LED
const uint P_KBD_D1 = 1; // shared, also LED
const uint P_KBD_D0 = 0; // shared, also LED
const uint P_KBD_STB = 8;
const uint P_KBD_NRST = 8;
// Bug! I put the buttons on the wrong side of the level shifter, so you must not fit/use/press
// them if the level shifters are fitted
const uint P_KBD_CLK = 11; // shared, also from button, in
const uint P_KBD_RST = 12; // shared, also from button, in

////////////////////////////////////////////////////////////////////////////////
// nascom_kbd: variables shared between processors
//
// nascom keyboard map
// indices 7:0 correspond to the DRIVE line values of bits 6:0 correspond to the SENSE lines.
// it is r/w by core 0 and ro by core 1
volatile uint8_t nkmap[8];
// counter
uint8_t nscan_drive;


static uint8_t get_mode(void);
static uint8_t ps2_getc(void);
static void mode_nascom_kbd(void);
static void mode_ascii_kbd(uint8_t parallel, uint8_t strobe_positive);
static void mode_ps2_codes();
static void nascom_kbd_core1(void);

////////////////////////////////////////////////////////////////////////////////
// Data structures

// scan code set 2 (8-bit hex) from (eg) https://wiki.osdev.org/PS/2_Keyboard
//
//                       PRESS                         RELEASE
// easy stuff            00                            F0 00
//                       ..
//                       86                            F0 86              I only have lookup for 00..83
//                                                                        codes 84..86 are used on scan code set 1
//
// simple E0 prefix      E0 ??                         E0 F0 ??
//
// applies to these:
// l-WINDOWS, r-ALT r-WINDOWS MENU  r-CTRL INSERT HOME  PgUP  DELETE END   PgDOWN UP-ARR LEFT-ARR DOWN-ARR RIGH-ARR KP/   KPENTER
// 0x1f       0x11  0x27      0x2f  0x14   0x70   0x6c  0x7d  0x71   0x69  0x7a   0x75   0x6b     0x72     0x74     0x4a  0x5a
// 0x1f       0x11  0x14      0x2f  0x27   0x70   0x6c  0x7d  0x71   0x69  0x7a   0x75   0x6b     0x72     0x74     0x4a  0x5a
//                    **              **
//
// 1st row of values is from https://wiki.osdev.org/PS/2_Keyboard, 2nd row is what my keyboard produces. Differences marked **
//
// final fiddly ones:
//
// print screen          E0 12 E0 7C                   E0 F0 7C E0 F0 12
// pause break           E1 14 77 E1 F0 14 F0 77       (none) (no auto-repeat)
//
// print screen just looks like 2 keys pressed and released in succession; easy to ignore like any other ignored E0 ?? pair,
// or just decode 1 of the 2, 2-key pairs and ignore the other.
// pause break is a total outlier. Need to decode E1 prefix. 14 and 77 are both keys in the normal map.
//
// NUMLCK maintains state within the keyboard!! As well as codes for press and release, it affects the 10 keys
// etween the main keypad and the numeric keypad (though NOT the codes from the keys on the numeric keypad itself)
// NUMLCK itself is 77 on press, f0 77 on release
// INSERT is       E0 70, E0 F0 70  or, after numlock has been pressed an odd number of times:
//           E0 12 E0 70, E0 F0 70 E0 F0 12
//
// Likewise for HOME. etc.
//
// I think the simplest way of handling this is to trap and discard the "E0 12" press and the "E0 F0 12" release. Then,
// - print screen becomes simply E0 7C/ E0 F0 7C
// - the num lock has no effect
//
// all keys except pause/break auto-repeat and there seems no way to turn it off at the keyboard.
// Could I eliminate repeating keys here? Not very easily..
//
// The numeric keypad is repurposed for hex entry:
// A - NUMLCK
// B - KP/
// C - KP*
// D - KP-
// E - KP+
// F - KP.
//
// The only E0 prefix stuff that's handled is for hex heypad and to put NASCOM arrow keys on either side of the space bar:
//   nas-key  nas-code key             press/release sequence
//    <-      2,6      l-WINDOWS       E0 1F/E0 F0 1F
//    ^       1,6      l-ALT           11/F0 11           SIMPLE (not E0 prefix)
//    v       3,6      r-ALT (ALT-GR)  E0 11/E0 F0 11
//    ->      4,6      r-CTRL          E0 14/E0 F0 14
//    CR      0,1      KPENTER         E0 5A/E0 F0 5A
//    B       1,1      KP/             E0 4A/E0 F0 4A
//
// Read the table like this: SPACE is PS/2 keyboard code 92. On the NASCOM it is on drive line 7, sense line 4 and is coded
// here as t(7,4) which is converted into a 6-bit value by function t (see definition, above). Shift is treated/encoded like
// any other key. Legal drive values are 0-7. Legal sense values are 0-6. The illegal value 7,7 is used to represent a key
// that has no corresponding key on the NASCOM keyboard (it is ignored). The function keys F1-F12 do not affect the NASCOM
// keyboard but their DEPRESSION creates a hardware strobe (release is ignored)
//       code   lookup  event
// F1    05   t(0,7)    0000
// F2    06     1,7     0001
// F3    04     2,7     0010
// F4    0c     3,7     0011
// F5    03     0,7     0100
// F6    0b     1,7     0101
// F7    83     2,7     0110
// F8    0a     3,7     0111
// F9    01     0,7     1000
// F10   09     1,7     1001
// F11   78     2,7     1010
// F12   07     3,7     1011
//                      1111 // no event
//
// converted codes repeat so need to part-decode the scan code[7:0] to generate the high two bits of the event code
//
// leaves codes (7,7) for NO KEY and (4,7) (5,7) (6,7) for SOME OTHER SPECIAL THINGs (currently unused)
//
// Key-codes in this table as expressed as a 3-bit drive and a 3-bit sense value and they are combined to form a
// 6-bit code in the low 6 bits of a byte. The upper 2 bits are unused ATM.

#define t(drive, sense) ((drive<<3) | (sense))
static uint8_t const nasKbdArray[] = {
    //  0        1        2        3        4        5        6        7        8        9        A        B        C        D        E        F   <--LS MS
    //       F9                F5       F3       F1       F2       F12               F10      F8       F6       F4       TAB      `                      v
    t(7,7),  t(0,7),  t(7,7),  t(0,7),  t(2,7),  t(0,7),  t(1,7),  t(3,7),  t(7,7),  t(1,7),  t(3,7),  t(1,7),  t(3,7),  t(5,6),  t(7,7),  t(7,7), // 0
    //       l-ALT    l-SHIFT           l-CTRL   q        1                                   z        s        a        w        2
    t(7,7),  t(1,6),  t(0,4),  t(7,7),  t(0,3),  t(5,4),  t(6,4),  t(7,7),  t(7,7),  t(7,7),  t(2,4),  t(3,4),  t(4,4),  t(4,3),  t(6,3),  t(7,7), // 1
    //       c        x        d        e        4        3                          SPACE    v        f        t        r        5
    t(7,7),  t(7,3),  t(1,4),  t(2,3),  t(3,3),  t(7,2),  t(5,3),  t(7,7),  t(7,7),  t(7,4),  t(7,1),  t(1,3),  t(1,5),  t(7,5),  t(1,2),  t(7,7), // 2
    //       n        b        h        g        y        6                                   m        j        u        7        8
    t(7,7),  t(2,1),  t(1,1),  t(1,0),  t(7,0),  t(2,5),  t(2,2),  t(7,7),  t(7,7),  t(7,7),  t(3,1),  t(2,0),  t(3,5),  t(3,2),  t(4,2),  t(7,7), // 3
    //       ,        k        i        o        0        9                          .        /        l        ;        p        -
    t(7,7),  t(4,1),  t(3,0),  t(4,5),  t(5,5),  t(6,2),  t(5,2),  t(7,7),  t(7,7),  t(5,1),  t(6,1),  t(4,0),  t(5,0),  t(6,5),  t(0,2),  t(7,7), // 4
    //                '                 [        =                          CAPLOCK  r-SHIFT  ENTER    ]                 #~
    t(7,7),  t(7,7),  t(6,0),  t(7,7),  t(6,6),  t(0,5),  t(7,7),  t(7,7),  t(7,7),  t(0,4),  t(0,1),  t(7,6),  t(7,7),  t(0,6),  t(7,7),  t(7,7), // 5
    //       \|                                           BACKSP                     KP1               KP4      KP7
    t(7,7),  t(7,7),  t(7,7),  t(7,7),  t(7,7),  t(7,7),  t(0,0),  t(7,7),  t(7,7),  t(6,4),  t(7,7),  t(7,2),  t(3,2),  t(7,7),  t(7,7),  t(7,7), // 6
    // KP0   KP.      KP2      KP5      KP6      KP8      ESC      NUMLCK   F11      KP+      KP3      KP-      KP*      KP9      SCRLCK
    t(6,2),  t(1,3),  t(6,3),  t(1,2),  t(2,2),  t(4,2),  t(7,7),  t(4,4),  t(2,7),  t(3,3),  t(5,3),  t(2,3),  t(7,3),  t(5,2),  t(7,7),  t(7,7), // 7
    //                         F7
    t(7,7),  t(7,7),  t(7,7),  t(2,7)                                                                                                              // 8
}; // 16*8 + 4 = 132 entries


// Translation table: Keyboard scan code -> ASCII code
// Indexed by scan codes in the range 0x00..0x83. There are 2 bytes per entry, so index with scancode*2
// 2 bytes are: ASCII code unshifted, ASCII code shifted,
// ASCII code of 0 means "non-existent scan code" TODO ??? means interpreted explicitly???
//
static uint8_t const ASCIIKbdArray[] = {
    //            F9                          F5            F3            F1            F2            F12
    0x00,0x00,    0x19,0x19,    0x00,0x00,    0x15,0x15,    0x13,0x13,    0x11,0x11,    0x12,0x12,    0x1c,0x1c, //00-07
    //            F10           F8            F6            F4            TAB
    0x00,0x00,    0x1a,0x1a,    0x18,0x18,    0x16,0x16,    0x14,0x14,    0x09,0x09,    '`' ,0x00,    0x00,0x00, //08-0f

    //            l-ALT         l-SHIFT       l-CTRL
    0x00,0x00,    '^' ,'^' ,    0x00,0x00,    0x00,0x00,    0x00,0x00,    'q' ,'Q' ,    '1' ,'!' ,    0x00,0x00, //10-17
    //
    0x00,0x00,    0x00,0xff,    'z' ,'Z' ,    's' ,'S' ,    'a' ,'A' ,    'w' ,'W' ,    '2' ,'"' ,    0x00,0x00, //18-1f

    0x00,0x00,    'c' ,'C' ,    'x' ,'X' ,    'd' ,'D' ,    'e' ,'E' ,    '4' ,'$' ,    '3' ,0x23,    0x00,0x00, //20-27
    0x00,0x00,    ' ' ,' ' ,    'v' ,'V' ,    'f' ,'F' ,    't' ,'T' ,    'r' ,'R' ,    '5' ,'%' ,    0x00,0x00, //28-2f

    0x00,0x00,    'n' ,'N' ,    'b' ,'B' ,    'h' ,'H' ,    'g' ,'G' ,    'y' ,'Y' ,    '6' ,'^' ,    0x00,0x00, //30-37
    0x00,0x00,    0x00,0x00,    'm' ,'M' ,    'j' ,'J' ,    'u' ,'U' ,    '7' ,'&' ,    '8' ,'*' ,    0x00,0x00, //38-3f

    0x00,0x00,    ',' ,'<' ,    'k' ,'K' ,    'i' ,'I' ,    'o' ,'O' ,    '0' ,')' ,    '9' ,'(' ,    0x00,0x00, //40-47
    0x00,0x00,    '.' ,'>' ,    '/' ,'?' ,    'l' ,'L' ,    ';' ,':' ,    'p' ,'P' ,    '-' ,'_' ,    0x00,0x00, //48-4f

    //                                          '
    0x00,0x00,    0x00,0x00,    0x27,'@' ,    0x00,0x00,    '[' ,'{' ,    '=' ,'+' ,    0x00,0x00,    0x00,0x00, //50-57
    // CAPLOCK    r-SHIFT       ENTER
    0x00,0x00,    0x00,0x00,    0x0d,0x0d,    ']' ,'}' ,    0x00,0x00,    '#' ,'~' ,    0x00,0x00,    0x00,0x00, //58-5f

    //                                                                                  BSPC
    0x00,0x00,    '\\','|' ,    0x00,0x00,    0x00,0x00,    0x00,0x00,    0x00,0x00,    0x08,0x08,    0x00,0x00, //60-67
    //            KP1                         KP4           KP7
    0x00,0x00,    0x31,0x31,    0x00,0x00,    0x34,0x34,    0x37,0x37,    0x00,0x00,    0x00,0x00,    0x00,0x00, //68-6f

    // KP0        KP.           KP2           KP5           KP6           KP8           ESC           NUMLCK
    '0' ,'0' ,    '.' ,'.' ,    '2' ,'2' ,    '5' ,'5' ,    '6' ,'6' ,    '8' ,'8' ,    0x1b,0x1b,    0x00,0x00, //70-77
    // F11        KP+           KP3           KP-           KP*           KP9           SCRLCK
    0x1b,0x1b,    '+' ,'+' ,    '3' ,'3' ,    '-' ,'-' ,    '*' ,'*' ,    '9' ,'9' ,    0x00,0x00,    '<', '<' , //78-7f

    //                                        F7
    '>' ,'>' ,    '^' ,'^' ,    'v' ,'v' ,    0x17,0x17                                                          //80-83
}; // 2*(16*8 + 4) = 264


int main() {
    bi_decl(bi_program_description("Nascom PS/2 keyboard adaptor and multiboard by foofoobedoo@gmail.com"));
    bi_decl(bi_program_version_string("0.3 26Jun2025"));
    bi_decl(bi_program_url("http://www.github.com/nealcrook/nascom"));

    uint8_t mode;

    stdio_init_all();

    // Initialise all GPIO that are to be used at any point
    gpio_init_mask(1<<P_PICO_LED |
                   1<<P_MODE2 |
                   1<<P_MODE1 |
                   1<<P_MODE0 |
                   1<<P_WRST_BTN |
                   1<<P_NMI_BTN |
                   1<<P_SDACT_LED |
                   1<<P_HALT_LED |
                   1<<P_DRIVE_LED |
                   1<<P_SDACT_LED |
                   1<<P_PS2_CLK |
                   1<<P_PS2_DAT |
                   1<<P_SER_TXD |
                   1<<P_SER_RXD |
                   1<<P_SDCS |
                   1<<P_SDDO |
                   1<<P_SDCLK |
                   1<<P_SDDI |
                   1<<P_KBD_D7 |
                   1<<P_KBD_D6 |
                   1<<P_KBD_D5 |
                   1<<P_KBD_D4 |
                   1<<P_KBD_D3 |
                   1<<P_KBD_D2 |
                   1<<P_KBD_D1 |
                   1<<P_KBD_D0 |
                   1<<P_KBD_STB |
                   1<<P_KBD_CLK |
                   1<<P_KBD_RST);

    // These are all set to input by the init call, with pull-down. These 2 need pull-down so that
    // button presses can be sensed in get_mode()
    gpio_pull_up(11);
    gpio_pull_up(12);

    // Get operating mode by using shared pins as inputs
    // jumpers from top-to-bottom
    // off off off           mode 0 - NASCOM keyboard - connect PL3 to the NASCOM Keyboard connector (PL3)
    // off off  on           mode 1 - Gemini parallel keyboard - connect J13 to the Gemini Keyboard connector
    // off  on off           mode 2 - Like 1 but with negative strobe
    // off  on  on           mode 3 - Gemini serial keyboard - connect J6 to Gemini Keyboard connector.
    //                                This requires U3 but not U2 to be fitted, also requires regulator U4.
    //  on off off           mode 4 - ?? SDcard functionality with pass-through serial port??
    //  on off  on           mode 5 - ?? What??
    //  on  on off           mode 6 - ?? NASCOM Emulator??
    //  on  on  on           mode 7 - Test mode. After reset, jumpers can be removed and control the LEDs
    //
    // Holding "WARM RESET" and/or "NMI" buttons down while reset is released could provide additional
    // mode selection, BUT that can't be used when the level-translators are used (see bug list above)
    mode = get_mode();

    switch(mode) {
        // mode_ routines never return.
    case 0: mode_nascom_kbd();
    case 1: mode_ascii_kbd(1,1); // Gemini parallel keyboard, +ve strobe
    case 2: mode_ascii_kbd(1,0); //        parallel keyboard, -ve strobe
    case 3: mode_ascii_kbd(0,0); // Gemini serial keyboard, TODO baud rate

    case 7: mode_ps2_codes();    // Report PS/2 key codes
    }

    // Come here on unsupported mode
    while (1) {
        gpio_put(P_PICO_LED, 0);
        sleep_ms(250);
        gpio_put(P_PICO_LED, 1);
        printf("Hello World. Mode is: %d\n",mode);
        sleep_ms(1000);
        mode = get_mode();
    }
}


////////////////////////////////////////////////////////////////////////////////
// b2:0 -- state of mode jumper; 0 if link absent, 1 if link fitted
uint8_t get_mode() {
    uint32_t allgpio;
    uint8_t mode;

    allgpio = gpio_get_all();
    mode = ((allgpio >> P_MODE2   -2) & (1<<2))
        |  ((allgpio >> P_MODE1   -1) & (1<<1))
        |  ((allgpio >> P_MODE0   -0) & (1<<0));
    return mode;
}


////////////////////////////////////////////////////////////////////////////////
// Code from lurk101, posted to https://forums.raspberrypi.com/viewtopic.php?t=329630
// Blocking software-polled PS/2 get-code routine.
// Same author has a library version that uses PIO, here:
// https://github.com/lurk101/pico-ps2kbd
// ..seems to work fine!
static uint8_t ps2_getc(void) {
    uint16_t r = 0;
    for (int i = 0; i < 11; i++) {
        while (gpio_get(P_PS2_CLK))
            ;
        r = (r >> 1) | (gpio_get(P_PS2_DAT) ? 0x8000 : 0);
        while (!gpio_get(P_PS2_CLK))
            ;
    }
    return r >> 6;
}


////////////////////////////////////////////////////////////////////////////////
// Come here and never return
// Implement PS/2 to NASCOM keyboard control
// - set all pin directions
// - set up core 1 to handle reading of the keyboard map via (input) pin changes
// - sit in an endless loop receiving PS/2 keyboard codes, processing them
//   and updating the keyboard map
// - special decode of PRINTSCREEN as RESET and SCROLL LOCK as NMI through the
//   dedicated signals on the keyboard connector
//
// - should work on NASCOM 1 and NASCOM 2 TODO test
//   TODO are any N1 mods. required in order to receive the extra codes?
//   TODO take some scope photos of the NASCOM scan, annotate timings and add
//   to my keyboard document
static void mode_nascom_kbd(void) {

    uint8_t tabcode;
    uint8_t ps2code;
    uint8_t ps2codeD1;
    uint8_t ps2codeD2;
    uint8_t kbdDrive;
    uint8_t kbdMask;

    // Set up pin directions based on mode
    gpio_set_dir_out_masked(1<<P_KBD_NNMI |
                            1<<P_KBD_NRST |
                            1<<P_KBD_D6 |
                            1<<P_KBD_D5 |
                            1<<P_KBD_D4 |
                            1<<P_KBD_D3 |
                            1<<P_KBD_D2 |
                            1<<P_KBD_D1 |
                            1<<P_KBD_D0);

    gpio_set_dir_in_masked(1<<P_KBD_CLK |
                           1<<P_KBD_RST);

    // Set all keyboard outputs to 1: scan lines and NMI/Reset
    gpio_put_masked(1<<P_KBD_D6 | // Mask of bits
                    1<<P_KBD_D5 |
                    1<<P_KBD_D4 |
                    1<<P_KBD_D3 |
                    1<<P_KBD_D2 |
                    1<<P_KBD_D1 |
                    1<<P_KBD_D0 |
                    1<<P_KBD_NNMI |
                    1<<P_KBD_NRST
                    ,
                    1<<P_KBD_D6 | // Values
                    1<<P_KBD_D5 |
                    1<<P_KBD_D4 |
                    1<<P_KBD_D3 |
                    1<<P_KBD_D2 |
                    1<<P_KBD_D1 |
                    1<<P_KBD_D0 |
                    1<<P_KBD_NNMI |
                    1<<P_KBD_NRST);

    // Initialise the keyboard map and scan counter. An empty map is all-1: a pressed key generates a 0
    for (int i=0;i<8;i++) {
        nkmap[i] = 0xff;
    }

    nscan_drive = 0;

    ps2codeD1 = 0;
    ps2codeD2 = 0;

    // Start core1, used to respond (in an ISR) to scans from the NASCOM
    multicore_launch_core1(nascom_kbd_core1);

    // 20ms down, 200ms release seems OK
    // 20ms down, 20ms release seems OK
    // 10ms down, 10ms release seems OK
    // 5ms down, 10ms release seems OK
    // 3ms down, 10ms release -- some keys seen, some keys missed.

    // Unused keys:
    // ESC
    // Pipe
    // Caps-lock
    // Rt-Menu
    // Rt-WIN - but decoded like another right-arrow
    // INSERT
    // HOME
    // PAGEUP
    // DELETE
    // END
    // PAGEDN
    // INSERT
    // Print Screen
    // Pause Break - decoded as 00 08 - like a control key

    // BUG: I did something funky with the F1-F12 keys, but I could decode them more simply here by
    //      making use of the 2 spare bits in the lookup table - but what to do with them?

    for (;;) {
        ps2code = ps2_getc();

        if ( ((ps2codeD2 == 0xE0) && (ps2codeD1 == 0xF0)) || ((ps2codeD1 == 0xE0) && (ps2code != 0xF0)) ) {
            // E0 F0 xx - RELEASE key so SET bit in nkmap. Only decode a sub-set of the codes that could occur here. Mask is 0 is key is not found
            // or
            // E0 xx - PRESS key so CLEAR bit in nkmap

            if ((ps2code == 0x1f) || (ps2code == 0x6b)) {
                // left-arrow: l-WIN or cursor left key, code 2,6
                kbdDrive = 2;
                kbdMask = 1<<6;
            }
            else if ((ps2code == 0x11) || (ps2code == 0x72)) {
                // down-arrow: r-ALT or cursor down key, code 3,6
                kbdDrive = 3;
                kbdMask = 1<<6;
            }
            else if ((ps2code == 0x14) || (ps2code == 0x27) || (ps2code == 0x74)) {
                // right-arrow: r-CTRL or cursor right key, code 4,6
                // expect 0x14 = r-CTRL but it seems to be r-WIN. 0x27 works on my keyboard, so decode both
                kbdDrive = 4;
                kbdMask = 1<<6;
            }
            else if (ps2code == 0x75) {
                // up-arrow: cursor up key, code 1,6
                // (alternative is l-ALT, pulled directly from look-up table)
                kbdDrive = 1;
                kbdMask = 1<<6;
            }
            else if (ps2code == 0x4a) {
                // KP/ used as another B on numeric pad
                kbdDrive = 1;
                kbdMask = 1<<1;
            }
            else if (ps2code == 0x5a) {
                // KPENTER used as another CR key on numeric pad
                kbdDrive = 0;
                kbdMask = 1<<1;
            }
            else {
                // leave map unchanged
                kbdDrive = 0;
                kbdMask = 0;
            }

            if ( ((ps2codeD2 == 0xE0) && (ps2codeD1 == 0xF0)) ) {
                // RELEASE key so SET bit
                nkmap[kbdDrive] = nkmap[kbdDrive] | kbdMask;
            }
            else {
                // PRESS key so CLEAR bit
                nkmap[kbdDrive] = nkmap[kbdDrive] & ~kbdMask;

                // Special: decode (press of) PRINTSCREEN. This doesn't affect the kbdmask but asserts NASCOM reset
                // (ignore the E0 12 prefix; decoding this causes problems because this sequence is also introduced
                // modally for some keys after pressing NUMLCK
                if (ps2code == 0x7c) {
                    gpio_put(P_KBD_NRST, 0);
                    sleep_ms(500); // RC network on nascom means that shorter pulses are lost
                    // TODO should not be necessary
                    for (int i=0;i<8;i++) {
                        nkmap[i] = 0xff;
                    }
                    gpio_put(P_KBD_NRST, 1);
                }
            }
        }
        else  if (ps2code < 132)  {
            // xx - key code with no prefix, and can be found in lookup table
            tabcode = nasKbdArray[ps2code];

            if (ps2code == 0x7e) {
                if (ps2codeD1 != 0xF0) {
                    // Special: decode (press of) SCROLL LOCK. This doesn't affect the kbdmask but asserts NASCOM NMI
                    // Ignore release of SCROLL LOCK.
                    gpio_put(P_KBD_NNMI, 0);
                    sleep_ms(500); // RC network on nascom means that shorter pulses are lost
                    gpio_put(P_KBD_NNMI, 1);
                }
            }
            else if (tabcode != t(7,7)) {
                kbdDrive = tabcode >> 3;
                kbdMask = 1 << (tabcode & 7);

                if (ps2codeD1 == 0xF0) {
                    // RELEASE key so SET bit
                    nkmap[kbdDrive] = nkmap[kbdDrive] | kbdMask;
                }
                else {
                    // PRESS key so CLEAR bit
                    nkmap[kbdDrive] = nkmap[kbdDrive] & ~kbdMask;
                }
            }
        }
        __dmb(); // make sure nkmap changes are flushed to memory
        ps2codeD2 = ps2codeD1;
        ps2codeD1 = ps2code;
    }
}


////////////////////////////////////////////////////////////////////////////////////////
// Code for driving NASCOM side of NASCOM keyboard: track the reset/clock inputs from
// the NASCOM software scanning and update the "drive" outputs in accordance with the
// keyboard map
//
// Plan "A" was to do all of the work in an ISR. However, given that I can dedicate
// this core to handling the polling signals from the NASCOM, plan "B" is make it
// very simple and just do the whole thing in a software-polled loop.
//
// https://forums.raspberrypi.com/viewtopic.php?t=306132
// suggests a latency of ~200ns is achievable using an ISR and
// a latency of ~71ns is achievable using polling.
static void nascom_kbd_core1(void) {
    uint32_t allgpio;
    uint32_t allgpio_prev;

    allgpio = gpio_get_all();
    for (;;) {
        allgpio_prev = allgpio;
        allgpio = gpio_get_all();

        // Both signals idle low and blip high for ~4.5us to perform the reset/increment.
        // When scanned by NAS-SYS, RST and CLK are never high simultaneously
        // when scanned by BASIC (shift-enter for pause/break) CLK goes high
        // while RST is high.

        if ((allgpio & 1<<P_KBD_CLK) && !(allgpio_prev & 1<<P_KBD_CLK)) {
            // CLK went 0->1 (edge); increment count
            // NASCOM does 8 clocks after reset so it relies on the counter wrapping
            nscan_drive = (nscan_drive + 1) %8;
        }
        if ((allgpio & 1<<P_KBD_RST)) {
            // RST is 1 (level); reset count -> overrides CLK if it's also high
            nscan_drive = 0;
        }

        // This RELIES on the pins being contiguous and P_KBD_D0 being GPIO 0. Otherwise,
        // the nkmap bits need to be shifted
        __dmb(); // make sure nkmap changes are flushed to memory

        gpio_put_masked(1<<P_KBD_D6 |
                        1<<P_KBD_D5 |
                        1<<P_KBD_D4 |
                        1<<P_KBD_D3 |
                        1<<P_KBD_D2 |
                        1<<P_KBD_D1 |
                        1<<P_KBD_D0,
                        nkmap[nscan_drive]);
    }
}


////////////////////////////////////////////////////////////////////////////////
// Come here and never return
// Implement PS/2 to ASCII keyboard control: either to parallel (with +ve or
// -ve strobe) or serial.
// - set all pin directions
// - sit in an endless loop receiving PS/2 keyboard codes, processing them
//   and converting ASCII codes
// - send code to pins (parallel) or to a UART mapped to the appropriate pins
//
//   TODO there are 2 Gemini keyboard versions. AVC can support an extended
//   keyboard that generates escape code prefixes for extra characters. Allow
//   this code to do either.. need to borrow from John and document its
//   behaviour.
//
static void mode_ascii_kbd(uint8_t parallel, uint8_t strobe_positive) {


}


/////////////////////////////////////////////////////////////////////////////////////////
// Just report codes from PS/2 keyboard
static void mode_ps2_codes() {
    for (;;) {
        printf("%02x ", ps2_getc());
    }
}


/*
/////////////////////////////////////////////////////////////////////////////////////////
// TODO halt, drive, reset_req, nmi_req are not currently implemented.
typedef struct KBD {

    unsigned char   matrix[8];     // maintain state of the hardware keyboard matrix
    unsigned char   halt;          // halt LED
    unsigned char   drive;         // drive LED
    unsigned char   nasmap;        // nasmap LED 0: PC keyboard mapping, 1: NASCOM keyboard mapping
    unsigned char   reset_req;     // user has pressed RESET button on keyboard
    unsigned char   nmi_req;       // user has pressed NMI button on keyboard
    unsigned char   flags;
    unsigned int    skip_count;    // for ignoring sysreq key sequence
} KBD;

// bits in kbd.flags
#define FLAG_RELEASE (1)
#define FLAG_E0PREFIX (2)
//
#define FLAG_NASMAP (4)
#define FLAG_SHIFT (8)
#define FLAG_SKIP (16)
//
#define FLAG_LSHIFT (32)
#define FLAG_RSHIFT (64)

KBD kbd;





// TODO can use sizeof
#define KeymapSize 132


const unsigned char Keymap[] PROGMEM =
// Without shift
"             \011`      q1   zsaw2  cxde43   vftr5  nbhgy6   mju78  ,kio09"
"  ./l;p-   \' [=    \015] \\        \010  1 47   0.2568\033  +3-*9      "
// With shift
"             \011~      Q!   ZSAW@  CXDE$#   VFTR%  NBHGY^   MJU&*  <KIO)("
"  >?L:P_   \" {+    \015} |        \010  1 47   0.2568\033  +3-*9       ";


// Interrupt service routine. Triggered on PS2 clock: accumulate the new
// data bit and either return immediately (ScanCode in progress) or put
// the ScanCode into a buffer and reset state ready for the next ScanCode
ISR(INT1_vect) {
    static int ScanCode = 0, ScanBit = 1;
    if (PIND & 1<<PIND4) ScanCode = ScanCode | ScanBit;
    ScanBit = ScanBit << 1;
    if (ScanBit != 0x800) return; // ScanCode in progress

    // Got a complete ScanCode; process it
    if ((ScanCode & 0x401) != 0x400) return; // Invalid start/stop bit
    int s = (ScanCode & 0x1FE) >> 1;


    // put it into the buffer
    uint8_t i = head + 1;
    if (i >= BUFFER_SIZE) i = 0;
    if (i != tail) {
        buffer[i] = s;
        head = i;
    }

    // get ready for next
    ScanCode = 0, ScanBit = 1;
}

void setup() {
    ////////////////////////////////////////////////////////////////////////////
    // clear PS/2 receive buffer
    head = 0;
    tail = 0;

    ////////////////////////////////////////////////////////////////////////////
    // initialise state
    // all keys released
    for (int i=0; i<8; i++) {
        kbd.matrix[i] = 0xff;
    }
    // all LEDs off
    kbd.halt = 0;
    kbd.drive = 0;
    kbd.nasmap = 0;
    // no key requests
    kbd.reset_req = 0;
    kbd.nmi_req = 0;
    // clear flags
    kbd.flags = 0;
    // skip_count is initialised when needed.

    ////////////////////////////////////////////////////////////////////////////
    EICRA = 2<<ISC10;                       // Falling edge
    PORTD = PORTD | 1<<PORTD4 | 1<<PORTD3;  // Enable pullups
    EIMSK = EIMSK | 1<<INT1;                // Enable interrupt
    Serial.begin(115200);
    Serial.println("Starting..");

    ////////////////////////////////////////////////////////////////////////////
    uint8_t code;
    while (1) {
        code = get_scan_code();
        if (code) {
            // scan codes (8-bit hex)
            //
            //                       PRESS                         RELEASE
            // easy stuff            00                            F0 00
            //                       ..
            //                       86                            F0 86
            //
            // simple E0 prefix      E0 ??                         E0 F0 ??
            //
            // applies to these:
            // l-WINDOWS, r-ALT r-WINDOWS MENU r-CTRL INSERT HOME PgUP DELETE
            // END PgDOWN UP-ARR LEFT-ARR DOWN-ARR RIGH-ARR KP/ KPENTER
            //
            // final fiddly ones:
            //
            // print screen          E0 12 E0 7C                   E0 F0 7C E0 F0 12
            // pause break           E1 14 77 E1 F0 14 F0 77       (none) (no auto-repeat)
            //
            // print screen just looks like 2 keys pressed and released in
            // succession; easy to ignore like any other ignored E0 ?? pair.

            // these codes get gobbled, just setting flags for later use
            if (kbd.flags & FLAG_SKIP) {
                kbd.skip_count--;
                if (kbd.skip_count == 0) {
                    kbd.flags ^= FLAG_SKIP;
                }
            }
            else if (code == 0xf0) {
                kbd.flags |= FLAG_RELEASE;
            }
            else if (code == 0xe0) {
                kbd.flags |= FLAG_E0PREFIX;
            }
            else if (code == 0x05) { // F1 key
                // Use F1 as a way to toggle the lookup
                // 0 (initial setting) use nascom row/column from both lower
                //   and upper case map (makes keycaps behave as marked)
                // 1 (toggled)         always use nascom row/column from lower
                //   case map (keep NASCOM keyboard association between
                //   non-shifted and shifted keys)
                if (kbd.flags & FLAG_RELEASE) {
                    kbd.flags ^= FLAG_RELEASE;
                }
                else {
                    kbd.flags ^= FLAG_NASMAP;
                    kbd.nasmap ^= 1;
                    kbd_leds();
                }
            }
            else if (code == 0xE1) { // Pause Break key (8-byte sequence)
                kbd.flags |= FLAG_SKIP;
                kbd.skip_count = 7; // skip next 7 codes
            }
            else {
                // track shift keys to decode which look-up table to use
                if (code == 0x12) { // Left shift key
                    if (kbd.flags & FLAG_RELEASE) {
                        kbd.flags ^= FLAG_LSHIFT;
                    }
                    else {
                        kbd.flags |= FLAG_LSHIFT;
                    }
                }
                else if (code == 0x59) { // Right shift key
                    if (kbd.flags & FLAG_RELEASE) {
                        kbd.flags ^= FLAG_RSHIFT;
                    }
                    else {
                        kbd.flags |= FLAG_RSHIFT;
                    }
                }

                // handle what we have now in the context of the flags

                // For codes with 0xE0 prefix, either ignore or remap to unused places in the 00..0x8e range
                if (kbd.flags & FLAG_E0PREFIX) {
                    kbd.flags ^= FLAG_E0PREFIX;
                    // make the codes with E0 prefix into unused places in the lookup table
                    if ((code == 0x6b) || (code == 0x1f)) {
                        code = 0x7f; // left arrow or l-WIN
                    }
                    else if ((code == 0x74) || (code == 0x2F) || (code == 0x27)) {
                        code = 0x80; // right arrow or MENU or r-CTRL
                    }
                    else if (code == 0x75) {
                        code = 0x81; // up arrow
                    }
                    else if ((code == 0x72) || (code == 0x11)) {
                        code = 0x82; // down arrow or r-ALT
                    }
                    else {
                        // The following keys are ignored not currently handled:
                        // Print Screen/SysRq      E0 12
                        // Numeric keypad /        E0 4A
                        // Numeric keypad ENTER    E0 5A
                        // Insert                  E0 70
                        // Home                    E0 6C
                        // Page up                 E0 7D
                        // Delete                  E0 71
                        // End                     E0 69
                        // Page down               E0 7A
                        // Right-hand windows key  E0 14
                        
                        //Serial.print("ERROR no fixup for E0 prefix scancode = 0x");
                        //Serial.println(code, HEX);

                        // TODO work out what to do with these. In order to ignore them, can just abandon this keycode:
                        continue;
                    }
                }


                // TODO trap F2 and F3 for RESET and NMI respectively. Maybe reset should be press to pause, press again to continue or
                // some other key to reset.

                int matrix_offset;
                int matrix_index;
                int matrix_bit;
                if (!(kbd.flags & FLAG_NASMAP) && ((kbd.flags & FLAG_LSHIFT) || (kbd.flags & FLAG_RSHIFT))) {
                    matrix_offset = 3; // use shift map
                }
                else {
                    matrix_offset = 1; // use unshifted map
                }

                if (code < 0x84) {
                    Serial.print(kbd.flags & FLAG_RELEASE);
                    
                    Serial.print(" Scancode=0x");
                    Serial.print(code, HEX);
                    
                    Serial.print(" lc=0x");
                    Serial.print(pgm_read_byte(&ktab[code*4+0]), HEX);
                    Serial.write(0x20);
                    Serial.write(pgm_read_byte(&ktab[code*4+0]));
                    
                    Serial.print(" uc=0x");
                    Serial.print(pgm_read_byte(&ktab[code*4+2]), HEX);
                    Serial.write(0x20);
                    Serial.write(pgm_read_byte(&ktab[code*4+2]));
                                        
                    Serial.print(" map=0x");
                    Serial.println(pgm_read_byte(&ktab[code*4+matrix_offset]), HEX);
         
                    matrix_index = pgm_read_byte(&ktab[code*4 + matrix_offset]) >> 4;
                    matrix_bit = pgm_read_byte(&ktab[code*4 + matrix_offset]) & 0xf;
                    if (kbd.flags & FLAG_RELEASE) {
                        // set bit
                        kbd.matrix[matrix_index] |= 1 << matrix_bit;
                    }
                    else {
                        // clear bit
                        kbd.matrix[matrix_index] &= ~(1 << matrix_bit);
                    }
                }
                else {
                    Serial.print(kbd.flags & FLAG_RELEASE);
                    Serial.print(" Scancode = 0x");
                    Serial.println(code, HEX);
                }
                kbd.flags &= ~FLAG_RELEASE;
            }
        }
    }
}


*/