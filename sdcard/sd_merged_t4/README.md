# sd_merged_t4

This is an experimental version of sd_merged modified for use with the NASBUG T4
monitor.

Once it's working properly, I intend to merge it into the sd_merged code-base:
probably by switching to the use of a streams output library ("Streaming"?).

Summary of differences:

1. (Both versions have a #define NASBUGT4 which selects (in roms.h) a
different version of the serboot code.)

2. In this version, all of the CR that are emitted on the NASCOM
are changed to 0x1f (the CR character used by T4)

3. msg_help in messages.h has its line-endings changed

4. version string in messages.h changed from 1.4 to 1.4T4

5. All NASSERIAL.println calls have been changed: either to use .print with an extra \x1f on the end or with an additional call to .print to do the \x1f.

5. All NASSERIAL.print calls have been reviewed to see if they needed change.

6. Changed all Serial calls to DEBSERIAL (this needs doing in the main code, too. It has not effect usually but it is inconsistent)



Q: In the original version I had CR LF (\r\n) which I have replaced
by \x1f -- do I need a line feed too? Or, conversely, can I omit it
from the NAS-SYS version?

TODO: the pager (screen_page_quit()) may need modification. Currently
it outputs code 0x17,0x01 -- the 0x17 is "cursor home" in NAS-SYS; but
why did I add the 01 there??
