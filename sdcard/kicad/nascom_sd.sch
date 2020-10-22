EESchema Schematic File Version 4
EELAYER 30 0
EELAYER END
$Descr A4 11693 8268
encoding utf-8
Sheet 1 1
Title ""
Date ""
Rev ""
Comp ""
Comment1 ""
Comment2 ""
Comment3 ""
Comment4 ""
$EndDescr
$Comp
L nascom_sd-rescue:DIL16 J4
U 1 1 5B7746F9
P 8200 1300
F 0 "J4" H 8200 1750 50  0000 C CNN
F 1 "DIL16" V 8200 1300 50  0000 C CNN
F 2 "Package_DIP:DIP-16_W7.62mm_Socket" H 8200 1300 50  0001 C CNN
F 3 "" H 8200 1300 50  0001 C CNN
	1    8200 1300
	1    0    0    -1  
$EndComp
Text Label 7700 950  2    60   ~ 0
PIO_B0
Text Label 7700 1050 2    60   ~ 0
PIO_B1
Text Label 7700 1150 2    60   ~ 0
PIO_B2
$Comp
L power:GND #PWR011
U 1 1 5B774B2C
P 8700 1650
F 0 "#PWR011" H 8700 1400 50  0001 C CNN
F 1 "GND" H 8700 1500 50  0000 C CNN
F 2 "" H 8700 1650 50  0001 C CNN
F 3 "" H 8700 1650 50  0001 C CNN
	1    8700 1650
	1    0    0    -1  
$EndComp
NoConn ~ 8550 1050
NoConn ~ 8550 1150
NoConn ~ 8550 1250
NoConn ~ 8550 1350
$Comp
L nascom_sd-rescue:DIL16 J7
U 1 1 5B774D30
P 10200 1300
F 0 "J7" H 10200 1750 50  0000 C CNN
F 1 "DIL16" V 10200 1300 50  0000 C CNN
F 2 "Package_DIP:DIP-16_W7.62mm_Socket" H 10200 1300 50  0001 C CNN
F 3 "" H 10200 1300 50  0001 C CNN
	1    10200 1300
	1    0    0    -1  
$EndComp
Text Label 9700 950  2    60   ~ 0
PIO_A0
Text Label 9700 1050 2    60   ~ 0
PIO_A1
Text Label 9700 1150 2    60   ~ 0
PIO_A2
Text Label 9700 1250 2    60   ~ 0
PIO_A3
Text Label 9700 1350 2    60   ~ 0
PIO_A4
Text Label 9700 1450 2    60   ~ 0
PIO_A5
Text Label 9700 1550 2    60   ~ 0
PIO_A6
Text Label 9700 1650 2    60   ~ 0
PIO_A7
$Comp
L power:GND #PWR019
U 1 1 5B774D4A
P 10700 1650
F 0 "#PWR019" H 10700 1400 50  0001 C CNN
F 1 "GND" H 10700 1500 50  0000 C CNN
F 2 "" H 10700 1650 50  0001 C CNN
F 3 "" H 10700 1650 50  0001 C CNN
	1    10700 1650
	1    0    0    -1  
$EndComp
NoConn ~ 10550 1050
NoConn ~ 10550 1150
NoConn ~ 10550 1250
NoConn ~ 10550 1350
Text Label 8550 2250 0    60   ~ 0
PIO_B4
Text Label 8550 2350 0    60   ~ 0
PIO_B3
Text Label 8550 2450 0    60   ~ 0
PIO_B2
Text Label 8550 2550 0    60   ~ 0
PIO_B1
Text Label 8550 2650 0    60   ~ 0
PIO_B0
NoConn ~ 8300 2850
NoConn ~ 8300 3450
$Comp
L power:GND #PWR09
U 1 1 5B7761EB
P 8450 3600
F 0 "#PWR09" H 8450 3350 50  0001 C CNN
F 1 "GND" H 8450 3450 50  0000 C CNN
F 2 "" H 8450 3600 50  0001 C CNN
F 3 "" H 8450 3600 50  0001 C CNN
	1    8450 3600
	1    0    0    -1  
$EndComp
Text Label 8550 2750 0    60   ~ 0
PIO_BRDY
Text Label 8550 3350 0    60   ~ 0
PIO_A7
Text Label 7550 2250 2    60   ~ 0
PIO_B5
Text Label 7550 2350 2    60   ~ 0
PIO_B6
Text Label 7550 2450 2    60   ~ 0
PIO_B7
Text Label 7550 2550 2    60   ~ 0
PIO_ARDY
Text Label 7550 2650 2    60   ~ 0
PIO_BSTB
Text Label 7550 2750 2    60   ~ 0
PIO_ASTB
Text Label 7550 2850 2    60   ~ 0
PIO_A0
Text Label 7550 2950 2    60   ~ 0
PIO_A1
Text Label 7550 3050 2    60   ~ 0
PIO_A2
Text Label 7550 3150 2    60   ~ 0
PIO_A3
Text Label 7550 3250 2    60   ~ 0
PIO_A4
Text Label 7550 3350 2    60   ~ 0
PIO_A5
Text Label 7550 3450 2    60   ~ 0
PIO_A6
Text Notes 8350 1850 2    60   ~ 12
NASCOM1 Connections
Text Notes 8750 3050 0    60   ~ 0
PIO\nconnection
$Comp
L nascom_sd-rescue:CONN_01X06 J5
U 1 1 5B776B75
P 9050 4750
F 0 "J5" H 9050 5100 50  0000 C CNN
F 1 "CONN_01X06" V 9150 4750 50  0000 C CNN
F 2 "nascom_sd:SDcard_module_1x06_P2.54mm" H 9050 4750 50  0001 C CNN
F 3 "" H 9050 4750 50  0001 C CNN
	1    9050 4750
	1    0    0    -1  
$EndComp
$Comp
L power:+5V #PWR013
U 1 1 5B776EFD
P 8800 4300
F 0 "#PWR013" H 8800 4150 50  0001 C CNN
F 1 "+5V" H 8800 4440 50  0000 C CNN
F 2 "" H 8800 4300 50  0001 C CNN
F 3 "" H 8800 4300 50  0001 C CNN
	1    8800 4300
	1    0    0    -1  
$EndComp
$Comp
L power:GND #PWR012
U 1 1 5B776F1D
P 8700 5150
F 0 "#PWR012" H 8700 4900 50  0001 C CNN
F 1 "GND" H 8700 5000 50  0000 C CNN
F 2 "" H 8700 5150 50  0001 C CNN
F 3 "" H 8700 5150 50  0001 C CNN
	1    8700 5150
	1    0    0    -1  
$EndComp
Text Label 8550 4700 2    60   ~ 0
MISO
Text Label 8550 4800 2    60   ~ 0
MOSI
Text Label 8550 4900 2    60   ~ 0
SCK
Text Label 8550 5000 2    60   ~ 0
CS_N
Text Notes 9400 4750 0    60   ~ 0
MicroSD Card Adaptor\nwith level-shifters and\n3V3 regulator
Text Notes 7150 7050 0    60   ~ 0
SD-card Adaptor for connection to NASCOM1 or NASCOM2 PIO and/or\nserial interface.\n\nfoofoobedoo@gmail.com
Wire Wire Line
	8550 950  8700 950 
Wire Wire Line
	8550 1650 8700 1650
Wire Wire Line
	7850 950  7700 950 
Wire Wire Line
	7850 1050 7700 1050
Wire Wire Line
	7850 1150 7700 1150
Wire Wire Line
	10550 950  10700 950 
Wire Wire Line
	10550 1650 10700 1650
Wire Wire Line
	9850 950  9700 950 
Wire Wire Line
	9850 1050 9700 1050
Wire Wire Line
	9850 1150 9700 1150
Wire Wire Line
	9850 1250 9700 1250
Wire Wire Line
	9850 1350 9700 1350
Wire Wire Line
	9850 1450 9700 1450
Wire Wire Line
	9850 1550 9700 1550
Wire Wire Line
	9850 1650 9700 1650
Wire Wire Line
	7550 2250 7800 2250
Wire Wire Line
	7550 2350 7800 2350
Wire Wire Line
	7550 2450 7800 2450
Wire Wire Line
	7550 2550 7800 2550
Wire Wire Line
	7550 2650 7800 2650
Wire Wire Line
	7550 2750 7800 2750
Wire Wire Line
	7550 2850 7800 2850
Wire Wire Line
	7550 2950 7800 2950
Wire Wire Line
	7550 3050 7800 3050
Wire Wire Line
	7550 3150 7800 3150
Wire Wire Line
	7550 3250 7800 3250
Wire Wire Line
	7550 3350 7800 3350
Wire Wire Line
	7550 3450 7800 3450
Wire Wire Line
	8300 2250 8550 2250
Wire Wire Line
	8550 2350 8300 2350
Wire Wire Line
	8550 2450 8300 2450
Wire Wire Line
	8550 2550 8300 2550
Wire Wire Line
	8550 2650 8300 2650
Wire Wire Line
	8550 2750 8300 2750
Wire Wire Line
	8550 3350 8300 3350
Wire Wire Line
	8300 3150 8400 3150
Wire Wire Line
	8400 3250 8300 3250
Connection ~ 8400 3150
Wire Wire Line
	8300 2950 8450 2950
Wire Wire Line
	8450 2950 8450 3050
Wire Wire Line
	8300 3050 8450 3050
Connection ~ 8450 3050
Wire Wire Line
	8550 4700 8850 4700
Wire Wire Line
	8550 4800 8850 4800
Wire Wire Line
	8550 4900 8850 4900
Wire Wire Line
	8550 5000 8850 5000
Wire Wire Line
	8850 4500 8700 4500
Wire Wire Line
	8700 4500 8700 5150
$Comp
L nascom_sd-rescue:LED D1
U 1 1 5B799FA9
P 4400 5600
F 0 "D1" H 4400 5700 50  0000 C CNN
F 1 "LED" H 4400 5500 50  0000 C CNN
F 2 "LED_THT:LED_D5.0mm" H 4400 5600 50  0001 C CNN
F 3 "" H 4400 5600 50  0001 C CNN
	1    4400 5600
	0    -1   -1   0   
$EndComp
Wire Wire Line
	4000 5450 4400 5450
Wire Wire Line
	4400 5750 4400 5900
$Comp
L power:GND #PWR03
U 1 1 5B79A363
P 4400 5900
F 0 "#PWR03" H 4400 5650 50  0001 C CNN
F 1 "GND" H 4400 5750 50  0000 C CNN
F 2 "" H 4400 5900 50  0001 C CNN
F 3 "" H 4400 5900 50  0001 C CNN
	1    4400 5900
	1    0    0    -1  
$EndComp
Text Notes 4650 5650 0    60   ~ 0
"INFO"
$Comp
L nascom_sd-rescue:C C1
U 1 1 5B79BB7B
P 7750 6050
F 0 "C1" H 7775 6150 50  0000 L CNN
F 1 "0.1uF" H 7775 5950 50  0000 L CNN
F 2 "Capacitor_THT:C_Axial_L3.8mm_D2.6mm_P7.50mm_Horizontal" H 7788 5900 50  0001 C CNN
F 3 "" H 7750 6050 50  0001 C CNN
	1    7750 6050
	1    0    0    -1  
$EndComp
$Comp
L nascom_sd-rescue:C C2
U 1 1 5B79BBD6
P 8250 6050
F 0 "C2" H 8275 6150 50  0000 L CNN
F 1 "0.1uF" H 8275 5950 50  0000 L CNN
F 2 "Capacitor_THT:C_Axial_L3.8mm_D2.6mm_P7.50mm_Horizontal" H 8288 5900 50  0001 C CNN
F 3 "" H 8250 6050 50  0001 C CNN
	1    8250 6050
	1    0    0    -1  
$EndComp
$Comp
L nascom_sd-rescue:CP C3
U 1 1 5B79BC2D
P 8700 6050
F 0 "C3" H 8725 6150 50  0000 L CNN
F 1 "10uF" H 8725 5950 50  0000 L CNN
F 2 "Capacitor_THT:C_Axial_L5.1mm_D3.1mm_P10.00mm_Horizontal" H 8738 5900 50  0001 C CNN
F 3 "" H 8700 6050 50  0001 C CNN
	1    8700 6050
	1    0    0    -1  
$EndComp
$Comp
L nascom_sd-rescue:CP C4
U 1 1 5B79BC78
P 9150 6050
F 0 "C4" H 9175 6150 50  0000 L CNN
F 1 "10uF" H 9175 5950 50  0000 L CNN
F 2 "Capacitor_THT:C_Axial_L5.1mm_D3.1mm_P10.00mm_Horizontal" H 9188 5900 50  0001 C CNN
F 3 "" H 9150 6050 50  0001 C CNN
	1    9150 6050
	1    0    0    -1  
$EndComp
Connection ~ 8250 5900
Connection ~ 8700 5900
Connection ~ 9150 5900
Connection ~ 8250 6200
Connection ~ 8700 6200
Connection ~ 9150 6200
$Comp
L power:+5V #PWR014
U 1 1 5B79C505
P 9950 5900
F 0 "#PWR014" H 9950 5750 50  0001 C CNN
F 1 "+5V" H 9950 6040 50  0000 C CNN
F 2 "" H 9950 5900 50  0001 C CNN
F 3 "" H 9950 5900 50  0001 C CNN
	1    9950 5900
	1    0    0    -1  
$EndComp
$Comp
L power:GND #PWR015
U 1 1 5B79C53D
P 9950 6200
F 0 "#PWR015" H 9950 5950 50  0001 C CNN
F 1 "GND" H 9950 6050 50  0000 C CNN
F 2 "" H 9950 6200 50  0001 C CNN
F 3 "" H 9950 6200 50  0001 C CNN
	1    9950 6200
	1    0    0    -1  
$EndComp
Wire Wire Line
	8400 3150 8400 3250
Wire Wire Line
	8450 3050 8450 3600
Wire Wire Line
	7750 5900 8250 5900
Wire Wire Line
	8250 5900 8700 5900
Wire Wire Line
	8700 5900 9150 5900
Wire Wire Line
	7750 6200 8250 6200
Wire Wire Line
	8250 6200 8700 6200
Wire Wire Line
	8700 6200 9150 6200
NoConn ~ 8550 1450
NoConn ~ 8550 1550
NoConn ~ 10550 1450
NoConn ~ 10550 1550
$Comp
L Mechanical:MountingHole H1
U 1 1 5D7E2E6F
P 10450 5650
F 0 "H1" H 10550 5696 50  0000 L CNN
F 1 "MountingHole" H 10550 5605 50  0000 L CNN
F 2 "MountingHole:MountingHole_3.2mm_M3" H 10450 5650 50  0001 C CNN
F 3 "~" H 10450 5650 50  0001 C CNN
	1    10450 5650
	1    0    0    -1  
$EndComp
$Comp
L Mechanical:MountingHole H2
U 1 1 5D7E37F6
P 10450 5850
F 0 "H2" H 10550 5896 50  0000 L CNN
F 1 "MountingHole" H 10550 5805 50  0000 L CNN
F 2 "MountingHole:MountingHole_3.2mm_M3" H 10450 5850 50  0001 C CNN
F 3 "~" H 10450 5850 50  0001 C CNN
	1    10450 5850
	1    0    0    -1  
$EndComp
$Comp
L Mechanical:MountingHole H3
U 1 1 5D7E3FF0
P 10450 6050
F 0 "H3" H 10550 6096 50  0000 L CNN
F 1 "MountingHole" H 10550 6005 50  0000 L CNN
F 2 "MountingHole:MountingHole_3.2mm_M3" H 10450 6050 50  0001 C CNN
F 3 "~" H 10450 6050 50  0001 C CNN
	1    10450 6050
	1    0    0    -1  
$EndComp
$Comp
L Mechanical:MountingHole H4
U 1 1 5D7E447C
P 10450 6250
F 0 "H4" H 10550 6296 50  0000 L CNN
F 1 "MountingHole" H 10550 6205 50  0000 L CNN
F 2 "MountingHole:MountingHole_3.2mm_M3" H 10450 6250 50  0001 C CNN
F 3 "~" H 10450 6250 50  0001 C CNN
	1    10450 6250
	1    0    0    -1  
$EndComp
$Comp
L Connector_Generic:Conn_02x08_Odd_Even J1
U 1 1 5D59DBDF
P 5000 3050
F 0 "J1" H 5050 3450 50  0000 C CNN
F 1 "Conn_02x08_Odd_Even" H 5150 2550 50  0000 C CNN
F 2 "Connector_IDC:IDC-Header_2x08_P2.54mm_Vertical" H 5000 3050 50  0001 C CNN
F 3 "~" H 5000 3050 50  0001 C CNN
	1    5000 3050
	1    0    0    -1  
$EndComp
Text Notes 5950 3550 0    60   ~ 0
SERIAL\nconnection
Wire Wire Line
	4800 3250 4700 3250
Wire Wire Line
	4700 3250 4700 3450
Wire Wire Line
	4800 3450 4700 3450
Connection ~ 4700 3450
Wire Wire Line
	4700 3450 4700 3650
$Comp
L power:GND #PWR04
U 1 1 5D5BE2A8
P 4700 3650
F 0 "#PWR04" H 4700 3400 50  0001 C CNN
F 1 "GND" H 4700 3500 50  0000 C CNN
F 2 "" H 4700 3650 50  0001 C CNN
F 3 "" H 4700 3650 50  0001 C CNN
	1    4700 3650
	1    0    0    -1  
$EndComp
Wire Wire Line
	4800 2950 4700 2950
Wire Wire Line
	4700 2950 4700 2550
Wire Wire Line
	4800 3150 4200 3150
Wire Wire Line
	5300 3250 5800 3250
Wire Wire Line
	4800 2750 4600 2750
NoConn ~ 5300 2950
NoConn ~ 5300 3050
NoConn ~ 5300 3150
NoConn ~ 5300 3350
NoConn ~ 5300 3450
NoConn ~ 4800 2850
NoConn ~ 4800 3050
NoConn ~ 4800 3350
$Comp
L nascom_sd-rescue:R R3
U 1 1 5D674C11
P 6200 2850
F 0 "R3" V 6280 2850 50  0000 C CNN
F 1 "33R" V 6200 2850 50  0000 C CNN
F 2 "Resistor_THT:R_Axial_DIN0204_L3.6mm_D1.6mm_P7.62mm_Horizontal" V 6130 2850 50  0001 C CNN
F 3 "" H 6200 2850 50  0001 C CNN
	1    6200 2850
	0    1    1    0   
$EndComp
Text Label 6550 2850 0    50   ~ 0
SERCLK_NAS
Text Notes 5350 3250 0    50   ~ 0
"20mA out"
Text Notes 4300 3150 0    50   ~ 0
"20mA in"
$Comp
L nascom_sd-rescue:R R2
U 1 1 5D6B14CC
P 5800 2550
F 0 "R2" V 5880 2550 50  0000 C CNN
F 1 "100K" V 5800 2550 50  0000 C CNN
F 2 "Resistor_THT:R_Axial_DIN0204_L3.6mm_D1.6mm_P7.62mm_Horizontal" V 5730 2550 50  0001 C CNN
F 3 "" H 5800 2550 50  0001 C CNN
	1    5800 2550
	-1   0    0    1   
$EndComp
Wire Wire Line
	5800 2700 5800 3250
Text Label 6550 3250 0    50   ~ 0
NAS_TXD
Text Label 4050 3150 2    50   ~ 0
RXD_NAS
$Comp
L Connector_Generic:Conn_02x13_Odd_Even J3
U 1 1 5D6EAB8B
P 8000 2850
F 0 "J3" H 8050 3550 50  0000 C CNN
F 1 "Conn_02x13_Odd_Even" H 8000 2150 50  0000 C CNN
F 2 "Connector_IDC:IDC-Header_2x13_P2.54mm_Vertical" H 8000 2850 50  0001 C CNN
F 3 "~" H 8000 2850 50  0001 C CNN
	1    8000 2850
	1    0    0    -1  
$EndComp
Text Label 10600 2250 0    60   ~ 0
PIO_B4
Text Label 10600 2350 0    60   ~ 0
PIO_B3
Text Label 10600 2450 0    60   ~ 0
PIO_B2
Text Label 10600 2550 0    60   ~ 0
PIO_B1
Text Label 10600 2650 0    60   ~ 0
PIO_B0
NoConn ~ 10350 2850
NoConn ~ 10350 3450
$Comp
L power:GND #PWR017
U 1 1 5D792237
P 10500 3600
F 0 "#PWR017" H 10500 3350 50  0001 C CNN
F 1 "GND" H 10500 3450 50  0000 C CNN
F 2 "" H 10500 3600 50  0001 C CNN
F 3 "" H 10500 3600 50  0001 C CNN
	1    10500 3600
	1    0    0    -1  
$EndComp
Text Label 10600 2750 0    60   ~ 0
PIO_BRDY
Text Label 10600 3350 0    60   ~ 0
PIO_A7
Text Label 9600 2250 2    60   ~ 0
PIO_B5
Text Label 9600 2350 2    60   ~ 0
PIO_B6
Text Label 9600 2450 2    60   ~ 0
PIO_B7
Text Label 9600 2550 2    60   ~ 0
PIO_ARDY
Text Label 9600 2650 2    60   ~ 0
PIO_BSTB
Text Label 9600 2750 2    60   ~ 0
PIO_ASTB
Text Label 9600 2850 2    60   ~ 0
PIO_A0
Text Label 9600 2950 2    60   ~ 0
PIO_A1
Text Label 9600 3050 2    60   ~ 0
PIO_A2
Text Label 9600 3150 2    60   ~ 0
PIO_A3
Text Label 9600 3250 2    60   ~ 0
PIO_A4
Text Label 9600 3350 2    60   ~ 0
PIO_A5
Text Label 9600 3450 2    60   ~ 0
PIO_A6
Text Notes 11100 2900 2    60   ~ 0
(daisy-chain)
Wire Wire Line
	9600 2250 9850 2250
Wire Wire Line
	9600 2350 9850 2350
Wire Wire Line
	9600 2450 9850 2450
Wire Wire Line
	9600 2550 9850 2550
Wire Wire Line
	9600 2650 9850 2650
Wire Wire Line
	9600 2750 9850 2750
Wire Wire Line
	9600 2850 9850 2850
Wire Wire Line
	9600 2950 9850 2950
Wire Wire Line
	9600 3050 9850 3050
Wire Wire Line
	9600 3150 9850 3150
Wire Wire Line
	9600 3250 9850 3250
Wire Wire Line
	9600 3350 9850 3350
Wire Wire Line
	9600 3450 9850 3450
Wire Wire Line
	10350 2250 10600 2250
Wire Wire Line
	10600 2350 10350 2350
Wire Wire Line
	10600 2450 10350 2450
Wire Wire Line
	10600 2550 10350 2550
Wire Wire Line
	10600 2650 10350 2650
Wire Wire Line
	10600 2750 10350 2750
Wire Wire Line
	10600 3350 10350 3350
Wire Wire Line
	10350 3150 10450 3150
Wire Wire Line
	10450 3250 10350 3250
Connection ~ 10450 3150
Wire Wire Line
	10350 2950 10500 2950
Wire Wire Line
	10500 2950 10500 3050
Wire Wire Line
	10350 3050 10500 3050
Connection ~ 10500 3050
Wire Wire Line
	10450 3150 10450 3250
Wire Wire Line
	10500 3050 10500 3600
$Comp
L Connector_Generic:Conn_02x13_Odd_Even J6
U 1 1 5D792271
P 10050 2850
F 0 "J6" H 10100 3550 50  0000 C CNN
F 1 "Conn_02x13_Odd_Even" H 10050 2150 50  0000 C CNN
F 2 "Connector_IDC:IDC-Header_2x13_P2.54mm_Vertical" H 10050 2850 50  0001 C CNN
F 3 "~" H 10050 2850 50  0001 C CNN
	1    10050 2850
	1    0    0    -1  
$EndComp
$Comp
L Connector_Generic:Conn_01x06 J2
U 1 1 5D7AF727
P 6550 1150
F 0 "J2" H 6500 1450 50  0000 L CNN
F 1 "Conn_01x06" H 6450 750 50  0000 L CNN
F 2 "Connector_PinHeader_2.54mm:PinHeader_1x06_P2.54mm_Vertical" H 6550 1150 50  0001 C CNN
F 3 "~" H 6550 1150 50  0001 C CNN
	1    6550 1150
	1    0    0    -1  
$EndComp
Wire Wire Line
	6350 1450 6250 1450
$Comp
L power:GND #PWR07
U 1 1 5D7D3584
P 6250 1450
F 0 "#PWR07" H 6250 1200 50  0001 C CNN
F 1 "GND" H 6250 1300 50  0000 C CNN
F 2 "" H 6250 1450 50  0001 C CNN
F 3 "" H 6250 1450 50  0001 C CNN
	1    6250 1450
	1    0    0    -1  
$EndComp
Connection ~ 6000 2850
Wire Wire Line
	6000 2850 6050 2850
Connection ~ 4200 3150
Wire Wire Line
	4200 3150 4050 3150
Connection ~ 5900 3250
Wire Wire Line
	5900 3250 6550 3250
Wire Wire Line
	5800 3250 5900 3250
Connection ~ 5800 3250
Wire Wire Line
	6350 2850 6550 2850
Wire Wire Line
	5800 2400 5800 2200
Text Notes 6700 1250 0    60   ~ 0
Serial\nconnection
Text Notes 8750 1250 0    60   ~ 0
PIO\nconnection
Wire Wire Line
	5300 2750 5400 2750
Wire Wire Line
	5500 2850 6000 2850
Wire Wire Line
	5500 2850 5300 2850
Connection ~ 5500 2850
Wire Wire Line
	4700 2550 5500 2550
Wire Wire Line
	5500 2550 5500 2850
Text Label 4050 2750 2    50   ~ 0
NAS_DRIVE
NoConn ~ 2300 4250
NoConn ~ 2100 4250
NoConn ~ 2700 5050
NoConn ~ 2700 4750
NoConn ~ 2700 4650
Wire Wire Line
	2700 5450 3700 5450
$Comp
L power:GND #PWR01
U 1 1 5D7A4406
P 2300 6500
F 0 "#PWR01" H 2300 6250 50  0001 C CNN
F 1 "GND" H 2305 6327 50  0000 C CNN
F 2 "" H 2300 6500 50  0001 C CNN
F 3 "" H 2300 6500 50  0001 C CNN
	1    2300 6500
	1    0    0    -1  
$EndComp
Wire Wire Line
	2300 6400 2300 6500
Connection ~ 2300 6400
Wire Wire Line
	2200 6400 2300 6400
Wire Wire Line
	2200 6250 2200 6400
Wire Wire Line
	2300 6250 2300 6400
$Comp
L power:+5V #PWR02
U 1 1 5D7908D8
P 2400 4100
F 0 "#PWR02" H 2400 3950 50  0001 C CNN
F 1 "+5V" H 2415 4273 50  0000 C CNN
F 2 "" H 2400 4100 50  0001 C CNN
F 3 "" H 2400 4100 50  0001 C CNN
	1    2400 4100
	1    0    0    -1  
$EndComp
Wire Wire Line
	2400 4250 2400 4100
Text Notes 2800 5550 0    50   ~ 0
"CMD"
Text Notes 2800 5350 0    50   ~ 0
"T2H"
Text Notes 2800 5950 0    50   ~ 0
"H2T"
Text Label 3150 5650 0    50   ~ 0
PIO_A4
Text Label 3150 5350 0    50   ~ 0
PIO_B0
Text Label 3150 5250 0    50   ~ 0
PIO_A7
Text Label 1150 4850 2    50   ~ 0
PIO_A0
Wire Wire Line
	1700 4850 1150 4850
Text Label 1150 5950 2    50   ~ 0
SCK
Text Label 1150 5850 2    50   ~ 0
MISO
Text Label 1150 5750 2    50   ~ 0
MOSI
Text Label 1150 5650 2    50   ~ 0
CS_N
Text Label 1150 5550 2    50   ~ 0
SERCLK_NAS
Text Label 1150 5450 2    50   ~ 0
RXD_NAS
Wire Wire Line
	2700 5950 3150 5950
Wire Wire Line
	2700 5850 3150 5850
Wire Wire Line
	2700 5750 3150 5750
Wire Wire Line
	2700 5650 3150 5650
Wire Wire Line
	2700 5550 3150 5550
Wire Wire Line
	2700 5350 3150 5350
Wire Wire Line
	2700 5250 3150 5250
Wire Wire Line
	1700 5950 1150 5950
Wire Wire Line
	1700 5850 1150 5850
Wire Wire Line
	1700 5750 1150 5750
Wire Wire Line
	1700 5650 1150 5650
Wire Wire Line
	1700 5550 1150 5550
Wire Wire Line
	1700 5450 1150 5450
Text Label 1150 5350 2    50   ~ 0
NAS_TXD
Text Label 1150 5250 2    50   ~ 0
PIO_A6
Text Label 1150 5150 2    50   ~ 0
PIO_A3
Text Label 1150 5050 2    50   ~ 0
PIO_A2
Text Label 1150 4950 2    50   ~ 0
PIO_A1
Wire Wire Line
	1700 5350 1150 5350
Wire Wire Line
	1700 5250 1150 5250
Wire Wire Line
	1700 5150 1150 5150
Wire Wire Line
	1700 5050 1150 5050
Wire Wire Line
	1700 4950 1150 4950
$Comp
L MCU_Module:Arduino_Nano_v3.x A1
U 1 1 5D5947FF
P 2200 5250
F 0 "A1" H 2450 4200 50  0000 C CNN
F 1 "Arduino_Nano_v3.x" H 2750 4100 50  0000 C CNN
F 2 "Module:Arduino_Nano" H 2350 4300 50  0001 L CNN
F 3 "http://www.mouser.com/pdfdocs/Gravitech_Arduino_Nano3_0.pdf" H 2200 4250 50  0001 C CNN
	1    2200 5250
	1    0    0    -1  
$EndComp
$Comp
L nascom_sd-rescue:R R1
U 1 1 5B79A006
P 3850 5450
F 0 "R1" V 3930 5450 50  0000 C CNN
F 1 "4k7" V 3850 5450 50  0000 C CNN
F 2 "Resistor_THT:R_Axial_DIN0204_L3.6mm_D1.6mm_P7.62mm_Horizontal" V 3780 5450 50  0001 C CNN
F 3 "" H 3850 5450 50  0001 C CNN
	1    3850 5450
	0    1    1    0   
$EndComp
Wire Wire Line
	6000 1350 6000 2850
Wire Wire Line
	6000 1350 6350 1350
Wire Wire Line
	5900 1250 5900 3250
Wire Wire Line
	5900 1250 6350 1250
Wire Wire Line
	4600 2750 4600 1150
Wire Wire Line
	4600 1150 6350 1150
Connection ~ 4600 2750
Wire Wire Line
	4050 2750 4600 2750
Wire Wire Line
	4200 1050 6350 1050
Wire Wire Line
	4200 1050 4200 3150
Wire Wire Line
	5800 2200 5400 2200
Wire Wire Line
	5400 2200 5400 2750
Wire Notes Line
	3550 1950 3550 3950
Wire Notes Line
	3550 3950 11100 3950
Wire Notes Line
	11100 3950 11100 1950
Wire Notes Line
	3550 1950 11100 1950
Text Notes 8300 3900 2    60   ~ 12
NASCOM2 Connections
NoConn ~ 7850 1250
NoConn ~ 7850 1350
NoConn ~ 7850 1450
NoConn ~ 7850 1550
NoConn ~ 7850 1650
Text Label 3150 5550 0    50   ~ 0
PIO_B2
Text Label 3150 5950 0    50   ~ 0
PIO_B1
Text Label 3150 5850 0    50   ~ 0
NAS_DRIVE
Text Label 3150 5750 0    50   ~ 0
PIO_A5
Text Notes 8250 7650 0    50   ~ 0
26-Jul-2020
NoConn ~ 1700 4650
NoConn ~ 1700 4750
Wire Wire Line
	9150 6200 9600 6200
Text Notes 7800 5800 0    60   ~ 0
No power flag on 5V because the NANO\nmodule has that property on its power pin
Wire Wire Line
	8850 4600 8800 4600
Wire Wire Line
	8800 4600 8800 4300
$Comp
L power:PWR_FLAG #FLG0101
U 1 1 5D5F891C
P 9600 6200
F 0 "#FLG0101" H 9600 6275 50  0001 C CNN
F 1 "PWR_FLAG" H 9600 6373 50  0000 C CNN
F 2 "" H 9600 6200 50  0001 C CNN
F 3 "~" H 9600 6200 50  0001 C CNN
	1    9600 6200
	1    0    0    -1  
$EndComp
Connection ~ 9600 6200
Wire Wire Line
	9600 6200 9950 6200
Wire Wire Line
	9150 5900 9950 5900
Text Notes 950  1050 0    79   ~ 16
NASCOM 2 Setup for serial interface:\nLSW2 -- all switches to Up/On\nLSW1/5 to Up/On (1 Stop bit)
Text Notes 10800 7650 0    50   ~ 0
REV B
Wire Notes Line
	3550 5750 3650 5750
Wire Notes Line
	3650 5750 3650 5950
Wire Notes Line
	3650 5950 3550 5950
Wire Notes Line
	3650 5850 3750 5850
Wire Notes Line
	3750 5850 3750 6400
Text Notes 3650 6700 0    60   ~ 0
A6 and A7 exist on NANO but not on UNO.\nThey are input-only pins and can only be\nsampled via the ADC.
Wire Wire Line
	4050 650  5400 650 
Wire Wire Line
	8700 650  8700 950 
Wire Wire Line
	8700 650  10700 650 
Wire Wire Line
	10700 650  10700 950 
Connection ~ 8700 650 
Wire Wire Line
	5400 2200 5400 650 
Connection ~ 5400 2200
Connection ~ 5400 650 
Wire Wire Line
	5400 650  6000 650 
Text Label 4050 650  2    50   ~ 0
NAS_5V
Wire Wire Line
	6350 950  6000 950 
Wire Wire Line
	6000 950  6000 650 
Connection ~ 6000 650 
Wire Wire Line
	6000 650  8700 650 
Wire Notes Line
	11100 1900 6100 1900
Wire Notes Line
	6100 1900 6100 700 
Wire Notes Line
	6100 700  11100 700 
Wire Notes Line
	11100 700  11100 1900
Wire Wire Line
	8400 2050 10450 2050
Wire Wire Line
	8400 2050 8400 3150
Wire Wire Line
	10450 2050 10450 3150
Wire Wire Line
	10450 2050 10950 2050
Wire Wire Line
	10950 2050 10950 650 
Wire Wire Line
	10950 650  10700 650 
Connection ~ 10450 2050
Connection ~ 10700 650 
$Comp
L Diode:1N5817 D2
U 1 1 5F2AEB66
P 2000 2150
F 0 "D2" V 1954 2229 50  0000 L CNN
F 1 "1N5817" V 2045 2229 50  0000 L CNN
F 2 "Diode_THT:D_DO-41_SOD81_P10.16mm_Horizontal" H 2000 1975 50  0001 C CNN
F 3 "http://www.vishay.com/docs/88525/1n5817.pdf" H 2000 2150 50  0001 C CNN
	1    2000 2150
	0    1    1    0   
$EndComp
Wire Wire Line
	2000 2000 2000 1750
$Comp
L power:+5V #PWR0101
U 1 1 5F2E75EA
P 2000 1750
F 0 "#PWR0101" H 2000 1600 50  0001 C CNN
F 1 "+5V" H 2015 1923 50  0000 C CNN
F 2 "" H 2000 1750 50  0001 C CNN
F 3 "" H 2000 1750 50  0001 C CNN
	1    2000 1750
	1    0    0    -1  
$EndComp
Wire Wire Line
	2000 2300 2000 2500
Wire Wire Line
	2000 2500 1650 2500
Text Label 1650 2500 2    50   ~ 0
NAS_5V
Text Notes 800  3400 0    50   ~ 0
Use-cases:\n1/ Board not connected to NASCOM; powered via USB:\nNAS_5V inactive; board powered from USB.\n2/ Board connected to NASCOM, USB disconnected:\nNAS_5V active; board powered from NASCOM.\n3/ Board connected to NASCOM, USB connected:\nUSB and NAS_5V active; board powered from either\nor both (highest voltage wins). If NASCOM is turned\noff before USB, this diode prevents the NANO from\npowering the NASCOM.
$Comp
L Connector_Generic:Conn_01x01 J8
U 1 1 5F2FC69D
P 6800 6200
F 0 "J8" H 6718 5975 50  0000 C CNN
F 1 "Conn_01x01" H 6718 6066 50  0000 C CNN
F 2 "Connector_Pin:Pin_D1.0mm_L10.0mm" H 6800 6200 50  0001 C CNN
F 3 "~" H 6800 6200 50  0001 C CNN
	1    6800 6200
	-1   0    0    1   
$EndComp
Wire Wire Line
	7000 6200 7750 6200
Connection ~ 7750 6200
Text Notes 7350 6350 2    50   ~ 0
GND connection for scope probe
$EndSCHEMATC
