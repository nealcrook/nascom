# setup

Load/run this program once on your nascom_sdcard hardware. It reports output to the Arduino console and does 3 things:

# Programs a piece of data called the "profile record" into the EEPROM
# Gives a visual test that the LED is working
# (If you attach the board to the NASCOM) tests the connection from the PIO to the nascom_sdcard

To use the PIO test, wait until the message "Monitoring PIO signals:" appears
then type the following port (O and Q) commands into NAS-SYS -- the stuff after
"#" is comments -- don't type this!

    O 6 F             # port A into output mode
    O 7 F             # port B into output mode
    O 4 AA            # 10101010 to port A  -- Arduino should report AA on port A
    Q 4               # PIO test.. expect AA
    O 4 55            # 01010101 to port A  -- Arduino should report 55 on port A
    Q 4               # PIO test.. expect 55
    O 5 AA            # 10101010 to port B  -- Arduino should report 2 on port B (bits [2:0])
    Q 5               # PIO test.. expect AA
    O 5 55            # 01010101 to port B  -- Arduino should report 5 on port B (bits [2:0])
    Q 5               # PIO test.. expect 55



After you have run this program successfully, load the code from sd_merged.
