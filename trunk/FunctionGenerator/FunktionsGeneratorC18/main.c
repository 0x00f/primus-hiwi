// LCD Routines from http://www.pyroelectro.com/tutorials/pic_lcd/software.html

#include <p18f4610.h>
#include <Delays.h>
#include <stdlib.h>
#include <stdio.h>
#include <usart.h>
#include <ctype.h>
//#include <EEP.h>  //PIC18F4410 has no internal eeprom
#include "portb.h"


//------------------Processor Configuration-------------------------
#pragma config STVREN   = OFF		// Stack overflow reset
#pragma config OSC      = HSPLL		// (10MHz*4 = 40MHz max clock)
#pragma config WDT      = OFF		// Watch Dog Timer (WDT)
//#pragma config WDTPS    = 32768
#pragma config CP0      = OFF		// Code protect
#pragma config IESO     = OFF		// Internal External (clock) Switchover
#pragma config FCMEN    = OFF     	// Fail Safe Clock Monitor
#pragma config MCLRE    = ON         // MCLR Enabled
#pragma config PWRT     = ON         // power up timer disabled
#pragma config BOREN    = OFF        // Brown-out Reset disabled in hardware and software 
#pragma config XINST    = OFF        // Instruction set extension and Indexed Addressing mode enabled  
#pragma config LVP      = OFF        // LVP disabled
#pragma config PBADEN   = OFF        // PORTB<4:0> pins are configured as digital I/O on Reset 

//-----------------------Defines----------------------------------
#define RW_PIN   PORTEbits.RE2   /* PORT for RW */
#define RS_PIN   PORTCbits.RC5   /* PORT for RS */
#define E_PIN    PORTEbits.RE0   /* PORT for E  */
#define BAUD 9600
#define CLK 40000000 

unsigned int terminated = 0;

char CR = 0x0D;                      //Carriage Return
char LF = 0x0A;                      //Line Feed

char PPG1[] = "        ";
char PPG2[] = "        ";
char PPG3[] = "        ";
char PPG4[] = "        ";

unsigned long int PPG_frequency = 12345678;
unsigned int PPG_CH1_amp = 123;
unsigned int PPG_CH2_amp = 123;
unsigned int PPG_phase = 1234;
unsigned int PPG_reset_firstrun = 0;

// New variables for pin press sequence functionality
unsigned long int PPG_Saved_Frequency;

// Output Frequency in Hz
#pragma idata idata1
static long int Freq_Data[] = {10,100,200,300,500,1000,2000,3000,5000,7000};


#pragma idata idata2
static unsigned int Wait_Time[] = {1000,100,100,50,50,10,10,5,5,1};

//#pragma udata 



// Serial data
char SERIAL_send[32];
char SERIAL_data[32];
char SERIAL_cmd[32];

unsigned int SERIAL_valid = 0;
unsigned int SERIAL_pos = 0;
unsigned int SERIAL_readstate = 0;
unsigned int USART_MAX_READ = 1000;

unsigned int MACHINE_state = 0;
unsigned int MACHINE_state0_page = 10;
unsigned int MACHINE_state0_loopcount = 0;
unsigned long int MACHINE_idleCount = 0;
unsigned int MACHINE_msg = 0;
unsigned int MACHINE_data = 0;
int MAX_MENU = 7;


void wait10( int count) {
    int i;
    for (i=0; i<count; i++) {
        Delay10KTCYx(255);
    }
}



//--------------------- array fill
void array_fill( char *a, int count, int value) {
  int i;
  for (i=0; i<count; i++) {
    *a = value;
    a++;
  }
}

void myputsUSART( char *a) {
  int i = 0;
  while (a[i]>0) {
    putcUSART( a[i]);
    Delay1KTCYx(10);
    i++;
  }
}

 
void SERIAL_reset( void) {
    array_fill( SERIAL_send, 32, 0);
    array_fill( SERIAL_data, 32, 0);
    SERIAL_valid = 0;
    SERIAL_pos = 0;
}


//--------------------- LCD functions

//4-bit print interface
void LCD_echo(unsigned int character)
{
  PORTC = character >> 4;

  RS_PIN = 1;
  E_PIN = 1;
  E_PIN = 0;
  RS_PIN = 0;

  PORTC=character & 0x0f;

  RS_PIN = 1;
  E_PIN = 1;
  E_PIN = 0;
  RS_PIN = 0;

  //Delay1KTCYx(200); 
  Delay1KTCYx(1);   // The Delay Above Is Only To
                    // Create The Type-Writer Effect
}

//4-bit instruction interface
void LCD_command(unsigned int command) {
  PORTC = command >> 4;
  E_PIN = 1;
  E_PIN = 0;

  PORTC = command &0x0f;
  E_PIN = 1;
  E_PIN = 0;

  Delay1KTCYx(10);
}

void LCD_movecursor( int line, int column)
{
  char i;
  LCD_command(0b00000010);	//Move Home
  if (line == 1) {
    LCD_command(0b11000000);	//Move 2nd Next Line
  }
  for (i=0; i<column; i++) {
    LCD_command(0b00010100); // move horizontally in a line
  }
}

void LCD_write( char *a) {
  unsigned int i = 0;
  while (a[ i] != '\0') {
    LCD_echo( a[ i]);
    i++;
//Delay1KTCYx(200);
  }
}

void paint_msg( char *msg1,  char *msg2) {
  LCD_movecursor( 0, 0);
  LCD_write(  msg1);
  LCD_movecursor( 1, 0);
  LCD_write( msg2);

  //LCD_command(0b00000010);
}

void welcome_message(void) {
  char welcome1[] = "20MHzGen";
  char welcome2[] = "FirmV5.0";

  LCD_movecursor( 0, 0);
  LCD_write( welcome1);
  LCD_movecursor( 1, 0);
  LCD_write( welcome2);

  LCD_command(0b00000010);
}

void error_message(void) {
  char msg1[] = "Error   ";
  char msg2[] = "i quit..";

  LCD_movecursor( 0, 0);
  LCD_write(  msg1);
  LCD_movecursor( 1, 0);
  LCD_write( msg2);

  LCD_command(0b00000010);
}

void LCD_clear(void) {
  LCD_command(0b00000001); //clear display
  LCD_command(0b00000010); //return home 
}

void LCD_init(void) {
  E_PIN = 0;
  RS_PIN = 0;
  RW_PIN = 0;

  LCD_command(0b00000110); //entry mode set
  LCD_command(0b00101000); //function set (4 bit bus, 2 lines, 5x8 dots display)
  LCD_command(0b00001110); //set cursor on, no blinking
  LCD_command(0b00000001); //clear display
  LCD_command(0b00000010); //return home 
}

//--------------------- button functions

void button_handler (void);


#pragma code button_interrupt = 0x08
 void button_int (void)
 {
//#asm
     _asm
           goto button_handler
     _endasm
//#endasm
 }




#pragma interrupt button_handler
void button_handler (void)
{
/*    char msg1[] = "        ";
    char msg2[] = "        ";

    LCD_command(0b00000001); //clear display
    LCD_command(0b00000010); //return home 
    
    msg1[0] = 0x30+(PORTA & 0b10000000);
    msg1[1] = 0x30+(PORTA & 0b01000000);
    msg1[2] = 0x30+(PORTA & 0b00100000);
    msg1[3] = 0x30+(PORTA & 0b00010000);
    msg1[4] = 0x30+(PORTA & 0b00001000);
    msg1[5] = 0x30+(PORTA & 0b00000100);
    msg1[6] = 0x30+(PORTA & 0b00000010);
    msg1[7] = 0x30+(PORTA & 0b00000001);

    msg2[0] = 0x30+INTCONbits.GIE;
    msg2[1] = 0x30+INTCONbits.PEIE;
    msg2[2] = 0x30+INTCONbits.TMR0IE;
    msg2[3] = 0x30+INTCONbits.INT0IE;
    msg2[4] = 0x30+INTCONbits.RBIE;
    msg2[5] = 0x30+INTCONbits.RBIF;
    msg2[6] = 0x30+INTCON3bits.INT1IF;
    msg2[7] = 0x30+INTCON3bits.INT1IE;

    paint_msg( msg1, msg2);
    wait10(5);
*/
    if (INTCON3bits.INT1IF == 1) {
      MACHINE_msg = 1;
      MACHINE_data = PORTA;
      //MACHINE_data = PORTB;
      INTCON3bits.INT1IF = 0;
    }
    INTCONbits.RBIF = 0;
    //INTCONbits.INT0IF = 0;
    //INTCONbits.TMR0IF = 0;
}


//--------------------- initial setup

void initPorts(void) {
    int config;

    //Setup IO Ports
    CMCON = 0x07;
    ADCON1 = 0x0F;
    // per default IN: TRISA=0xFF; TRISB=0xFF; TRISC=0x00; TRISD=0xFF; TRISE=0x00; 
    PORTA=0x00;	PORTB=0x00; PORTC=0x00;	PORTD=0x00; PORTE=0x00;

    //**** configure Change Notification in PORTB  with pullups enabled, falling edge ***
    config=0;
    config = PORTB_CHANGE_INT_ON | PORTB_PULLUPS_OFF;
    //OpenPORTB(config);   //configures and enables change notification in PORTB

	//----------------------Interrupts---------------------
	// 1 = Enabled     0 = Disabled
    RCONbits.IPEN = 1;			// Interrupt Priority Enable Bit
    INTCONbits.GIE = 1;			// Global Interrupt Enable Bit
    INTCONbits.PEIE = 0;		// Peripheral Interrupt Enable Bit
    INTCONbits.TMR0IE = 0;		// TMR0 Overflow Interrupt Enable Bit

    INTCON3bits.INT1IE = 1;		// External Interrupt Enable Bit
    //INTCONbits.RBIE = 1;

}

void myOpenUSART() {
  /*
   * Open the USART configured as
   * 8N1, 9600 baud, in polled mode
   */
  OpenUSART(USART_TX_INT_OFF & 
            USART_RX_INT_OFF & 
            USART_ASYNCH_MODE &
            USART_EIGHT_BIT & 
            USART_CONT_RX & 
            USART_BRGH_LOW &
            USART_ADDEN_OFF, 64);
    
}

void error() {
    int i;
    char buffer1[] = "e:      ";
    char buffer2[] = "        ";


    for (i=0; i<32; i++) {
        sprintf( buffer1, "e:%02d-%03d", i, SERIAL_pos);
        sprintf( buffer2, "%02X  %04X", SERIAL_send[i], SERIAL_data[i]);
        paint_msg( buffer1, buffer2);
        if ((SERIAL_send[i] == 0) && (SERIAL_data[i]==0)) {
            wait10(0);
        } else {
            wait10(10); 
        }
    }
}


int readFromUSART( void) {
    char c = 0;
    unsigned int i = 0;
    i = 0;
    while ((c != 0x0D) && (i<USART_MAX_READ) ) {
        i++;
        if(DataRdyUSART() == 1) {
            /* Get the characters received from the USART */
            c = ReadUSART();
    
            SERIAL_data[SERIAL_pos] = c;
            c = 0x0D;
            if (SERIAL_pos < 32)
                SERIAL_pos++;     
            else
                SERIAL_pos =0;
        } else {
            Delay1KTCYx( 1);
        }
   }
    if (i<USART_MAX_READ) { return 1; }
    else { return 0; }
 }


void putsUSARTecho( char *a) {
    int i = 0;
    int k;
    i = 0;
    while (a[i]>0) {
        SERIAL_send[i] = a[i];
        putcUSART( a[i]);
        k = readFromUSART();
        i++;
    }
    //readFromUSART();
    //readFromUSART();
    //SERIAL_reset();
}

char numbers[] = "0123456789";

int changeMode( int mode) {
    char buffer[] = "MODE12";
    int i=100;
    
    SERIAL_reset();
    sprintf( buffer, "MODE%d%c", mode, 0x0D);
    putsUSARTecho( buffer);
    
    readFromUSART(); // 0x0A
    readFromUSART(); // 0x0D
    readFromUSART(); // mode
    readFromUSART(); // >
    
//error();

    if (SERIAL_data[ SERIAL_pos -2] == numbers[mode]) { 
        SERIAL_reset();
        return 1; 
    }
    return 0;
}

void PPG_USART_reset();

char PPG_save_msg1[] = "saving  ";
char PPG_save_msg2[] = "to rom..";
char PPG_save_msg3[] = "saved   ";
char PPG_save_msg4[] = "to rom. ";
void PPG_save() {
    char buffer[] = "SAVE\x0D";

    int i;

    SERIAL_reset();
    putsUSARTecho( buffer);

    readFromUSART(); // Prompt
    readFromUSART(); // Prompt

    paint_msg( PPG_save_msg1, PPG_save_msg2);
    // not working: 2/10/20
    //for(i=0;i<20;i++) { Delay10KTCYx(255); }
    // not working: while (!DataRdyUSART()) ;
    // "EEPROM SAVED" returned if successfull
    // 12 chars + 1 + 2 Prompt
    // BUT remember ECHO prompt "SAVEx0dx0ax0dEEPROM SAVED !x0ax0d#>"
    for(i=0;i<32;i++) {
      readFromUSART();
      if (SERIAL_data[ SERIAL_pos -1] == 0x3E) { break; }
    }

    if (SERIAL_data[ SERIAL_pos -1] != 0x3E) { // ">"
        error();
        PPG_USART_reset();
    } else {
      paint_msg( PPG_save_msg3, PPG_save_msg4);
      //error();
    }
}


void PPG_read( void) {
    char buffer[] = "READ\x0D";
    char c;
    int i = 0;
    int k = 0, l = 0, m = 0;
    unsigned long int p = 0;
    i = changeMode( 4);
    
    if (i == 1) {
        putsUSARTecho( buffer);
        //SERIAL_reset();
        readFromUSART(); // Prompt
        readFromUSART(); // Prompt
        readFromUSART();
        while (SERIAL_data[ SERIAL_pos -1] != 0x0D) {
            readFromUSART();
        }
        i = SERIAL_pos -2; // i holds index of 0x0A
        readFromUSART(); // read prompt
        readFromUSART(); // Promt
        PPG_frequency = 0;
//        for (k=0;k<i;k++) {
//            c = SERIAL_data[ k];
//            if (c == 0x0D) { break; }
//        }
        l = 7;
		k = 0;
        while (SERIAL_data[ l] != 0x0A) {
			k++;
			l++;
			if (l == 31) { break; }
		}      
//        for (l=k+3;l<i;l++) {
		l = 7;
		while (SERIAL_data[ l] != 0x0A) {
            c = SERIAL_data[ l];
            p = 1;
			k--;
			l++;
            for (m=0;m<k;m++) { p = p * 10; }
            PPG_frequency = PPG_frequency + ((int)(c)-0x30)*p;
        }
    } else {
        PPG_frequency = 1;
        error();
    }
    
    i = changeMode( 2);
    if (i == 1) {
        putsUSARTecho( buffer);
        //SERIAL_reset();
        readFromUSART();
        readFromUSART();
        readFromUSART();
        while (SERIAL_data[ SERIAL_pos -1] != 0x0D) {
            readFromUSART();
        }
        i = SERIAL_pos -2; // i holds index of 0x0A
        readFromUSART(); // read prompt
        readFromUSART();
        PPG_CH1_amp = 0;
        l = 7;
		k = 0;
        while (SERIAL_data[ l] != 0x0A) {
			k++;
			l++;
			if (l == 31) { break; }
		}      
//        for (l=k+3;l<i;l++) {
		l = 7;
		while (SERIAL_data[ l] != 0x0A) {
            c = SERIAL_data[ l];
            p = 1;
			k--;
			l++;
            for (m=0;m<k;m++) { p = p * 10; }
            PPG_CH1_amp = PPG_CH1_amp + ((int)(c)-0x30)*p;
        }
        if (PPG_CH1_amp > 999) { PPG_CH1_amp = 999; }
    } else {
        error();
    }

    i = changeMode( 3);
    if (i == 1) {
        putsUSARTecho( buffer);
        //SERIAL_reset();
        readFromUSART();
        readFromUSART();
        readFromUSART();
        while (SERIAL_data[ SERIAL_pos -1] != 0x0D) {
            readFromUSART();
        }
        i = SERIAL_pos -2; // i holds index of 0x0A
        readFromUSART(); // read prompt
        readFromUSART();
        PPG_CH2_amp = 0;
        l = 7;
		k = 0;
        while (SERIAL_data[ l] != 0x0A) {
			k++;
			l++;
			if (l == 31) { break; }
		}      
//        for (l=k+3;l<i;l++) {
		l = 7;
		while (SERIAL_data[ l] != 0x0A) {
            c = SERIAL_data[ l];
            p = 1;
			k--;
			l++;
            for (m=0;m<k;m++) { p = p * 10; }
            PPG_CH2_amp = PPG_CH2_amp + ((int)(c)-0x30)*p;
        }
        if (PPG_CH2_amp > 999) { PPG_CH2_amp = 999; }
    } else {
        error();
    }

    i = changeMode( 5);
    if (i == 1) {
        putsUSARTecho( buffer);
        //SERIAL_reset();
        readFromUSART();
        readFromUSART();
        readFromUSART();
        while (SERIAL_data[ SERIAL_pos -1] != 0x0D) {
            readFromUSART();
        }
        i = SERIAL_pos -2; // i holds index of 0x0A
        readFromUSART(); // read prompt
        readFromUSART();
        PPG_phase = 0;
        l = 7;
		k = 0;
        while (SERIAL_data[ l] != 0x0A) {
			k++;
			l++;
			if (l == 31) { break; }
		}      
//        for (l=k+3;l<i;l++) {
		l = 7;
		while (SERIAL_data[ l] != 0x0A) {
            c = SERIAL_data[ l];
            p = 1;
			k--;
			l++;
            for (m=0;m<k;m++) { p = p * 10; }
            PPG_phase = PPG_phase + ((int)(c)-0x30)*p;
        }
    } else {
        error();
    }

}

void handleIdle( void) {
    char msg1[] = "        ";
    char msg2[] = "        ";
    MACHINE_state0_loopcount++;
    if (MACHINE_state0_loopcount == 100) {
        MACHINE_state0_page++;
        switch( MACHINE_state0_page) {
            case 1:
                sprintf( msg1, "Freq:   ");
                sprintf( msg2, "%08ld", PPG_frequency);
                break;
            case 2:
                sprintf( msg1, "Amp 1:  ");
                sprintf( msg2, "   %03umV", PPG_CH1_amp);
                break;
            case 3:
                sprintf( msg1, "Amp 2:  ");
                sprintf( msg2, "   %03umV", PPG_CH2_amp);
                break;
            case 4:
                sprintf( msg1, "Phase:  ");
                sprintf( msg2, "  %03u.%u.", (PPG_phase/10), (PPG_phase%10));
                //msg2[0] = 237;
                msg2[7] = 223;
                break;
            default: 
                sprintf( msg1, "status..");
                sprintf( msg2, ". menu .");
                MACHINE_state0_page = 0;
                break;
                
        }
        paint_msg( msg1, msg2);
        MACHINE_state0_loopcount = 0;
    }
    Delay10KTCYx(10);
}

// Menu: Frequ->Amp1->Amp2->phase->save?->reload?
unsigned int MACHINE_state1_page = 0;
unsigned int MACHINE_state1_repaint = 0;
unsigned int MACHINE_state1_cursor[] = {0,0,0,0,0,0,0};

void menuValidateCursor( void) {
    unsigned int mask = 0;
    unsigned int currentPos = 0;
    unsigned int currentPosB = 0;
    int i;
    currentPos = MACHINE_state1_cursor[ MACHINE_state1_page];

    switch( MACHINE_state1_page) {
        case 0: 
            if (currentPos > 7) {
                currentPos = 0;
            }
            break;
        case 1:
        case 2:
            if (currentPos > 4) {
                currentPos = 2;
            } else {
                if (currentPos < 2) {
                    currentPos = 2;
                }
            }
            break;
        case 3:
            if (currentPos > 5) { currentPos = 1; break; }
            if (currentPos == 2) { currentPos = 3; break; }
            if (currentPos == 0) { currentPos = 1; break; }
            break;
        default:
            currentPos = 0;
    }
    MACHINE_state1_cursor[ MACHINE_state1_page] = currentPos;
    MACHINE_state1_repaint = 1;
}

char PPGLOADING1[] = "waiting ";
char PPGLOADING2[] = "for PPG ";
void PPG_USART_reset() {
    int i;

    if (PPG_reset_firstrun == 0) {
        CloseUSART();   
        PPG_reset_firstrun = 0;
    }

    paint_msg( PPGLOADING1, PPGLOADING2);
    SERIAL_reset();
    myOpenUSART();
    WriteUSART( 0x11);
    wait10(1);
    WriteUSART( 0x0D);

    i = 0;
    while (!DataRdyUSART()) {
        wait10(1);
        i = 1 - i;
        if (i == 0) { 
            PPGLOADING1[7] = 0x20;
            PPGLOADING2[7] = 0x2E;
        } else {
            PPGLOADING1[7] = 0x2E;
            PPGLOADING2[7] = 0x20;
        }
        paint_msg( PPGLOADING1, PPGLOADING2);
    }
    
    for (i=0; i<31; i++) {
        readFromUSART();
    }
}

char reload_msg1[] = "PPG     ";
char reload_msg2[] = "loaded  ";
void menuChange( int vorzeichen) {
    unsigned long int d = 0;
    int i;

    switch (MACHINE_state1_page) {
        // frequency
        case 0:
            d = 1;
            for (i=0;i<MACHINE_state1_cursor[ MACHINE_state1_page];i++) {
                d = 10*d;
            }
            if (vorzeichen == -1) {
                if ((PPG_frequency-d)>100) {
                    PPG_frequency = PPG_frequency -d;
                } else { PPG_frequency = 100; }
            } else {
                PPG_frequency = PPG_frequency + d;
                if (PPG_frequency > 20000000) { PPG_frequency = 20000000; }
            }
            i = changeMode( 4);
            if (i == 1) {
                array_fill( SERIAL_cmd, 32, 0);
                sprintf( SERIAL_cmd, "%ld%c", PPG_frequency, 0x0D);
                putsUSARTecho( SERIAL_cmd);
                readFromUSART();
                readFromUSART();
                readFromUSART();
                readFromUSART();
            }
            break;
        case 1:
            if (MACHINE_state1_cursor[ MACHINE_state1_page] == 2) { d = 1; }
            if (MACHINE_state1_cursor[ MACHINE_state1_page] == 3) { d = 10; }
            if (MACHINE_state1_cursor[ MACHINE_state1_page] == 4) { d = 100; }
            if (vorzeichen == -1) {
                if (PPG_CH1_amp > d) { PPG_CH1_amp = PPG_CH1_amp - d; }
                else { PPG_CH1_amp = 0; }
            } else {
                PPG_CH1_amp = PPG_CH1_amp + d;
                if (PPG_CH1_amp > 999) { PPG_CH1_amp = 999; }
            }
            i = changeMode( 2);
            if (i == 1) {
                array_fill( SERIAL_cmd, 32, 0);
                sprintf( SERIAL_cmd, "%u%c", PPG_CH1_amp, 0x0D);
                putsUSARTecho( SERIAL_cmd);
                readFromUSART();
                readFromUSART();
                readFromUSART();
                readFromUSART();
            }
            break;
        case 2:
            if (MACHINE_state1_cursor[ MACHINE_state1_page] == 2) { d = 1; }
            if (MACHINE_state1_cursor[ MACHINE_state1_page] == 3) { d = 10; }
            if (MACHINE_state1_cursor[ MACHINE_state1_page] == 4) { d = 100; }
            if (vorzeichen == -1) {
                if (PPG_CH2_amp > d) { PPG_CH2_amp = PPG_CH2_amp - d; }
                else { PPG_CH2_amp = 0; }
            } else {
                PPG_CH2_amp = PPG_CH2_amp + d;
                if (PPG_CH2_amp > 999) { PPG_CH2_amp = 999; }
            }
            i = changeMode( 3);
            if (i == 1) {
                array_fill( SERIAL_cmd, 32, 0);
                sprintf( SERIAL_cmd, "%u%c", PPG_CH2_amp, 0x0D);
                putsUSARTecho( SERIAL_cmd);
                readFromUSART();
                readFromUSART();
                readFromUSART();
                readFromUSART();
            }
            break;
        case 3:
            if (MACHINE_state1_cursor[ MACHINE_state1_page] == 1) { d = 1; }
            if (MACHINE_state1_cursor[ MACHINE_state1_page] == 3) { d = 10; }
            if (MACHINE_state1_cursor[ MACHINE_state1_page] == 4) { d = 100; }
            if (MACHINE_state1_cursor[ MACHINE_state1_page] == 5) { d = 1000; }
            if (vorzeichen == -1) {
                if (PPG_phase >= d) { PPG_phase = PPG_phase - d; }
                else { PPG_phase = 3600-(d-PPG_phase); }
            } else {
                PPG_phase = PPG_phase + d;
                if (PPG_phase > 3599) { PPG_phase = PPG_phase-3600; }
            }
            i = changeMode( 5);
            if (i == 1) {
                array_fill( SERIAL_cmd, 32, 0);
                sprintf( SERIAL_cmd, "%u%c", PPG_phase, 0x0D);
                putsUSARTecho( SERIAL_cmd);
                readFromUSART();
                readFromUSART();
                readFromUSART();
                readFromUSART();
            }
            break;
        case 4:
            PPG_save();
            break;
        // reload PPG
        case 5:
            if (vorzeichen == 1) {
                PPG_read();
                paint_msg( reload_msg1, reload_msg2);
                wait10(5);
            }
            break;
        case 6:
            if (vorzeichen == 1) {
                PPG_USART_reset(); 
                error();
            }
        default:
            break;
    }
}

void handleMsg( void) {
    unsigned int button;
//    char msg1[] = "        ";
//    char msg2[] = "        ";
    switch (MACHINE_msg) {
        case 1: // Button pressed
            // enter menu mode if screen saver
            if (MACHINE_state == 0) { 
                MACHINE_state = 1;
                MACHINE_state1_page = 0;
                menuValidateCursor();
                MACHINE_state1_repaint = 1;
                return;
            } 
            // else process button
            // shift 4 bits to the right
            //button = MACHINE_data >>4;
            button = MACHINE_data;

/*
    LCD_command(0b00000001); //clear display
    LCD_command(0b00000010); //return home 
    
    msg1[0] = 0x30+(button & 0b10000000);
    msg1[1] = 0x30+(button & 0b01000000);
    msg1[2] = 0x30+(button & 0b00100000);
    msg1[3] = 0x30+(button & 0b00010000);
    msg1[4] = 0x30+(button & 0b00001000);
    msg1[5] = 0x30+(button & 0b00000100);
    msg1[6] = 0x30+(button & 0b00000010);
    msg1[7] = 0x30+(button & 0b00000001);

    paint_msg( msg1, msg2);
    wait10(5);*/

            switch (button) {
                // most right button
                case 0b00001000:
                    MACHINE_state1_page++;
                    MACHINE_state1_page = MACHINE_state1_page%MAX_MENU;
                    break;
                // center right button
                case 0b00000100:
                    if (MACHINE_state1_page == 4) break;
                    if (MACHINE_state1_page == 5) break;

                    MACHINE_state1_cursor[MACHINE_state1_page]++;
                    menuValidateCursor();
                    break;
                // center left button
                case 0b00000010:
                    menuChange(-1);
                    break;
                // most left button
                case 0b00000001:
                    menuChange(1);
                    break;
                default: 
                    ;
            }
            MACHINE_state1_repaint = 1;
            break;
        default:
            ;
    }  
}

void handleMenu( void) {
    char msg1[] = "        ";
    char msg2[] = "        ";

    if (MACHINE_state1_repaint == 1) {
        LCD_command(0b00000001); //clear display
        LCD_command(0b00000010); //return home 
        //sprintf( msg2, "u d %c  %c", 0x7F, 0x7E);
        sprintf( msg2, "u d %c  %c", 0x3C, 0x3E);
        switch( MACHINE_state1_page) {
            case 0: 
                sprintf( msg1, "%08ld", PPG_frequency);
                break;
            case 1: 
                sprintf( msg1, "U1:%03umV", PPG_CH1_amp);
                break;
            case 2: 
                sprintf( msg1, "U2:%03umV", PPG_CH2_amp);
                break;
            case 3: 
                sprintf( msg1, "p:%03u.%u.", (PPG_phase/10), (PPG_phase%10));
                msg1[7] = 0x2A;
                break;
            case 4: 
                sprintf( msg1, "save?   ", PPG_frequency);
                sprintf( msg2, "y      %c", 0x3E);
                break;
            case 5: 
                sprintf( msg1, "reload? ", PPG_frequency);
                sprintf( msg2, "y      %c", 0x3E);
                break;
            case 6: 
                sprintf( msg1, "PPGreset");
                sprintf( msg2, "y      %c", 0x3E);
                break;
            default: 
                break;
        }
        paint_msg( msg1, msg2);
        LCD_movecursor( 0, 7-MACHINE_state1_cursor[ MACHINE_state1_page]);
        MACHINE_state1_repaint = 0;
    }
}



//--------------------- main function

char GREETING[] = "MODE1\x0D";
char SHUTDOWN1[] = "shutting";
char SHUTDOWN2[] = "down... ";

#pragma code
void main(void) { 
    int i,offset;
  
	TRISB=0xFF; TRISC=0x00; TRISD=0xFF; TRISE=0x00; //Setup IO Ports
    PORTC=0x00;	PORTD=0x00; PORTE=0x00;

    LCD_clear();  //clear display
    Delay10KTCYx(200);  //Delay to allow LCD startup
    LCD_init(); //init the lcd driver
    welcome_message(); //display startup message
    
    PPG_reset_firstrun = 1;
    PPG_USART_reset();
    wait10(10);
    //PPG_save();

    initPorts();     //Enable interrupts

    //wait10(5);

    for (MACHINE_state1_page=0;MACHINE_state1_page<MAX_MENU;MACHINE_state1_page++) {
        MACHINE_state1_cursor[ MACHINE_state1_page] = 0;
        menuValidateCursor();
    }
    MACHINE_state1_page = 0;

    // read stored settings
    PPG_read();
  
    MACHINE_msg = 0;
    MACHINE_state = 0;
    MACHINE_idleCount = 0;
    // main loop
    while( terminated == 0) {
        MACHINE_idleCount++;
        if (MACHINE_msg >0) {
            handleMsg();
            MACHINE_msg = 0;
            MACHINE_data = 0;
            MACHINE_idleCount = 0;
        }
        switch( MACHINE_state) {
            case 0: 
                handleIdle();
                MACHINE_idleCount = 0;
                break;
            case 1:
                handleMenu();
                break;
            default:
                error_message();
                terminated = 1;
                break;
        }
        if (MACHINE_idleCount == 1000*500000) {
            MACHINE_idleCount = 0;
            MACHINE_state = 0;
        }
    }

    CloseUSART();
    paint_msg( SHUTDOWN1, SHUTDOWN2);
    for(i=0;i<10;i++) { Delay10KTCYx(255); }
} /*------------------------end of main--------------------------*/