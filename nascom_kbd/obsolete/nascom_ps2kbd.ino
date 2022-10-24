// nascom_ps2kbd                 -*- c -*-
// https://github.com/nealcrook/nascom
//
// Interface a PS/2 keyboard to the NASCOM 2 scanned keyboard interface
// using an ARDUINO Uno/Nano (ATMEGA328).
//
////////////////////////////////////////////////////////////////////////////////////////////////
//
// Initial code for PS/2 interface is from:
//
// David Johnson-Davies - www.technoblogy.com - 10th September 2016
//    Arduino Uno or ATmega328
//
// CC BY 4.0
// Licensed under a Creative Commons Attribution 4.0 International license:
//  http://creativecommons.org/licenses/by/4.0/
//
//
// Interrupt-safe buffer handling from the PS2Keyboard library
//
// Other references:
//
// ATMEL guru Nick Gammon on interrupts:
// https://arduino.stackexchange.com/questions/1784/how-many-interrupt-pins-can-an-uno-handle
// http://www.gammon.com.au/interrupts
//
// Everything to do with PS/2:
// http://www-ug.eecg.toronto.edu/msl/nios_devices/datasheets/PS2%20Keyboard%20Protocol.htm


// TODO
// DONE 1. Get it working as-is
// DONE 2. Modify to greate queue, change loop() to poll for scan codes and display them
// 3. Implement scan-code tracking state machine from ESP32 code
// 4. Add keymap generation code
// 5. Add ISR for NASCOM .. are there enough interrupts? Need 1 for PS/2, 1 for NASCOM reset, one for NASCOM clk
// -> yes there are; there are 2 external interrupts but all pins can generate pin-change interrupts which are as fast.
// 6. unify data types
// 7. benchmark


// PS/2 receive buffer
#define BUFFER_SIZE 45
static volatile uint8_t buffer[BUFFER_SIZE];
static volatile uint8_t head, tail;

/////////////////////////////////////////////////////////////////////////////////////////
// TODO halt, drive, reset_req, nmi_req are not currently implemented.
typedef struct KBD {

    unsigned char   matrix[8];     /* maintain state of the hardware keyboard matrix */
    unsigned char   halt;          /* halt LED */
    unsigned char   drive;         /* drive LED */
    unsigned char   nasmap;        /* nasmap LED 0: PC keyboard mapping, 1: NASCOM keyboard mapping*/
    unsigned char   reset_req;     /* user has pressed RESET button on keyboard */
    unsigned char   nmi_req;       /* user has pressed NMI button on keyboard */
    unsigned char   flags;
    unsigned int    skip_count;    /* for ignoring sysreq key sequence */
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

// Translation table: Keyboard scan code -> ASCII code or NASCOM matrix position
// Indexed by scan codes in the range 0x00..0x83. There are 4 bytes per entry, so index with scancode*4
// 4 bytes are: ASCII code unshifted, NASCOM matrix position unshifted, ASCII code shifted, NASCOM matrix code shifted
// (the ASCII code is redundant for this application but I might use it for something else)
// ASCII code of 0 means "non-existent scan code"
// NASCOM matrix code 0xib -- i is index; corresponds to the column select on the schematic. b is the bit position,
// corresponding to the A/B/C/D/E/F/G on the schematic. Code of 0xff means "not on NASCOM keyboard"
// i can be 0..7 (4 bits)
// b can be 0..6 (3 bits)
// ** USE MSB to indicate whether shift key is set.
//
// The reason for 2 NASCOM keymap positions: On PC keyboard, shift-8 is "*". On a NASCOM keyboard, shift-8 is "("
// 2 keyboard translations are supported:
// * PC layout: the state of the PC shift keys is tracked. When "8" is pressed, depending on the state of shift, the unshifted
//   map or the shifted map is used. Unshifted map sets the matrix for "8", shifted map sets the matrix for ":" (shift-: is "*" on NASCOM keyboard)
// * NASCOM layout: the state of the PC shift keys is ignored. When "8" is pressed, the unshifted map is used. Unshifted map sets the matrix for "8"
//
// Only a small number of keys are affected by this (some number keys and punctuation/symbols) so most entries
// in the table have the same value for the unshifted and the shifted matrix codes.

// At the moment I am using the shift keys to choose between 2 entries in this table, AND I am using the table to find matrix mappings for
// the shift key itself (note that, on the NASCOM keyboard, you can't distinguish left and right shift keys)

// That  approacj doesn't fully solve the problem.. 
// consider the PC key =, which is shifted to give +
// the equivalent NASCOM key is - which is shifted to give =
//
// because the = switches from unshifted on the PC keyboard to shifted on the NASCOM keyboard, we cannot simply treat the
// shift key as another key to synthesise in the matrix.
// Instead, each matrix code needs to include information about whether the shift bit should be set in the matrix.
// if we run with PC keyboard mappings:
// "=" will generate "shift -" in the matrix
// "shift =" will generate "+" in the matrix (+ is not a shifted key on the NASCOM keyboard)
//
// if we run with NASCOM keyboard mappings:
//
// TO BE CONTINUED





//
// Special keys:
// PC TAB key maps to NASCOM GRA. l-SHIFT, r-SHIFT, l-CTRL map to the equivalent NASCOM keys.
// PC l-WIN, l-ALT r-ALT MENU to NASCOM cursor keys LEFT, UP, RIGHT, DOWN (to match NASCOM layout) as well as the PC's marked cursor keys
// (l-ALT done in this table, others done by remapping E0-prefix codes in the code later on).
//
// TODO maybe map TAB to NASCOM tab code, and use something else for GRA (Caps lock?)
//
const unsigned char ktab[] PROGMEM = {
    //                    F9                                          F5                    F3                    F1                    F2                    F12
    0x00,0xff,0x00,0xff,  0x19,0xff,0x19,0xff,  0x00,0xff,0x00,0xff,  0x15,0xff,0x15,0xff,  0x13,0xff,0x13,0xff,  0x11,0xff,0x11,0xff,  0x12,0xff,0x12,0xff,  0x1c,0xff,0x1c,0xff, //00-07
    //                    F10                   F8                    F6                    F4                    TAB *GRA*
    0x00,0xff,0x00,0xff,  0x1a,0xff,0x1a,0xff,  0x18,0xff,0x18,0xff,  0x16,0xff,0x16,0xff,  0x14,0xff,0x14,0xff,  0x09,0x56,0x09,0x56,  '`' ,0xff,0x00,0xff,  0x00,0xff,0x00,0xff, //08-0f

    //                    l-ALT   *UP-ARR*      l-SHIFT                                     l-CTRL
    0x00,0xff,0x00,0xff,  '^' ,0x16,'^' ,0x16,  0x00,0x04,0x00,0x04,  0x00,0xff,0x00,0xff,  0x00,0x03,0x00,0x03,  'q' ,0x54,'Q' ,0x54,  '1' ,0x64,'!' ,0x64,  0x00,0xff,0x00,0xff, //10-17
    //
    0x00,0xff,0x00,0xff,  0x00,0xff,0xff,0xff,  'z' ,0x24,'Z' ,0x24,  's' ,0x34,'S' ,0x34,  'a' ,0x44,'A' ,0x44,  'w' ,0x43,'W' ,0x43,  '2' ,0x63,'"' ,0x63,  0x00,0xff,0x00,0xff, //18-1f

    0x00,0xff,0x00,0xff,  'c' ,0x73,'C' ,0x73,  'x' ,0x14,'X' ,0x14,  'd' ,0x23,'D' ,0x23,  'e' ,0x33,'E' ,0x33,  '4' ,0x72,'$' ,0x72,  '3' ,0x53,0x23,0x53,  0x00,0xff,0x00,0xff, //20-27
    0x00,0xff,0x00,0xff,  ' ' ,0x74,' ' ,0x74,  'v' ,0x71,'V' ,0x71,  'f' ,0x13,'F' ,0x13,  't' ,0x15,'T' ,0x15,  'r' ,0x75,'R' ,0x75,  '5' ,0x12,'%' ,0x12,  0x00,0xff,0x00,0xff, //28-2f

    0x00,0xff,0x00,0xff,  'n' ,0x21,'N' ,0x21,  'b' ,0x11,'B' ,0x11,  'h' ,0x10,'H' ,0x10,  'g' ,0x70,'G' ,0x70,  'y' ,0x25,'Y' ,0x25,  '6' ,0x22,'^' ,0x62,  0x00,0xff,0x00,0xff, //30-37
    0x00,0xff,0x00,0xff,  0x00,0x00,0x00,0x00,  'm' ,0x31,'M' ,0x31,  'j' ,0x20,'J' ,0x20,  'u' ,0x35,'U' ,0x35,  '7' ,0x32,'&' ,0x22,  '8' ,0x42,'*' ,0x60,  0x00,0xff,0x00,0xff, //38-3f

    0x00,0xff,0x00,0xff,  ',' ,0x41,'<' ,0x41,  'k' ,0x30,'K' ,0x30,  'i' ,0x45,'I' ,0x45,  'o' ,0x55,'O' ,0x55,  '0' ,0x62,')' ,0x52,  '9' ,0x52,'(' ,0x42,  0x00,0xff,0x00,0xff, //40-47
    0x00,0xff,0x00,0xff,  '.' ,0x51,'>' ,0x51,  '/' ,0x61,'?' ,0x61,  'l' ,0x40,'L' ,0x40,  ';' ,0x50,':' ,0x60,  'p' ,0x65,'P' ,0x65,  '-' ,0x02,'_' ,0x76,  0x00,0xff,0x00,0xff, //48-4f

    //                                          '
    0x00,0xff,0x00,0xff,  0x00,0xff,0x00,0xff,  0x27,0x05,'@' ,0x05,  0x00,0xff,0x00,0xff,  '[' ,0x66,'{' ,0x66,  '=' ,0x02,'+' ,0x50,  0x00,0xff,0x00,0xff,  0x00,0xff,0x00,0xff, //50-57
    // CAPLOCK            r-SHIFT               ENTER                                                             *CH* *LF*
    0x00,0xff,0x00,0xff,  0x00,0x04,0x00,0x04,  0x0d,0x01,0x00,0x01,  ']' ,0x76,'}' ,0x76,  0x00,0xff,0x00,0xff,  '#' ,0x06,'~' ,0x06,  0x00,0xff,0x00,0xff,  0x00,0xff,0x00,0xff, //58-5f

    //                                                                                                                                  BSPC
    0x00,0xff,0x00,0xff,  '\\',0x02,'|' ,0x02,  0x00,0xff,0x00,0xff,  0x00,0xff,0x00,0xff,  0x00,0xff,0x00,0xff,  0x00,0xff,0x00,0xff,  0x08,0x00,0x08,0x00,  0x00,0xff,0x00,0xff, //60-67
    //                    KP1                                         KP4                   KP7
    0x00,0xff,0x00,0xff,  0x31,0x00,0x31,0x00,  0x00,0xff,0x00,0xff,  0x34,0x00,0x34,0x00,  0x37,0x00,0x37,0x00,  0x00,0xff,0x00,0xff,  0x00,0xff,0x00,0xff,  0x00,0xff,0x00,0xff, //68-6f

    // KP0                KP.                   KP2                   KP5                   KP6                   KP8                   ESC                   NUMLCK
    '0' ,0xff,'0' ,0xff,  '.' ,0xff,'.' ,0xff,  '2' ,0xff,'2' ,0xff,  '5' ,0xff,'5' ,0xff,  '6' ,0xff,'6' ,0xff,  '8' ,0xff,'8' ,0xff,  0x1b,0x00,0x1b,0x00,  0x00,0x00,0x00,0x00, //70-77
    // F11                KP+                   KP3                   KP-                   KP*                   KP9                   SCRLCK                LEFT-ARR
    0x1b,0xff,0x1b,0xff,  '+' ,0xff,'+' ,0xff,  '3' ,0xff,'3' ,0xff,  '-' ,0xff,'-' ,0xff,  '*' ,0xff,'*' ,0xff,  '9' ,0xff,'9' ,0xff,  0x00,0x00,0x00,0x00,  '<', 0x26,'<' ,0x26, //78-7f

    // RIGHT-ARR          UP-ARR                DOWN-ARR              F7
    '>' ,0x46,'>' ,0x46,  '^' ,0x16,'^' ,0x16,  'v' ,0x36,'v' ,0x36,  0x17,0xff,0x17,0xff                                                                                          //80-83
};




void kbd_leds(void) {
    Serial.print("TODO change kbd LEDs to show HALT=");
    Serial.print(kbd.halt);
    Serial.print(" DRIVE=");
    Serial.print(kbd.drive);
    Serial.print(" NASMAP=");
    Serial.println(kbd.nasmap);
}


uint8_t get_scan_code(void) {
    uint8_t c, i;

    i = tail;
    if (i == head) return 0;
    i++;
    if (i >= BUFFER_SIZE) i = 0;
    c = buffer[i];
    tail = i;
    return c;
}

/*

, Break = 0, Modifier = 0, Shift = 0


  if (s == 0xAA) return;                   // BAT completion code
  //
  if (s == 0xF0) { Break = 1; return; }
  if (s == 0xE0) { Modifier = 1; return; }
  if (Break) {
    if ((s == 0x12) || (s == 0x59)) Shift = 0;
    Break = 0; Modifier = 0; return;
  }
  if ((s == 0x12) || (s == 0x59)) Shift = 1;
  if (Modifier) return;
  char c = pgm_read_byte(&Keymap[s + KeymapSize*Shift]);
  if (c == 32 && s != 0x29) return;
  Serial.print(c);
  return;
*/



#define KeymapSize 132

// Connections to PS/2 keyboard. Changing these is NOT enough to remap the pins:
// the only alternative pin for IRQPIN is pin 2, which moves the interrupt to
// INT0, but various other changes are also needed.
const int DataPin = 4;
const int IRQpin =  3; // was 2 in original for INT0, now using 3 => INT1

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


// Usually, this is called repeatedly but in this application we finish setup with an endless loop
// so never, ever come here.
void loop() {
}
