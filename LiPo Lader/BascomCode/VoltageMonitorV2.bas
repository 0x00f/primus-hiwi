'************************************************
'*            L-Ion Voltage Supervisor          *
'*                 AVR = ATMega8                *
'*               V1.0 [30.05.2104]              *
'*           M.Schulze, M.A.Stadtlander         *
'*        Kompiliert mit BASCOM AVR 2.0.7.7     *
'*           ZARM Universitaet Bremen           *
'************************************************

' Wir benutzen den ATMega8
$regfile = "m8def.dat"
' MyAVR Board hat ein 3.6864MHz Crystal
' Diese Frequenz erm�glich Serielle BAUD Raten mit 0% Fehler
' Wichtig: Der Mega muss den Ext Osc. Fuse gesetzt haben
$crystal = 8000000
' Print/RS232 Baud Rate
$baud = 9600

$hwstack = 32       ' default use 32 for the hardware stack
$swstack = 10       ' default use 10 for the SW stack
$framesize = 40       ' default use 40 for the frame space


' Configure ADC
' Configure single mode and auto prescaler setting
' The single mode must be used with the GETADC() function
' The prescaler divides the internal clock by 2,4,8,16,32,64 or 128
' Because the ADC needs a clock from 50-200 KHz
' The AUTO feature, will select the highest clockrate possible
Config Adc = Single , Prescaler = Auto , Reference = Avcc
' Now give power to the chip
Start Adc

' Configure TWI / I2C
Config Twislave = &H70 , Btr = 2 , Bitrate = 100000 , Gencall = 1
' In i2c the address has 7 bits. The LS bit is used to indicate read or write
' When the bit is 0, it means a write and a 1 means a read
' When you address a slave with the master in bascom, the LS bit will be set/reset automatic.
' The TWAR register in the AVR is 8 bit with the slave address also in the most left 7 bits
' This means that when you setup the slave address as &H70, TWAR will be set to &H0111_0000
' And in the master you address the slave with address &H70 too.
' The AVR TWI can also recognize the general call address 0. You need to either set bit 0 for example
' by using &H71 as a slave address, or by using GENCALL=1



' As you might need other interrupts as well, you need to enable them all manual
Enable Interrupts


Led Alias Portb.0       'Define name
Config Portb = Output       'Config Port A as output


' Byte Types are unsigned 8-Bit numbers, 0 to 255 (1 Byte used)
' Integer Types are signed 16-Bit numbers, -32,768 to +32,767 (2 Bytes used)
' Word Types are unsigned 16-Bit Numbers, 0 to 65535 (2 Bytes used)
' Long Types are signed 32-Bit Numbers, -2147483648 to 2147483647 (4 Bytes used)

' These Vars store the Raw ADC Data, which is a 10 Bit Value between 0 and 1023
Dim W As Long , 1c As Word , 2c As Word , 3c As Word
Dim 1c_vout As Single , 2c_vout As Single , 3c_vout As Single
Dim W_vin As Long , 1c_vin As Single , 2c_vin As Single , 3c_vin As Single

Dim W1 As Long , W2 As Long , W3 As Long , W4 As Long , W5 As Long
Dim Delta_1c As Single , Delta_2c As Single , Delta_3c As Single
Dim Delta_1c_b As Byte , Delta_2c_b As Byte , Delta_3c_b As Byte

Dim W_v_d As Single



Print "M8 Slave Voltage Monitor V2.1"


Do
Led = 1       'switch off all LEDS
Waitms 500       'wait 1 second
Led = 0

Disable Interrupts

   W = 0
   W1 = Getadc(0)
   W2 = Getadc(0)
   W3 = Getadc(0)
   W4 = Getadc(0)
   W5 = Getadc(0)

   W = W + W1
   W = W + W2
   W = W + W3
   W = W + W4
   W = W + W5
   W = W / 5

   'Print "CH0 Raw ADC: " ; W

   1c = Getadc(1)
   2c = Getadc(2)
   3c = Getadc(3)


   ' GND Spannung
   W_v_d = W
   W_v_d = W_v_d * 3222656
   W_v_d = W_v_d / 1000000000
   W_v_d = W_v_d * 0.997815783
   W_v_d = W_v_d - 1.157429454


   ' Spannungen nach dem Spannungsteiler
   1c_vout = 1c * 3222656
   1c_vout = 1c_vout / 1000000000

   2c_vout = 2c * 3222656
   2c_vout = 2c_vout / 1000000000

   3c_vout = 3c * 3222656
   3c_vout = 3c_vout / 1000000000


   ' Spannungen vor dem Spannungsteiler
   ' 1c_vin = (10k + 45.7k) * (1c_vout / 45.7k)
   1c_vin = 1c_vout / 45700
   1c_vin = 1c_vin * 55700


   ' 2c_vin = (10k + 6956) * (2c_vout / 6956)
   2c_vin = 2c_vout / 6956
   2c_vin = 2c_vin * 16956


   ' 3c_vin = (10k + 3764) * (3c_vout / 3764)
   3c_vin = 3c_vout / 3764
   3c_vin = 3c_vin * 13764



   ' Hier addieren wir den offset des grounds zu den berechneten spannungen
   If W_v_d < 0 Then
      1c_vin = 1c_vin - W_v_d
      2c_vin = 2c_vin - W_v_d
      3c_vin = 3c_vin - W_v_d
   Else
      1c_vin = 1c_vin + W_v_d
      2c_vin = 2c_vin + W_v_d
      3c_vin = 3c_vin + W_v_d
   End If



   ' Hier werden die Differenzen zwischen einzelnen Spannungen berechnet
   ' Somit m�ssen wir nicht alle Spannungen einzelnd zu Master senden
    Delta_1c = 1c_vin 
    Delta_2c = 2c_vin - 1c_vin
    Delta_3c = 3c_vin - 2c_vin

   ' Hier mappen wir die Differenzspannungen die zwischen 4.05V und 1.5V liegen
   ' auf Werte zwischen 0 und 255. Somit k�nnen die Daten in einem 8 Bit
   ' I2C Read gesendet werden:
   ' Schritt 1: Ziehe 1.5V von der gemessene Spannung ab
   Delta_1c = Delta_1c - 1.5
   Delta_2c = Delta_2c - 1.5
   Delta_3c = Delta_3c - 1.5

   ' Schritt 2: Multipliziere bei 100 (2.55 -> 255 = 0b11111111)
   ' Damit gilt f�r den min. Wert von 1.5: (1.50 - 1.50) * 100 = 000
   ' F�r den max. Wert von 4.05 gilt:      (4.05 - 1.50) * 100 = 255
   Delta_1c = Delta_1c * 100
   Delta_2c = Delta_2c * 100
   Delta_3c = Delta_3c * 100

   ' Schritt 3: Speicher die Wert in Byte Variablen. Kommastellen fallen Weg
   Delta_1c_b = Delta_1c
   Delta_2c_b = Delta_2c
   Delta_3c_b = Delta_3c

   Enable Interrupts

   Print "CH0 ADC: " ; W_v_d ; " CH1 ADC: " ; 1c_vout ; " CH2 ADC: " ; 2c_vout ; " CH3 ADC: " ; 3c_vout
   Print "1C Voltage: " ; 1c_vin ; " 2C Voltage: " ; 2c_vin ; " 3C Voltage: " ; 3c_vin
   Print "Delta1: " ; Delta_1c_b ; " Delta2: " ; Delta_2c_b ; " Delta3: " ; Delta_3c_b



Waitms 500
'Print "Toggle PortB.1"

Loop
                                                           'unconditional loop
End


'A master can send or receive bytes.
'A master protocol can also send some bytes, then receive some bytes
'The master and slave must match.

'the following labels are called from the library
Twi_stop_rstart_received:
  'Print "Master sent stop or repeated start"
Return


Twi_addressed_goread:
  'Print "We were addressed and master will send data"
Return


Twi_addressed_gowrite:
  'Print "We were addressed and master will read data"
Return


'this label is called when the master sends data and the slave has received the byte
'the variable TWI holds the received value
Twi_gotdata:
   'Print "received : " ; Twi
Return


'this label is called when the master receives data and needs a byte
'the variable twi_btr is a byte variable that holds the index of the needed byte
'so when sending multiple bytes from an array, twi_btr can be used for the index

Twi_master_needs_byte:
  'Print "Master needs byte : " ; Twi_btr
  'Print "ADC value: " ; W

  If Twi_btr = 1 Then       ' send lower 8 bits of adc value
    Twi = Delta_1c_b
   ' Print "Sent lower 8: " ; Twi
    'Twi = 5
  Elseif Twi_btr = 2 Then       'send remaining 2 bits of adc value
    Twi = Delta_2c_b
   ' Print "Sent upper 2: " ; Twi
    'Twi = 50
    'Print "twi is: " ; Twi
  Elseif Twi_btr = 3 Then
    Twi = Delta_3c_b
  Else
    Twi = 0
  End If

Return


'when the mast has all bytes received this label will be called
Twi_master_need_nomore_byte:
  'Print "Master does not need anymore bytes"
Return