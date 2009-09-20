/*
 *  Verbs.h
 *  patchedAppleHDA
 *
 *  Created by Evan Lojewski on 8/17/09.
 *  Copyright 2009. All rights reserved.
 *
 */

#define VERB_4BIT(__codec__, __node__, __verb__, __payload__)		(((__codec__ & 0xF) << 28)| ((__node__ & 0x0FF) << 20) | ((__verb__ & 0xF) << 16) | (__payload__ & 0xFFFF))
#define VERB_16BIT(__codec__, __node__, __verb__, __payload__)		(((__codec__ & 0xF) << 28)| ((__node__ & 0x0FF) << 20) | ((__verb__ & 0xFFF) << 8) | (__payload__ & 0xFF))



#define VERB_RESPONSE_UNSOLICITED(__response__)		(__response__ & (0x01 << 28))
#define VERB_RESPONSE_TAG(__response__)				(__response__ & (0x03 << 32))
#define VERB_RESPONSE(__response__)					(__response__ & 0xFFFFFFF)


#define HDA_GET_PARAMETERS	0x00

#define HDA_SELECT_CONTROL	0x01
#define HDA_SET_CONNECTION_SELECT	0x701



#define HDA_GET_PINSENCE	0xF09
#define HDA_EXEC_PINSENCE	0x709

#define HDA_SET_EAPD		0x70C
#define HDA_PIN_CTRL		0x707

	//#define HDA_SET_EAPD			0x3B0

