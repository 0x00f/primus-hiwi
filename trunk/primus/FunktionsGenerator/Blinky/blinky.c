#include <htc.h>

__CONFIG(1, HS & FCMDIS & IESODIS);
__CONFIG(2, PWRTDIS & SWBOREN & BORV45 & WDTPS32K);
__CONFIG(3, CCP2RB3 & PBDIGITAL & LPT1DIS & MCLREN);
__CONFIG(4, XINSTEN & STVREN & LVPDIS & DEBUGEN);
__CONFIG(5, UNPROTECT);
__CONFIG(6, UNPROTECT);
__CONFIG(7, UNPROTECT);

void init(void)
{
// port directions: 1=input, 0=output
TRISB = 0b00000000;
}
char counter;
void main(void)
{
init();
while (1){
PORTB = counter;
_delay(500);
counter++;
}
}