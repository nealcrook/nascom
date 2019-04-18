// parser - part of nascom_sdcard2                             -*- c -*-
// https://github.com/nealcrook/nascom
//


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


// Extract a number from the command line.
// Designed for 16-bit hex numbers but can also work for small decimal
// numbers.
// buffer is null-terminated.
// base is 10 or 16.
// Parse buffer. Skip a command delimited by a space. Expect a numeric
// string of 1-4 characters. Convert to a 16-bit binary number. If more
// than 4 characters are present, continue parsing, so that the last
// 4 are used.
// The converted number is in result.
// Return 1 if successful, return 0 if no argument is present or an
// illegal character present.
// TODO bug: only works if the number is the last thing on the line. Need to detect whitespace after the number and return
int cas_parse_num(char *buffer, int* result, int base) {
    int num = 0;
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
            Serial.println(num, HEX);
            if ((val >= '0') && (val <= '9')) {
                num = (num * base) + (val - '0');
            }
            else if ((base==16) && (val >= 'a') && (val <= 'f')) {
                num = (num << 4) | (val - 'a' + 10);
            }
            else if ((base==16) && (val >= 'A') && (val <= 'F')) {
                num = (num << 4) | (val - 'A' + 10);
            }
            else {
                Serial.print(F("Error on cas_parse_num with "));
                Serial.println(val);
                return 0;
            }
        }
    }
    // ran out of buffer so we must be done
    *result = num;
    return 1;
}


// Parse a file-name from the command line.
// buffer is null-terminated.
// parse the buffer. Skip a command delimited by a space. Expect a string
// of 1-8 characters, followed by a dot (".") followed by a string of
// 1-3 characters (terminated by space or end-of-buffer).
// Fills in result[] as follows:
// [0] = 1 if the name fits the format described, 0 if error.
// [1] = index associated with first character of prefix
// [2] = number of characters in prefix
// [3] = number of characters in suffix
// therefore the prefix is at [1].. [1]+[2]-1
// and the suffix is at [1]+[2]+1 .. [1]+[2]+[3]
// x x x f r e d . t x t
// 0 1 2 3 4 5 6 7 8 9 10
//
// [1] = 3
// [2] = 4
// [3] = 3
//
// TODO or, might want to arrange those differently to make handling easier
// later.
//
// TODO currently accept ANY character in filename apart from space and dot.
// May want to be more stringent.
void cas_parse_name(char *buffer, char *result) {
    int arg = 0;
    int index = 0;
    char val;

    result[0] = 0; // default is error

    // 0 -> skip command (non white-space) looking for white-space
    // 1 -> skip white-space looking for argument)
    // 2 -> processing prefix
    // 3 -> processing suffix
    int state = 0;
    while (val = buffer[index]) {
        switch(state) {
        case 0:  if (val == ' ') {
                state = 1;
            }
            break;

        case 1:  if (val == ' ') {
                break;
            }
            if (val == '.') {
                return; // error: no prefix
            }
            // first character of prefix
            state = 2;
            result[1] = index;
            result[2] = 1;
            break;

        case 2:  if (val == ' ') {
                return; // error: no dot or suffix
            }
            if (val == '.') {
                state = 3;
                result[3] = 0;
                break;
            }
            // continue with prefix
            result[2]++;
            if (result[2] > 8) {
                return; // error: prefix too long
            }
            break;

        case 3:  if (val == '.') {
                return; // error: double dot
            }
            if (val == ' ') {
                if ((result[3] > 0) && (result[3] < 4)) {
                    result[0] = 1; // success
                }
                return; // success or error: suffix too short/long
            }
            // continue with suffix
            result[3]++;
            break;
        }
        index++;
    }
    // ran out of buffer
    if ((result[3] > 0) && (result[3] < 4)) {
        result[0] = 1; // success
    }
    return; // success or error: suffix too short/long
}


