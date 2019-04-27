// messages.h - part of nascom_sdcard2                             -*- c -*-
// https://github.com/nealcrook/nascom
//
// with thanks to
// https://stackoverflow.com/questions/14325485/an-array-of-strings-stored-in-flash-with-progmem-in-arduino
// for the syntax (the need for the second "const" in the final line)


// Message flags, used by pr_msg
#define F_MSG_RESPONSE (1)
#define F_MSG_NULLTERM (2)
#define F_MSG_CR       (4)

const char msg_err_fname_bad[]      PROGMEM = "Error - filename missing or wrongly formed or wrong length";
const char msg_err_fname_missing[]  PROGMEM = "Error - file not found";
const char msg_warn_fname_missing[] PROGMEM = "Warning - file not found. At your risk.";
const char msg_info_2bdeleted[]     PROGMEM = "Info - existing file will be deleted.";
const char msg_err_sd_missing[]     PROGMEM = "Error - SDcard not found";
const char msg_err_vdisk_missing[]  PROGMEM = "Error - No virtual disk mounted";
const char msg_err_vdisk_bad[]      PROGMEM = "Error - Could not open file for virtual disk";
const char msg_err_addr_bad[]       PROGMEM = "Error - expected address in hex";
const char msg_err_num_bad[]        PROGMEM = "Error - expected number in decimal";
const char msg_err_try_help[]       PROGMEM = "Error - try typing HELP";
const char msg_help[]               PROGMEM = "INFO - version and status\r\n"
                                              "TO xxxx - relocate boot loader to xxxx\r\n"
                                              "PAUSE nn - delay before supplying text file\r\n"
                                              "NULLS nn - delay between lines of text file\r\n"
                                              "NEW - re-read SDcard\r\n"
                                              "AUTOGO [0 | 1] - execute a file after loading\r\n"
                                              "MO <file> - mount virtual disk from SDcard\r\n"
                                              "DS DV DF - directory\r\n"
                                              "ES <file>  - erase file\r\n"
                                              "RS RV RF <file> [AI] - cue read\r\n"
                                              "WS <file> [AI] - cue write\r\n"
                                              "TS <file> - send text file now\r\n"
                                              "  F/S/V versions specify Flash/SDcard/Vdisk\r\n"
                                              "  AI to auto-increment file names";
const char msg_info[]               PROGMEM = "This is NASCAS version 1.0";


/*

// Examples of using strings in PROGMEM

// cheaty way of doing it: the F macro indicates that the message should be stored in Flash
Serial.println(F("The F macro indicates that the message should be stored in Flash"));

const char str2[] = "Now is the time for all good men";
const char str3[] = "To come to the aid of the party";
const char * const str[] = {str2, str3};

char * foo;

Serial.println();
Serial.println(str2);
Serial.println(str3);

// works - address of buffer/string
foo = str2;
while (*foo != 0) { Serial.write(*foo++); }
Serial.println();

// works - address of buffer/string
foo = str[1];
while (*foo != 0) { Serial.write(*foo++); }
Serial.println();

// cannot read directly from flash memory. Need to use pgm_read_byte
// ROMS is not a good example.. I did not manage to store that array in PROGMEM
// the FLASH is in a different address space so, while it's OK to manipulate
// its addresses in the normal way, to actually use its data you need to use
// the pgm_read_*() functions.
//
// Now, I should know/understand enough to do the same thing with the ROM and save some
// more RAM space.

// works
Serial.write(pgm_read_byte(msg0));
Serial.write(pgm_read_byte(msg0 + 1));
Serial.write(pgm_read_byte(msg0 + 2));

// works
int bar = 0;
while ((pgm_read_byte(msg0 + bar) != 0)) { Serial.write(pgm_read_byte(msg0 + bar++)); }

// works
bar = msg0;
while ((pgm_read_byte(bar) != 0)) { Serial.write(pgm_read_byte(bar++)); }

// works (but see caveat..)
bar = msg[1];
while ((pgm_read_byte(bar) != 0)) { Serial.write(pgm_read_byte(bar++)); }


// but!! example above only works if it can be statically determined. This does NOT work:
bar = msg[i];
// instead, need to use
bar = pgm_read_word(&msg[i])


*/
