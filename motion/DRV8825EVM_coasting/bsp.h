#ifndef bsp_h
#define bsp_h

#include <msp430f1612.h>//<msp430x16x.h>
#undef USE_TIMERB

typedef unsigned char uint8_t;
typedef unsigned short uint16_t;
typedef unsigned long uint32_t;

void BSP_init(void);
void assert(uint8_t boolval);

#define TRUE 1
#define FALSE 0
#define LED_on()   (P6OUT |= BIT5)
#define LED_off()  (P6OUT &= ~BIT5)
#define LED_toggle() (P6OUT ^= BIT5)


#define STP_toggle() (P4OUT ^= BIT3)
#define STP_on()     (P4OUT |= BIT3)
#define STP_off()    (P4OUT &= ~BIT3)

#define Stepper_on()   (P4OUT |= (BIT6 | BIT7))
#define Stepper_off()  (P4OUT &= ~(BIT6 | BIT7))

#define DIRECTION(bDir) if(bDir) P4OUT |= BIT4; else P4OUT &= ~BIT4

#define uStep8_on()   (P5OUT |= (BIT3 + BIT1))
#define uStep32_on()   (P5OUT |= (BIT3 + BIT1 + BIT0))
#define uStep_off()  (P5OUT &= ~(BIT3 + BIT1 + BIT0))

#define DECAY_set(bFast)  if(bFast) P4OUT |= BIT1; else P4OUT &= ~BIT1

#define SYS_TICK (8 * 1000000)
#define SYS_TICKF (8.0f * 1000000.0f)
#define TIMER_A_CLK_DIV 1.0f //4
#define CLOCK_TICK_TO_FLOAT 0.000000125f//(TIMER_A_CLK_DIV/SYS_TICKF)

#endif                                                             /* bsp_h */

