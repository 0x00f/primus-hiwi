'----------------------------------------------------------------
'                  (c) 1995-2010, MCS
'                      xm128-ADC.bas
'  This sample demonstrates the Xmega128A1 ADC
'-----------------------------------------------------------------

$regfile = "xm64a3udef.dat"
$crystal = 32000000
$hwstack = 64
$swstack = 64
$framesize = 64


'First Enable The Osc Of Your Choice
Config Osc = Enabled , 32mhzosc = Enabled

'configure the systemclock
Config Sysclock = 32mhz , Prescalea = 1 , Prescalebc = 1_1

Config Com3 = 9600 , Mode = Asynchroneous , Parity = None , Stopbits = 1 , Databits = 8
Open "COM3:" For Binary As #1

Dim Calibration_word As Word
Dim Adca_byte_0 As Byte At Calibration_word Overlay
Dim Adca_byte_1 As Byte At Calibration_word + 1 Overlay

'First we read the Calibration bytes form Signature Row (to get the real 12-Bit)
Adca_byte_0 = Readsig(&H20)
Adca_byte_1 = Readsig(&H21)

'Write factory calibration values to calibration register
Adca_call = Adca_byte_0
Adca_calh = Adca_byte_1

Dim Unsigned_single_ended As Single

Unsigned_single_ended = 503663       '0.503663       '_(2.0625/4095) = 0.50366 mV

Const Adc_a_offset = 200

Print #1 , "ADC test"

'setup the ADC-A converter
'Config Adca = Single , Convmode = Unsigned , Resolution = 12bit , Dma = Off , Reference = Intvcc , Event_mode = None , Prescaler = 512 , Ch0_gain = 1 , Ch0_inp = Single_ended , Mux0 = &B000_00 , Ch1_gain = 1 , Ch1_inp = Single_ended , Mux1 = &B1_000 , Ch2_gain = 1 , Ch2_inp = Single_ended , Mux2 = &B10_000 , Ch3_gain = 1 , Ch3_inp = Single_ended , Mux3 = &B11_000
'setup the ADC-A converter
Config Adca = Single , Convmode = Unsigned , Resolution = 12bit , Dma = Off , Reference = Intvcc , Event_mode = None , _
Prescaler = 512 , _       'Sweep = Ch01 , _
Ch0_gain = 1 , Ch0_inp = Single_ended , Mux0 = &B00000000 , _
Ch1_gain = 1 , Ch1_inp = Single_ended , Mux1 = &B00100000 , _
Ch2_gain = 1 , Ch2_inp = Single_ended , _
Ch3_gain = 1 , Ch3_inp = Single_ended

Dim W(100) As Word , X As Word , X_v As Single , X_total As Single , I As Byte , Mux As Byte , Avg As Word , Avg_v As Single
Do
   'Mux = I * 8           ' or you can use shift left,3 to get the proper offset
   ' W = Getadc(adca , 0 , Mux)
   '   W = Getadc(adca , 0)   'when not using the MUX parameter the last value of the MUX will be used!
   ' use ADCA , use channel 0, and use the pinA.0-pinA.3
   'Print #1 , "RES:" ; I ; "-" ; W
   'Incr I
   'If I > 3 Then I = 0
   Mux = &B0_0100_000

   I = 0
   X_total = 0

   Do
      W(i) = Getadc(adca , 0 , &B00100000)
      W(i) = W(i) - Adc_a_offset

      X = Getadc(adca , 0 , &B00100000)
      X = X - Adc_a_offset
      X_v = X
      X_v = X_v * 503663
      X_v = X_v / 1000000
      X_total = X_total + X_v
      Incr I
   Loop Until I = 100

   X_total = X_total / 100

   'X = Getadc(adca , 0 , &B00100000)
   'X = X - Adc_a_offset

   Avg = 0
   Avg_v = 0

   I = 0

   Do
      Avg = Avg + W(i)
      'Print #1 , "avg: " ; Avg ; " i: " ; I
      Incr I
   Loop Until I = 100

   Avg_v = Avg
   Avg = Avg / 100
   Avg_v = Avg_v / 100

   'Avg_v = X

   'Print #1 , "avg: " ; Avg ; " avg_single: " ; Avg_v
   'Avg = Avg * Unsigned_single_ended

   Avg_v = Avg_v * 503663       'Unsigned_single_ended
   Avg_v = Avg_v / 1000000

   'ADC Resolution = ((Vinp - (-deltaV))/Vref) * G * (TOP + 1)
   'ADC Resolution = ((1.0 + 0.103125)/2.076875) * 1 * (4095 + 1)


   X_v = X
   X_v = X_v * 503663
   X_v = X_v / 1000000

   X_total = X_total - 0

   Print #1 , "x: " ; X ; " in mV: " ; X_total
   'Print #1 , "ch4: " ; Avg ; " in mV: " ; Avg_v

   Waitms 1000
Loop

End