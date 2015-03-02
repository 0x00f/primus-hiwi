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

$lib "xmega.lib"
$external _xmegafix_clear
$external _xmegafix_rol_r1014

'First Enable The Osc Of Your Choice
Config Osc = Enabled , 32mhzosc = Enabled

'configure the systemclock
Config Sysclock = 32mhz , Prescalea = 1 , Prescalebc = 1_1

Config Com3 = 115200 , Mode = Asynchroneous , Parity = None , Stopbits = 1 , Databits = 8
Open "COM3:" For Binary As #1

' Configure TWI / I2C
Dim Twi_start As Byte
Config Twicslave = &H70 , Btr = 16 , Gencall = 1
' In i2c the address has 7 bits. The LS bit is used to indicate read or write
' When the bit is 0, it means a write and a 1 means a read
' When you address a slave with the master in bascom, the LS bit will be set/reset automatic.
' The TWAR register in the AVR is 8 bit with the slave address also in the most left 7 bits
' This means that when you setup the slave address as &H70, TWAR will be set to &H0111_0000
' And in the master you address the slave with address &H70 too.
' The AVR TWI can also recognize the general call address 0. You need to either set bit 0 for example
' by using &H71 as a slave address, or by using GENCALL=1
Open "twic" For Binary As #4


Enable Interrupts


Config Portc.4 = Output
Led Alias Portc.4

Print #1 , "Xmega revision:" ; Mcu_revid       ' make sure it is 7 or higher !!! lower revs have many flaws

' This section reads the internal factory calibration signature and writes it
' to the appropriate registers so the adc values are correct.
Dim Calibration_word As Word
Dim Adca_byte_0 As Byte At Calibration_word Overlay
Dim Adca_byte_1 As Byte At Calibration_word + 1 Overlay
'First we read the Calibration bytes form Signature Row (to get the real 12-Bit)
Adca_byte_0 = Readsig(&H20)
Adca_byte_1 = Readsig(&H21)
'Write factory calibration values to calibration register
Adca_call = Adca_byte_0
Adca_calh = Adca_byte_1


Dim Adc_mux(16) As Byte

' Note BASCOM arrays begin at 1 by default
' To begin at 0 use CONFIG BASE=0
Adc_mux(1) = &B0_0000_000
Adc_mux(2) = &B0_0001_000
Adc_mux(3) = &B0_0010_000
Adc_mux(4) = &B0_0011_000
Adc_mux(5) = &B0_0100_000
Adc_mux(6) = &B0_0101_000
Adc_mux(7) = &B0_0110_000
Adc_mux(8) = &B0_0111_000
Adc_mux(9) = &B0_1000_000
Adc_mux(10) = &B0_1001_000
Adc_mux(11) = &B0_1010_000
Adc_mux(12) = &B0_1011_000
Adc_mux(13) = &B0_1100_000
Adc_mux(14) = &B0_1101_000
Adc_mux(15) = &B0_1110_000
Adc_mux(16) = &B0_1111_000


Dim Unsigned_single_ended As Single
Unsigned_single_ended = 0.503663       '_(2.0625/4095) = 0.50366 mV

' This offset must be manually measured. Ground the ADC Input und measure the ADC.
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

Dim W As Word       ' Variable to store single adc results
Dim Avg As Single , Avg_v As Single
Dim I As Byte , J As Byte       ' Generic counter variables
Dim Remainder As Byte

' These are the vars that store the data which will be sent over I2C
Dim Adci2c(16) As Word

Do       ' loop forever

   Do       ' loop through 16 adc inputs

      I = 1       ' Array index always begins at 1
      Avg = 0
      Avg_v = 0

      ' disable interrupts so that the data can be aquired and stored without
      ' possible corruption from I2C request interrupts
      Disable Interrupts

      Do
         W = Getadc(adca , 0 , Adc_mux(j))
         ' Make sure we do not subtract if the value is below the adc offset
         If W >= Adc_a_offset Then
            W = W - Adc_a_offset
         Else
            W = 0
         End If

         Avg = Avg + W
         Incr I
      Loop Until I = 101

      Avg = Avg / 100

      Adci2c(j) = Avg       ' store the value as Word to be sent over I2C

      Enable Interrupts


      Avg_v = Avg
      Avg_v = Avg_v * Unsigned_single_ended

      'ADC Resolution = ((Vinp - (-deltaV))/Vref) * G * (TOP + 1)
      'ADC Resolution = ((1.0 + 0.103125)/2.076875) * 1 * (4095 + 1)



      Print #1 , "CH " ; J ; " raw ADC: " ; Avg ; " - in mV: " ; Avg_v
      'Print #1 , "ch4: " ; Avg ; " in mV: " ; Avg_v

      Incr J

      Toggle Led

   Loop Until J = 17


   Print #1 , "  ----------------------------------  "

   Waitms 1000
   J = 1

Loop

End



'A master can send or receive bytes.
'A master protocol can also send some bytes, then receive some bytes
'The master and slave must match.

'the following labels are called from the library
Twi_stop_rstart_received:
   Print #1 , "Master sent stop or repeated start"
Return


Twi_addressed_goread:
   Print #1 , "We were addressed and master will send data"
Return


Twi_addressed_gowrite:
   Print #1 , "We were addressed and master will read data"
Return


'this label is called when the master sends data and the slave has received the byte
'the variable TWI holds the received value
Twi_gotdata:
   Print #1 , "received : " ; Twic
Return


'this label is called when the master receives data and needs a byte
'the variable twi_btr is a byte variable that holds the index of the needed byte
'so when sending multiple bytes from an array, twi_btr can be used for the index

Twi_master_needs_byte:

   Print "Master needs byte : " ; Twic_btr

   Remainder = Twic_btr Mod 2

   If Twic_btr > 0 And Twic_btr < 17 Then
      If Remainder = 0 Then
         Twic = High(adci2c(twic_btr))       ' even requests send the upper 8 Bits
      Else
         Twic = Low(adci2c(twic_btr))       ' odd requests send the lower 8 bits
      End If
   Else
      Twic = 0
   End If

Return


'when the mast has all bytes received this label will be called
Twi_master_need_nomore_byte:
   Print #1 , "Master does not need anymore bytes"
Return