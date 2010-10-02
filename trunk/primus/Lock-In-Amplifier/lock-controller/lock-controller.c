#include <p18f1220.h>
#include <delays.h>

#pragma config OSC = INTIO1
#pragma config FSCM = OFF
#pragma config IESO = OFF
#pragma config PWRT = OFF
#pragma config BOR = OFF
#pragma config WDT = OFF
#pragma config MCLRE = ON
#pragma config STVR = OFF
#pragma config LVP = OFF
#pragma config CP1 = OFF
#pragma config CPB = OFF
#pragma config CPD = OFF
#pragma config WRT0 = OFF
#pragma config WRT1 = OFF
#pragma config WRTB = OFF
#pragma config WRTC = OFF
#pragma config WRTD = OFF
#pragma config EBTR0 = OFF
#pragma config EBTR1 = OFF
#pragma config EBTRB = OFF

#define INPUT1     PORTBbits.RB0
#define INPUT2     PORTBbits.RB1
#define ZUST_A     PORTAbits.RA0
#define ZUST_B     PORTAbits.RA1
#define ZUST_C     PORTAbits.RA2
#define INTEXT     PORTAbits.RA3
#define FAST_RELAY PORTBbits.RB2
#define SLOW_RELAY PORTBbits.RB3
#define RAMP_RELAY PORTBbits.RB4


void Delay10TCYx(unsigned char unit);


void main (void)
{
  /* Make all bits on the Port B (LEDs) output bits.
   * If bit is cleared, then the bit is an output bit.
   */
  
	OSCCON = 0b01110010;    //configuring register to give 8MHz internal system clock source
	ADCON1 = 0b11111111;    //disable all analog inputs 
	TRISA = 0b00001111;     //RA0..RA3 are inputs, RA4..RA7 are outputs
    TRISB = 0b00000011;     //RB0..RB1 are inputs, RB2..RB7 are outputs
    PORTA = 0;              //initialize PORTA 
	PORTB = 0;              //initialize PORTB
    
while(1)
 {
	while (!INTEXT)    //while on internal control
	    {
	      if(ZUST_A==1){FAST_RELAY = 1; SLOW_RELAY = 0; RAMP_RELAY = 0;}
	      else if (ZUST_B==1){FAST_RELAY = 0; SLOW_RELAY = 1; RAMP_RELAY = 0;}     
	      else{FAST_RELAY = 0; SLOW_RELAY = 0; RAMP_RELAY = 1;}
	      Delay10TCYx(0);
	    }  
	
	while (INTEXT)    //while on internal control
	    {
          if((PORTB&&0b00000011)==0){FAST_RELAY = 0; SLOW_RELAY = 0; RAMP_RELAY = 0;}
	      else if((PORTB&&0b00000011)==1){FAST_RELAY = 1; SLOW_RELAY = 0; RAMP_RELAY = 0;}
	      else if((PORTB&&0b00000011)==2){FAST_RELAY = 0; SLOW_RELAY = 1; RAMP_RELAY = 0;}     
	      else{FAST_RELAY = 0; SLOW_RELAY = 0; RAMP_RELAY = 1;}
	      Delay10TCYx(0);
	    }  
	
	 Delay10TCYx(0);    
  }

}
