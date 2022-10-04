// setup                            -*- c -*-
// https://github.com/nealcrook/nascom
//
// ARDUINO Uno/Nano (ATMEGA328) connected to NASCOM 2 as mass-storage device
//
// The EEPROM contains a blob of data called the "profile record". This
// has to be installed as a one-time operation.
//
// It can be installed using NASconsole. However, to make it easier to get
// started, this utility provides an alternative method for programming it.
//
////////////////////////////////////////////////////////////////////////////////

#define SECTOR_CHUNK (128)
#define PIN_LED A2
#include <EEPROM.h>

// Pin mapping for PIO port A bits[7:0]
#define PIN_XD7 A0
#define PIN_XD6 6
#define PIN_XD5 A5
#define PIN_XD4 A4
#define PIN_XD3 5
#define PIN_XD2 4
#define PIN_XD1 3
#define PIN_XD0 2

// Pin mapping for PIO port B bits[2:0]
// A7 is input-only and can only be sampled through the ADC
#define PIN_YD2 A7
#define PIN_YD1 A1
#define PIN_YD0 A3

// bit set and clear macros
#define cbi(sfr, bit) (_SFR_BYTE(sfr) &= ~_BV(bit))
#define sbi(sfr, bit) (_SFR_BYTE(sfr) |= _BV(bit))


// Prototypes for stuff in this file
void program_profile_record(void);


// Data structures
typedef struct PROFILE {
    char fnam_fext[4][8+1+3+1]; // Null-terminated MSDOS 8.3 names including dot
    uint8_t nsect_per_track;    // sectors per track
    uint8_t ntrack;             // tracks TODO not used.. could be used to detect illegal seek.
    uint8_t first_sect;         // number associated with first sector
    uint8_t sect_chunks;        // number of SECTOR_CHUNKs per sector
} PROFILE;


// Overlay the profile with a char array - makes it simple
// to populate from a byte stream of EEPROM reads.
typedef union UPROFILE {
    struct PROFILE f;
    char b[56];
} UPROFILE;


// The 4 profiles for the default profile record
UPROFILE profile0 {
    {
        {"POLYDOS0.DSK","POLYDOS1.DSK","POLYDOS2.DSK","POLYDOS3.DSK"},
         36, // 18 sectors per track per side
         35, // 35 tracks
         0,  // first sector is sector 0
         2   // 256 bytes per sector
    }
};
UPROFILE profile1 {
    {
        {"NASDOS0.DSK", "NASDOS1.DSK", "NASDOS2.DSK", "NASDOS3.DSK"},
         32, // 16 sectors per track per side
         80, // 80 tracks
         1,  // first sector is sector 1
         2   // 256 bytes per sector
    }
};
UPROFILE profile2 {
    {
        {"CPM0.DSK",    "CPM1.DSK",    "CPM2.DSK",    "CPM3.DSK"},
         10, // 10 sectors per side (NASCOM version of CP/M)
         77, // 77 tracks
         1,  // first sector is sector 1
         4   // 515 bytes per sector
    }
};
UPROFILE profile3 {
    {
        {"SDBOOT0.DSK", "SDBOOT1.DSK", "SDBOOT2.DSK", "SDBOOT3.DSK"},
         36, // 18 sectors per track per side
         35, // 35 tracks
         0,  // first sector is sector 0
         4   // 512 bytes per sector
    }
};




// Everything is done in here.
void setup()   {
    Serial.begin(115200);  // for Debug
    pinMode(PIN_LED, OUTPUT);

    digitalWrite(PIN_LED, 0);
    Serial.println("LED test.. LED is off");
    delay(1000 * 2);
    digitalWrite(PIN_LED, 1);
    Serial.println("LED test.. LED is on");
    delay(1000 * 2);
    digitalWrite(PIN_LED, 0);
    Serial.println("LED test.. LED is off");

    program_profile_record();

    Serial.println("EEPROM programmed: setup complete. Now program code from sd_merged");

    Serial.println("Monitoring PIO signals:");

    // Pins connected to PIO port A
    pinMode(PIN_XD7, INPUT);
    pinMode(PIN_XD6, INPUT);
    pinMode(PIN_XD5, INPUT);
    pinMode(PIN_XD4, INPUT);
    pinMode(PIN_XD3, INPUT);
    pinMode(PIN_XD2, INPUT);
    pinMode(PIN_XD1, INPUT);
    pinMode(PIN_XD0, INPUT);

    // Pins connected to PIO port B
    pinMode(PIN_YD1, INPUT);
    pinMode(PIN_YD0, INPUT);

    // The PIN_YD2 is an input-only analog pin that can only be
    // read by doing an ADC conversion (do NOT call pinMode on it; it can
    // do weird stuff)
    // Speed up ADC conversion by changing prescaler from /128 to /16
    sbi(ADCSRA, ADPS2);
    cbi(ADCSRA, ADPS1);
    cbi(ADCSRA, ADPS0);

    int porta;
    int portb;
    int old_porta = 0xabcd; // impossible previous values
    int old_portb = 0xabcd;
    for (;;) {
        porta =
            (digitalRead(PIN_XD7) << 7) | (digitalRead(PIN_XD6) << 6) | (digitalRead(PIN_XD5) << 5) | (digitalRead(PIN_XD4) << 4) |
            (digitalRead(PIN_XD3) << 3) | (digitalRead(PIN_XD2) << 2) | (digitalRead(PIN_XD1) << 1) | (digitalRead(PIN_XD0));

        portb =
            (digitalRead(PIN_YD1) << 1) | (digitalRead(PIN_YD0));
        if (analogRead(PIN_YD2) > 500) {
            portb = portb | (1 << 2);
        }

        if (porta != old_porta) {
            Serial.print("Port A: ");
            Serial.println(porta,HEX);
            old_porta = porta;
        }
        if (portb != old_portb) {
            Serial.print("Port B: ");
            Serial.println(portb,HEX);
            old_portb = portb;
        }
    }
}


// This routine is invoked repeatedly by the arduino "scheduler"
// but, since setup() is an endless loop, it is never executed
void loop() {
    Serial.println("Never get here");
}


// EEPROM holds a "profile record" consisting of a header followed by
// 4 profiles. Each profile defines 4 virtual disk images and the disk
// geometry. The 5 bytes of header are: N A S x y  where:
// NAS are ASCII values for those letters
// x is the default profile to use at reset (numeric code, not ASCII)
// y is the checksum of the whole record, such that the modulo-256
// sum of the bytes (including the checksum) is 0. The layout of a
// profile is shown below. (Strictly, it is wasteful to null-terminate
// the file names, but it makes the code simpler elsewhere and we have
// enough space.) The profile record can be edited using the console
// interface.
void program_profile_record() {

    Serial.print("Profile record checksum byte: 0x");
    Serial.println(EEPROM.read(4), HEX);

    // profile record is 5 bytes + 4 profile entries of 56 bytes each
    unsigned char csum = 0;
    for (int i=0; i<(5+4*56); i++) {
        csum = csum + EEPROM.read(i);
    }

    Serial.print("Profile record checksum: 0x");
    Serial.println(0xff & csum, HEX);

    Serial.println("Programming profile record..");

    // Header
    EEPROM.update(0, 'N');
    EEPROM.update(1, 'A');
    EEPROM.update(2, 'S');
    EEPROM.update(3, 0);   // default profile
                           // checksum - don't program it yet
    for (int i=0; i<56; i++) {
        EEPROM.update(5+0*56+i, profile0.b[i]);
        EEPROM.update(5+1*56+i, profile1.b[i]);
        EEPROM.update(5+2*56+i, profile2.b[i]);
        EEPROM.update(5+3*56+i, profile3.b[i]);
    }

    // Compute checksum
    csum = 0;
    for (int i=0; i<(5+4*56); i++) {
        // skip checksum location
        if (i != 4) {
            csum = csum + EEPROM.read(i);
        }
    }
    csum = 0xff & ((csum ^ 0xff) + 1);

    // Program it
    EEPROM.update(4, csum);
    Serial.print("Profile record checksum: 0x");
    Serial.println(0xff & csum, HEX);
}
