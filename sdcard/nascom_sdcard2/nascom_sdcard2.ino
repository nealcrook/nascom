// nascom_sdcard2
// https://github.com/nealcrook/nascom
//
// ARDUINO connected to NASCOM 2 as mass-storage device
//
// 2 separate interfaces:
//
// 1. Connect through PIO
// 2. Connect through UART
//
/////////////////////////////////////////////////////
// Connect through PIO for the purposes of:
// - dumping data from the NASCOM
// - providing virtual floppy disk capability
// - (maybe/future) providing virtual ".NAS" and ".CAS" support
//
// The virtual floppy capability can work in conjunction with a
// modified POLYDOS ROM in which the disk drivers address this hardware.
//
// Virtual NAS/CAS support would would work in conjunction with
// a patched/modified NAS-SYS in which the R/W commands (or the I/O
// tables) are modified to address this device.
//
// This is not "transparent" to the NASCOM - a utility program
// runs on the NASCOM to control this hardware.
//
// Operations can be associated with upto 5 file-names on the
// SD card. For example, associate 4 of them with virtual drive
// images and use the other one for dumping binary streams.
// Can seek by track/sector or by raw offset
// Can read/write by sector or by specified byte count.
//
/////////////////////////////////////////////////////
// Connect through UART for the purpose of:
// - Providing a "virtual cassette interface" in
//   which the existing R and W commands (and the
//   equivalent from within BASIC and other applications)
//   are directed to files on SDcard
//
// This is "transparent" to the NASCOM but a utility
// program is needed/provided to control what file is
// used for read/write. The utility is tiny (XX bytes)
// and can be bootstrap-loaded through the serial
// port.
/////////////////////////////////////////////////////
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
// If you are using the PIO connection you can pick
// up GND from there. If you are only using the serial
// connection you will need to add a connection to GND
//
// If you are powering the Arduino from the NASCOM
// you will need to set the jumper accordingly and
// add a connection to +5V
//
/////////////////////////////////////////////////////
// PROTOCOL FOR PIO INTERFACE
//
// The NASCOM acts as the Host and the Arduino acts as the Target. The
// protocol uses a handshake in each direction. There are 5 different
// signalling patterns (pictures in the github sdcard/doc/ area):
//
// 1a/ send command byte from Host to Target
// 1b/ send data byte from Host to Target
// 2/  send data byte from Target to Host
// 3/ change bus direction from Host driving to Target driving
// 4/ change bus direction from Target driving to Host driving
//
// After reset, the Host is driving data to the Target. H2T is low,
// T2H is low, CMD is undefined.
//
// 1a/ send command byte from Host to Target
// - Host: put xd=command byte, put cmd=1
// - Host: invert H2T
// - Host: wait until T2H == H2T
// - Target: wait until H2T != T2H
// - Target: sample value of xd, cmd
// - Target: put T2H = H2T
//
// 1b/ send data byte from Host to Target
// - same as 1a, except cmd=0
//
// 2/  send data byte from Target to Host
// - Target: put xd=data byte
// - Target: invert T2H
// - Target: wait until T2H != H2T
// - Host: wait until T2H == H2T
// - Host: sample value of xd
// - Host: put T2H = !H2T
//
// 3/ change bus direction from Host driving to Target driving
// - Host: set xd bus to INPUT
// - Host: put T2H = !H2T
// - Target: wait until T2H != H2T
// - Target: set xd bus to OUTPUT
//
// 4/ change bus direction from Target driving to Host driving
// - Target: set xd bus to INPUT
// - Target: invert T2H
// - Host: wait until T2H != H2T
// - Host: set xd bus to OUTPUT
//
// Observe:
// - Each step requires 1 handshake toggle. Therefore, the protocol
//   can run at any speed down to DC.
// - For patterns where the Host is driving the bus, the idle state of
//   the handshakes is that they match.
// - For patterns where the Target is driving the bus, the idle state of
//   the handshakes is that they differ
//
// Thus:
// 1a - start and end with handshakes matching
// 1b - start and end with handshakes matching
// 2  - start and end with handshakes differing
// 3  - start with handshakes matching, end with handshakes differing
// 4  - start with handshakes differing, end with handshakes matching
//
/////////////////////////////////////////////////////
// PROTOCOL FOR SERIAL INTERFACE
//
// When running the serial utility, eg:
// E 0C80
// SDcard>
//
// (documented in NASCOM host program)
//
//
/////////////////////////////////////////////////////
// COMMANDS
//
// Work them out from the comments or refer to separate document
//
/////////////////////////////////////////////////////



// TODO set geometry command to allow different disk types to be mixed?
// TODO implement restore_state
// TODO implement save_state
// TODO do error checking in n_rd
// TODO consider removing CMD_DEFAULT as it doesn't seem useful in the way
// that I orginally expected.
// TODO could drive CMD=1 during T2H to indicate ABORT but would
// have to be very careful to ensure both sides can track state.


// For testing
//#define DEBUG
#define SDEBUG

/////////////////////////////////////////////////////
// Pin assignments (PIO)
#define PIN_T2H A1
#define PIN_H2T A0
#define PIN_CMD A4
#define PIN_ERROR A2
#define PIN_XD7 9
#define PIN_XD6 8
#define PIN_XD5 7
#define PIN_XD4 6
#define PIN_XD3 5
#define PIN_XD2 4
#define PIN_XD1 3
#define PIN_XD0 2

/////////////////////////////////////////////////////
// Pin assignments (SERIAL)
#define PIN_DRV 6
#define PIN_CLK 9
#define PIN_NTXD 7
#define PIN_NRXD 8


/////////////////////////////////////////////////////
// Commands

#define CMD_NOP           (0x80)
#define CMD_RESTORE_STATE (0x81)
#define CMD_SAVE_STATE    (0x82)
#define CMD_LOOP          (0x83)
#define CMD_DIR           (0x84)
#define CMD_STATUS        (0x85)
#define CMD_INFO          (0x86)
#define CMD_STOP          (0x87)


// Bits [2:0] of these commands are the file ID (FID)
#define CMD_OPEN     (0x10)
#define CMD_OPENR    (0x18)
#define CMD_SEEK     (0x20)
#define CMD_TS_SEEK  (0x28)
#define CMD_SECT_RD  (0x30)
#define CMD_N_RD     (0x38)
#define CMD_SECT_WR  (0x40)
#define CMD_N_WR     (0x48)
#define CMD_DEFAULT  (0x50)
#define CMD_SIZE     (0x58)
#define CMD_SIZE_RD  (0x60)
#define CMD_CLOSE    (0x68)


/////////////////////////////////////////////////////

// Filename for state save/restore
#define STATE_FILE "NASCOM.SD"

// Number of bytes available
#define BUFFER (48)

// Which files have known names and exist
#define FLAG_RAW (0x10)
#define FLAG_DRV3 (0x08)
#define FLAG_DRV2 (0x04)
#define FLAG_DRV1 (0x02)
#define FLAG_DRV0 (0x01)

// Constants for converting track/sector/side to offset
// TODO maybe have "set geometry"?
// These are correct for the version of PolyDos I'm running on jsnascom
// but may be wrong for the version on my actual NASCOM. Also, not sure
// how 2 sides are handled.. by doubling the tracks or otherwise?
// ..actually, PolyDos doesn't care because it treats the disk as a linear
// sequence of sectors and my low-level drivers do the same; don't consider
// tracks/sectors at all.
#define SECTORS_PER_TRACK (18)
#define BYTES_PER_SECTOR (256)
#define TRACKS (80)

#include <EEPROM.h>
#include <SD.h>
#include <SoftwareSerial.h>


// Prototypes
long get_value32(void);
void set_data_dir(int my_dir);
int restore_state(int auto_restore);
unsigned int get_value(void);
char fid(char fid);
//
void cmd_default(char fid);
void cmd_open(char fid, int mode);
void cmd_close(char fid);
void cmd_save_state(void);
void cmd_restore_state(void);
void cmd_loop(void);
void cmd_dir(void);
void cmd_info(void);
void cmd_stop(void);
void cmd_seek(char fid);
void cmd_ts_seek(char fid);
void cmd_status(void);
void cmd_sect_rd(char fid);
void cmd_sect_wr(char fid);
void cmd_n_rd(char fid);
void cmd_n_wr(char fid);
void cmd_size(char fid);
void cmd_size_rd(char fid);

void cmd_cass(void);
void cmd_cass_rd(void);
void cmd_cass_wr(void);
void cas_wr_eeprom(void);
void cas_rd_eeprom(void);

// hint of next number to use when auto-generating file names
int next_file;

// default file ID
char default_fid;

// status of most recent command
int status;

// Work with upto 5 files. Low bits indicate which are valid/open
// TODO only use this at restore time, then MSB at save time. In normal
// operation use handles[] to show whether a FID is valid.
char flags;
File handles[5];

// Buffer for accumulating string from host
// BUFFER chars are available, 0..BUFFER-1
// but string is null-terminated which takes up 1 char.
// TODO this is for virtual disk; NOT used by cass.. which has its own buffer. Can they
// share? Can the buffer be non-global??
// best solution is to modify virtual disk version to NOT have a global buffer; it is not
// necessary (even for the testing stuff).
char buf[BUFFER];

// Protocol bit
int my_t2h;

// INPUT when receiving data OUTPUT when sending data
char direction;


// define ROM data - boot ROM and some applications/games
#include "roms.h"

// non-volatile state/flags. These are all set to 0 on cold boot (boot with no SD-card
// present) otherwise they are preserved.
// some of them are multi-bit
#define F_NV_RD_INC   (0x1)
#define F_NV_WR_INC   (0x2)
// 0 = FLASH
// 1 = SD
// 2 = DISK IMAGE
#define F_NV_RD_SRC   (0xc)
#define F_NV WR_SRC   (0x30)
// mimic the Generate command
#define F_NV_AUTO_GO  (0x40)
// use stored read file name/source/auto_go at startup rather than loading the boot code
#define F_NV_AUTO_EXEC (0x80)
#define F_NV_BASIC_HDR (0x100)
// todo how many bits??
#define F_NV_SPEED    (0x0)

// These are all non-volatile, stored in EEPROM
int cas_flags=0;
int cas_speed=0;
char cas_rd_name[] = "NAS-RD00.CAS";
char cas_wr_name[] = "NAS-WR00.CAS";
// TODO add storage for virtual disk name


// 

// numbers (BCD) for auto-inc rd/wr
char cas_rd_num = 0;
char cas_wr_num = 0;


// TODO mechanism for auto-reset of stuff.. 


// NEXT
//
// FAT files are 8.3 names -- at least 1 before, at least 1 after maybe have 4 non-volatile names and share with // stuff.
// Polydos files are 8.2 -- at least 1 before, always 2 after
// add command to toggle flags and to increment/decrement speed
// add info page
// implement save to SDcard
// implement load from SDcard
// implement load from FLASH

// need flag to indicate if Polydos disk file is open



// flag commands seem to work OK
// TODO save values to EEPROM
// read and convert args for TO command.

// skip command
// skip spaces
// get next 4 digits 1234 ASCII
// as ascii 31 32 33 34
// subtract 0x30 to get 1 2 3 4
// send 34 12



int wotfile;



// state for loop()
unsigned long drive_on = 0;


// arduino clock is 16MHz
SoftwareSerial mySerial(PIN_NTXD, PIN_NRXD, 1); // RX, TX, INVERSE_LOGIC on pin

void setup()   {
  Serial.begin(115200);  // for Debug

  wotfile = 0;

  flags = 0;
  buf[0] = 0;
  my_t2h = 0;
  next_file = 0;
  direction = INPUT;

  // H2T, T2H, CMD have fixed direction
//  pinMode(PIN_H2T, INPUT);
//  pinMode(PIN_T2H, OUTPUT);
//  pinMode(PIN_CMD, INPUT);
//  pinMode(PIN_ERROR, OUTPUT);

//  set_data_dir(direction);
//  digitalWrite(PIN_T2H, my_t2h);
//  digitalWrite(PIN_ERROR, 0);

  status = SD.begin();

  Serial.println("Init SD card");
  Serial.print(status);

  if (status) {
     // recover flags from EEPROM storage
     cas_rd_eeprom();
  }
  else {
     // no SDcard present => cold boot,
     // re-initialise all NV variables in EEPROM
     Serial.println("Re-initialise non-volatile variables");
     cas_wr_eeprom();
  }


//  if (status) {
//    restore_state(1);
//  }

//  // wait until handshake from host is idle
//  while (0 != digitalRead(PIN_H2T)) {
//  }

  Serial.println("Start software serial");
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


  PRR  &= ~(1 << PRTIM1);                         // Ensure Timer1 is not disabled

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
  mySerial.println(" Hello NASCOM this is the Arduino");
  mySerial.println("R");
  // TODO - set up baud rate for external clock.

  Serial.println("End init sequence");
}


#ifdef SDEBUG
void loop() {
  // Make a decision about what we're going to do..
  //
  // - if a parallel command, get it and process it to completion
  // (existing get_value() waits for parallel command from host; need
  //  to replace/supplement that with a command that polls for a toggle)
  //
  // - if a serial char received and drive light is OFF, it's a serial
  //   command; get it and process it to completion.
  //
  // - if a serial char received and drive light is ON, it's a file save;
  //   grab the data and save it to the specified place.
  //
  // - if drive light is ON and has been on for a while (longer than it
  //   takes for write data to arrive and longer than it would be on if
  //   it was being toggled in order to play a tune(!!)), it's a file load;
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
        Serial.println("Cassette command");
        cmd_cass();
    }
    else {
        Serial.print("Cassette write with loop count ");
        Serial.println(drive_on);
        drive_on = 0;
        cmd_cass_wr();
    }
  }  
  else if (drive_on > 66000) {
    // File Load
    Serial.println("Cassette read");
    drive_on = 0;
    cmd_cass_rd();
  }
  // TODO check for parallel command
}
#endif


#ifdef DEBUG
// Simple test for read/write access to SD card. It all seems to work exactly as expected!
void loop() {
  buf[0] = 'A';
  buf[1] = '.';
  buf[2] = 'T';
  buf[3] = 'X';
  buf[4] = 'T';
  buf[5] = 0;
  handles[0] = SD.open(buf, FILE_WRITE);
  buf[0] = 'B';
  handles[1] = SD.open(buf, FILE_WRITE);
  buf[0] = 'C';
  handles[2] = SD.open(buf, FILE_WRITE);
  buf[0] = 'D';
  handles[3] = SD.open(buf, FILE_WRITE);
  buf[0] = 'X';
  handles[4] = SD.open(buf, FILE_READ);
  if (handles[0]) Serial.println("Open OK for A.TXT");
  if (handles[1]) Serial.println("Open OK for B.TXT");
  if (handles[2]) Serial.println("Open OK for C.TXT");
  if (handles[3]) Serial.println("Open OK for D.TXT");
  if (handles[4]) Serial.println("Open OK for X.TXT");
  // all of these will succeed except for X.TXT because
  // the others are all open for FILE_WRITE and so will create a file if it does not exist
  // X.TXT is open for FILE_READ. Since it does not exist it will fail.
  Serial.println("Finished open test");

  // Try reading first few bytes from each file
  for (int i=0; i<5; i++) {
    Serial.print("Read from file ");
    Serial.print(i);
    Serial.print(": ");
    handles[i].seek(0L);
    for (int j=0; j<16; j++) {
      Serial.write(handles[i].read());
    }
    Serial.println();
  }

  // Replace some bytes in A.TXT
  handles[0].seek(5L);
  handles[0].write('I');
  handles[0].write('S');
  handles[0].flush();

  // Try reading first few bytes from each file again
  for (int i=0; i<5; i++) {
    Serial.print("Read from file ");
    Serial.print(i);
    Serial.print(": ");
    handles[i].seek(0L);
    for (int j=0; j<16; j++) {
      Serial.write(handles[i].read());
    }
    Serial.println();
  }

  // Restore bytes in A.TXT
  handles[0].seek(5L);
  handles[0].write('i');
  handles[0].write('s');
  handles[0].flush();

  for (int i=0; i<5; i++) {
    handles[i].close();
  }

  // try some auto-generated file names
  // ..this is pretty slow. May want to restrict it to 100 files. BUT
  // there is no failure mechanism..
  for (int i=0; i<5; i++) {
    buf[0] = 0;
    auto_name(buf);
    Serial.println(buf);
    handles[0] = SD.open(buf, FILE_WRITE);
    if (handles[0]) {
      handles[0].write('x');
      handles[0].flush();
      handles[0].close();
    }
    else {
      Serial.print("Tried to open ");
      Serial.print(buf);
      Serial.println(" but open failed");
    }
  }
  while (1) {}
}

#else
// Each pass through loop handles 1 command to completion
// and leaves the Target set up as a receiver.
void zz_loop() {
  //Serial.println("Start command wait");

  int cmd_data = get_value();
  // Turn off the ERROR LED in anticipation
  digitalWrite(PIN_ERROR, 0);

  //Serial.print("Command ");
  //Serial.println(cmd_data,HEX);

  switch (cmd_data) {
    case 0x100 | CMD_NOP:
      break; // let Host decide that we're alive
    case 0x100 | CMD_RESTORE_STATE:
      cmd_restore_state();
      break;
    case 0x100 | CMD_SAVE_STATE:
      cmd_save_state();
      break;
    case 0x100 | CMD_LOOP:
      cmd_loop();
      break;
    case 0x100 | CMD_DIR:
      cmd_dir();
      break;
    case 0x100 | CMD_STATUS:
      cmd_status();
      break;
    case 0x100 | CMD_INFO:
      cmd_info();
      break;
    case 0x100 | CMD_STOP:
      cmd_stop();
      break;
    // These are command that accept a FID in bits [2:0]
    // This is cumbersome but should generate efficient code..
    case 0x100 | CMD_OPEN | 0:
    case 0x100 | CMD_OPEN | 1:
    case 0x100 | CMD_OPEN | 2:
    case 0x100 | CMD_OPEN | 3:
    case 0x100 | CMD_OPEN | 4:
    case 0x100 | CMD_OPEN | 5:
    case 0x100 | CMD_OPEN | 7:
      cmd_open(fid(cmd_data & 0x7), FILE_WRITE);
      break;
    case 0x100 | CMD_OPENR | 0:
    case 0x100 | CMD_OPENR | 1:
    case 0x100 | CMD_OPENR | 2:
    case 0x100 | CMD_OPENR | 3:
    case 0x100 | CMD_OPENR | 4:
    case 0x100 | CMD_OPENR | 5:
    case 0x100 | CMD_OPENR | 7:
      cmd_open(fid(cmd_data & 0x7), FILE_READ);
      break;
    case 0x100 | CMD_CLOSE | 0:
    case 0x100 | CMD_CLOSE | 1:
    case 0x100 | CMD_CLOSE | 2:
    case 0x100 | CMD_CLOSE | 3:
    case 0x100 | CMD_CLOSE | 4:
    case 0x100 | CMD_CLOSE | 5:
    case 0x100 | CMD_CLOSE | 7:
      cmd_close(fid(cmd_data & 0x7));
      break;
    case 0x100 | CMD_SEEK | 0:
    case 0x100 | CMD_SEEK | 1:
    case 0x100 | CMD_SEEK | 2:
    case 0x100 | CMD_SEEK | 3:
    case 0x100 | CMD_SEEK | 4:
    case 0x100 | CMD_SEEK | 5:
    case 0x100 | CMD_SEEK | 7:
      cmd_seek(fid(cmd_data & 0x7));
      break;
    case 0x100 | CMD_TS_SEEK | 0:
    case 0x100 | CMD_TS_SEEK | 1:
    case 0x100 | CMD_TS_SEEK | 2:
    case 0x100 | CMD_TS_SEEK | 3:
    case 0x100 | CMD_TS_SEEK | 4:
    case 0x100 | CMD_TS_SEEK | 5:
    case 0x100 | CMD_TS_SEEK | 7:
      cmd_ts_seek(fid(cmd_data & 0x7));
      break;
    case 0x100 | CMD_SECT_RD | 0:
    case 0x100 | CMD_SECT_RD | 1:
    case 0x100 | CMD_SECT_RD | 2:
    case 0x100 | CMD_SECT_RD | 3:
    case 0x100 | CMD_SECT_RD | 4:
    case 0x100 | CMD_SECT_RD | 5:
    case 0x100 | CMD_SECT_RD | 7:
      cmd_sect_rd(fid(cmd_data & 0x7));
      break;
    case 0x100 | CMD_SECT_WR | 0:
    case 0x100 | CMD_SECT_WR | 1:
    case 0x100 | CMD_SECT_WR | 2:
    case 0x100 | CMD_SECT_WR | 3:
    case 0x100 | CMD_SECT_WR | 4:
    case 0x100 | CMD_SECT_WR | 5:
    case 0x100 | CMD_SECT_WR | 7:
      cmd_sect_wr(fid(cmd_data & 0x7));
      break;
    case 0x100 | CMD_N_RD | 0:
    case 0x100 | CMD_N_RD | 1:
    case 0x100 | CMD_N_RD | 2:
    case 0x100 | CMD_N_RD | 3:
    case 0x100 | CMD_N_RD | 4:
    case 0x100 | CMD_N_RD | 5:
    case 0x100 | CMD_N_RD | 7:
      cmd_n_rd(fid(cmd_data & 0x7));
      break;
    case 0x100 | CMD_N_WR | 0:
    case 0x100 | CMD_N_WR | 1:
    case 0x100 | CMD_N_WR | 2:
    case 0x100 | CMD_N_WR | 3:
    case 0x100 | CMD_N_WR | 4:
    case 0x100 | CMD_N_WR | 5:
    case 0x100 | CMD_N_WR | 7:
      cmd_n_wr(fid(cmd_data & 0x7));
      break;
    case 0x100 | CMD_DEFAULT | 0:
    case 0x100 | CMD_DEFAULT | 1:
    case 0x100 | CMD_DEFAULT | 2:
    case 0x100 | CMD_DEFAULT | 3:
    case 0x100 | CMD_DEFAULT | 4:
    case 0x100 | CMD_DEFAULT | 5:
    case 0x100 | CMD_DEFAULT | 7:
      cmd_default(fid(cmd_data & 0x7));
      break;
    case 0x100 | CMD_SIZE | 0:
    case 0x100 | CMD_SIZE | 1:
    case 0x100 | CMD_SIZE | 2:
    case 0x100 | CMD_SIZE | 3:
    case 0x100 | CMD_SIZE | 4:
    case 0x100 | CMD_SIZE | 5:
    case 0x100 | CMD_SIZE | 7:
      cmd_size(fid(cmd_data & 0x7));
      break;
    case 0x100 | CMD_SIZE_RD | 0:
    case 0x100 | CMD_SIZE_RD | 1:
    case 0x100 | CMD_SIZE_RD | 2:
    case 0x100 | CMD_SIZE_RD | 3:
    case 0x100 | CMD_SIZE_RD | 4:
    case 0x100 | CMD_SIZE_RD | 5:
    case 0x100 | CMD_SIZE_RD | 7:
      cmd_size_rd(fid(cmd_data & 0x7));
      break;
    default:
      // Not a command or not a recognised command.
      // Light the ERROR LED.
      digitalWrite(PIN_ERROR, 1);
      break;
  }
}
#endif

////////////////////////////////////////////////////////////////
// Stuff that waggles pins

// wait until incoming handshake differs from our value. During
// transfers initiated by the Host (cmd/parameters/data and got2h)
// it's an indication that we need to do something.
void wait4_hs_differ(void) {
  while (my_t2h == digitalRead(PIN_H2T)) {
  }
}


// wait until incoming handshake matches from our value. During
// transfers initiated by the Target (us) (response/data/goh2t)
// it's an indication that the transfer we initiated has been
// acknowledged by the host.
void wait4_hs_match(void) {
  while (my_t2h != digitalRead(PIN_H2T)) {
  }
}


// set outgoing handshake equal to incoming handshake. During transfers
// initiated by the Host this is the Target indicating that it is done.
// During transactions initiated by the Target this is how the Target
// initiates the transfer.
// Theoretically we don't need to read the other handshake, we can rely
// on our own copy. However, it seems more robust to do it like this.
void set_hs_match(void) {
  my_t2h = digitalRead(PIN_H2T);
  digitalWrite(PIN_T2H, my_t2h);
}


// set outgoing handshake as inverse of incoming handshake. This is how WOT
// the Target (us) initiates a transfer
// theoretically we don't need to read the other handshake, we can rely
// on our own copy. However, it seems more robust to do it like this.
void set_hs_differ(void) {
  my_t2h = 1 ^ digitalRead(PIN_H2T);
  digitalWrite(PIN_T2H, my_t2h);
}


// wait for a valid 9-bit value from the Host. Grab it and ack it.
// msb is command bit
// TODO lots of places where this is called it is assumed to be a data
// byte (ie, bit8=0). Maybe should check this (eg by adding a parameter)
// and erroring/recovering if it's not.
unsigned int get_value(void) {
  int value;

  wait4_hs_differ(); // See initiation from Host
  value = (digitalRead(PIN_CMD) << 8) |
  (digitalRead(PIN_XD7) << 7) | (digitalRead(PIN_XD6) << 6) | (digitalRead(PIN_XD5) << 5) | (digitalRead(PIN_XD4) << 4) |
  (digitalRead(PIN_XD3) << 3) | (digitalRead(PIN_XD2) << 2) | (digitalRead(PIN_XD1) << 1) | (digitalRead(PIN_XD0));
  set_hs_match(); // Ack to Host
  return value;
}


// put a data byte from target to the host.
// If global direction==INPUT, do a bus turn-around first.
// Argument final_direction controls whether to do a turn-around
// at the end: if final_direction==INPUT, do a bus turn-around
// at the end.
void put_value(unsigned char val, char final_direction) {
  if (direction == INPUT) {
    // Start of GoT2H cell. Start with handshakes match, end with handshakes differ
    wait4_hs_differ(); // See initiation from Host
    direction = OUTPUT;
    set_data_dir(direction);
  }

  // Start of Target->Host cell. Start and end with handshakes differ
  digitalWrite(PIN_XD7, 1 & (val>>7));
  digitalWrite(PIN_XD6, 1 & (val>>6));
  digitalWrite(PIN_XD5, 1 & (val>>5));
  digitalWrite(PIN_XD4, 1 & (val>>4));
  digitalWrite(PIN_XD3, 1 & (val>>3));
  digitalWrite(PIN_XD2, 1 & (val>>2));
  digitalWrite(PIN_XD1, 1 & (val>>1));
  digitalWrite(PIN_XD0, 1 & (val>>0));

  set_hs_match(); // Initiate
  wait4_hs_differ(); // See ack from Host
  if (final_direction == INPUT) {
    // Start of GoH2T cell. Start with handshakes differ, end with handshakes match.
    direction = INPUT;
    set_data_dir(direction);
    set_hs_match();
  }
}


////////////////////////////////////////////////////////////////
// Miscellaneous helpers

// given a fid, see wherher it references the default fid and,
// if so, replace it
char fid(char fid) {
  return (fid == 7) ? default_fid : fid;
}


// if buffer is empty, auto-create the next unused name
// of the form NASxxx.BIN
// By using next_file as a hint we only have to do the (slow)
// search for the first free file once per boot.
void auto_name(char *buffer) {
  if (buffer[0] == 0) {
    buffer[0] = 'N';
    buffer[1] = 'A';
    buffer[2] = 'S';
    buffer[6] = '.';
    buffer[7] = 'B';
    buffer[8] = 'I';
    buffer[9] = 'N';
    buffer[10] = 0;
    while (next_file<1000) {
      buffer[3] = '0' + int(next_file/100);
      buffer[4] = '0' + ((int(next_file/10)) %10);
      buffer[5] = '0' + (next_file %10);
      next_file++;
      if (! SD.exists(buffer)) {
        // does not exist; just what we're looking for
        return;
      }
      // give up. File open will fail.
    }
  }
}


// get a null-terminated string from the host. If necessary,
// truncate it at the buffer size.
// If string is 0-length, auto-generate a name of the
// form NASxxx.BIN
// ASSUME: direction is INPUT
void get_filename(char *buffer) {
  int index = 0;
  char val;

  while (1) {
    val = get_value();
    buffer[index++] = val;
    if ((val == 0) | (index == BUFFER)) {

      // truncate the string in the case where the buffer is
      // full. Redundant if the buffer is not full or if the
      // buffer is exactly full (in which case, val==0)
      buffer[BUFFER-1] = 0;
      auto_name(buffer);
      Serial.println(buffer);
      return;
    }
  }
}


// Get a 32-bit value from the host.
long get_value32(void) {
  long offset;

  offset = (long)get_value();
  offset = offset | ((long)get_value() << 8);
  offset = offset | ((long)get_value() << 16);
  offset = offset | ((long)get_value() << 24);
  return offset;
}


// set direction to OUTPUT (T2H) or INPUT (H2T)
void set_data_dir(int my_dir) {
  pinMode(PIN_XD7, my_dir);
  pinMode(PIN_XD6, my_dir);
  pinMode(PIN_XD5, my_dir);
  pinMode(PIN_XD4, my_dir);
  pinMode(PIN_XD3, my_dir);
  pinMode(PIN_XD2, my_dir);
  pinMode(PIN_XD1, my_dir);
  pinMode(PIN_XD0, my_dir);
}


////////////////////////////////////////////////////////////////
// Commands

// try to restore configuration from saved file.
// TRUE if file was found and read successfully.
//
// RESPONSE: sends TRUE or FALSE response to host. Updates global status
void cmd_restore_state(void) {
  status = restore_state(0);
  put_value(status, INPUT);
}


// helper.
// try to restore configuration from saved file.
// if auto=0 restore if file exists
// if auto=1 restore if file exists AND auto flag in file is 1
//
// return TRUE if file exists and readable
// return FALSE otherwise
int restore_state(int auto_restore) {
  Serial.println("TODO restore_state");

  // TODO for now, just attempt to load DSK0.BIN etc.
  buf[0] = 'D';
  buf[1] = 'S';
  buf[2] = 'K';
  buf[3] = '0';
  buf[4] = '.';
  buf[5] = 'B';
  buf[6] = 'I';
  buf[7] = 'N';
  buf[8] = 0;
  handles[0] = SD.open(buf, FILE_WRITE);
  buf[3] = '1';
  handles[1] = SD.open(buf, FILE_WRITE);
  buf[3] = '2';
  handles[2] = SD.open(buf, FILE_WRITE);
  buf[3] = '3';
  handles[3] = SD.open(buf, FILE_WRITE);
  return 1;
}

// save configuration to file
// create file if it does not exist, overwrite it if it does exist
//
// first byte is flags:
// 7   auto
// 6  RESERVED
// 5  RESERVED
// 4  file4  - raw file
// 3  file3  - drive 3 file
// 2  file2  - drive 2 file
// 1  file1  - drive 1 file
// 0  file0  - drive 0 file
//
// next 3 bytes are RESERVED
// rest of file is set of null-terminated strings
// one string for each bit set in flags[4:0]
// string for flags[0] is first.
// Each string is a file-name, relative to root
//
// RESPONSE: sends TRUE or FALSE response to host. Updates global status
void cmd_save_state(void) {
  Serial.println("TODO cmd_save_state");
  put_value(1, INPUT);
}


// Accept 1 byte and send back the 1s complement as
// a response; used for testing the link
//
// RESPONSE: 1 byte. Does not update global status
void cmd_loop(void) {
  put_value(0xff ^ get_value(), INPUT);
}


// Report directory listing as formatted string
// terminated with NUL (0x00)
//
// RESPONSE: NUL-terminated string. Does not update global status
void cmd_dir(void) {
  File root = SD.open("/");
  root.rewindDirectory();
  File entry;

  while (entry = root.openNextFile()) {
    int len = 15;
    char * name = entry.name();
    while (*name != 0) {
      put_value(*name++, OUTPUT);
      len--;
    }

    if (entry.isDirectory()) {
      put_value('/', OUTPUT);
    }
    else {
      // Print file size in bytes. Max file size is 2gb ie 10 digits
      int pad=0;
      long i=1000000000;
      long n = entry.size();
      long dig;

      while (len > 0) {
        put_value(' ', OUTPUT);
        len--;
      }

      while (i > 0) {
        dig = n/i; // integer division with truncation
        n = n % i; // remainder
        if ((dig > 0) | (pad==1) | (i==1)) {
            pad = 1;
            put_value('0'+dig, OUTPUT);
        }
        else {
            put_value(' ', OUTPUT);
        }
        i = i/10;
      }
      put_value(' ', OUTPUT);
      put_value('b', OUTPUT);
      put_value('y', OUTPUT);
      put_value('t', OUTPUT);
      put_value('e', OUTPUT);
      put_value('s', OUTPUT);
    }
    put_value(0x0d, OUTPUT);
    put_value(0x0a, OUTPUT);
    entry.close();
  }
  // Tidy up and finish
  put_value(0,INPUT);
  root.close();
  return;
}


// Report files assigned to each FID as formatted string
// terminated with NUL (0x00)
//
// RESPONSE: NUL-terminated string. Does not update global status
void cmd_info(void) {
  Serial.println("Info");
  for (int i=0; i<5; i++) {
    put_value(0x30 + i,OUTPUT);
    put_value(':',OUTPUT);
    put_value(' ',OUTPUT);
    Serial.print(i);
    Serial.print(": ");
    if (handles[i]) {
      char * name = handles[i].name();
      while (*name != 0) {
        Serial.print(*name);
        put_value(*name++, OUTPUT);
      }
    }
    else {
      put_value('-',OUTPUT);
      Serial.print('-');
    }
    Serial.println();
    put_value(0x0d,OUTPUT);
    put_value(0x0a,OUTPUT);
  }
  put_value(0,INPUT);
}


// Switch all ports that are connected to the NASCOM to be inputs
// (benign) then go into a tight loop doing nothing forever.
//
// RESPONSE: none.
void cmd_stop(void) {
  set_data_dir(INPUT);
  pinMode(PIN_H2T, INPUT);
  pinMode(PIN_T2H, INPUT);
  pinMode(PIN_CMD, INPUT);
  pinMode(PIN_ERROR, INPUT);
  Serial.println("cmd_stop - wait for reset");
  while (1) {
  }
}


// Close file
//
// RESPONSE: none. Does not update global status
void cmd_close(char fid) {
  if (handles[fid]) {
    // file handle is currently in use
    handles[fid].close();
  }
}


// Receive null-terminated filename from host.
// Magic: if filename is 0-bytes, auto-generate a
// name of the form NASxxx.BIN where xxx is a number
// 000, 001 etc.
//
// close any existing file using this fid
// attempt to open file
// FILE_READ - error if file does not exist. FID
// is left unused.
// FILE_WRITE - seek to start of file
//
// RESPONSE: sends TRUE on success (fid is now associated
// with a file) or FALSE on error (fid is now unused)
// Updates global status
void cmd_open(char fid, int mode) {
  status = 0;

  get_filename(buf);

  if (handles[fid]) {
    // file handle is currently in use
    handles[fid].close();
  }

  handles[fid] = SD.open(buf, mode);
  if (handles[fid]) {
    status = handles[fid].seek(0);
  }

  put_value(status, INPUT);
}


// Get 2 bytes from host
// - track
// - sector
// seek drive specified by fid to the appropriate place
// success: drive is ready to rd/wr, send response TRUE
// fail: send response FALSE
//
// RESPONSE: sends TRUE or FALSE response to host. Updates global status
void cmd_ts_seek(char fid) {
  status = 0;
  int track = get_value();
  int sector = get_value();
  if (handles[fid]) {
//    Serial.print("Seek to track ");
//    Serial.print(track,HEX);
//    Serial.print(" sector" );
//    Serial.println(sector,HEX);
    long offset = ((long)SECTORS_PER_TRACK * (long)track + (long)sector) * (long)BYTES_PER_SECTOR;
    status = handles[fid].seek(offset);
  }
  else {
    Serial.print("Seek to track but no disk");
  }
  put_value(status, INPUT);
}


// Get 4 bytes from host (LSByte first) used as offset into file.
// seek drive specified by fid to the appropriate place
// success: drive is ready to rd/wr, send response TRUE
// fail: send response FALSE
//
// RESPONSE: sends TRUE or FALSE response to host. Updates global status
void cmd_seek(char fid) {
  status = 0;

  if (handles[fid]) {
    status = handles[fid].seek(get_value32());
  }
  put_value(status, INPUT);
}


// Helper for cmd_n_wr(), cmd_sect_wr()
void n_wr(char fid, long count) {
  long written = 0L;
  status = 0;

//  Serial.print("Write byte count ");
//  Serial.println(count,HEX);

  if (handles[fid]) {
     for (long i = 0L; i< count; i++) {
      written = written + handles[fid].write(get_value());
     }
     status = written == count;
     // polite and rugged to do this
     handles[fid].flush();
  }
  else {
     for (long i = 0L; i< count; i++) {
       get_value(); // need this NOT to get optimised away
     }
  }
  put_value(status, INPUT);
}


// Get 4 bytes from the host (byte count N, ls byte first)
// do write of N bytes on file specified by fid
// assume drive is at correct place!
//
// RESPONSE: send TRUE or FALSE response to host. Updates global status
void cmd_n_wr(char fid) {
  Serial.println("CMD_N_WR");
  n_wr(fid, get_value32());
}


// do write of 1 sector of bytes on file specified by fid
// assume drive is at correct place!
//
// RESPONSE: send TRUE or FALSE response to host. Updates global status
void cmd_sect_wr(char fid) {
  n_wr(fid, BYTES_PER_SECTOR);
}


// helper for cmd_n_rd(), cmd_sect_rd(), cmd_size_rd()
void n_rd(char fid, long count) {
  status = 0;

//  Serial.print("Read for fid ");
//  Serial.print(fid,HEX);
//  Serial.print(" and byte count ");
//  Serial.println(count,HEX);

  if (handles[fid]) {
    for (long i = 0L; i< count; i++) {
      // TODO should check for -1
      // TODO probably better.. much faster.. to pass a buffer.
      put_value(handles[fid].read(), OUTPUT);
    }
    status = 1;
  }
  else {
    for (long i = 0L; i< count; i++) {
      put_value(0, OUTPUT);
    }
  }
  put_value(status, INPUT);
}


// get 4 bytes from the host (byte count N)
// do read of N bytes on drive specified by fid
// assume drive is at correct place!
//
// RESPONSE: sends TRUE or FALSE response to host. Updates global status
void cmd_n_rd(char fid) {
  n_rd(fid, get_value32());
}


// do read of 1 sector on drive specified by fid
// assume drive is at correct place!
//
// RESPONSE: sends TRUE or FALSE response to host. Updates global status
void cmd_sect_rd(char fid) {
  n_rd(fid, BYTES_PER_SECTOR);
}


// return global status from most recent routine that updated it. The
// global status is not changed by the execution of this command.
//
// RESPONSE: sends TRUE or FALSE to host - value of global status
// from most recent command that updates it
void cmd_status(void) {
  put_value(status, INPUT);
}


// set the default file - used by OPEND etc.
//
// RESPONSE: none.
void cmd_default(char fid) {
  default_fid = fid;
}


// read the file size
//
// RESPONSE: 4 bytes (file size, LS byte first),
// followed by 1 status byte.
void cmd_size(char fid) {
   long size = handles[fid].size();
   put_value( size        & 0xff, OUTPUT);
   put_value((size >> 8)  & 0xff, OUTPUT);
   put_value((size >> 16) & 0xff, OUTPUT);
   put_value((size >> 24) & 0xff, OUTPUT);
   put_value(0, INPUT); // TODO get status
}


// read whole file. Assume file is rewound (eg, has just
// been opened, or has received a seek(0)).
//
// RESPONSE: 4 bytes (file size, LS byte first) followed
// by all the bytes of the file, in order, followed by 1
// status byte.
void cmd_size_rd(char fid) {
   long size = handles[fid].size();
   put_value( size        & 0xff, OUTPUT);
   put_value((size >> 8)  & 0xff, OUTPUT);
   put_value((size >> 16) & 0xff, OUTPUT);
   put_value((size >> 24) & 0xff, OUTPUT);
   n_rd(fid, size);
}



///////////////////////////////////////////// Serial stuff

// Use an argument (or lack thereof) to set/clear or toggle a flag.
// buffer is null-terminated.
// parse the buffer. Skip a command delimited by space. Look for 1st character
// of argument.
// No argument:                          return current with bit_mask toggled
// 1st character of argument is ASCII 0: return current with bit_mask cleared
// 1st character of argument is ASCII 1: return current with bit_mask set
// any other argument:                   return current unchanged
int cas_gen_flag(char *buffer, int current, int bit_mask) {
  int index = 0;
  char val;

  // 0 -> skip command (non white-space) looking for white-space
  // 1 -> skip white-space looking for argument)
  int state = 0;
  while (val = buffer[index++]) {
    if ((state == 0) && (val == ' ')) {
      state = 1;
    }
    else if ((state == 1) && (val != ' ')) {
      if (val == '0') { return current & ~bit_mask; }
      if (val == '1') { return current |  bit_mask; }
      // illegal argument; flag unchanged
      return current;
    }
  }
  // ran out of buffer: toggle flag
  return current ^ bit_mask;
}


// Extract a 16-bit number from the command line.
// buffer is null-terminated.
// parse the buffer. Skip a command delimited by a space. Expect a hex
// string of 1-4 characters. Convert to a 16-bit binary number. If more
// than 4 characters are present, continue parsing, so that the last
// 4 are used. If no argument is present or an illegal character is
// present, return 0.
// TODO return 0 as error indicator is not wonderful, but works for
// the one use-case here because we expect a RAM address and there
// is no RAM at 0.
int cas_parse_hex(char *buffer) {
  int arg = 0;
  int index = 0;
  char val;

  // 0 -> skip command (non white-space) looking for white-space
  // 1 -> skip white-space looking for argument)
  // 2 -> processing argument
  int state = 0;
  while (val = buffer[index++]) {
    if ((state == 0) && (val == ' ')) {
      state = 1;
    }
    else if (((state == 1) && (val != ' ')) || (state == 2)) {
      state = 2;

      if ((val >= '0') && (val <= '9')) {
         arg = (arg << 4) | (val - '0');
      }
      else if ((val >= 'A') && (val <= 'F')) {
         arg = (arg << 4) | (val - 'A' + 10);
      }
      else {
         Serial.print("Error on cas_parse_hex with ");
         Serial.println(val);
         return 0;
      }
    }
  }
  // ran out of buffer
  return arg;
}


// Come here when DRIVE is off and there is a serial character available. Infer that a
// nul-terminated string is going to be delivered. Receive the string into a buffer
// and process it to completion -- for example, by setting up state that will be used
// subsequently.
void cmd_cass(void) {
  char buf [48];
  int index = 0;
  int cmd = 0;
  Serial.println("Get command line");
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
  Serial.print("Received command line of ");
  Serial.print(index);
  Serial.println(" characters");

  // BUG what if only 1 character.. ought to work (the 2nd char is a NULL) but does it??
  // if only 1 charcater it never gets to here.. TODO bug in HOST program.

  // TODO handle upper and lower case - eg, by converting command codes to upper
  cmd = (buf[0] << 8) | buf[1];
  switch (cmd) {

    // There is not enough space for the help text. Maybe store it in FLASH
    // and print it character by character?
    case ('H'<<8 | 'E'):      // HELP
      Serial.println("Help");
      mySerial.write(0xff); // indicate that message is coming

      mySerial.println("INFO HELP");
      mySerial.println("RI WI");
      mySerial.println("RV WV <file>");
      mySerial.println("RF <file>");
      mySerial.println("RC WC <file>");
      mySerial.println("VD <file>");
      mySerial.println("AE");
      mySerial.println("AG");
      mySerial.println("BH");
      mySerial.println(".");              // handled in the Host
      mySerial.println("EC80");           // handled in the Host
      mySerial.println("TO xxxx");
      mySerial.println("SP n");
      break;

    case ('I'<<8 | 'N'):      // INFO
      Serial.println("Info");
      mySerial.write(0xff); // indicate that message is coming
      mySerial.println("This is NASCOM_SDCARD version X.X");
      mySerial.print("Flags: 0x");
      mySerial.println(cas_flags, HEX);
      break;

    case ('R'<<8 | 'I'):
      Serial.println("Read-increment");
      cas_flags = cas_gen_flag(buf, cas_flags, F_NV_RD_INC);
      cas_rd_num = 0;
      break;

    case ('W'<<8 | 'I'):
      Serial.println("Write-increment");
      cas_flags = cas_gen_flag(buf, cas_flags, F_NV_WR_INC);
      cas_wr_num = 0;
      break;

//TODO RV WV
//TODO RF
//TODO RC WC
//TODO VD

    case ('A'<<8 | 'E'):
      Serial.println("Auto-exec");
      cas_flags = cas_gen_flag(buf, cas_flags, F_NV_AUTO_EXEC);
      break;

    case ('A'<<8 | 'G'):
      Serial.println("Auto-go");
      cas_flags = cas_gen_flag(buf, cas_flags, F_NV_AUTO_GO);
      break;

    case ('B'<<8 | 'H'):
      Serial.println("Basic header");
      cas_flags = cas_gen_flag(buf, cas_flags, F_NV_BASIC_HDR);
      break;

    // TODO need a routine to pick up a file name
    // then everything else sets a flag (source) and picks/stores a specific file name
    // maybe best to store the filenames in a specific 2D 3 x *8+1+3) array
    // so it's easy to point to it.


    // TODO -- only accepts UPPER CASE HEX
    case ('T'<<8 | 'O'):
      int destination;
      destination = cas_parse_hex(buf);
      if (destination) {
        mySerial.write((byte)0x55); // indicate that relocation will occur
        mySerial.write((byte)(destination & 0xff));      // low part
        mySerial.write((byte)((destination>>8) & 0xff)); // high
        Serial.print("TO (relocate) to 0x");
        Serial.println(destination, HEX);
        // break from here will result in an unneeded NULL being sent but
        // that is not a problem because the Host is in ZINLIN (either from
        // the NAS-SYS or the SDCard command loops) which accepts data from
        // from serial or keyboard and will simply gobble and discard NULLs.        
      }
      else {
        // bad argument
        Serial.print("TO (relocate) with bad argument");
      }
      break;


// TODO SPeed command




    // TODO need to replace this.. the RF should do the same thing but implies that we have a "catalog"
    // for the flash files that we can search..

    case ('N'<<8 | 'E'):
      Serial.println("Next Flash file");
      wotfile++;
      mySerial.write(0xff); // indicate that message is coming
      break;


    default:
      mySerial.write(0xff); // indicate that message is coming
      mySerial.println("Error - try typing HELP");
  }



  // Send response "done"
  mySerial.write((byte)0x00);
}


// Respond to a cassette "R"ead command.
// For now, this just means delivering a file (from on-chip ROM) selected by wotfile - converting
// it on-the-fly from binary to CAS format - then waiting for DRIVE to go off.
void cmd_cass_rd() {
  int remain;// total number of data bytes left to send
  int addr;  // initial address of file to send
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
  addr = ROMS[wotfile*4 + 2];
  remain = ROMS[wotfile*4 + 1];




  index = 0;
  // total number of blocks needed to send remain bytes
  block = ((remain + 0xff) & 0xff00) >> 8;

  while (block != 0) {
    block--;  // the new block number
    Serial.print("Send block ");
    Serial.println(block);
    Serial.print("Remain ");
    Serial.println(remain);
    // output sync pattern
    mySerial.write((byte)0x00);
    mySerial.write((byte)0xff);
    mySerial.write((byte)0xff);
    mySerial.write((byte)0xff);
    mySerial.write((byte)0xff);
    Serial.print("nulls done ");
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
    Serial.print("header done ");
    // output block body
    csum = 0;
    while (count !=0) {
      csum = csum + pgm_read_byte(ROMS[wotfile*4] + (int)(index));
      mySerial.write(pgm_read_byte(ROMS[wotfile*4] + (int)(index)));

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

  Serial.println("wait for DRIVE=1..");

  // wait for pin to negate
  while (digitalRead(PIN_DRV) == 0) { }
  Serial.println("DONE.");
  if (cas_flags & F_NV_AUTO_GO) {
    mySerial.print("E");
    mySerial.println(ROMS[wotfile*4+3], HEX);
  }
}


// Respond to a write. For now, this just means waiting for DRIVE to go off then emptying any received/buffered data
void cmd_cass_wr(void) {
  Serial.println("wait for DRIVE=1..");

  // wait for pin to negate
  while (digitalRead(PIN_DRV) == 0) { }


  while (mySerial.available()) {
    mySerial.read();
  }
  
  Serial.println("DONE.");
}


// store non-volatile variables in eeprom
void cas_wr_eeprom(void) {
  int i;
  EEPROM.update(0, cas_flags & 0xff);
  EEPROM.update(1, cas_flags >> 8);
  EEPROM.update(2, cas_speed & 0xff);
  EEPROM.update(3, cas_speed >> 8);
  for (i=0; i<12; i++) {
    // if name is 8.3 then there is a NULL on the end that we need not copy.
    // if they are shorter then there is a NULL somewhere and maybe junk
    // characters afterwards.
    EEPROM.update(4+i, cas_rd_name[i]);
    EEPROM.update(4+12+i, cas_wr_name[i]);
  }
}

// recover non-volatile variables from eeprom
void cas_rd_eeprom(void) {
    int i;
    cas_flags  = EEPROM.read(0);
    cas_flags |= EEPROM.read(1) << 8;
    cas_speed  = EEPROM.read(2);
    cas_speed |= EEPROM.read(3) << 8;
    for (i=0; i<12; i++) {
        cas_rd_name[i] = EEPROM.read(4+i);
        cas_wr_name[i] = EEPROM.read(4+12+i);
    }
}
