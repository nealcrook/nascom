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
// Other references:
//
// ATMEL guru Nick Gammon on interrupts:
// https://arduino.stackexchange.com/questions/1784/how-many-interrupt-pins-can-an-uno-handle
// http://www.gammon.com.au/interrupts
//


// TODO
// DONE 1. Get it working as-is
// 2. Modify to greate queue, change loop() to poll for characters and display them
// 3. Implement state machine from ESP32 code
// 4. Add keymap generation code
// 5. Add ISR for NASCOM .. are there enough interrupts? Need 1 for PS/2, 1 for NASCOM reset, one for NASCOM clk
// -> yes there are; there are 2 external interrupts but all pins can generate pin-change interrupts which are as fast.



/* PS/2 Keyboard Interface v2

   David Johnson-Davies - www.technoblogy.com - 10th September 2016
   Arduino Uno or ATmega328
   
   CC BY 4.0
   Licensed under a Creative Commons Attribution 4.0 International license: 
   http://creativecommons.org/licenses/by/4.0/
*/

#define KeymapSize 132

const int DataPin = 4;
const int IRQpin =  3; // was 2 in original for INT0, now using 3 => INT1

const char Keymap[] PROGMEM = 
// Without shift
"             \011`      q1   zsaw2  cxde43   vftr5  nbhgy6   mju78  ,kio09"
"  ./l;p-   \' [=    \015] \\        \010  1 47   0.2568\033  +3-*9      "
// With shift
"             \011~      Q!   ZSAW@  CXDE$#   VFTR%  NBHGY^   MJU&*  <KIO)("
"  >?L:P_   \" {+    \015} |        \010  1 47   0.2568\033  +3-*9       ";

ISR(INT1_vect) {
  static int ScanCode = 0, ScanBit = 1, Break = 0, Modifier = 0, Shift = 0;
  if (PIND & 1<<PIND4) ScanCode = ScanCode | ScanBit;
  ScanBit = ScanBit << 1;
  if (ScanBit != 0x800) return;
  // Process scan code
  if ((ScanCode & 0x401) != 0x400) return; // Invalid start/stop bit
  int s = (ScanCode & 0x1FE) >> 1;
  ScanCode = 0, ScanBit = 1;
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
}

void setup() {
  EICRA = 2<<ISC10;                       // Falling edge
  PORTD = PORTD | 1<<PORTD4 | 1<<PORTD3;  // Enable pullups
  EIMSK = EIMSK | 1<<INT1;                // Enable interrupt
  Serial.begin(115200);
  Serial.print("Starting..");
}

void loop() {
}

