// parser etc. - part of nascom_sdcard2                             -*- c -*-
// https://github.com/nealcrook/nascom
//

// If c is a lower-case alphabetic character, return the upper-case equivalent.
// Otherwise return c unchanged.
char to_upper(char c) {
    if (c >= 'a' && c <= 'z') {
         c = c - 32;
    }
    return c;
}


// If c is A-Z or a-z or 0-9 or _ or - return 1 else return 0
int legal_char(char c) {
    if ((c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9') || (c == '_') || (c == '-')) {
        return 1;
    }
    return 0;
}


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


// Each routine parses 1 space-delimited token
// Return 0 for failure, 1 for success
// In general, they move to the next token whether they
// pass or fail


// Step over the token until the 1st space or the end of the string.
// So, successive calls might leave the buffer pointer like this:
//
// "TO   12bc 1234"
//  ^        ^        before and after first call
//           ^    ^   before and after 2nd call


// advance to 1st char in space-delimited string
// "TOO MUCH"   "TOO   MUCH   "TOO  MUCH"
//  ^---^           ^--^            ^      before and after (last one: no change)
//
// Use this to step past the command to the first token and
// use it from within another parser on error so that the parser
// can skip over the bad token.
int parse_leading(char **buf) {
    int state = 0; // looking for whitespace
    while (**buf != '\0') {
        if ((state == 1) && (**buf != ' ')) {
            return 1;
        }
        if ((state == 0) && (**buf == ' ')) {
            state = 1;
        }
        *buf = *buf + 1;
    }
    // fail
    return 0;
}

// Parse a number from a null-terminated buffer.
// Buffer starts at the first character of the alleged number.
// Parse until first space or end of line.
// Return with buf pointing to first space or end of line.
// Return true: number recognised, converted value is in result
// Return fail: non-numeric character found
// base can be 10 or 16
// Designed for +ve 16-bit numbers but there is no overflow detection
// so will parse an arbitrarily long numeric string and return the
// low 16-bits of the result.
int parse_num(char **buf, int* result, int base) {
    int digits_converted = 0;

    *result = 0;
    while ((**buf != '\0') && (**buf != ' ')) {
        Serial.print("Result: ");
        Serial.println(*result, HEX);
        if ((**buf >= '0') && (**buf <= '9')) {
            *result = (*result * base) + (**buf - '0');
            digits_converted++;
        }
        else if ((base==16) && (**buf >= 'a') && (**buf <= 'f')) {
            *result = (*result << 4) | (**buf - 'a' + 10);
            digits_converted++;
        }
        else if ((base==16) && (**buf >= 'A') && (**buf <= 'F')) {
            *result = (*result << 4) | (**buf - 'A' + 10);
            digits_converted++;
        }
        else {
            // bad digit - ignore any earlier good ones
            digits_converted = 0;
            break;
        }
        *buf = *buf + 1;
    }
    // move to start of next token
    parse_leading(buf);
    return (digits_converted != 0);
}


// Look to see if the next token is AI or ai.
// Return true: it is; buffer pointer is moved to the next token
// Return false: it is not; buffer pointer is unchanged
int parse_ai(char **buf) {
    if (to_upper(**buf) == 'A') {
        *buf = *buf + 1;
        if (to_upper(**buf) == 'I') {
            *buf = *buf + 1;
            parse_leading(buf);
            return 1;
        }
        *buf = *buf - 1;
    }
    return 0;
}


// Look for MSDOS-format file-name: 1-8 char followed by dot followed by 1-3 char.
// Return true: found it, copied it to dest, buffer pointer moved to next token
// Return false: did not find it, part-copied it to dest, buffer pointer moved to next token
// Copy in dest is a literal copy of the original, including dot, and is null-terminated.
int parse_fname_msdos(char **buf, char * dest) {
    // < 100 - length of prefix
    // > 100 - 100 + length of suffix
    int len = 0;

    while ((**buf != '\0') && (**buf != ' ')) {
        //printf("Len = %d char = %c\n", len, **buf);
        if ((len >= 1) && (len < 100) && (**buf == '.')) {
            // in prefix, got at least 1 char and now found dot: all is good
            *dest++ = '.';
            // move to suffix
            len = 100;
        }
        else if (legal_char(**buf) && ((len < 8) || ((len >= 100) && (len < 103)))) {
            // OK in prefix or suffix
            *dest++ = **buf;;
            len++;
        }
        else {
            // bad
            len = 0;
            break;
        }
        *buf = *buf + 1;
    }
    // move to start of next token
    parse_leading(buf);
    // null-terminate copied string whether or not it is complete
    *dest = '\0';
    return (len > 100); // in suffix and at least 1 suffix character
}


// Look for PolyDos-format file-name: 1-8 char followed by dot followed by 2 char.
// Return true: found it, copied it to dest, buffer pointer moved to next token
// Return false: did not find it, part-copied it to dest, buffer pointer moved to next token
// Copy in dest is 10 characters, no dot, with any gap between the prefix and the
// suffix filled with spaces. It is null-terminated for consistency (the way it ends up
// being used, that is not necessary)
int parse_fname_polydos(char **buf, char * dest) {
    // < 100 - length of prefix
    // > 100 - 100 + length of suffix
    int len = 0;

    while ((**buf != '\0') && (**buf != ' ')) {
        //printf("Len = %d char = %c\n", len, **buf);
        if ((len >= 1) && (len < 100) && (**buf == '.')) {
            // in prefix, got at least 1 char and now found dot: all is good
            // space-pad the prefix to 8 characters
            while (len < 8) {
                *dest++ = ' ';
                len++;
            }
            // move to suffix
            len = 100;
        }
        else if (legal_char(**buf) && ((len < 8) || ((len >= 100) && (len < 102)))) {
            // OK in prefix or suffix
            *dest++ = **buf;;
            len++;
        }
        else {
            // bad
            len = 0;
            break;
        }
        *buf = *buf + 1;
    }
    // move to start of next token
    parse_leading(buf);
    // null-terminate copied string whether or not it is complete
    *dest = '\0';
    return (len == 102); // in suffix and exactly 2 suffix characters
}
