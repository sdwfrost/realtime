#ifndef bsp_h
#define bsp_h

#include <msp430f1612.h>//<msp430x16x.h>

typedef unsigned char uint8_t;
typedef unsigned short uint16_t;
typedef unsigned long uint32_t;
typedef char int8_t;
typedef short int16_t;
typedef long int32_t;
typedef long long int int64_t;
typedef unsigned long long int uint64_t;

#define TRUE 1
#define FALSE 0

void BSP_init(void);
void assert(uint8_t boolval);

#define LED_on()   (P6OUT |= BIT5)
#define LED_off()  (P6OUT &= ~BIT5)

#define STP_on()   (P4OUT |= BIT3)
#define STP_off()  (P4OUT &= ~BIT3)
#define STP_toggle() (P4OUT ^= BIT3)

#define Stepper_on()   (P4OUT |= (BIT6 | BIT7))
#define Stepper_off()  (P4OUT &= ~(BIT6 | BIT7))

#define DIRECTION(bDir) if(bDir) P4OUT |= BIT4; else P4OUT &= ~BIT4

#define MD0PIN BIT3
#define MD1PIN BIT1
#define MD2PIN BIT0
#define uStep_off()   (P5OUT &= ~(MD2PIN + MD2PIN + MD2PIN))
#define uStep2_on()   (P5OUT |= (MD0PIN))
#define uStep4_on()   (P5OUT |= (MD1PIN))
#define uStep8_on()   (P5OUT |= (MD1PIN + MD0PIN))
#define uStep16_on()  (P5OUT |= (MD2PIN))
#define uStep32_on()  (P5OUT |= (MD2PIN + MD1PIN + MD0PIN))

#define DECAY_set(bFast)  if(bFast) P4OUT |= BIT1; else P4OUT &= ~BIT1

#define SYS_TICK (8 * 1000000)
#define SYS_TICKF (8.0f * 1000000.0f)
#define TIMER_A_CLK_DIV 1.0f //4
#define CLOCK_TICK_TO_FLOAT 0.000000125f//(TIMER_A_CLK_DIV/SYS_TICKF)

#endif                                                             /* bsp_h */

