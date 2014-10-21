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
Dim W As Long
Dim W_v As Long
Dim Channel1 As Byte , Channel2 As Byte
Dim V1 As Word , V2 As Word
Dim W1 As Long , W2 As Long , W3 As Long , W4 As Long , W5 As Long
Dim 1c As Long , 1c_vout As Single , 1c_vin As Single , 1c_vin_long As Word
Dim X As Single , X_v As Single , X_l As Long
Dim Delta_1c As Single , Delta_1c_long As Long

Dim Fractional As Long

Channel1 = 0
Channel2 = 1

Config Single = Scientific , Digits = 7

W = 160
1c = 683       '~2.2V

Do

   W_v = W * 3222656
   X = W_v
   X = X / 1000000000
   X = X * 0.997815783
   X = X - 1.157429454
   'X_l = X * 1000000000
   Print X


   ' Spannungen nach dem Spannungsteiler
   1c_vout = 1c * 3222656
   1c_vout = 1c_vout / 1000000000


   '1c_vout = 1c_vout * 1000000000
   Delta_1c = 1c_vout - X
   Delta_1c = Delta_1c * 1000000       'remove decimal point
   Delta_1c_long = Delta_1c
   'Fractional = Lon Delta_1c Mod 10
   Delta_1c_long = Delta_1c_long / 100000

   ' Spannungen vor dem Spannungsteiler
   ' 1c_vin = (10k + 45.7k) * (1c_vout / 45.7k)
   1c_vin = 1c_vout / 45700
   1c_vin = 1c_vin * 55700
   1c_vin_long = 1c_vin * 100

Loop
                                                           'unconditional loop
End