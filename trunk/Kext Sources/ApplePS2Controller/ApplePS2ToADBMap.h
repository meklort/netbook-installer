/*
 * Copyright (c) 1998-2000 Apple Computer, Inc. All rights reserved.
 *
 * @APPLE_LICENSE_HEADER_START@
 * 
 * The contents of this file constitute Original Code as defined in and
 * are subject to the Apple Public Source License Version 1.1 (the
 * "License").  You may not use this file except in compliance with the
 * License.  Please obtain a copy of the License at
 * http://www.apple.com/publicsource and read it before using this file.
 * 
 * This Original Code and all software distributed under the License are
 * distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, EITHER
 * EXPRESS OR IMPLIED, AND APPLE HEREBY DISCLAIMS ALL SUCH WARRANTIES,
 * INCLUDING WITHOUT LIMITATION, ANY WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE OR NON-INFRINGEMENT.  Please see the
 * License for the specific language governing rights and limitations
 * under the License.
 * 
 * @APPLE_LICENSE_HEADER_END@
 */

#ifndef _APPLEPS2TOADBMAP_H
#define _APPLEPS2TOADBMAP_H



/* 
 * Special key values
 */

#define ADBK_DELETE	0x33
#define ADBK_FORWARD_DELETE	0x75
#define ADBK_PBFNKEY	0x3F
#define ADBK_LEFT	0x3B
#define ADBK_RIGHT	0x3C
#define ADBK_UP		0x3E
#define ADBK_DOWN	0x3D
#define ADBK_PGUP	0x74
#define ADBK_PGDN	0x79
#define ADBK_HOME	0x73
#define ADBK_END	0x77
#define ADBK_CONTROL	0x36
#define ADBK_CONTROL_R  0x7D
#define ADBK_FLOWER	0x37
#define ADBK_SHIFT	0x38
#define ADBK_SHIFT_R    0x7B
#define ADBK_CAPSLOCK	0x39
#define ADBK_OPTION	0x3A
#define ADBK_OPTION_R   0x7C
#define	ADBK_NUMLOCK	0x47
#define ADBK_SPACE	0x31
#define ADBK_F		0x03
#define ADBK_O		0x1F
#define ADBK_P		0x23
#define ADBK_Q		0x0C
#define ADBK_V		0x09
#define ADBK_1		0x12
#define ADBK_2		0x13
#define ADBK_3		0x14
#define ADBK_4		0x15
#define ADBK_5		0x17
#define ADBK_6		0x16
#define ADBK_7		0x1A
#define ADBK_8		0x1C
#define ADBK_9		0x19
#define ADBK_0		0x1D
#define ADBK_F9		0x65
#define ADBK_F10	0x6D
#define ADBK_F11	0x67
#define ADBK_F12	0x6F
#define	ADBK_POWER	0x7f	/* actual 0x7f 0x7f */

#define ADBK_KEYVAL(key)	((key) & 0x7f)
#define ADBK_PRESS(key)		(((key) & 0x80) == 0)
#define ADBK_KEYDOWN(key)	(key)
#define ADBK_KEYUP(key)		((key) | 0x80)
#define ADBK_MODIFIER(key)	((((key) & 0x7f) == ADBK_SHIFT) || \
(((key) & 0x7f) == ADBK_SHIFT_R) || \
(((key) & 0x7f) == ADBK_CONTROL) || \
(((key) & 0x7f) == ADBK_CONTROL_R) || \
(((key) & 0x7f) == ADBK_FLOWER) || \
(((key) & 0x7f) == ADBK_OPTION) || \
(((key) & 0x7f) == ADBK_OPTION_R) || \
(((key) & 0x7f) == ADBK_NUMLOCK) || \
(((key) & 0x7f) == ADBK_CAPSLOCK))

/* ADB Keyboard Status - ADB Register 2 */

#define	ADBKS_LED_NUMLOCK		0x0001
#define	ADBKS_LED_CAPSLOCK		0x0002
#define	ADBKS_LED_SCROLLLOCK		0x0004
#define	ADBKS_SCROLL_LOCK		0x0040
#define	ADBKS_NUMLOCK			0x0080
/* Bits 3 to 5 are reserved */
#define	ADBKS_APPLE_CMD			0x0100
#define	ADBKS_OPTION			0x0200
#define	ADBKS_SHIFT			0x0400
#define	ADBKS_CONTROL			0x0800
#define	ADBKS_CAPSLOCK			0x1000
#define	ADBKS_RESET			0x2000
#define	ADBKS_DELETE			0x4000
/* bit 16 is reserved */



#define DEADKEY 0x80

static const UInt8 PS2ToADBMap[0x82] = 
{
/*  ADB       AT  Key-Legend
 ======================== */
DEADKEY,  // 00
0x35,  // 01  Escape
ADBK_1,  // 02  1
ADBK_2,  // 03  2
ADBK_3,  // 04  3
ADBK_4,  // 05  4
ADBK_5,  // 06  5
ADBK_6,  // 07  6
ADBK_7,  // 08  7
ADBK_8,  // 09  8
ADBK_9,  // 0a  9
ADBK_0,  // 0b  0
0x1b,  // 0c  -_
0x18,  // 0d  =+
ADBK_DELETE,  // 0e  Backspace
0x30,  // 0f  Tab
ADBK_Q,  // 10  Q
0x0d,  // 11  W
0x0e,  // 12  E
0x0f,  // 13  R
0x11,  // 14  T
0x10,  // 15  Y
0x20,  // 16  U
0x22,  // 17  I
ADBK_O,  // 18  O
ADBK_P,  // 19  P
0x21,  // 1a  [{
0x1e,  // 1b  ]}
0x24,  // 1c  Enter
0x3b,  // 1d  Left Ctrl
0x00,  // 1e  A
0x01,  // 1f  S
0x02,  // 20  D
ADBK_F,  // 21  F
0x05,  // 22  G
0x04,  // 23  H
0x26,  // 24  J
0x28,  // 25  K
0x25,  // 26  L
0x29,  // 27  ;:
0x27,  // 28  '"
0x32,  // 29  `~
0x38,  // 2a  Left Shift
0x2a,  // 2b  \|
0x06,  // 2c  Z
0x07,  // 2d  X
0x08,  // 2e  C
ADBK_V,  // 2f  V
0x0b,  // 30  B
0x2d,  // 31  N
0x2e,  // 32  M
0x2b,  // 33  ,<
0x2f,  // 34  .>
0x2c,  // 35  /?
0x3c,  // 36  Right Shift
0x43,  // 37  Keypad *
0x3a,  // 38  Left Alt
ADBK_SPACE,  // 39  Space
ADBK_CAPSLOCK,  // 3a  Caps Lock
0x7a,  // 3b  F1
0x78,  // 3c  F2
0x63,  // 3d  F3
0x76,  // 3e  F4
0x60,  // 3f  F5
0x61,  // 40  F6
0x62,  // 41  F7
0x64,  // 42  F8
ADBK_F9,  // 43  F9
ADBK_F10,  // 44  F10
ADBK_NUMLOCK,  // 45  Num Lock
0x6b,  // 46  Scroll Lock
0x59,  // 47  Keypad Home
0x5b,  // 48  Keypad Up
0x5c,  // 49  Keypad PgUp
0x4e,  // 4a  Keypad -
0x56,  // 4b  Keypad Left
0x57,  // 4c  Keypad 5
0x58,  // 4d  Keypad Right
0x45,  // 4e  Keypad +
0x53,  // 4f  Keypad End
0x54,  // 50  Keypad Down
0x55,  // 51  Keypad PgDn
0x52,  // 52  Keypad Insert
0x41,  // 53  Keypad Del
DEADKEY,  // 54  SysReq
DEADKEY,  // 55
/*DEADKEY*/ 0x0a,  // 56 ABNT2 "\|"
ADBK_F11,  // 57  F11
ADBK_F12,  // 58  F12
DEADKEY,  // 59
DEADKEY,  // 5a
DEADKEY,  // 5b
DEADKEY,  // 5c
DEADKEY,  // 5d
DEADKEY,  // 5e
DEADKEY,  // 5f
0x3e,  // 60  Right Ctrl
0x3d,  // 61  Right Alt
0x4c,  // 62  Keypad Enter
0x4b,  // 53  Keypad /
0x7e,  // 64  Up Arrow
0x7d,  // 65  Down Arrow
0x7b,  // 66  Left Arrow
0x7c,  // 67  Right Arrow
0x72,  // 68  Insert
ADBK_FORWARD_DELETE,  // 69  Delete
ADBK_PGUP,  // 6a  Page Up
ADBK_PGDN,  // 6b  Page Down
ADBK_HOME,  // 6c  Home
ADBK_END,  // 6d  End
0x69,  // 6e  Print Scrn
0x71,  // 6f  Pause
ADBK_FLOWER,  // 70  Left Window
0x36,  // 71  Right Window
0x6e,  // 72  Applications
/*DEADKEY*/ 0x5e,  // 73 ABNT2 "?/"
DEADKEY,  // 74
DEADKEY,  // 75
DEADKEY,  // 76
DEADKEY,  // 77
/* International */ DEADKEY,  // 78
DEADKEY,  // 79
DEADKEY,  // 7a
DEADKEY,  // 7b
0x7f,  // 7c
0x48,  // 7d Volume Up
0x49,  // 7e Volume Down
0x4a   // 7f Volume Mute
};

#endif /* !_APPLEPS2TOADBMAP_H */
