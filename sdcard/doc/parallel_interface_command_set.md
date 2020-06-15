# Parallel Interface command set

This describes the commands that can be sent across the parallel interface. Each
command is initiated by the host (the NASCOM).

At startup, the host must perform a "training" process which signals to the
software on the NASsd board that the interface is active, and initilises the
protocol.

Each command is 1 byte in size. Some commands include an argument field. The
assignment of byte codes to commands is shown in nascom_sdcard.ino


## NOP

Do nothing. Used by the Host to establish its handshake with the target, and to
check that the target is responding.

Arguments: None

Response: None


## RESTORE_STATE

Equivalent to PRESTOREn with n=0 (refer to the description of PRESTORE further
down in this document).

Arguments: None

Response: 1 byte response; FALSE (0) for error, TRUE (non-zero) for success.


## LOOP

Send back a response equal to the 1-s complement of the argument; used for
test/debug purposes. This command does NOT affect the value returned by the
STATUS command.

Arguments: 1 byte

Response: 1 byte.


## DIR

Report directory of root of SDcard FAT Filesystem.

Arguments: None

Response: ASCII string formated for 48-column screen, terminated with 0.


## STATUS

Return the status of the most recent command

Arguments: None

Response: 1 byte response; FALSE (0) for error, TRUE (non-zero) for success.


## INFO

Report what files are mounted on the 5 possible FIDs.

Arguments: None

Response: ASCII string formated for 48-column screen, terminated with 0.


## STOP

Set all pins to input and go into endless loop; do not process any more
commands. Requires RESET to recover. Aim is to be benign on the PIO interconnect
so that the EPROM programmer can operate.

Arguments: None

Response: None


## OPENn (n= 0,1,2,3,4)

Open a file with read/write intent. If the file did not exist, it is created. If
it did exist, it is opened (see also OPENRn). The initial seek point is the
START of the file.

n is called a fid (file identifier) and allows 5 different files to be open
simultaneously; a particular open file is then referenced by number: 0..4.

If an open file is already associated with n, that file will be closed.

Arguments: A zero-terminated string specifies the file name on the SD card. The
name must match the requirements of the file format: 8.3. In the special case of
a file length of 0, a file name of the form NASxxx.BIN will be generated
automatically (xxx is the next available value in the sequence 000..999).

For this and all other similar commands, the value n is not an argument, but is
encoded in the low 3-bits of the command.

Response: 1 byte response; FALSE (0) for error, TRUE (non-zero) for success.


## OPENRn (n= 0,1,2,3,4)

Open a file with read intent. If it did exist, it is opened. The initial seek
point is the START of the file. If the file did not exist, return error.

n is called a fid (file identifier) and allows 5 different files to be open
simultaneously; a particular open file is then referenced by number: 0..4.

If an open file is already associated with n, that file will be closed.

Arguments: A zero-terminated string specifies the file name on the SD card. The
name must match the requirements of the file format: 8.3. In the special case of
a file length of 0, a file name of the form NASxxx.BIN will be generated
automatically (xxx is the next available value in the sequence 000..999).

If you use OPEN on a file that does not exist, then read it (zero bytes) you
will be left with a zero-byte file of that name, and no errors. Also, you cannot
distinguish between a file that did not exist and a pre-existing zero-byte file.
However, if you OPENR a file that does not exist, you will get an error.

Response: 1 byte response; FALSE (0) for error, TRUE (non-zero) for success.


## CLOSEn (n= 0,1,2,3,4)

Close a file. In general, this is a polite thing to do but is not necessary.

Arguments: none

Response: none


## SEEKn (n= 0,1,2,3,4)

Seek to a specified byte offset in the file. Error if the fid is not in use or
if the offset is beyond the end of the file.

Arguments: 4 bytes specifying the offset. LS byte first.

Response: 1 byte response; FALSE (0) for error, TRUE (non-zero) for success.


## TS_SEEKn (n= 0,1,2,3,4)

Seek to a specified offset in the file, specified by track and sector. Error if
the fid is not in use or if the calculated byte offset is beyond the end of the
file. The actual offset associated with a given track/sector is a function of
the disk geometry (see Appendix 2).

Arguments: 2 bytes specifying the offset. Track first, sector second.

Response: 1 byte response; FALSE (0) for error, TRUE (non-zero) for success.


## SECT_RDn (n= 0,1,2,3,4)

Read 256 bytes from the specified file at the current position.

Arguments: None

Response: 256 bytes, followed by 1 byte of status; FALSE (0) for error, TRUE
(non-zero) for success.


## SECT_WRn (n= 0,1,2,3,4)

Write 256 bytes to the specified file at the current position.

Arguments: 256 data bytes.

Response: 1 byte response; FALSE (0) for error, TRUE (non-zero) for success.


## N_RDn (n= 0,1,2,3,4)

Read upto 2^32-1 bytes from the specified file at the current position.

Arguments: 4 bytes specifying the number of bytes to be read (LS byte first).

Response: Specified number of data bytes, followed by 1 byte of status; FALSE
(0) for error, TRUE (non-zero) for success.


## N_WRn (n= 0,1,2,3,4)

Write upto 2^32-1 bytes to the specified file at the current position.

Arguments: 4 bytes specifying the number of bytes to be written (LS byte first)
followed by that number of data bytes.

Response: 1 byte response; FALSE (0) for error, TRUE (non-zero) for success.


## SIZEn (n= 0,1,2,3,4)

Report the size of the specified file. Error if the fid is not in use.

Arguments: None

Response: 4 bytes (file size, LS byte first) followed by 1 byte status; FALSE
(0) for error, TRUE (non-zero) for success.


## SIZE_RDn (n= 0,1,2,3,4)

Read all the bytes of a file. Assume file is rewound (eg, has just been opened,
or has received a seek(0)).

Arguments: None.

Response: 4 bytes (file size, LS byte first) followed by all the bytes of the
file, in order, followed by 1 status byte; FALSE (0) for error, TRUE (non-zero)
for success.


## PBOOTn (n= 0,1,2,3)

n is the profile id (pid). Performs all of the functions of PRESTOREn
then reads the first sector from the first disk and sends that data to
the host. The sector size is a function of the disk geometry, which in
turn is defined by the pid.

The status byte reflects the status of the read; there is no way to
tell if the PRESTORE was successful.

This command is intended for use as part of a minimum-sized boostrap
loader.

Arguments: None

Response: all of the bytes of 1 sector followed by 1 byte status; FALSE (0)
for error, TRUE (non-zero) for success.


## PRESTOREn (n=0,1,2,3)

n is the profile id (pid). The EEPROM contains 4 "profiles" and the pid selects
one of them. Each profile defines 4 file names and the disk geometry. PRESTORE
verifies that the profile record in the EEPROM has a good magic number and
checksum, then attempts to open the 4 files and associate them with fid 0,1,2,3.

If the record is bad or missing, default file names and geometry is used.

If 4 files are opened successfully, the result is TRUE (no way to tell if
the default names or the selected profile were used).

Arguments: None

Response: 1 byte status; FALSE (0) for error, TRUE (non-zero) for success.

--END--
