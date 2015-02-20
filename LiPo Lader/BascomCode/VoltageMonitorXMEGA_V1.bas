'*******************************************************************************
'*                          L-Ion Voltage Supervisor                           *
'*                              AVR = ATMega8                                  *
'*                            V2.0 [18.12.2104]                                *
'*                         M.Schulze, M.A.Stadtlander                          *
'*                     Kompiliert mit BASCOM AVR 2.0.7.7                       *
'*                   Benötigt die extra I2C Slave Library                      *
'*                         ZARM Universitaet Bremen                            *
'*******************************************************************************

' Wir benutzen den xMega64A3U
$regfile = "xm64a3udef.dat"
' Wichtig: Der Mega muss den Ext Osc. Fuse gesetzt haben
$crystal = 32000000
' Print/RS232 Baud Rate
'Serial Interface to PC
Config Com3 = 9600 , Mode = Asynchroneous , Parity = None , Stopbits = 1 , Databits = 8
Open "COM3:" For Binary As #1

'first enable the osc of your choice
Config Osc = Enabled , 32mhzosc = Enabled

'Config Osc = Enabled
'Config Sysclock = 2mhz                           '2MHz

' YOU CAN MINIMIZE POWER CONSUMPTION FOR EXAMPLE WITH :
' 1. Use Low supply voltage
' 2. Use Sleep Modes
' 3. Keep Clock Frequencys low (also with Precsalers)
' 4. Use Powe Reduction Registers to shut down unused peripherals

'With Power_reduction you can shut down specific peripherals that are not used in your application
'Paramters: aes,dma,ebi,rtc,evsys,daca,dacb,adca,adcb,aca,acb,twic,usartc0,usartc1,spic,hiresc,tcc0,tcc1
'Config Power_reduction = Dummy , Aes = Off , Twic = On , Twid = Off , Twie = Off , Aca = On , Adcb = On , Tcc0 = Off , Tcc1 = Off , Dma = Off

'configure the systemclock
Config Sysclock = 32mhz , Prescalea = 1 , Prescalebc = 1_1

' YOU CAN MINIMIZE POWER CONSUMPTION FOR EXAMPLE WITH :
' 1. Use Low supply voltage
' 2. Use Sleep Modes
' 3. Keep Clock Frequencys low (also with Precsalers)
' 4. Use Powe Reduction Registers to shut down unused peripherals

'With Power_reduction you can shut down specific peripherals that are not used in your application
'Paramters: aes,dma,ebi,rtc,evsys,daca,dacb,adca,adcb,aca,acb,twic,usartc0,usartc1,spic,hiresc,tcc0,tcc1
'Config Power_reduction = Dummy , Aes =Off, Twic =Off, Twid =Off, Twie =Off, Aca =Off, Adcb =Off, Tcc0 =Off, Tcc1 =Off, Dma =Off


$hwstack = 64       ' default use 64 for the hardware stack
$swstack = 40       ' default use 40 for the SW stack
$framesize = 40       ' default use 40 for the frame space

$lib "xmega.lib"
$external _xmegafix_clear
$external _xmegafix_rol_r1014

'setup the ADC-A converter
'Config Adca = Single , Convmode = Unsigned , Resolution = 12bit , Dma = Off , Reference = Intvcc , Event_mode = None , Prescaler = 512 , Ch0_gain = 1 , Ch0_inp = Single_ended , Mux0 = &B000_00 , Ch1_gain = 1 , Ch1_inp = Single_ended , Mux1 = &B1_000 , Ch2_gain = 1 , Ch2_inp = Single_ended , Mux2 = &B10_000 , Ch3_gain = 1 , Ch3_inp = Single_ended , Mux3 = &B11_000
Dim Adctest As Word

'Config Adca = Single , Convmode = Unsigned , Resolution = 12bit , Dma = Off , Reference = Intvcc , Event_mode = None , Prescaler = 32 , Ch0_gain = 1 , Ch0_inp = Single_ended , Mux0 = 0       'you can setup other channels as well

'setup the ADC-A converter
Config Adca = Single , Convmode = Unsigned , Resolution = 12bit , Dma = Off , Reference = Intvcc , Event_mode = None , Prescaler = 32 , Ch0_gain = 1 , Ch0_inp = Single_ended , Mux0 = &B000_00 , Ch1_gain = 1 , Ch1_inp = Single_ended , Mux1 = &B1_000 , Ch2_gain = 1 , Ch2_inp = Single_ended , Mux2 = &B10_000 , Ch3_gain = 1 , Ch3_inp = Single_ended , Mux3 = &B11_000

' Configure TWI / I2C
Dim Twi_start As Byte
Config Twicslave = &H70 , Btr = 4 , Gencall = 1
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

Open "twic" For Binary As #4

Config Portc.4 = Output
Led Alias Portc.4
'Config Portc = Input

Dim Measurement As Word
Dim Measurement_minus_offset As Word
Dim Measurement_single As Single
Dim I As Byte

Dim Calibration_word As Word
Dim Adca_byte_0 As Byte At Calibration_word Overlay
Dim Adca_byte_1 As Byte At Calibration_word + 1 Overlay

'First we read the Calibration bytes form Signature Row (to get the real 12-Bit)
Adca_byte_0 = Readsig(&H20)
Adca_byte_1 = Readsig(&H21)

'Write factory calibration values to calibration register
Adca_call = Adca_byte_0
Adca_calh = Adca_byte_1

Print #1 ,
Print #1 , "----------START----------"
Print #1 , "Calibration Word = " ; Hex(calibration_word)
Print #1 , "The calibration value &H0444 looks like a standard mean value for calibration !?"

Config Eeprom = Mapped       'When we want to use ERAM Variables with XMEGA

Const Adc_a_offset = 172       '<<<<<<<<<<<<Measured OFFSET of ADC from Port A  in UNSIGNED SINGLE ENDED MODE WITH INTVCC AS REFERENCE

Const Unsigned_single_ended = 0.503663       '_(2.0625/4095) = 0.50366 mV

' Byte Types are unsigned 8-Bit numbers, 0 to 255 (1 Byte used)
' Integer Types are signed 16-Bit numbers, -32,768 to +32,767 (2 Bytes used)
' Word Types are unsigned 16-Bit Numbers, 0 to 65535 (2 Bytes used)
' Long Types are signed 32-Bit Numbers, -2147483648 to 2147483647 (4 Bytes used)


Dim Temp As Byte       ' Used when shifting the 10 bit ADC into Byte vars
Dim Temp_word As Word
Dim W As Word , X As Word , Y As Word , Z As Word , A As Word
Dim W_v As Long , X_v As Long , Y_v As Long , Z_v As Long , A_v As Long
Dim Channel1 As Byte , Channel2 As Byte
Dim V1 As Word , V2 As Word
Channel1 = 0
Channel2 = 1


Dim Mux As Byte


Print #1 , "xMega64 Slave Voltage Monitor V2"

Do
   Led = 1       'switch off all LEDS
   Waitms 300       'wait 1 second
   Led = 0

   Disable Interrupts



      'W = Getadc(adca , 0 , 8)
      'X = Getadc(adca , 0 , 16)
      'Y = Getadc(adca , 0 , 24)
      'Z = Getadc(adca , 0 , 32)
      'A = Getadc(adca , 0 , 40)
      'A = Getadc(adca , 0 , 32)
      'Waitms 1
      'W = Getadc(adca , 0 , 32)
      'Waitms 1
      'X = Getadc(adca , 0 , 32)
      'Waitms 1
      'Y = Getadc(adca , 0 , 32)
      'Waitms 1
     ' Z = Getadc(adca , 0 , 32)
     ' Waitms 1


         ' or you can use shift left,3 to get the proper offset
  W = Getadc(adca , 0 , 32)
'   W = Getadc(adca , 0)   'when not using the MUX parameter the last value of the MUX will be used!
  ' use ADCA , use channel 0, and use the pinA.0-pinA.3
  Print "RES:" ; I ; "-" ; W


      'W_v = W       '* 5035
     ' X_v = X       '* 5035
      'Y_v = Y       '* 5035
      'Z_v = Z       '* 5035
      'A_v = A
      'Print #1 , "CH0: " ; W_v ; " CH1: " ; X_v ; " CH2: " ; Y_v ; " CH3: " ; Z_v ; " CH4: " ; A_v
      'Print #1 , "CH0: " ; W ; " CH1: " ; X ; " CH2: " ; Y ; " CH3: " ; Z ; " CH4: " ; A
   Enable Interrupts


     'Waitms 500

Loop
                                                           'unconditional loop
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
  'Print "Master needs byte : " ; Twi_btr
  'Print "ADC value: " ; W

  Temp = W       ' only fist 8 bits of w are assigend to temp
  Temp_word = W       ' all 10 bits of adc value stored in Temp_word
  Shift Temp_word , Right , 8

  If Twic_btr = 1 Then       ' send lower 8 bits of adc value
    Twic = Temp
   ' Print "Sent lower 8: " ; Twi
    'Twi = 5
  Elseif Twic_btr = 2 Then       'send remaining 2 bits of adc value
    Twic = Temp_word
   ' Print "Sent upper 2: " ; Twi
    'Twi = 50
    'Print "twi is: " ; Twi
  Else
    Twic = 0
  End If

Return


'when the mast has all bytes received this label will be called
Twi_master_need_nomore_byte:
  Print #1 , "Master does not need anymore bytes"
Return