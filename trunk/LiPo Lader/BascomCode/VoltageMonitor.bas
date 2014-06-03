'************************************************
'*            L-Ion Voltage Supervisor          *
'*                 AVR = ATMega8                *
'*               V1.0 [30.05.2104]              *
'*           M.Schulze, M.A.Stadtlander         *
'*        Kompiliert mit BASCOM AVR 2.0.7.5     *
'*           ZARM Universitaet Bremen           *
'************************************************

' Wir benutzen den ATMega8
$regfile = "m8def.dat"

' MyAVR Board hat ein 3.6864MHz Crystal
' Diese Frequenz ermöglich Serielle BAUD Raten mit 0% Fehler
$crystal = 3686400
' Wichtig: Der Mega muss den Ext Osc. Fuse gesetzt haben

' Print/RS232 Baud Rate
$baud = 9600

'configure single mode and auto prescaler setting
'The single mode must be used with the GETADC() function

'The prescaler divides the internal clock by 2,4,8,16,32,64 or 128
'Because the ADC needs a clock from 50-200 KHz
'The AUTO feature, will select the highest clockrate possible
Config Adc = Single , Prescaler = Auto , Reference = Avcc
'Now give power to the chip
Start Adc

Leds Alias Portb.1       'Define name
Config Portb = Output       'Config Port A as output
Config Portc = Input
Dim S As String * 10
Dim A As Byte
Dim Mybaud As Long
Dim C As Integer
Dim W As Word , Channel1 As Byte , Channel2 As Byte
Dim V1 As Word , V2 As Word
Channel1 = 0
Channel2 = 1

C = 1
Print "print variable c " ; C

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

S = "Hello"
Mybaud = 19200

Do       'sdfsd
Leds = 1       'switch off all LEDS
Waitms 300       'wait 1 second
Leds = 0
  W = Getadc(channel1)
  'V1 = * W
  Upperline
  Cls
  'Print "Channel " ; Ch1 ; " value " ; W
  Lcd "Ch " ; Channel1 ; ": " ; W
  Lowerline
  W = Getadc(channel2)
 ' Print "Channel " ; Ch2 ; " value " ; W
  Lcd "Ch " ; Channel2 ; ": " ; W
  Waitms 500
'Serout S , 0 , D , 1 , Mybaud , 0 , 8 , 1       'switch on all LEDs
Print "Toggle PortB.1"
Waitms 300       'wait 1 second

Loop
                                                           'unconditional loop
End