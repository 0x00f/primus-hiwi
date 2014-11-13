'-------------------------------------------------------------------------------

'                            (c) 2004 MCS Electronics

'                        This demo shows an example of the TWI

'                       Not all AVR chips have TWI (hardware I2C)

'-------------------------------------------------------------------------------



'The chip will work in TWI/I2C master mode

'Connected is a PCF8574A 8-bits port extender


$regfile = "M8def.dat"       ' the used chip

$crystal = 3686400       ' frequency used

$baud = 19200       ' baud rate

$hwstack = 32       ' default use 32 for the hardware stack

$swstack = 10       ' default use 10 for the SW stack

$framesize = 40       ' default use 40 for the frame space


$lib "i2c_twi.lbx"       ' we do not use software emulated I2C but the TWI


Config Scl = Portc.5       ' we need to provide the SCL pin name

Config Sda = Portc.4       ' we need to provide the SDA pin name

Config Portb.0 = Output

Led Alias Portb.0

'On the Mega88,          On the PCF8574A

'scl=PC5 , pin 28            pin 14

'sda=PC4 , pin 27            pin 15



I2cinit       ' we need to set the pins in the proper state


Config Twi = 100000       ' wanted clock frequency

'will set TWBR and TWSR

'Twbr = 12                                                   'bit rate register

'Twsr = 0                                                    'pre scaler bits

 Const M8_write = &H70
 Const M8_read = &H71


Dim B As Byte , W As Byte , X As Byte , Y As Byte , Z As Byte

Print "TWI master"

Led = 0

Do
  Toggle Led
  Incr B       ' increase value

' I2csend &H0 , B       ' send the value to general call address

 ' I2csend &H70 , B       ' send the value

 ' Print "Error : " ; Err       ' show error status

 'I2creceive Slave , Var , B2w , B2r
  I2cstart

  ''I2creceive &H70 , X , 0 , 1       ' get 1 byte
  I2cwbyte M8_read
  'I2cwbyte M8_write
  I2crbyte X , Ack
  I2crbyte Y , Ack,
  I2crbyte Z , Nack

  I2cstop

  '-----------------
  'I2csend &H70 , B       ' send the value
  'Print "Error : " ; Err       ' show error status
  'I2creceive &H70 , X       ' get a byte
  'Print X ; " " ; Err       ' show error

  '----------------

  Print X ; " " ; Err
  Print Y ; " " ; Err
  Print Z ; " " ; Err

  Waitms 500       'wait a bit

Loop

End