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
' Diese Frequenz ermöglich Serielle BAUD Raten mit 0% Fehler
' Wichtig: Der Mega muss den Ext Osc. Fuse gesetzt haben
$crystal = 8000000
' Print/RS232 Baud Rate
$baud = 9600

$hwstack = 32       ' default use 32 for the hardware stack
$swstack = 10       ' default use 10 for the SW stack
$framesize = 40       ' default use 40 for the frame space

' Configure lcd screen
Config Lcdpin = Pin , Db4 = Portd.4 , Db5 = Portd.5 , Db6 = Portd.6 , Db7 = Portd.7 , E = Portd.3 , Rs = Portd.2
Config Lcd = 16 * 2

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
'Config Portc = Input

'Const Ref = 3.3 / 1024

' Byte Types are unsigned 8-Bit numbers, 0 to 255 (1 Byte used)
' Integer Types are signed 16-Bit numbers, -32,768 to +32,767 (2 Bytes used)
' Word Types are unsigned 16-Bit Numbers, 0 to 65535 (2 Bytes used)
' Long Types are signed 32-Bit Numbers, -2147483648 to 2147483647 (4 Bytes used)

Dim A As Byte
Dim Temp As Byte       ' Used when shifting the 10 bit ADC into Byte vars
Dim Temp_word As Word
Dim W As Long , X As Word , Y As Word , Z As Word
Dim W_v As Long , X_v As Long , Y_v As Long , Z_v As Long
Dim Channel1 As Byte , Channel2 As Byte
Dim V1 As Word , V2 As Word
Dim W1 As Long , W2 As Long , W3 As Long , W4 As Long , W5 As Long
Dim W_v_d As Single
Channel1 = 0
Channel2 = 1

W = &H3FF
Shift W , Right , 3

Print "M8 Slave Voltage Monitor V2"

Cls       'clear the LCD display
Lcd "Hello world."       'display this at the top line
Lowerline       'select the lower line
Wait 1
Lcd "ATMega8 ADC Demo"       'display this at the lower line
Wait 1
For A = 1 To 16
   Shiftlcd Right       'shift the text to the right
   Waitms 100       'wait a moment
Next

Cls
Shiftlcd Left 17


Do
Led = 1       'switch off all LEDS
Waitms 300       'wait 1 second
Led = 0

Disable Interrupts
   'W = Getadc(0)
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

   X = Getadc(1)
   Y = Getadc(2)
   Z = Getadc(3)

   ' Calculate the correct voltage by + or - the offset
   'If W < 500 Then
   '   W_v = W * 3222
   '   W_v = 100
   'Else
   '   W_v = W * 3222
   '   W_v = W_v + 1000
   'End If

   W_v = W * 3222656
   'W_v = W_v * 0.997815783

   W_v_d = W_v

   W_v_d = W_v_d / 1000000000

   W_v_d = W_v_d * 997815783

   'W_v = W_v - 1.1575429454
   W_v_d = W_v_d - 1157429454

   'W_v_d = W_v_d / 1000000000


   'W_v = W_v - 5000       '
   'W_v = W_v + 7000       ' ADC genauigkeit offset wert

   X_v = X * 3222
   Y_v = Y * 3222
   Z_v = Z * 3222

   Print "CH0: " ; W_v_d ; " CH1: " ; X_v ; " CH2: " ; Y_v ; " CH3: " ; Z_v


Enable Interrupts

  'Upperline
 ' Cls       ' Clear the LCD
 ' Lcd "Ch " ; Channel1 ; ": " ; W
  'Lowerline
  'W = Getadc(1)
 ' Lcd "Ch " ; Channel2 ; ": " ; W
  Waitms 500
'Print "Toggle PortB.1"
Waitms 300       'wait 1 second

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

  Temp = W       ' only fist 8 bits of w are assigend to temp
  Temp_word = W       ' all 10 bits of adc value stored in Temp_word
  Shift Temp_word , Right , 8

  If Twi_btr = 1 Then       ' send lower 8 bits of adc value
    Twi = Temp
   ' Print "Sent lower 8: " ; Twi
    'Twi = 5
  Elseif Twi_btr = 2 Then       'send remaining 2 bits of adc value
    Twi = Temp_word
   ' Print "Sent upper 2: " ; Twi
    'Twi = 50
    'Print "twi is: " ; Twi
  Else
    Twi = 0
  End If

Return


'when the mast has all bytes received this label will be called
Twi_master_need_nomore_byte:
  'Print "Master does not need anymore bytes"
Return