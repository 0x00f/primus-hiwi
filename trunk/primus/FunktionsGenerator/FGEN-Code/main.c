/*      DDS Frequency Generator

	Version 2.1
	Last Edit: 10/4/04
	Written in: HiTech PIC C v7.86 PL4
	Written by: David L. Jones
	Copyright(C)2004 David L. Jones
NOTES:
- Written for a PIC16F628 target

*/

// Revision notes
// 1.0 - First prototype LCD version
// 2.0 - First LED display version for Rev1.0 PCB
// 2.1 - Fix for 5th digit frequency problem

//#include "pic18.h"
#include <htc.h>
#include <delay.c>
//#include "delay.h"
#include <float.h>


//***** configuration fuses
// int oscillator, code protect off, eeprom code protect off
//__CONFIG(FOSC2|CPD|CP0|CP1|0x0400); 
//__CONFIG(LVPDIS & INTIO & MCLRDIS & BOREN & WDTDIS & DATUNPROT);
__CONFIG(1, HS & FCMDIS & IESODIS);
__CONFIG(2, PWRTDIS & SWBOREN & BORV45 & WDTPS32K);
__CONFIG(3, CCP2RB3 & PBDIGITAL & LPT1DIS & MCLREN);
__CONFIG(4, XINSTEN & STVREN & LVPDIS & DEBUGEN);
__CONFIG(5, UNPROTECT);
__CONFIG(6, UNPROTECT);
__CONFIG(7, UNPROTECT);


#define TRUE    1
#define FALSE   0

// relay definitions
#define SCLK_HIGH       RA1=TRUE                //set ad9835 sclk line
#define SCLK_LOW        RA1=FALSE
#define SDATA_HIGH      RA2=TRUE                //set ad9835 sdata line
#define SDATA_LOW       RA2=FALSE
#define FSYNC_HIGH      RA3=TRUE                //set ad9835 fsync line
#define FSYNC_LOW       RA3=FALSE
#define SHIFT_BUTTON    RB0                     //SHIFT button
#define INC_BUTTON      RA6                     //INC button
#define SET_BUTTON      RA7                     //SET button
#define LCDSEG_A        RB1
#define LCDSEG_B        RB2
#define LCDSEG_C        RB3
#define LCDSEG_D        RB4
#define LCDSEG_E        RB5
#define LCDSEG_F        RB6
#define LCDSEG_G        RB7
#define LED1MHz         RB7
#define LED100KHz       RB6
#define LED10KHz        RB5
#define LED1KHz         RB4
#define LED100Hz        RB3
#define LED10Hz         RB2
#define LED1Hz          RB1
#define LEDsink         RA4
#define SEGsink         RA0

//global variables
	unsigned int cursor;
	unsigned int SevenSegNUM;
	unsigned int LEDNUM;
	unsigned long int D1MHz;
	unsigned long int D100KHz;
	unsigned long int D10KHz;
	unsigned long int D1KHz;
	unsigned long int D100Hz;
	unsigned long int D10Hz;
	unsigned long int D1Hz;

//*****************************************************************
//SEND THE FREQUENCY WORD TO THE DDS CHIP
void SendWordDDS(unsigned int ddsword){
	unsigned int tw;
	SCLK_HIGH; 
	FSYNC_HIGH; 
	FSYNC_LOW;
	tw=ddsword;
	if((tw&32768)==0) SDATA_LOW; else SDATA_HIGH;
	SCLK_HIGH; SCLK_LOW; SCLK_HIGH;

	tw=ddsword;
	if((tw&16384)==0) SDATA_LOW; else SDATA_HIGH;
	SCLK_HIGH; SCLK_LOW; SCLK_HIGH;

	tw=ddsword;
	if((tw&8192)==0) SDATA_LOW; else SDATA_HIGH;
	SCLK_HIGH; SCLK_LOW; SCLK_HIGH;

	tw=ddsword;
	if((tw&4096)==0) SDATA_LOW; else SDATA_HIGH;
	SCLK_HIGH; SCLK_LOW; SCLK_HIGH;

	tw=ddsword;
	if((tw&2048)==0) SDATA_LOW; else SDATA_HIGH;
	SCLK_HIGH; SCLK_LOW; SCLK_HIGH;

	tw=ddsword;
	if((tw&1024)==0) SDATA_LOW; else SDATA_HIGH;
	SCLK_HIGH; SCLK_LOW; SCLK_HIGH;

	tw=ddsword;
	if((tw&512)==0) SDATA_LOW; else SDATA_HIGH;
	SCLK_HIGH; SCLK_LOW; SCLK_HIGH;

	tw=ddsword;
	if((tw&256)==0) SDATA_LOW; else SDATA_HIGH;
	SCLK_HIGH; SCLK_LOW; SCLK_HIGH;

	tw=ddsword;
	if((tw&128)==0) SDATA_LOW; else SDATA_HIGH;
	SCLK_HIGH; SCLK_LOW; SCLK_HIGH;

	tw=ddsword;
	if((tw&64)==0) SDATA_LOW; else  SDATA_HIGH;
	SCLK_HIGH; SCLK_LOW; SCLK_HIGH;

	tw=ddsword;
	if((tw&32)==0) SDATA_LOW; else SDATA_HIGH;
	SCLK_HIGH; SCLK_LOW; SCLK_HIGH;

	tw=ddsword;
	if((tw&16)==0) SDATA_LOW; else SDATA_HIGH;
	SCLK_HIGH; SCLK_LOW; SCLK_HIGH;

	tw=ddsword;
	if((tw&8)==0)   SDATA_LOW; else SDATA_HIGH;
	SCLK_HIGH; SCLK_LOW; SCLK_HIGH;

	tw=ddsword;
	if((tw&4)==0)   SDATA_LOW; else SDATA_HIGH;
	SCLK_HIGH; SCLK_LOW; SCLK_HIGH;

	tw=ddsword;
	if((tw&2)==0)   SDATA_LOW; else SDATA_HIGH;
	SCLK_HIGH; SCLK_LOW; SCLK_HIGH;

	tw=ddsword;
	if((tw&1)==0)   SDATA_LOW; else SDATA_HIGH;
	SCLK_HIGH; SCLK_LOW; SCLK_HIGH;
	FSYNC_HIGH;             //end 16bit word
}

//*****************************************************************
// sends the 32bit word passed, to the FREQ0 Reg of the 9835
void SendFreqRegDDS(unsigned long int fv){
	unsigned int word;
	unsigned long int t;
	t=fv;
	t=t&0x000000ff;
	word=(unsigned int)(0x3000+(t));        //get 8L LSB with mask
	SendWordDDS(word);
	t=fv;
	t=t&0x0000ff00;
	word=(unsigned int)(0x2100+(t>>=8));    //get 8H LSB with mask
	SendWordDDS(word);
	t=fv;
	t=t&0x00ff0000;
	word=(unsigned int)(0x3200+(t>>=16));   //get 8L MSB with mask
	SendWordDDS(word);
	t=fv;
	t=t&0xff000000;
	word=(unsigned int)(0x2300+(t>>=24));   //get 8H MSB with mask
	SendWordDDS(word);
}

//*****************************************************************
// converts a frequency in Hz to the 9835 register value
unsigned long int ConvertFrequency(unsigned long int temp){
	unsigned long int c;
	c=(unsigned long int)(temp/11.64153218e-3);
	return(c);
}

//*****************************************************************
//saves the current frequency to EEPROM
void SaveFreq(void){
//	eeprom_write(1,D1MHz);
//	eeprom_write(2,D100KHz);
//	eeprom_write(3,D10KHz);
//	eeprom_write(4,D1KHz);
//	eeprom_write(5,D100Hz);
//	eeprom_write(6,D10Hz);
//	eeprom_write(7,D1Hz);
}

//*****************************************************************
//loads the frequency from the EEPROM
void LoadFreq(void){
//	D1MHz=eeprom_read(1);
//	if (D1MHz>9) D1MHz=0;
//	D100KHz=eeprom_read(2);
//	if (D100KHz>9) D100KHz=0;
//	D10KHz=eeprom_read(3);
//	if (D10KHz>9) D10KHz=0;
//	D1KHz=eeprom_read(4);
//	if (D1KHz>9) D1KHz=0;
//	D100Hz=eeprom_read(5);
//	if (D100Hz>9) D100Hz=0;
//	D10Hz=eeprom_read(6);
//	if (D10Hz>9) D10Hz=0;
//	D1Hz=eeprom_read(7);
//	if (D1Hz>9) D1Hz=0;
}

//*****************************************************************
//update DDS frequency
void UpdateDDS(void){
	unsigned long int freqreg;
	unsigned long int freq;         //signal frequency
	freq=0;                 //convert digits to frequency
	freq=freq+D1Hz;
	freq=freq+(10*D10Hz);
	freq=freq+(100*D100Hz);
	freq=freq+(1000*D1KHz);
	freq=freq+(10000*D10KHz);
	freq=freq+(100000*D100KHz);
	freq=freq+(1000000*D1MHz);
		
	freqreg=ConvertFrequency(freq); //convert to register value
	SendFreqRegDDS(freqreg);        //send to DDS chip
}

//*****************************************************************
//displays a number on the 7seg display
void segLED(void){

	switch(SevenSegNUM){
		case 0: PORTB=126;
			break;
		case 1: PORTB=12;
			break;
		case 2: PORTB=182;
			break;
		case 3: PORTB=158;
			break;
		case 4: PORTB=204;
			break;
		case 5: PORTB=218;
			break;
		case 6: PORTB=250;
			break;
		case 7: PORTB=14;
			break;
		case 8: PORTB=254;
			break;
		case 9: PORTB=222;
			break;
	}
	LEDsink=TRUE;           //disable LED sink
	SEGsink=FALSE;          //enable 7SEg sink
	//DelayMs(5);            	//display LED for 5ms
    _delay(500);
	LEDsink=TRUE;           //DISABLE LED sink
	SEGsink=TRUE;           //disable 7SEg sink
}
//*****************************************************************
//displays a single frequency display LED for 25ms
//Only one LED is on at any one time.
void FreqLED(void){

	//switch all LED's off first
	LED1MHz=FALSE;
	LED100KHz=FALSE;
	LED10KHz=FALSE;
	LED1KHz=FALSE;
	LED100Hz=FALSE;
	LED10Hz=FALSE;
	LED1Hz=FALSE;
	LEDsink=FALSE;          //enable LED sink
	SEGsink=TRUE;           //disable 7SEg sink

	switch(LEDNUM){
		case 6: LED1MHz=TRUE;
			break;
		case 5: LED100KHz=TRUE;
			break;
		case 4: LED10KHz=TRUE;
			break;
		case 3: LED1KHz=TRUE;
			break;
		case 2: LED100Hz=TRUE;
			break;
		case 1: LED10Hz=TRUE;
			break;
		case 0: LED1Hz=TRUE;
			break;
	};
	//DelayMs(5);            	//displayLED for 5ms
    _delay(500);
    LEDsink=TRUE;           //DISABLE LED sink
	SEGsink=TRUE;           //disable 7SEg sink
}

//*****************************************************************
// key bounce delay of a few hundred ms while displaying LED
void KeyDelay(void) {
	int i;
	for(i=0;i<20;i++){
		FreqLED();
		segLED();
	}
}

//*****************************************************************
// send the required commands to initialise the 9835
void InitialiseDDS(void){
	SendWordDDS(0xF800);
	SendWordDDS(0xB000);
	SendWordDDS(0x5000);
	SendWordDDS(0x4000);
	SendWordDDS(0x1800);	//clear phase register
	SendWordDDS(0x0900);
	SendFreqRegDDS(ConvertFrequency(1000));	//initial frequency
	SendWordDDS(0xC000);
}

//*****************************************************************
void main(void){
	//CMCON=0b00000111;               //disable comparator
	PORTA=0;
	PORTB=0;
	TRISA=0;                        //PORTA are all outputs
	TRISB=0;                        //PORTB are all outputs
	TRISB0=TRUE;                    //switch input
	TRISA7=TRUE;                    //switch input
	TRISA6=TRUE;                    //switch input
	RBPU=FALSE;                     //enable portb pullups
	GIE=FALSE;                      //disable all interrupts
	
	cursor=0;

	InitialiseDDS();
	
	LoadFreq();                     //recover saved frequency
	UpdateDDS();
			
	while(TRUE){
		//now wait for keypress and continually update displays 
		LEDNUM=cursor;
		FreqLED();              		//update frequency cursor LED
		switch (cursor){
			case 6: SevenSegNUM=D1MHz;
				break;
			case 5: SevenSegNUM=D100KHz;
				break;
			case 4: SevenSegNUM=D10KHz;
				break;
			case 3: SevenSegNUM=D1KHz;
				break;
			case 2: SevenSegNUM=D100Hz;
				break;
			case 1: SevenSegNUM=D10Hz;
				break;
			case 0: SevenSegNUM=D1Hz;
				break;
		}                      
		segLED();	//display 7seg LED 

		if (INC_BUTTON==FALSE) {        //if INC button is pressed
			switch(cursor){
				case 6:
					D1MHz+=1;
					if (D1MHz>9) D1MHz=0;
					break;
				case 5:
					D100KHz+=1;
					if (D100KHz>9) D100KHz=0;
					break;
				case 4:
					D10KHz+=1;
					if (D10KHz>9) D10KHz=0;
					break;
				case 3:
					D1KHz+=1;
					if (D1KHz>9) D1KHz=0;
					break;
				case 2:
					D100Hz+=1;
					if (D100Hz>9) D100Hz=0;
					break;
				case 1:
					D10Hz+=1;
					if (D10Hz>9) D10Hz=0;
					break;
				case 0:
					D1Hz+=1;
					if (D1Hz>9) D1Hz=0;
					break;
			}
			KeyDelay();           //key bounce delay
		}
		if (SHIFT_BUTTON==FALSE) {        //if SEL button is pressed
			cursor+=1;
			if (cursor>=7) cursor=0;
			LEDNUM=cursor;
			KeyDelay();           //key bounce delay
		}
		if (SET_BUTTON==FALSE) {
			UpdateDDS();
			SaveFreq();     //if SET button is pressed
			KeyDelay();           //key bounce delay
		}
	}
}
