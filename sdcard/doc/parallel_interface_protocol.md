# Parallel interface protocol

The NASCOM acts as the Host and the Arduino acts as the Target. The protocol
uses a handshake in each direction. There are 5 different signalling patterns --
shown in [protocol pictures](protocol.pdf)

The protocol uses:

* 8 data bits
* A command bit, CMD, that always goes from the Host to the Target
* A handshake from Host to Target, H2T.
* A handshake from Target to Host, T2H.

The data bits change from input to output depending upon the transaction; the
change-over has to happen at both ends of the link without bus contention and
without leaving the bus floating for an indeterminate time.

The pictures show:

* 1a -- send command byte from Host to Target
* 1b -- send data byte from Host to Target
* 2 -- send data byte from Target to Host
* 3 -- change bus direction from Host driving to Target driving
* 4 -- change bus direction from Target driving to Host driving

After reset, the Host is driving data to the Target. H2T is low, T2H is low, CMD
is undefined.

## 1a: Send command byte from Host to Target

* Host: put xd=command byte, put cmd=1
* Host: invert H2T
* Host: wait until T2H == H2T
* Target: wait until H2T != T2H
* Target: sample value of xd, cmd
* Target: put T2H = H2T

## 1b: Send data byte from Host to Target

* Same as 1a, except cmd=0

## 2: Send data byte from Target to Host

* Target: put xd=data byte
* Target: invert T2H
* Target: wait until T2H != H2T
* Host: wait until T2H == H2T
* Host: sample value of xd
* Host: put T2H = !H2T

## 3: Change bus direction from Host driving to Target driving

* Host: set xd bus to INPUT
* Host: put T2H = !H2T
* Target: wait until T2H != H2T
* Target: set xd bus to OUTPUT

## 4: Change bus direction from Target driving to Host driving

* Target: set xd bus to INPUT
* Target: invert T2H
* Host: wait until T2H != H2T
* Host: set xd bus to OUTPUT

## Rules:

* Each step requires 1 handshake toggle. Therefore, the protocol
can run at any speed down to DC.
* For patterns where the Host is driving the bus, the idle state of
the handshakes is that they match.
* For patterns where the Targer is driving the bus, the idle state of
the handshakes is that they differ

Thus:

* 1a: Start and end with handshakes matching.
* 1b: Start and end with handshakes matching.
* 2: Start and end with handshakes differing.
* 3: Start with handshakes matching, end with handshakes differing.
* 4: Start with handshakes differing, end with handshakes matching.
