// nascom_sdcard
//
// ARDUINO connected to NASCOM 2 PIO to act as mass-storage
// device for the purposes of:
// - dumping data from the NASCOM
// - providing virtual floppy disk capability
// - (maybe/future) providing virtual ".NAS" and ".CAS" support
//
// Virtual floppy capability would work in conjunction with a
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
// 5  SCK                  DIG13  (also on-board LED)
// 6  CS                   DIG10
//
// 2/ connection to NASCOM via 26-way ribbon
//
// Name   Direction   ARDUINO   NASCOM
// -----------------------------------
// T2H    OUT          ANA1     B0 (pin 10)
// H2T    IN           ANA0     B1 (pin 8)
// CMD    IN           ANA4     B2 (pin 6)
// XD7    IN/OUT       DIG9     A7 (pin 24)
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
// 3/ connection to LED
//
// Name   Direction   ARDUINO   Notes
// -----------------------------------
// ERROR  OUT         A2        To LED. Other end of LED via resistor to GND
//
/////////////////////////////////////////////////////
// PROTOCOL
//
// The NASCOM acts as the Host and the Arduino acts as the Target. The
// protocol uses a handshake in each direction. There are 5 different
// signalling patterns:
//
// 1a/ send command byte from Host to Target
// 1b/ send data byte from Host to Target
// 2/  send data byte from Target to Host
// 3/ change bus direction from Host driving to Target driving
// 4/ change bus direction from Target driving to Host driving
//
// After reset, the Host is driving data to the Target. H2T is low, T2H is low,
// CMD is undefined.
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
// can run at any speed down to DC.
// - For patterns where the Host is driving the bus, the idle state of
//   the handshakes is that they match.
// - For patterns where the Targer is driving the bus, the idle state of
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
// COMMANDS
//
// Work them out from the comments or refer to separate document
//
/////////////////////////////////////////////////////



// TODO set geometry command to allow different disk types to be mixed?
// TODO implement restore_state
// TODO implement save_state
// TODO implement cmd_dir
// TODO do error checking in n_rd

// For testing
//#define DEBUG


/////////////////////////////////////////////////////
// Pin assignments
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
// Commands

#define CMD_NOP           (0x80)
#define CMD_RESTORE_STATE (0x81)
#define CMD_SAVE_STATE    (0x82)
#define CMD_LOOP          (0x83)
#define CMD_DIR           (0x84)
#define CMD_STATUS        (0x85)

#define CMD_OPEN0 (0x10)
#define CMD_OPEN1 (0x11)
#define CMD_OPEN2 (0x12)
#define CMD_OPEN3 (0x13)
#define CMD_OPEN4 (0x14)
// 0x15-0x17 RESERVED
#define CMD_CLOSE0 (0x18)
#define CMD_CLOSE1 (0x19)
#define CMD_CLOSE2 (0x1a)
#define CMD_CLOSE3 (0x1b)
#define CMD_CLOSE4 (0x1c)
#define CMD_CLOSED (0x1f)
// 0x1d-0x1e RESERVED
#define CMD_SEEK0  (0x20)
#define CMD_SEEK1  (0x21)
#define CMD_SEEK2  (0x22)
#define CMD_SEEK3  (0x23)
#define CMD_SEEK4  (0x24)
#define CMD_SEEKD  (0x27)
// 0x25-0x26 RESERVED
#define CMD_TS_SEEK0  (0x28)
#define CMD_TS_SEEK1  (0x29)
#define CMD_TS_SEEK2  (0x2a)
#define CMD_TS_SEEK3  (0x2b)
#define CMD_TS_SEEK4  (0x2c)
#define CMD_TS_SEEKD  (0x2f)
// 0x2d-0x2e RESERVED
#define CMD_SECT_RD0  (0x30)
#define CMD_SECT_RD1  (0x31)
#define CMD_SECT_RD2  (0x32)
#define CMD_SECT_RD3  (0x33)
#define CMD_SECT_RD4  (0x34)
#define CMD_SECT_RDD  (0x37)
// 0x35-0x36 RESERVED
#define CMD_N_RD0     (0x38)
#define CMD_N_RD1     (0x39)
#define CMD_N_RD2     (0x3a)
#define CMD_N_RD3     (0x3b)
#define CMD_N_RD4     (0x3c)
#define CMD_N_RDD     (0x3f)
// 0x3d-0x3e RESERVED
#define CMD_SECT_WR0  (0x40)
#define CMD_SECT_WR1  (0x41)
#define CMD_SECT_WR2  (0x42)
#define CMD_SECT_WR3  (0x43)
#define CMD_SECT_WR4  (0x44)
#define CMD_SECT_WRD  (0x47)
// 0x45-0x46 RESERVED
#define CMD_N_WR0     (0x48)
#define CMD_N_WR1     (0x49)
#define CMD_N_WR2     (0x4a)
#define CMD_N_WR3     (0x4b)
#define CMD_N_WR4     (0x4c)
#define CMD_N_WRD     (0x4f)
// 0x4d-0x4e RESERVED
#define CMD_DEFAULT0  (0x50)
#define CMD_DEFAULT1  (0x51)
#define CMD_DEFAULT2  (0x52)
#define CMD_DEFAULT3  (0x53)
#define CMD_DEFAULT4  (0x54)
// 0x55-0x5f RESERVED
#define CMD_SIZE0     (0x58)
#define CMD_SIZE1     (0x59)
#define CMD_SIZE2     (0x5a)
#define CMD_SIZE3     (0x5b)
#define CMD_SIZE4     (0x5c)
#define CMD_SIZED     (0x5f)
// 0x5d-0x5e RESERVED
#define CMD_SIZE_RD0  (0x60)
#define CMD_SIZE_RD1  (0x61)
#define CMD_SIZE_RD2  (0x62)
#define CMD_SIZE_RD3  (0x63)
#define CMD_SIZE_RD4  (0x64)
#define CMD_SIZE_RDD  (0x67)
// 0x64-0x66 RESERVED

/////////////////////////////////////////////////////

// Filename for state save/restore
#define STATE_FILE "NASCOM.SD"

// Number of bytes available
#define BUFFER (128)

// Which files have known names and exist
#define FLAG_RAW (0x10)
#define FLAG_DRV3 (0x08)
#define FLAG_DRV2 (0x04)
#define FLAG_DRV1 (0x02)
#define FLAG_DRV0 (0x01)

// Constants for converting track/sector/side to offset
// TODO maybe have "set geometry"?
// These are correct for the version of PolyDos I'm running on jsnascom
// but may be wrong for the version on my actual NASCOM
// also, not sure how 2 sides are handled.. by doubling the tracks or otherwise?
#define SECTORS_PER_TRACK (18)
#define BYTES_PER_SECTOR (256)
#define TRACKS (80)


#include <SD.h>

// Prototypes
void set_data_dir(int my_dir);
int restore_state(int auto_restore);
unsigned int get_value(void);
char fid(char fid);
//
void cmd_default(char fid);
void cmd_open(char fid);
void cmd_close(char fid);
void cmd_save_state(void);
void cmd_restore_state(void);
void cmd_dir(void);
void cmd_loop(void);
void cmd_seek(char fid);
void cmd_ts_seek(char fid);
void cmd_status(void);
void cmd_sect_rd(char fid);
void cmd_sect_wr(char fid);
void cmd_n_rd(char fid);
void cmd_n_wr(char fid);
void cmd_size(char fid);
void cmd_size_rd(char fid);

// hint of next number to use when auto-generating file names
int next_file;

// default file ID
char default_fid;

// status of most recent command
int status;

// Work with upto 5 files. Low bits indicate which are valid/open
char flags;
File handles[5];

// Buffer for accumulating string from host
// BUFFER chars are available, 0..BUFFER-1
// but string is null-terminated which takes up 1 char.
char buf[BUFFER];

// Protocol bit
int my_t2h;

// INPUT when receiving data OUTPUT when sending data
char direction;

void setup()   {
  Serial.begin(115200);  // for Debug

  flags = 0;
  buf[0] = 0;
  my_t2h = 0;
  next_file = 0;
  direction = INPUT;

  // H2T, T2H, CMD have fixed direction
  pinMode(PIN_H2T, INPUT);
  pinMode(PIN_T2H, OUTPUT);
  pinMode(PIN_CMD, INPUT);
  pinMode(PIN_ERROR, OUTPUT);

  set_data_dir(direction);
  digitalWrite(PIN_T2H, my_t2h);
  digitalWrite(PIN_ERROR, 0);

  status = SD.begin();

  Serial.println("Init SD card");
  Serial.print(status);

  if (status) {
    restore_state(1);
  }

  // wait until handshake from host is idle
  while (0 != digitalRead(PIN_H2T)) {
  }

  Serial.println("Start command loop");
}

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
void loop() {
  int cmd_data = get_value();

  // Blip LED (too short to see) each command, leave it ON for error
  digitalWrite(PIN_ERROR, 1);
  if (cmd_data & 0x100) {
    digitalWrite(PIN_ERROR, 0);
    switch (cmd_data & 0xff) {
     case CMD_NOP:
       break; // let Host decide that we're alive
     case CMD_OPEN0:
     case CMD_OPEN1:
     case CMD_OPEN2:
     case CMD_OPEN3:
     case CMD_OPEN4:
       cmd_open(cmd_data & 0x7);
       break;
     case CMD_CLOSE0:
     case CMD_CLOSE1:
     case CMD_CLOSE2:
     case CMD_CLOSE3:
     case CMD_CLOSE4:
     case CMD_CLOSED:
       cmd_close(fid(cmd_data & 0x7));
       break;
     case CMD_SAVE_STATE:
       cmd_save_state();
       break;
     case CMD_RESTORE_STATE:
       cmd_restore_state();
       break;
     case CMD_DIR:
       cmd_dir();
       break;
     case CMD_LOOP:
       cmd_loop();
       break;
     case CMD_SEEK0:
     case CMD_SEEK1:
     case CMD_SEEK2:
     case CMD_SEEK3:
     case CMD_SEEK4:
     case CMD_SEEKD:
       cmd_seek(fid(cmd_data & 0x7));
       break;
     case CMD_TS_SEEK0:
     case CMD_TS_SEEK1:
     case CMD_TS_SEEK2:
     case CMD_TS_SEEK3:
     case CMD_TS_SEEK4:
     case CMD_TS_SEEKD:
       cmd_ts_seek(fid(cmd_data & 0x7));
       break;
     case CMD_STATUS:
       cmd_status();
       break;
     case CMD_SECT_RD0:
     case CMD_SECT_RD1:
     case CMD_SECT_RD2:
     case CMD_SECT_RD3:
     case CMD_SECT_RD4:
     case CMD_SECT_RDD:
       cmd_sect_rd(fid(cmd_data & 0x7));
       break;
     case CMD_SECT_WR0:
     case CMD_SECT_WR1:
     case CMD_SECT_WR2:
     case CMD_SECT_WR3:
     case CMD_SECT_WR4:
     case CMD_SECT_WRD:
       cmd_sect_wr(fid(cmd_data & 0x7));
       break;
     case CMD_N_RD0:
     case CMD_N_RD1:
     case CMD_N_RD2:
     case CMD_N_RD3:
     case CMD_N_RD4:
     case CMD_N_RDD:
       cmd_n_rd(fid(cmd_data & 0x7));
       break;
     case CMD_N_WR0:
     case CMD_N_WR1:
     case CMD_N_WR2:
     case CMD_N_WR3:
     case CMD_N_WR4:
     case CMD_N_WRD:
       cmd_n_wr(fid(cmd_data & 0x7));
       break;
     case CMD_DEFAULT0:
     case CMD_DEFAULT1:
     case CMD_DEFAULT2:
     case CMD_DEFAULT3:
     case CMD_DEFAULT4:
       cmd_default(fid(cmd_data & 0x7));
       break;
     case CMD_SIZE0:
     case CMD_SIZE1:
     case CMD_SIZE2:
     case CMD_SIZE3:
     case CMD_SIZE4:
       cmd_size(fid(cmd_data & 0x7));
       break;  
     case CMD_SIZE_RD0:
     case CMD_SIZE_RD1:
     case CMD_SIZE_RD2:
     case CMD_SIZE_RD3:
     case CMD_SIZE_RD4:
       cmd_size_rd(fid(cmd_data & 0x7));
       break;
     // Anything else is ignored.
    }
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
  Serial.print("FID 0 status ");
  Serial.println(handles[0],HEX);
  buf[3] = '1';
  handles[1] = SD.open(buf, FILE_WRITE);
  Serial.print("FID 1 status ");
  Serial.println(handles[1],HEX);
  buf[3] = '2';
  handles[2] = SD.open(buf, FILE_WRITE);
  Serial.print("FID 2 status ");
  Serial.println(handles[2],HEX);
  buf[3] = '3';
  handles[3] = SD.open(buf, FILE_WRITE);
  Serial.print("FID 3 status ");
  Serial.println(handles[3],HEX);

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


// report directory listing as formatted string
// terminated with NUL (0x00)
//
// RESPONSE: NUL-terminated string. Does not update global status
void cmd_dir(void) {
  Serial.println("TODO cmd_dir");
}


// accept 1 byte and send back the 1s complement as
// a response; used for testing the link
//
// RESPONSE: 1 byte. Does not update global status
void cmd_loop(void) {
  put_value(0xff ^ get_value(), INPUT);
}


// close file
//
// RESPONSE: none. Does not update global status
void cmd_close(char fid) {
  if (flags & (1 << fid)) {
    // file handle is currently in use
    handles[fid].close();
    flags = flags & (0xff ^ (1 << fid));
  }
}


// receive null-terminated filename from host
// close any existing file using this fid
// open new file and seek to beginning
// magic: if filename is 0-bytes, auto-generate a
// name of the form NASxxx.BIN where xxx is a number
// 000, 001 etc.
// success: set appropriate flag bit, send response TRUE
// fail: appropriate flag bit, send response FALSE
//
// RESPONSE: sends TRUE or FALSE response to host. Updates global status
void cmd_open(char fid) {
  status = 0;

  get_filename(buf);
  if (flags & (1 << fid)) {
    // file handle is currently in use
    handles[fid].close();
    flags = flags ^ (1 << fid);
  }

  handles[fid] = SD.open(buf, FILE_WRITE);
  if (handles[fid]) {
    status = handles[fid].seek(0);
  }

  flags = flags | (status << fid);
  put_value(status, INPUT);
}


// get 2 bytes from host
// - track
// - sector
// seek drive specified by fid to the appropriate place
// success: drive is ready to rd/wr, send response TRUE
// fail: send response FALS
//
// RESPONSE: sends TRUE or FALSE response to host. Updates global status
void cmd_ts_seek(char fid) {
  status = 0;
  if (flags & (1 << fid)) {
    int track = get_value();
    int sector = get_value();
    status = handles[fid].seek((SECTORS_PER_TRACK * track + sector)* BYTES_PER_SECTOR);
  }
  put_value(status, INPUT);
}


// get 4 bytes from host (LSByte first) used as offset into file.
// seek drive specified by fid to the appropriate place
// success: drive is ready to rd/wr, send response TRUE
// fail: send response FALSE
//
// RESPONSE: sends TRUE or FALSE response to host. Updates global status
void cmd_seek(char fid) {
  long offset;

  status = 0;
  if (flags & (1 << fid)) {
    offset = get_value();
    offset = offset | (get_value() << 8);
    offset = offset | (get_value() << 16);
    offset = offset | (get_value() << 24);
    status = handles[fid].seek(offset);
    Serial.print("Seek for fid ");
    Serial.print(fid,HEX);
    Serial.print(" offset ");
    Serial.println(offset, HEX);
  }
  put_value(status, INPUT);
}


// helper for cmd_n_wr(), cmd_sect_wr()
void n_wr(char fid, long count) {
  Serial.print("Write byte count ");
  Serial.println(count,HEX);
  long written = 0L;
  if (flags & (1 << fid)) {
     for (long i = 0L; i< count; i++) {
      written = written + handles[fid].write(get_value());
     }
     status = written == count;
     // polite and rugged to do this
     handles[fid].flush();
  }
  put_value(status, INPUT);
}


// get 4 bytes from the host (byte count N, ls byte first)
// do write of N bytes on file specified by fid
// assume drive is at correct place!
//
// RESPONSE: send TRUE or FALSE response to host. Updates global status
void cmd_n_wr(char fid) {
  Serial.println("CMD_N_WR");
  long count = get_value();
  count = count | (get_value() << 8);
  count = count | (get_value() << 16);
  count = count | (get_value() << 24);
  n_wr(fid, count);
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
  Serial.print("Read byte count ");
  Serial.println(count,HEX);
  status = 0;
  if (flags & (1 << fid)) {
     for (long i = 0L; i< count; i++) {
      // TODO should check for -1
      // TODO probably better.. much faster.. to pass a buffer.
      put_value(handles[fid].read(), OUTPUT);
     }
     status = 1;
  }
  put_value(status, INPUT);
}


// get 4 bytes from the host (byte count N)
// do read of N bytes on drive specified by fid
// assume drive is at correct place!
//
// RESPONSE: sends TRUE or FALSE response to host. Updates global status
void cmd_n_rd(char fid) {
  long count = get_value();
  count = count | (get_value() << 8);
  count = count | (get_value() << 16);
  count = count | (get_value() << 24);
  n_rd(fid, count);
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
