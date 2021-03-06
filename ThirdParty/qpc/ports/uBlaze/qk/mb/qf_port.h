/*****************************************************************************
* Product:  QF/C, port to 80x86, QK port, Open Watcom compiler
* Last Updated for Version: 4.3.00
* Date of the Last Update:  Oct 31, 2011
*
*                    Q u a n t u m     L e a P s
*                    ---------------------------
*                    innovating embedded systems
*
* Copyright (C) 2002-2011 Quantum Leaps, LLC. All rights reserved.
*
* This software may be distributed and modified under the terms of the GNU
* General Public License version 2 (GPL) as published by the Free Software
* Foundation and appearing in the file GPL.TXT included in the packaging of
* this file. Please note that GPL Section 2[b] requires that all works based
* on this software must also be made publicly available under the terms of
* the GPL ("Copyleft").
*
* Alternatively, this software may be distributed and modified under the
* terms of Quantum Leaps commercial licenses, which expressly supersede
* the GPL and are specifically designed for licensees interested in
* retaining the proprietary status of their code.
*
* Contact information:
* Quantum Leaps Web site:  http://www.quantum-leaps.com
* e-mail:                  info@quantum-leaps.com
*****************************************************************************/
#ifndef qf_port_h
#define qf_port_h

                 /* The maximum number of active objects in the application */
#define QF_MAX_ACTIVE 63
#define QF_TIMEEVT_CTR_SIZE 4

#include "mb_interface.h"
#define QF_INT_DISABLE microblaze_disable_interrupts
#define QF_INT_ENABLE  microblaze_enable_interrupts

//#undef QF_CRIT_STAT_TYPE
#define QF_CRIT_STAT_TYPE u32
#ifdef QF_CRIT_STAT_TYPE
#  include "xintc.h"
   extern XIntc intc;

#  define QF_CRIT_ENTRY(stat_) do { \
	(stat_) = XIntc_In32(intc.BaseAddress + XIN_IER_OFFSET); \
	XIntc_Out32(intc.BaseAddress + XIN_IER_OFFSET, 0); \
} while(0)

#  define QF_CRIT_EXIT(stat_) \
	XIntc_Out32(intc.BaseAddress + XIN_IER_OFFSET, (stat_))
//#  define QF_CRIT_STAT_    QF_CRIT_STAT_TYPE critStat_;

#else /* unconditionally lock and unlock */
#  define QF_CRIT_ENTRY(stat_)  QF_INT_DISABLE()
#  define QF_CRIT_EXIT(stat_)   QF_INT_ENABLE()
#endif/* QF_CRIT_STAT_TYPE */

#include "qep_port.h"                                           /* QEP port */
#include "qk_port.h"                                             /* QK port */
#include "qf.h"                        /* QF platform-independent interface */

#endif                                                         /* qf_port_h */
