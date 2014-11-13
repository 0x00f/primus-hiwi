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


' Byte Types are unsigned 8-Bit numbers, 0 to 255 (1 Byte used)
' Integer Types are signed 16-Bit numbers, -32,768 to +32,767 (2 Bytes used)
' Word Types are unsigned 16-Bit Numbers, 0 to 65535 (2 Bytes used)
' Long Types are signed 32-Bit Numbers, -2147483648 to 2147483647 (4 Bytes used)

' These Vars store the Raw ADC Data, which is a 10 Bit Value between 0 and 1023
Dim W As Word , 1c As Word , 2c As Word , 3c As Word
Dim W_v As Long , 1c_vout As Single , 2c_vout As Single , 3c_vout As Single
Dim W_vin As Long , 1c_vin As Single , 2c_vin As Single , 3c_vin As Single
Dim Delta_1c As Single , Delta_2c As Single , Delta_3c As Single
Dim Delta_1c_b As Byte , Delta_2c_b As Byte , Delta_3c_b As Byte


Dim W_v_d As Single



Do

   W = 160
   1c = 400
   2c = 800
   3c = 1000


   ' GND Spannung
   W_v_d = W
   W_v_d = W_v_d * 3222656
   W_v_d = W_v_d / 1000000000
   W_v_d = W_v_d * 0.997815783
   W_v_d = W_v_d - 1.157429454

   W_v_d = -1.006295559


   ' Spannungen nach dem Spannungsteiler
   '1c_vout = 1c * 3222656
   '1c_vout = 1c_vout / 1000000000

   1c_vout = 1.907812116


   '2c_vout = 2c * 3222656
   '2c_vout = 2c_vout / 1000000000

   2c_vout = 2.320312017


   '3c_vout = 3c * 3222656
   '3c_vout = 3c_vout / 1000000000

   3c_vout = 2.462109086

   ' Spannungen vor dem Spannungsteiler
   ' 1c_vin = (10k + 45.7k) * (1c_vout / 45.7k)
   1c_vin = 1c_vout / 45700
   1c_vin = 1c_vin * 55700
   '1c_vin_long = 1c_vin * 100

   ' 2c_vin = (10k + 6956) * (2c_vout / 6956)
   2c_vin = 2c_vout / 6956
   2c_vin = 2c_vin * 16956
   '2c_vin_long = 2c_vin * 100

   ' 3c_vin = (10k + 3764) * (3c_vout / 3764)
   3c_vin = 3c_vout / 3764
   3c_vin = 3c_vin * 13764
   '3c_vin_long = 3c_vin * 100



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
   ' Somit müssen wir nicht alle Spannungen einzelnd zu Master senden
    Delta_1c = 1c_vin 

    Delta_2c = 2c_vin - 1c_vin

    Delta_3c = 3c_vin - 2c_vin


   ' Hier mappen wir die Differenzspannungen die zwischen 4.05V und 1.05V liegen
   ' auf Werte zwischen 0 und 255. Somit können die Daten in einem 8 Bit
   ' I2C Read gesendet werden:
   ' Schritt 1: Ziehe 1.5V von der gemessene Spannung ab
   Delta_1c = Delta_1c - 1.5
   Delta_2c = Delta_2c - 1.5
   Delta_3c = Delta_3c - 1.5

   ' Schritt 2: Multipliziere bei 100 (2.55 -> 255 = 0b11111111)
   ' Damit gilt für den min. Wert von 1.5: (1.50 - 1.50) * 100 = 000
   ' Für den max. Wert von 4.05 gilt:      (4.05 - 1.50) * 100 = 255
   Delta_1c = Delta_1c * 100
   Delta_2c = Delta_2c * 100
   Delta_3c = Delta_3c * 100

   ' Schritt 3: Speicher die Wert in Byte Variablen. Kommastellen fallen Weg
   Delta_1c_b = Delta_1c
   Delta_2c_b = Delta_2c
   Delta_3c_b = Delta_3c

   Print "CH0: " ; W_v_d ; " CH1: " ; 1c_vout ; " CH2: " ; 2c_vout ; " CH3: " ; 3c_vout
   Print "1C: " ; 1c_vin ; " 2C: " ; 2c_vin ; " 3C: " ; 3c_vin
   Print "Delta1: " ; Delta_1c_b ; " Delta2: " ; Delta_2c_b ; " Delta3: " ; Delta_3c_b

Loop
                                                           'unconditional loop
End