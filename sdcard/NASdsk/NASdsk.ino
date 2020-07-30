// NASdsk                             -*- c -*-
// https://github.com/nealcrook/nascom
//
// ARDUINO connected to NASCOM 2 PIO to act as mass-storage
// device for the purposes of:
// - dumping data from the NASCOM
// - providing virtual floppy disk capability
//
// The virtual floppy capability can work in conjunction with a
// modified POLYDOS ROM in which the disk drivers address this hardware.
//
// This hardware is not "transparent" to the NASCOM - a utility program
// or modified code is needed on the NASCOM to control it.
//
// ** This software relies on the SdFat implementation. Download it
// ** into your Arduino/libraries area and then edit SdFat/src/SdFatConfig.h
// ** to change "#define USE_LONG_FILE_NAMES" from 1 to 0.
//
// Operations can be associated with upto 5 file-names on the
// SD card. For example, associate 4 of them with virtual drive
// images and use the other one for dumping binary streams or "printer".
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
// see ../doc/parallel_interface_protocol.md
//
/////////////////////////////////////////////////////
// COMMANDS
//
// see ../doc/parallel_interface_commands.md
//
/////////////////////////////////////////////////////


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
//
#define SECTOR_CHUNK (128)
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


// profile with default values - this is the setup for PolyDos2
// (disk geometry is abstracted away by the PolyDos ROM so only
// the file names and sector size matter).
UPROFILE profile {
    {
        {"DSK0.BIN", "DSK1.BIN", "DSK2.BIN", "DSK3.BIN"},
         36, // 18 sectors per track per side
         35, // 35 tracks
         0,  // first sector is sector 0
         2   // 256 bytes per sector
    }
};


// TODO do error checking in n_rd
// TODO could drive CMD=1 during T2H to indicate ABORT but would
// have to be very careful to ensure both sides can track state.


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
// CMD_RESTORE_STATE is deprecated: use CMD_PRESTORE instead.
#define CMD_RESTORE_STATE (0x81)
// 0x82 is unused
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
// 0x50 is unused
#define CMD_SIZE     (0x58)
#define CMD_SIZE_RD  (0x60)
#define CMD_CLOSE    (0x68)

// Bits [2:0] of these commands are the profile ID (PID)
#define CMD_PBOOT    (0x70)
#define CMD_PRESTORE (0x78)


/////////////////////////////////////////////////////

// Size of buffer big enough to hold null-terminated MSDOS 8.3
// name (including the ".")
#define BUFFER (8+1+3+1)

// *not* the standard Arduino library (which has some bugs and performance
// problems). Download from https://github.com/greiman/SdFat
#define SPI_SPEED SD_SCK_MHZ(50)
#include <SdFat.h>

#include <EEPROM.h>


// Prototypes
long get_value32(void);
void set_data_dir(int my_dir);
int prestore(char pid);
unsigned int get_value(void);
//
void cmd_prestore(char pid);
void cmd_loop(void);
void cmd_dir(void);
void cmd_status(void);
void cmd_info(void);
void cmd_stop(void);
void cmd_open(char fid, int mode);
void cmd_close(char fid);
void cmd_seek(char fid);
void cmd_ts_seek(char fid);
void cmd_sect_rd(char fid);
void cmd_sect_wr(char fid);
void cmd_n_rd(char fid);
void cmd_n_wr(char fid);
void cmd_size(char fid);
void cmd_size_rd(char fid);
void cmd_pboot(char pid);

// hint of next number to use when auto-generating file names
int next_file;

// status of most recent command
int status;

// Work with upto 5 files. Use handles[] to show whether a FID is valid.
// Need File rather than FatFile here because FatFile.size() does not exist.
#define FIDS (5)
File handles[FIDS]; // legal values are 0..(FID-1)

// One-time initialisation is in setup().
FatFile *working_dir;

// Protocol bit
int my_t2h;

// Mechanism to detect that the NASCOM wants to do disk operations across
// the PIO interface.
int train_count;

// INPUT when receiving data OUTPUT when sending data
char direction;

SdFat SD;

void setup()   {
    Serial.begin(115200);  // for Debug

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

    // TODO handle SD not-found case!!
    Serial.println(F("Init SD card"));
    if (SD.begin(10, SPI_SPEED)) {
        // move to NASCOM directory, if it exists.
        SD.chdir("NASCOM", 1);
        working_dir = SD.vwd();

        prestore(7);
    }

    my_t2h = rd_h2t();
    train_count = 0;

    Serial.println(F("Start command loop"));
}


// Each pass through loop polls for a command. The check hs_differ is non-blocking
// which allows this loop to be extended with other options.
void loop() {
    if (hs_differ()) {
        if (train_count == 4) {
            cmd_disk();
        }
        else {
            Serial.println(F("Train.."));
            train_count++;
            set_hs_match(); // Ack to host
        }
    }
}


// Come here when there is a disk command: get_value will not block.
// On entry and exit, the Target is set up as a receiver.
void cmd_disk() {
    int cmd_data = get_value();
    // Turn off the ERROR LED in anticipation
    digitalWrite(PIN_ERROR, 0);

    Serial.print(F("Command "));
    Serial.println(cmd_data,HEX);

    switch (cmd_data) {
    case 0x100 | CMD_NOP:
        break; // let Host decide that we're alive
    case 0x100 | CMD_RESTORE_STATE: // TODO deprecated. Equivalent to prestore(0)
        cmd_prestore(0);
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
        cmd_open(cmd_data & 0x7, O_RDWR | O_CREAT);
        break;
    case 0x100 | CMD_OPENR | 0:
    case 0x100 | CMD_OPENR | 1:
    case 0x100 | CMD_OPENR | 2:
    case 0x100 | CMD_OPENR | 3:
    case 0x100 | CMD_OPENR | 4:
        cmd_open(cmd_data & 0x7, O_RDONLY);
        break;
    case 0x100 | CMD_CLOSE | 0:
    case 0x100 | CMD_CLOSE | 1:
    case 0x100 | CMD_CLOSE | 2:
    case 0x100 | CMD_CLOSE | 3:
    case 0x100 | CMD_CLOSE | 4:
        cmd_close(cmd_data & 0x7);
        break;
    case 0x100 | CMD_SEEK | 0:
    case 0x100 | CMD_SEEK | 1:
    case 0x100 | CMD_SEEK | 2:
    case 0x100 | CMD_SEEK | 3:
    case 0x100 | CMD_SEEK | 4:
        cmd_seek(cmd_data & 0x7);
        break;
    case 0x100 | CMD_TS_SEEK | 0:
    case 0x100 | CMD_TS_SEEK | 1:
    case 0x100 | CMD_TS_SEEK | 2:
    case 0x100 | CMD_TS_SEEK | 3:
    case 0x100 | CMD_TS_SEEK | 4:
        cmd_ts_seek(cmd_data & 0x7);
        break;
    case 0x100 | CMD_SECT_RD | 0:
    case 0x100 | CMD_SECT_RD | 1:
    case 0x100 | CMD_SECT_RD | 2:
    case 0x100 | CMD_SECT_RD | 3:
    case 0x100 | CMD_SECT_RD | 4:
        cmd_sect_rd(cmd_data & 0x7);
        break;
    case 0x100 | CMD_SECT_WR | 0:
    case 0x100 | CMD_SECT_WR | 1:
    case 0x100 | CMD_SECT_WR | 2:
    case 0x100 | CMD_SECT_WR | 3:
    case 0x100 | CMD_SECT_WR | 4:
        cmd_sect_wr(cmd_data & 0x7);
        break;
    case 0x100 | CMD_N_RD | 0:
    case 0x100 | CMD_N_RD | 1:
    case 0x100 | CMD_N_RD | 2:
    case 0x100 | CMD_N_RD | 3:
    case 0x100 | CMD_N_RD | 4:
        cmd_n_rd(cmd_data & 0x7);
        break;
    case 0x100 | CMD_N_WR | 0:
    case 0x100 | CMD_N_WR | 1:
    case 0x100 | CMD_N_WR | 2:
    case 0x100 | CMD_N_WR | 3:
    case 0x100 | CMD_N_WR | 4:
        cmd_n_wr(cmd_data & 0x7);
        break;
    case 0x100 | CMD_SIZE | 0:
    case 0x100 | CMD_SIZE | 1:
    case 0x100 | CMD_SIZE | 2:
    case 0x100 | CMD_SIZE | 3:
    case 0x100 | CMD_SIZE | 4:
        cmd_size(cmd_data & 0x7);
        break;
    case 0x100 | CMD_SIZE_RD | 0:
    case 0x100 | CMD_SIZE_RD | 1:
    case 0x100 | CMD_SIZE_RD | 2:
    case 0x100 | CMD_SIZE_RD | 3:
    case 0x100 | CMD_SIZE_RD | 4:
        cmd_size_rd(cmd_data & 0x7);
        break;
    case 0x100 | CMD_PBOOT | 0:
    case 0x100 | CMD_PBOOT | 1:
    case 0x100 | CMD_PBOOT | 2:
    case 0x100 | CMD_PBOOT | 3:
        cmd_pboot(cmd_data & 0x7);
        break;
    case 0x100 | CMD_PRESTORE | 0:
    case 0x100 | CMD_PRESTORE | 1:
    case 0x100 | CMD_PRESTORE | 2:
    case 0x100 | CMD_PRESTORE | 3:
        cmd_prestore(cmd_data & 0x7);
        break;
    default:
        // Not a command or not a recognised command.
        // Light the ERROR LED.
        digitalWrite(PIN_ERROR, 1);
        break;
    }
}


////////////////////////////////////////////////////////////////
// Stuff that tests/waggles pins

// get value of H2T. My current implementation maps this to A7
// which can only be read using analogRead
int rd_h2t(void) {
    return analogRead(PIN_H2T) > 500;
}


// poll to see if incoming handshake differs from our value. During
// transfers initiated by the Host (cmd/parameters/data and got2h)
// it's an indication that we need to do something.
int hs_differ(void) {
    return my_t2h != rd_h2t();
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

// if buffer is empty, auto-create the next unused name
// of the form NASxxx.BIN
// By using next_file as a hint we only have to do the (slow)
// search for the first free file once per boot.
void auto_name(char *buffer) {
    if (buffer[0] == 0) {
        buffer[0] = 'N';
        buffer[1] = 'A';
        buffer[2] = 'S'; // leave 3 bytes for file number
        buffer[6] = '.';
        buffer[7] = 'B';
        buffer[8] = 'I';
        buffer[9] = 'N';
        buffer[10] = 0;  // null-terminate the string
        while (next_file<1000) {
            buffer[3] = '0' + int(next_file/100);
            buffer[4] = '0' + ((int(next_file/10)) %10);
            buffer[5] = '0' + (next_file %10);
            next_file++;
            if (! working_dir->exists(buffer)) {
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

// try to restore configuration from specified profile
// TRUE if virtual disks were opened successfully.
//
// RESPONSE: sends TRUE or FALSE response to host. Updates global status
void cmd_prestore(char pid) {
    status = prestore(pid);
    put_value(status, INPUT);
}


// Helper for cmd_prestore(), cmd_pboot()
//
// if EEPROM profile record is good, use the supplied pid to restore
// a profile. If it is missing or not good, stay with the ROM-based default.
// A pid of 0, 1, 2, 3 restores that pid.
// A pid of 7 indirects the default pid stored in the profile record.
//
// return TRUE if virtual disks were opened successfully.
// return FALSE otherwise
int prestore(char pid) {
    Serial.println(F("prestore"));

    // profile record is 5 bytes + 4 profile entries of 56 bytes each
    unsigned char csum = 0;
    for (int i=0; i<(5+4*56); i++) {
        csum = csum + EEPROM.read(i);
    }

    if (csum == 0) {
        Serial.println(F("using profile record"));
        if (pid == 7) {
            pid = EEPROM.read(3);
        }

        // get stuff from EEPROM
        int base = 5 + (pid * sizeof(struct PROFILE));
        for (int i=0; i<sizeof(struct PROFILE); i++) {
            profile.b[i] = EEPROM.read(base+i);
        }
    }

    // TODO there is no option to have fewer disks: error unless all 4 exist.
    // Do I even need to do this or should an operation open and close the disk, in which case only need 1 handle.
    // TODO in the case where file does not exist, does O_RDWR create it? I think it does *not* because there
    // is a separate flag O_CREAT
    for (int i=0; i<4; i++) {
        if (handles[i]) {
            // file handle is currently in use
            handles[i].close();
        }
        handles[i].open(profile.f.fnam_fext[i], O_RDWR);
    }
    // Success?
    return (handles[0].isOpen() && handles[1].isOpen() && handles[2].isOpen() && handles[3].isOpen());
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
    FatFile handle;
    char name[BUFFER];

    working_dir->rewind();
    while (handle.openNext(working_dir, O_RDONLY)) {
        char * pname = name;
        int len = 15;
        handle.getSFN(name);

        while (*pname != 0) {
            put_value(*pname++, OUTPUT);
            len--;
        }

        if (handle.isDir()) {
            put_value('/', OUTPUT);
        }
        else {
            while (len > 0) {
                put_value(' ', OUTPUT);
                len--;
            }

            // Print file size in bytes. Max file size is 2gb ie 10 digits
            int pad=0;
            long i=1000000000;
            long n = handle.fileSize();
            long dig;

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
        handle.close();
    }
    // Tidy up and finish
    put_value(0,INPUT);
}


// Report files assigned to each FID as formatted string
// terminated with NUL (0x00)
//
// RESPONSE: NUL-terminated string. Does not update global status
void cmd_info(void) {
    char name[BUFFER];
    char *pname = name;

    Serial.println(F("Info"));
    for (int i=0; i<5; i++) {
        put_value(0x30 + i,OUTPUT);
        put_value(':',OUTPUT);
        put_value(' ',OUTPUT);
        Serial.print(i);
        Serial.print(F(": "));
        if (handles[i]) {
            handles[i].getName(pname, BUFFER);
            Serial.println(pname);
            while (*pname != 0) {
                put_value(*pname++, OUTPUT);
            }
        }
        else {
            Serial.println('-');
            put_value('-',OUTPUT);
        }
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
    Serial.println(F("cmd_stop - wait for reset"));
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
// O_RDONLY - error if file does not exist. FID
// is left unused.
// O_RDWR | O_CREATE - seek to start of file. Create file if it
// does not exist.
//
// RESPONSE: sends TRUE on success (fid is now associated
// with a file) or FALSE on error (fid is now unused)
// Updates global status
void cmd_open(char fid, int mode) {
    char name[BUFFER];
    status = 0;

    get_filename(name);

    if (handles[fid]) {
        // file handle is currently in use
        handles[fid].close();
    }

    handles[fid].open(name, mode);
    if (handles[fid]) {
        // Documentation implies that this happens on OPEN but is not explicit
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
        long offset = ( (long)profile.f.nsect_per_track * (long)track + (long)sector - (long)profile.f.first_sect ) * (long)(profile.f.sect_chunks * SECTOR_CHUNK);
        status = handles[fid].seek(offset);
    }
    else {
        Serial.print(F("Seek to track but no disk"));
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
    long offset = get_value32();
    if (handles[fid]) {
        status = handles[fid].seek(offset);
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
    Serial.println(F("CMD_N_WR"));
    n_wr(fid, get_value32());
}


// do write of 1 sector of bytes on file specified by fid
// assume drive is at correct place!
//
// RESPONSE: send TRUE or FALSE response to host. Updates global status
void cmd_sect_wr(char fid) {
    n_wr(fid, (long)(profile.f.sect_chunks * SECTOR_CHUNK));
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
    n_rd(fid, (long)(profile.f.sect_chunks * SECTOR_CHUNK));
}


// return global status from most recent routine that updated it. The
// global status is not changed by the execution of this command.
//
// RESPONSE: sends TRUE or FALSE to host - value of global status
// from most recent command that updates it
void cmd_status(void) {
    put_value(status, INPUT);
}


// read the file size
//
// RESPONSE: 4 bytes (file size, LS byte first),
// followed by 1 status byte.
void cmd_size(char fid) {
    long size = handles[fid].size(); // always succeeds => no status.
    put_value( size        & 0xff, OUTPUT);
    put_value((size >> 8)  & 0xff, OUTPUT);
    put_value((size >> 16) & 0xff, OUTPUT);
    put_value((size >> 24) & 0xff, OUTPUT);
    put_value(0, INPUT);
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


// boot. Given a profile pid (as part of the command)
// and no other parameters, load the profile and use
// it to return 1 sector's worth of read data for the
// profile's geometry: the first sector of the first
// disk.
//
// RESPONSE: sends TRUE or FALSE response to host. Updates global status
void cmd_pboot(char pid) {
    prestore(pid);
    handles[0].seek(0);
    // errors up to now will be ignored, but will make the read fail.
    // If the read fails it returns the correct amount of data, but the
    // data is all-0. n_rd updates the global status so that the final
    // response byte indicates whether the whole process has been successful
    n_rd(0, (long)(profile.f.sect_chunks * SECTOR_CHUNK));
    put_value(status, INPUT);
}
