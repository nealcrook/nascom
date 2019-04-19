// nascom_sdcard2                             -*- c -*-
// https://github.com/nealcrook/nascom
//
// ARDUINO Uno/ATMEGA328 connected to NASCOM 2 as mass-storage device
//
// Connect through UART for the purpose of providing a "virtual cassette
// interface" in which the NAS-SYS R and W commands (and the equivalent from
// within BASIC and other applications) are directed to files on SDcard.
//
// This is "transparent" to the NASCOM but a utility program "serboot" is
// executed on the NASCOM to control what file is used for the read/write.
// serboot is tiny (~103 bytes) and is stored in the Arduino FLASH and
// automatically bootstrap-loaded through the serial port when the Arduino
// is reset.
//
////////////////////////////////////////////////////////////////////////////////
// WIRING:
//
// 1/ connection to uSDcard adaptor (assumes UNO)
//
// uSD                     ARDUINO
// -------------------------------
// 1  GND                  GND
// 2  VCC                  5V
// 3  MISO                 DIG12
// 4  MOSI                 DIG11
// 5  SCK                  DIG13  (also ARDUINO's on-board LED)
// 6  CS                   DIG10
//
// 2/ connection to NASCOM PIO PL4 via 26-way ribbon
//
// Name   Direction   ARDUINO   NASCOM
// -----------------------------------
// T2H    OUT          ANA1     B0 (pin 10)
// H2T    IN           ANA0     B1 (pin 8)
// CMD    IN           ANA4     B2 (pin 6)
// XD7    IN/OUT       DIG9     A7 (pin 24)  *** CHANGE TO ANA5 ***
// XD6    IN/OUT       DIG8     A6 (pin 25)
// XD5    IN/OUT       DIG7     A5 (pin 23)
// XD4    IN/OUT       DIG6     A4 (pin 21)
// XD3    IN/OUT       DIG5     A3 (pin 19)
// XD2    IN/OUT       DIG4     A2 (pin 17)
// XD1    IN/OUT       DIG3     A1 (pin 15)
// XD0    IN/OUT       DIG2     A0 (pin 13)
//
//                     GND      GND (pins 16,18)
//
// 3/ connection to NASCOM serial interface PL2 via 16-way ribbon
//
// Name   Direction   ARDUINO   NASCOM
// -----------------------------------
// TDRIVE IN           ??       DRIVE (pin1)                             ANA3 .. but DIG6 for debug
// NASTXD IN                    20mA OUT (pin 12)                        DIG0 .. but DIG7 for debug
// NASRXD OUT                   20mA IN (pin 9)                          DIG1 .. but DIG8 for debug
// NASSCK OUT                   EXT TX CLK, EXT RX CLK (pin4, pin5)      DIG9
// GND                          GND (pin 11,15)
// 5V                           5V  (pin 2)
//
//
// 4/ connection to LED
//
// Name   Direction   ARDUINO   Notes
// -----------------------------------
// ERROR  OUT         ANA2      To LED. Other end of LED via resistor to GND
//
//
// 5/ power
//
// If you are using the PIO connection you can pick up GND from there. If you
// are only using the serial connection you will need to add a GND connection.
//
// If you are powering the Arduino from the NASCOM you will need to set the
// jumper accordingly and add a connection to +5V.
//
////////////////////////////////////////////////////////////////////////////////
// PROTOCOL FOR SERIAL INTERFACE
//
// When running serboot (serboot.asm)
// E 0C80
// SDcard>
//
// NAS-SYS always polls the serial interface as well as the keyboard, so the
// serial interface can deliver input at any time. By sending R<return>
// followed by the CAS-encoded serboot code, followed by E0C80 <return>
// the NASCOM will load and execute the serboot binary, which provides a
// command-line interface.
//
// Commands from Host (serboot) are between 1 and 39 characters
// followed/terminated in a NUL (0x00). TODO check that's true ie that a 40 char buffer is enough.
// Document this detail in serboot.asm code.
//
// Responses to the Host (by this program) are:
//
// RSDONE        (0x00  - command complete, no other respons.
// RSMOVE hh ll  (0x55) - relocate serboot to specified address
// RSMSG         (0xff) - ASCII text follows. Print until NUL.
//
////////////////////////////////////////////////////////////////////////////////
// FORMATS
//
// Virtual disk is a binary blob stored as an MSDOS file. It uses PolyDos disk
// format, which is documented in the PolyDos System Programmers Guide.
// File name is 1-8 prefix, exactly 2 suffix. When stored in a directory entry
// the name occupies 10 bytes with space characters separating the prefix from
// the suffix if the prefix is <8 characters.
//
// MSDOS files are 1-8 prefix, 1-3 suffix. When accessed using the SD library
// the filenames are in char buffers with the dot included.
//
// At reset or when NEW command is issued, check for SD card. If found, check
// for directory named NASCOM. If found, all file read/write uses that
// directory. Otherwise, use the root directory.
//
////////////////////////////////////////////////////////////////////////////////
// COMMANDS
//
// Refer to the comments or to the help text in messages.h
//
////////////////////////////////////////////////////////////////////////////////



// TODO
// Code PAUSE, NULLS (trivial)
// Define how to store src state and remove wotfile in favour
// - make sure it has a "no file" state - make that abort a R
// Make read cas handle Vdisk as well as Flash
// Make parser extension-sensitive so it can choose binary/cas conversion
// Add routine for serving literal (CAS) files
// - get it working for SD and vdisk
// Add commands TV TS for serving text files - should be easy. Add to Help
// Finally, make read cas handle SD files
// Code auto-increment on file names.
// Code write literal to SD
// Code write literal to Vdisk
// Code write cas routine
// Code write cas to SD
// Code write cas to Vdisk


////////////////////////////////////////////////////////////////////////////////
// Pin assignments (SERIAL)
#define PIN_DRV 6
#define PIN_CLK 9
#define PIN_NTXD 7
#define PIN_NRXD 8


#include <SD.h>
#include <SoftwareSerial.h>

// This is the format of a 20-byte PolyDos directory entry.
typedef struct DIRENT {
    char fnam_fext[10]; // 8 char filename, 2 char extension.
                        // Blanks in unused positions, no "."
    uint8_t fsfl;       // system flags
    uint8_t fufl;       // user flags
    int fsec;           // start sector address
    int flen;           // length of data in 256-byte sectors
    int flda;           // load address on target
    int fexa;           // entry/execution address on target
} DIRENT;

// This represents a char buffer overlayed on a PolyDos directory entry
struct Dirent {
  union {
    struct DIRENT f;
    char b[20];
  };
} Dirent;


// Prototypes in this here file
void cmd_cass(void);
void cmd_cass_rd(void);
void cmd_cass_wr(void);
void open_sdcard(void);

// Stuff provided by parser.ino
extern char to_upper(char c);
extern int legal_char(char c);
extern int cas_gen_flag(char *buffer, int current, int bit_mask);
extern int parse_leading(char **buf);
extern int parse_num(char **buf, int* result, int base);
extern int parse_ai(char **buf);
extern int parse_fname_msdos(char **buf, char * dest);
extern int parse_fname_polydos(char **buf, char * dest);


// Only ever have 1 file open at a time
File handle;


// Boot ROM and some applications/games - stored in FLASH to save resources.
#include "roms.h"
// Message strings - stored in FLASH to save resources.
#include "messages.h"


// 16-bit flags/state.

// 0 = FLASH
// 1 = SD
// 2 = DISK IMAGE
#define F_RD_SRC   (0xc000)
#define F_WR_SRC   (0x3000)

// 0 = store binary file, convert to/from cas
// 1 = store file literally
// 3, 4 reserved
#define F_RD_CONV (0x0c00)
#define F_WR_CONV (0x0300)

// TODO eg for SPEED or for AUTO-INC
#define F_SPARE1  (0x0080)
#define F_SPARE2  (0x0040)
#define F_SPARE3  (0x0020)
#define F_SPARE4  (0x0010)

#define F_SD_FOUND (0x08)
#define F_NASDIR_FOUND (0x04)
#define F_VDISK_MOUNT (0x02)
// 0 do not auto-go, 1 automatically execute program if possible
#define F_AUTO_GO   (0x01)

// Startup defaults: read from Flash and auto-go.
// This works because flash is always present and becasue 0 is an illegal destination for writes.
int cas_flags = F_AUTO_GO;


// code these away
int cas_rd_state=0;
int cas_wr_state=0;


// These are automatically null-terminated
// When the NASCOM/ directory exists, the name will be used directly
// When it does not, start at offset 6 instead
#define STR_PATH_OFFSET ((cas_flags & F_NASDIR_FOUND) ? 0 : 7)
// sometimes just need the string NASCOM - temporarily change the / to a NUL at offset STR_SLASH_OFFSET
#define STR_SLASH_OFFSET (6)
// where to start when filling in the name
#define STR_FILE_OFFSET (7)
char cas_rd_name[]  = "NASCOM/NAS-RD00.CAS";
char cas_wr_name[]  = "NASCOM/NAS-WR00.CAS";
char cas_vdisk_name[] = "NASCOM/NAS-XX00.DSK";

// numbers (BCD) for auto-inc rd/wr
// TODO don't need these because I can do the name change in-situ.
//char cas_rd_num = 0;
//char cas_wr_num = 0;


// this is effectively rd_dirent. Boot device is Flash and 0 means the first
// file: SERBOOT.GO
int wotfile = 0;

// state for loop()
unsigned long drive_on = 0;


// arduino clock is 16MHz
SoftwareSerial mySerial(PIN_NTXD, PIN_NRXD, 1); // RX, TX, INVERSE_LOGIC on pin


// Run-time check of available RAM
// http://jheyman.github.io/blog/pages/ArduinoTipsAndTricks/
void pr_freeRAM(void) {
  extern int __heap_start, *__brkval;
  int v;
  Serial.print(F("Bytes of free RAM = "));
  Serial.println((int) &v - (__brkval == 0 ? (int) &__heap_start : (int) __brkval));
}


void setup()   {
    Serial.begin(115200);  // for Debug

    open_sdcard();

    pinMode(PIN_DRV, INPUT);

    // TODO not yet complete..
    // Choose a pin
    // set up accordingly
    // set the divider correctly for the required baud rate

    // Generate output clock that will be used as 16x clock for the NASCOM UART.
    // The output pin options are shown in the I/O Multiplexing table of the data sheet
    // ..need to select an Output Compare unit from one of the timers.
    // OC2B PD[3] = DIG3
    // OC2A PB[3] = DIG11 -- used for SDcard
    // OC1B PB[2] = DIG10 -- used for SDcard
    // OC1A PB[1] = DIG9  -- best candidate and already assigned for output clock.
    //
    // => use Timer1

    // Atmega clock is 16MHz. UART needs 16x clock. Timeout causes pin to toggle
    // and need 2 toggles for 1Hz. Therefore, for a baud rate B need a divide
    // value of D = 16E6/(16 * 2 * B). Frequency should then be 16E6/D


    // TODO determine what the critical factor is in the baud rate. Is it really that
    // the nascom cannot keep up? If so, would see an overrun error on the NASCOM UART.

    // For 1200 baud need divide by 417 (19208Hz)
    //     2400                     208  <-- seems to work OK
    //     4800                     104  <-- seems to work OK on small blocks but not reliable
    //     9600                      52  <-- does not work; bad data at NASCOM
    //    19200                      26
    //
    // For a divider of N, OCR1 is set to N-1.

    PRR  &= ~(1 << PRTIM1);                         // Ensure Timer1 is enabled

    TCCR1B |= (1 << CS10);                          // Set Timer1 clock to "no prescaling"
    TCCR1B &= ~((1 << CS11) | (1 << CS12));

    TCCR1B &= ~(1 << WGM13);                        // Set Timer1 CTC mode=4
    TCCR1B |=  (1 << WGM12);
    TCCR1A &= ~(1 << WGM11);
    TCCR1A &= ~(1 << WGM10);
    //
    TCCR1A |= (1 <<  COM1A0);                       // Set "toggle on compare match"
    TCCR1A &= ~(1 << COM1A1);
    OCR1A = 208-1;                                  // Set the compare value to toggle OC1A
    // bits in TCCR select OC unit as source of output, but still need to set the pin to the
    // output direction so that the clock is available at the output
    pinMode(PIN_CLK, OUTPUT);

    // should not need this?
    pinMode(PIN_NTXD, INPUT_PULLUP);

    mySerial.begin(2400); // 1200 is default baud rate on NASCOM
    // Need the leading space so that NAS-SYS will ignore the line
    mySerial.println(F(" Hello NASCOM this is the Arduino"));

    // Bootstrap the CLI on the host. Sending R causes the NASCOM to start a READ which will
    // cause loop() to call cmd_cass_rd which will load file from Flash directory index given
    // by 'wotfile' and, provided the auto-execute flag is set, it will go ahead and execute it.
    mySerial.println(F("R"));

    Serial.println(F(".init"));
}


void loop() {
    // - if a serial char received and drive light is OFF, it's a command
    //   from the CLI running on the NASCOM; get it and process it to completion.
    //
    // - if a serial char received and drive light is ON, it's the first
    //   byte of a WRITE. Grab the data and save it to the specified place.
    //
    // - if drive light is ON and has been on for a while (longer than it
    //   takes for write data to arrive and longer than it would be on if
    //   it was being toggled in order to play a tune(!!)), it's a READ;
    //   supply the data from the specified place.
    //
    // This routine is invoked repeatedly by the arduino "scheduler" and so
    // there is no loop inside here; do one pass of polling and drop through
    // the bottom. If anything needs doing it will be invoked from here. Any
    // state needs to be global.

    if (digitalRead(PIN_DRV) == 0) {
        drive_on++;
    }
    else {
        drive_on = 0;
    }

    if (mySerial.available()) {
        if (drive_on == 0) {
            // Receive and process a command
            Serial.println(F(">cmd_cass"));
            cmd_cass();
        }
        else {
            // File save
            Serial.print(F(">cmd_cass_wr count= "));
            Serial.println(drive_on);
            drive_on = 0;
            // Write
            cmd_cass_wr();
        }
    }
    else if (drive_on > 66000) {
        // File Load
        Serial.println(F(">cmd_cass_rd"));
        drive_on = 0;
        cmd_cass_rd();
    }
}


// Print a message to the Host through the serial port. The message is stored in Flash.
// Flags determine whether a leading 0xff is sent, whether a trailing CR is sent
// and whether a trailing NUL is sent (refer to the protocol description).
void pr_msg(int msg, char flags) {
    if (flags & F_MSG_RESPONSE) {
        mySerial.write((byte)0xff); // indicate to host that a message is coming
    }

    while ((pgm_read_byte(msg) != 0)) {
        mySerial.write(pgm_read_byte(msg++));
    }

    if (flags & F_MSG_CR) {
        mySerial.println(); // TODO maybe do this explicitly. What does NASCOM need? CR LF or both? this does \r\n
    }

    if (flags & F_MSG_NULLTERM) {
        mySerial.write((byte)0x00); // indicate to host that a message is coming
    }
}


// Used by iterator. Print a directory entry, contained in b.
// 2nd argument is unused but needed so the signature matches for all functions
// called by the iterator.
// Always returns 0, which forces the iterator to run to completion.
int pr_dirent(union Dirent *d, char *dummy) {
    // format name at start of buf by removing spaces and adding a "." and by
    // padding afterwards to a 13-character field
    int len=12;
    for (int i=0; i<10; i++) {
        if (i==8) {
            mySerial.print(".");
        }
        if (d->b[i] != ' ') {
            len--;
            mySerial.print(d->b[i]);
        }
    }
    while (len>0) {
        mySerial.print(" ");
        len--;
    }
    // TODO it would be nice if there were leading zeroes
    // I think that's easy to add to Print.cpp in the install directory..
    // Change Print::print(unsigned int n, base)
    // so that it checks for base 16 and uses a different print routine
    // OR add another parameter "width" that, in Print::printNumber prefills the buffer with
    // space or 0 and pulls str count back accordingly.
    mySerial.print("SIZE=0x");
    mySerial.print((uint16_t)d->f.flen, HEX);
    mySerial.print(" LOAD=0x");
    mySerial.print((uint16_t)d->f.flda, HEX);
    mySerial.print(" EXE=0x");
    mySerial.println((uint16_t)d->f.fexa, HEX); 
    return 0; // Force the interator to run to completion
}


// Used by iterator. Look for string match in the 10 characters
// of buf and name.
// return 0 if no match (to make the iterator move on)
// returm 1 if match (to make the iterator terminate)
int find_dirent(union Dirent *d, char *name) {
    Serial.print("Compare ->");
    Serial.write(d->b, 10);
    Serial.print("<-- and -->");
    Serial.write(name, 10);
    Serial.println("<--");

    for (int i=0; i<10; i++) {
        if (d->b[i] != name[i]) {
            return 0; // Force iterator to continue
        }
    }
    return 1; // Force iterator to abort
}


// Iterator. fn is called for each valid flash directory entry. If fn returns 1,
// the iterator aborts and returns the iteration number (which is the dirent
// number), otherwise the iterator continues to completion.
int foreach_flash_dir(void *fn, char * fname) {
    int (*fn_ptr)(union Dirent *d, char * buf2);
    fn_ptr = fn;

    for (int i=0; i<sizeof(romdir)/sizeof(struct DIRENT); i++) {
        // read the 18-byte FDIRENT into a 20-byte DIRENT by padding
        // in the middle so that all the fields we care about line up.
        union Dirent dirent;

        int base = &romdir[i].fnam_fext;
        for (int j=0; j<20; j++) {
            if ((j==10) | (j==11)) {
                // the flag fields don't exist in the FDIRENT
                continue;
            }
            dirent.b[j] = pgm_read_byte(base++);
        }
        if ( (*fn_ptr)(&dirent, fname) ) {
            return i;
        }
    }
    return -1; // Iterator ran to completion
}


// Iterator. fn is called for each valid vdisk directory entry. If fn returns 1,
// the iterator aborts and returns the iteration number (which is the dirent
// number), otherwise the iterator continues to completion.
int foreach_vdisk_dir(void *fn, char * fname) {
    int (*fn_ptr)(union Dirent *d, char * buf2);
    fn_ptr = fn;

    if ( (SD.exists(&cas_vdisk_name[STR_PATH_OFFSET])) && (handle = SD.open(&cas_vdisk_name[STR_PATH_OFFSET], FILE_READ)) ) {
        union Dirent dirent;

        pr_freeRAM();

        handle.read(dirent.b, 20); // read and discard disk volume name
        handle.read(dirent.b, 4);  // read next free sector addr, next free fcb addr

        // In PolyDos this structure is stored in RAM at 0xc418 and the
        // "next free FCB" address is relative to that, so rebase to 0
        // then convert to number of dirents at 20 bytes per entry.
        // Finally, this was the address of the first free entry and
        // so step back by 1 to get to the last used entry.
        int last = (dirent.b[2] | (dirent.b[3] << 8)) - 0xc418;
        last = (last/20) - 1;

        for (int i=0; i<last; i++) {
            handle.read(dirent.b, 20);

            if (dirent.f.fsfl & 2) {
                // system byte "deleted" flag is set so skip this entry
                continue;
            }

            // convert the size to bytes
            dirent.f.flen *= 256;

            // invoke the callback
            if ( (*fn_ptr)(&dirent, fname) ) {
                handle.close();
                return i;
            }
        }
        handle.close();
        return -1; // Iterator ran to completion
    }
    else {
        pr_msg(msg_err_vdisk_bad, F_MSG_RESPONSE + F_MSG_CR);
    }
}




// Check for SDcard and (if present) check for existence of NASCOM directory.
// Update cas_flags accordingly. Used at startup and after NEw command.
//
// LIBRARY BUG: as described here http://forum.arduino.cc/index.php/topic,66415.0.html
// the SD library only allows you to call SD.begin() onece. Subsequent times,
// it reports "fail". The fix is to switch to https://github.com/greiman/SdFat
// or to edit the library code: in libraries/SD/src/SD.cpp SDClass::begin, add
// root.close(); before the "return".
void open_sdcard(void) {
    Serial.print(F("SDcard flags: 0x"));
    // Build the nul-terminated string "NASCOM"
    cas_vdisk_name[STR_SLASH_OFFSET] = 0;
    cas_flags &= ~(F_SD_FOUND | F_NASDIR_FOUND | F_VDISK_MOUNT);
    if (SD.begin()) {
        cas_flags |= F_SD_FOUND;
        if (SD.exists(cas_vdisk_name)) {
            cas_flags |= F_NASDIR_FOUND;
        }
    }
    // Restore original string
    cas_vdisk_name[STR_SLASH_OFFSET] = '/';
    Serial.println(cas_flags, HEX);
}


// Come here when DRIVE is off and there is a serial character available. Infer that a
// nul-terminated string is going to be delivered. Receive the string into a buffer
// and process it to completion -- for example, by setting up state that will be used
// subsequently.
void cmd_cass(void) {
    char buf[40]; // TODO I think the maximum incoming line is 40 + NUL. May need to make this 1 byte larger. Test.
    char * pbuf = &buf[0];
    char res[4];
    int index = 0;
    int cmd = 0;
    File entry; // for DIR command
    Serial.println(F("Get cmd line"));

    // Receive a NUL-terminated string from the Host into buf[]
    while (1) {
        if (mySerial.available()) {
            buf[index] = mySerial.read();
            if (buf[index] == 0) {
                break;
            }
            else {
                index++;
            }
        }
    }
    Serial.print(F("Rx cmd line of "));
    Serial.print(index);
    Serial.println(F(" char"));

    // The line is guaranteed to be at least 1 char + 1 NUL and to start with a non-blank. Only the first 2 characters
    // of a command are significant, so it's always OK simply to blindly check the first 2 characters
    cmd = (to_upper(buf[0]) << 8) | to_upper(buf[1]);
    switch (cmd) {

    case ('H'<<8 | 'E'):      // HELP
        pr_msg(msg_help, F_MSG_RESPONSE + F_MSG_CR);
        break;

    case ('I'<<8 | 'N'):      // INFO - version and status
        pr_msg(msg_info, F_MSG_RESPONSE + F_MSG_CR);
        mySerial.print("Flags: 0x");  // TODO decode it??
        mySerial.println(cas_flags, HEX);
        mySerial.print(F("Read  name: "));
        mySerial.println(&cas_rd_name[STR_PATH_OFFSET]);
        mySerial.print(F("Write name: "));
        mySerial.println(&cas_wr_name[STR_PATH_OFFSET]);
        mySerial.print(F("Vdisk name: "));
        mySerial.println(&cas_vdisk_name[STR_PATH_OFFSET]);
        break;

    case ('T'<<8 | 'O'):      // TO xxxx - relocate boot loader to xxxx.
        int destination;
        if (parse_leading(&pbuf) && parse_num(&pbuf, &destination, 16)) {
            mySerial.write((byte)0x55); // indicate to host that relocation will occur
            mySerial.write((byte)(destination & 0xff));      // low part
            mySerial.write((byte)((destination>>8) & 0xff)); // high
            Serial.print(F("TO to 0x"));
            Serial.println(destination, HEX);
            // break from here will result in an unneeded NULL being sent but
            // that is not a problem because the Host is in ZINLIN (either from
            // the NAS-SYS or the SDCard command loops) which accepts data from
            // from serial or keyboard and will simply gobble and discard NULLs.
        }
        else {
            // bad argument
            pr_msg(msg_err_addr_bad, F_MSG_RESPONSE + F_MSG_CR);
        }
        break;

    case ('A'<<8 | 'U'): // AUTOGO [0 | 1] - execute a file after loading
        cas_flags = cas_gen_flag(buf, cas_flags, F_AUTO_GO);
        break;

    case ('N'<<8 | 'E'): // NEW - (re)read SDcard
        open_sdcard();
        break;

    case ('M'<<8 | 'O'): // MO <8.3> - Mount virtual disk from FAT file-system. In PolyDos format
        if (cas_flags & F_SD_FOUND) {
            if (parse_leading(&pbuf) && parse_fname_msdos(&pbuf, &cas_vdisk_name[STR_FILE_OFFSET])) {
                // Don't want to create a file, so check existence first
                if ( (SD.exists(&cas_vdisk_name[STR_PATH_OFFSET])) && (handle = SD.open(&cas_vdisk_name[STR_PATH_OFFSET], FILE_WRITE)) ) {
                    handle.close();
                    cas_flags |= F_VDISK_MOUNT;
                }
                else {
                    pr_msg(msg_err_fname_missing, F_MSG_RESPONSE + F_MSG_CR);
                }
            }
            else {
                pr_msg(msg_err_fname_bad, F_MSG_RESPONSE + F_MSG_CR);
            }
        }
        else {
            pr_msg(msg_err_sd_missing, F_MSG_RESPONSE + F_MSG_CR);
        }
        break;

    case ('D'<<8 | 'S'):  // DS - directory of SDcard
        // TODO need a 2-column or 3-column format. Do I need a pager? I hope not
        // tho I already have it on my wish-list and it would only require
        // counting lines here and issuing the extra response byte..
        if (cas_flags & F_SD_FOUND) {
            if (cas_flags & F_NASDIR_FOUND) {
                // Build the nul-terminated string "NASCOM"
                cas_vdisk_name[STR_SLASH_OFFSET] = 0;
                handle = SD.open(cas_vdisk_name);
                // Restore original string
                cas_vdisk_name[STR_SLASH_OFFSET] = '/';
            }
            else {
                handle = SD.open("/");
            }
            handle.rewindDirectory();
            mySerial.write((byte)0xff); // indicate to host that a message is coming
            while (entry = handle.openNextFile()) {
                mySerial.print(entry.name());
                entry.isDirectory() ? mySerial.println("/") : mySerial.println("");
                entry.close();
            }
            handle.close();
        }
        else {
            pr_msg(msg_err_sd_missing, F_MSG_RESPONSE + F_MSG_CR);
        }
        break;

    case ('D'<<8 | 'F'):  // DF - directory of Flash
        // TODO there are only a few so can print name and meta-data
        mySerial.write((byte)0xff); // indicate to host that a message is coming
        foreach_flash_dir(&pr_dirent, 0);
        break;

    case ('D'<<8 | 'V'):  // DV - directory of Virtual disk
        // TODO may want a pager
        if (cas_flags & F_SD_FOUND) {
             if (cas_flags & F_VDISK_MOUNT) {
                 mySerial.write((byte)0xff); // indicate to host that a message is coming
                 foreach_vdisk_dir(&pr_dirent, 0);
             }
             else {
                 pr_msg(msg_err_vdisk_missing, F_MSG_RESPONSE + F_MSG_CR);
             }
        }
        else {
            pr_msg(msg_err_sd_missing, F_MSG_RESPONSE + F_MSG_CR);
        }
        break;

    case ('R'<<8 | 'F'): // RF <8.2> - Read specified file from flash file-system. Convert binary->cas
        if (parse_leading(&pbuf) && parse_fname_polydos(&pbuf, &cas_rd_name[STR_FILE_OFFSET])) {
            // try to find it..
            wotfile = foreach_flash_dir(&find_dirent, &cas_rd_name[STR_FILE_OFFSET]);
            if (wotfile == -1) {
                pr_msg(msg_err_fname_missing, F_MSG_RESPONSE + F_MSG_CR);
            }
            // TODO also need to set or clear some other flags to show the source and that it's all valid
        }
        else {
            pr_msg(msg_err_fname_bad, F_MSG_RESPONSE + F_MSG_CR);
        }
        break;

    case ('R'<<8 | 'V'): // RV <8.2> - Read specified file from virtual file-system. Convert binary->cas
        if (cas_flags & F_SD_FOUND) {
             if (cas_flags & F_VDISK_MOUNT) {
                 if (parse_leading(&pbuf) && parse_fname_polydos(&pbuf, &cas_rd_name[STR_FILE_OFFSET])) {
                     // try to find it..
                     wotfile = foreach_vdisk_dir(&find_dirent, &cas_rd_name[STR_FILE_OFFSET]);
                     if (wotfile == -1) {
                         pr_msg(msg_err_fname_missing, F_MSG_RESPONSE + F_MSG_CR);
                     }
                     // TODO also need to set or clear some other flags to show the source and that it's all valid
                     // TODO there's no point in setting wotfile, of course!!
                 }
                 else {
                     pr_msg(msg_err_fname_bad, F_MSG_RESPONSE + F_MSG_CR);
                 }
             }
             else {
                 pr_msg(msg_err_vdisk_missing, F_MSG_RESPONSE + F_MSG_CR);
             }
        }
        else {
            pr_msg(msg_err_sd_missing, F_MSG_RESPONSE + F_MSG_CR);
        }
        break;


/*    case ('W'<<8 | 'V'): // WV <8.2> - Write specified file to virtual file-system. Convert cas->binary.
        Serial.println(F("Wr Virt file"));
        // TODO need flag to show that virtual file system is mounted. Error if not
        cas_parse_name(buf, res);
        // All flash files are 1-8 characters and a 2-character extension: GO
        if ((res[0] == 0) || (res[2] > 8) || (res[3] != 2)) {
            pr_msg(msg_err_fname_bad, F_MSG_RESPONSE + F_MSG_CR);
        }
        else {
            // try to find it TODO.
            // at the end need to leave flags showing the data source and the index, so that the
            // read command knows where to get the data and that it has to do the binary->cas conversion
            pr_msg(msg_err_fname_missing, F_MSG_RESPONSE + F_MSG_CR);
        }
        break;
*/

/*    case ('R'<<8 | 'C'): // RC <8.3> - Read specified file from FAT file-system. Already in CAS format
        Serial.println(F("Rd CAS"));
        cas_parse_name(buf, res);
        // All FAT files are 1-8 characters and a 1-3-character extension
        if ((res[0] == 0) || (res[2] > 8) || (res[3] > 3)) {
            pr_msg(msg_err_fname_bad, F_MSG_RESPONSE + F_MSG_CR);
        }
        else {
            cas_cp_filename(buf, cas_rd_name, res[1], 1 + res[2] + res[3], 0); // Final 0 means MSDOS format
            Serial.println(cas_rd_name);
            if ( SD.exists(cas_rd_name) ) {
                Serial.println(F("CAS file OK"));

                // there are cases where the file does not exist yet because we'll write it before
                // reading it, it's up to the user to decide if that's really an error. Therefore,
                // 1/ we cannot rely on opening the file now; need to defer until it's needed
                // 2/ need to set flags as though this was successful
            }
            else {
                pr_msg(msg_err_fname_missing, F_MSG_RESPONSE + F_MSG_CR);
            }

            cas_rd_state = 1;
        }
        break;
*/

/*    case ('W'<<8 | 'C'): // WC <8.3> - Write specified file to FAT file-system. Already in CAS format
        Serial.println(F("Wr CAS"));
        cas_parse_name(buf, res);

        // All FAT files are 1-8 characters and a 1-3-character extension
        if ((res[0] == 0) || (res[2] > 8) || (res[3] > 3)) {
            pr_msg(msg_err_fname_bad, F_MSG_RESPONSE + F_MSG_CR);
        }
        else {
            cas_cp_filename(buf, cas_wr_name, res[1], 1 + res[2] + res[3], 0); // Final 0 means MSDOS format
            // TODO need to document that [0] is disk, [1] is read [2] is write

            // The file does not exist yet so nothing to do here except remember state
            cas_wr_state = 1;
        }
        break;
*/

    default:
        pr_msg(msg_err_try_help, F_MSG_RESPONSE + F_MSG_CR);
    }

    // Send response "done"
    mySerial.write((byte)0x00);
}


// Respond to DRIVE light being on and timeout being reached without any rx data
// -> infer a "R"ead command.
// CAS format: supply bytes from file on SD until it's empty.
// FLASH format: encode chunk of data in CAS format
// End by waiting for DRIVE light to go off
// TODO other formats
void cmd_cass_rd() {
    if ( ((cas_rd_state & 0xf) == 1) && (handle = SD.open(cas_rd_name, FILE_READ)) ) {
        // have a file name and can open the file -> good to go!
        // while drive light is on, grab bytes and send them to serial
        Serial.println(F("file from disk"));
        char c;
        while (handle.read(&c, 1)) {
            mySerial.print(c);
        }
        handle.close();
    }
    else if ( ((cas_rd_state & 0xf) == 0) ) {
        // CAS-encode a binary file from Flash
         Serial.println(F("file from Flash"));
        cass_bin2cas();
    }
    else {
        Serial.println(F("Error")); //no file name or unsupported destination" 0- should abort tape and send rto Host
    }

    // wait for pin to negate
    while (digitalRead(PIN_DRV) == 0) {
    }
}


// For now, this just means delivering a file (from on-chip ROM) selected by wotfile - converting
// it on-the-fly from binary to CAS format
void cass_bin2cas() {
    int remain;// total number of data bytes left to send
    int addr;  // initial load address of file to send
    int block; // current block number.
    int count; // bytes in this block
    int index; // index into byte array
    int csum;  // accumulated checksum


    // tidy this code up. Also, I'll need to use the same code for grabbing
    // data from a disk image, so it needs to be less specific

    // work out first block number
    // accumulate checksum
    // know start address
    // loop until block reaches 0
    // do a block

    remain = pgm_read_word(&romdir[wotfile].flen);
    addr =   pgm_read_word(&romdir[wotfile].flda);

    // address of first byte of code
    index = pgm_read_word(&romdir[wotfile].fptr);

    // total number of blocks needed to send remain bytes
    block = ((remain + 0xff) & 0xff00) >> 8;

    while (block != 0) {
        block--;  // the new block number
        Serial.print(F("Block="));
        Serial.println(block);
        Serial.print(F("Remain="));
        Serial.println(remain);
        // output sync pattern
        mySerial.write((byte)0x00);
        mySerial.write((byte)0xff);
        mySerial.write((byte)0xff);
        mySerial.write((byte)0xff);
        mySerial.write((byte)0xff);

        // output block header and checksum
        csum = (addr & 0xff) + (addr >> 8) + block;
        mySerial.write(addr & 0xff);
        mySerial.write(addr >> 8);
        if (remain > 255) {
            count = 256;
            mySerial.write((byte)0); // means 256 bytes
            // do not need to accumulate count (0) in checksum
        }
        else {
            count = remain;
            mySerial.write(count);
            csum = csum + count;
        }
        mySerial.write(block);
        mySerial.write(csum & 0xff); // header checksum .. or make this a char?? Need everything unsigned??

        // output block body
        csum = 0;
        while (count !=0) {
            csum = csum + pgm_read_byte(index);
            mySerial.write(pgm_read_byte(index));

            index++;
            count--;
            remain--; // TODO simply subtract count 
            addr++; // TODO simply add count
        }
        mySerial.write(csum & 0xff); // body checksum
 
        // inter-block gap -- 10 nul characters
        for (csum = 0; csum < 10; csum++) {
            mySerial.write((byte)0);
        }
    }


    if (cas_flags & F_AUTO_GO) {
        mySerial.print("E");
        mySerial.println(pgm_read_word(&romdir[wotfile].fexa), HEX);
    }
    Serial.println(pgm_read_word(&romdir[wotfile].fexa), HEX);
    Serial.print(F(".cass_bin2cas"));
}


// Respond to DRIVE light being on and rx data being available -> infer a "W"rite command.
// CAS format: store byte stream to file on SD until DRIVE goes off.
// After DRIVE goes off, disard any remaining/buffered data
// TODO other formats.
void cmd_cass_wr(void) {
    if ( ((cas_wr_state & 0xf) == 1) && (handle = SD.open(cas_wr_name, FILE_WRITE)) ) {
        // have a file name and can open the file -> good to go!
        // while drive light is on, grab bytes and send them to disk
        while (digitalRead(PIN_DRV) == 0) {
            if (mySerial.available()) {
                handle.write(mySerial.read());
            }
        }
        handle.flush();
        handle.close();
    }
    else {
        Serial.println(F("Error")); //no file name or unsupported destination" TODO should be to CLI
        // wait for pin to negate
        while (digitalRead(PIN_DRV) == 0) { }
    }

    // empty any rogue characters TODO do I still need this?
    while (mySerial.available()) {
        mySerial.read();
    }
}
