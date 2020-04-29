RTE v.0.5.3 with APU2 connection
================================

* Power supply

Power to the APU2 is delivered by 2.5/5.5 mm DC Jack cable.
Connect 12 V, 2 A power supply to RTE J13 connector.
Then connect RTE J12 connector with APU2 J21 connector with DC Jack - DC Jack
wire.

* SPI

 RTE header J7 pin | APU2 header J6 pin
:-----------------:|:-------------------:
 1 (NC)            | Not connected
 2 (GND)           | 2 (GND)
 3 (CS)            | 3 (SPICS#)
 4 (SCLK)          | 4 (SPICLK)
 5 (MISO)          | 5 (SPIDI)
 6 (MOSI)          | 6 (SPIDO)
 7 (NC)            | Not connected
 8 (NC)            | Not connected

SPI connection can be realized with IDC 8 pin wire, but 7th and 8th wires
have to be opened.

* Serial

Connection is realized with a RS 232 D-Sub - D-Sub cross cable.
Connect RTE RS 232 connector (J14) with APU2 RS 232 connector (J19).

If you don't have RS 232 D-Sub - D-Sub cable you can short RS232 connector pins
in the following way:

Without hardware flow control:

 RTE RS 232 connector (J14) | APU2 RS 232 connector (J19)
:--------------------------:|:---------------------------:
 2 (RS232 RX)               | 3 (RS232 TX)
 3 (RS232 TX)               | 2 (RS232 RX)
 5 (GND)                    | 5 (GND)

With hardware flow control:

 RTE RS 232 connector (J14) | APU2 RS 232 connector (J19)
:--------------------------:|:---------------------------:
 2 (RS232 RX)               | 3 (RS232 TX)
 3 (RS232 TX)               | 2 (RS232 RX)
 5 (GND)                    | 5 (GND)
 7 (RS232 RTS)              | 8 (RS232 CTS)
 8 (RS232 CTS)              | 7 (RS232 RTS)

* Other pins

 RTE header J1 pin      | APU2 header J4 pin
:----------------------:|:------------------:
 1 (Orange Pi GPIO)     | 6 (LED1)
 2 (Orange Pi GPIO)     | 7 (LED2)
 3 (Orange Pi GPIO)     | 8 (LED3)

 RTE header J11 pin     | APU2 header J2 pin
:----------------------:|:------------------:
 9 (OC buffer output)   | 3 (PWR)
 8 (OC buffer output)   | 5 (RST)

 RTE header J11 pin     | APU2 header J4 pin
:----------------------:|:------------------:
 10 (OC buffer output)  | 5 (MODESW)
