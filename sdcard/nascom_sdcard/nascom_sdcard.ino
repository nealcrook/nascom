// nascom_sdcard
// https://github.com/nealcrook/nascom
//
// ARDUINO connected to NASCOM 2 PIO to act as mass-storage
// device for the purposes of:
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
// WIRING (assumes Arduino Uno/Nano)
//
// ANA6/ANA7 ARE INPUT ONLY *AND* YOU CANNOT USE
// digitalRead ON THEM - ONLY analogRead.
//
//
// 1/ connection to uSDcard adaptor
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
// H2T    IN           ANA7     B1 (pin 8)
// CMD    IN           ANA3     B2 (pin 6)
// XD7    IN/OUT       ANA0     A7 (pin 24)
// XD6    IN/OUT       DIG6     A6 (pin 25)
// XD5    IN/OUT       ANA5     A5 (pin 23)
// XD4    IN/OUT       ANA4     A4 (pin 21)
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
// ERROR  OUT         ANA2      To LED. Other end of LED via resistor to GND
//
/////////////////////////////////////////////////////
// PROTOCOL
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
// TODO do error checking in n_rd
// TODO consider removing CMD_DEFAULT as it doesn't seem useful in the way
// that I orginally expected.
// TODO could drive CMD=1 during T2H to indicate ABORT but would
// have to be very careful to ensure both sides can track state.


// For testing
//#define DEBUG


/////////////////////////////////////////////////////
// Pin assignments
#define PIN_T2H A1
#define PIN_H2T A7
#define PIN_CMD A3
#define PIN_ERROR A2
#define PIN_XD7 A0
#define PIN_XD6 6
#define PIN_XD5 A5
#define PIN_XD4 A4
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
// but may be wrong for the version on my actual NASCOM. Also, not sure
// how 2 sides are handled.. by doubling the tracks or otherwise?
// ..actually, PolyDos doesn't care because it treats the disk as a linear
// sequence of sectors and my low-level drivers do the same; don't consider
// tracks/sectors at all.
#define SECTORS_PER_TRACK (18)
#define BYTES_PER_SECTOR (256)
#define TRACKS (80)


#include <SD.h>

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
  while (0 != rd_h2t()) {
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
  //Serial.println("Start command wait");

  int cmd_data = get_value();
  // Turn off the ERROR LED in anticipation
  digitalWrite(PIN_ERROR, 0);

  Serial.print("Command ");
  Serial.println(cmd_data,HEX);

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

// get value of H2T. My current implementation maps this to A7
// which can only be read using analogRead
int rd_h2t(void) {
    return analogRead(PIN_H2T) > 500;
}


// wait until incoming handshake differs from our value. During
// transfers initiated by the Host (cmd/parameters/data and got2h)
// it's an indication that we need to do something.
void wait4_hs_differ(void) {
  while (my_t2h == rd_h2t()) {
  }
}


// wait until incoming handshake matches from our value. During
// transfers initiated by the Target (us) (response/data/goh2t)
// it's an indication that the transfer we initiated has been
// acknowledged by the host.
void wait4_hs_match(void) {
  while (my_t2h != rd_h2t()) {
  }
}


// set outgoing handshake equal to incoming handshake. During transfers
// initiated by the Host this is the Target indicating that it is done.
// During transactions initiated by the Target this is how the Target
// initiates the transfer.
// Theoretically we don't need to read the other handshake, we can rely
// on our own copy. However, it seems more robust to do it like this.
void set_hs_match(void) {
  my_t2h = rd_h2t();
  digitalWrite(PIN_T2H, my_t2h);
}


// set outgoing handshake as inverse of incoming handshake. This is how WOT
// the Target (us) initiates a transfer
// theoretically we don't need to read the other handshake, we can rely
// on our own copy. However, it seems more robust to do it like this.
void set_hs_differ(void) {
  my_t2h = 1 ^ rd_h2t();
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
  return (handles[0] && handles[1] && handles[2] && handles[3]);
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
