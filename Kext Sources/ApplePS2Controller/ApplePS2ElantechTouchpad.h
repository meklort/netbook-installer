/*
 *  ApplePS2ElantechTouchpad.h
 *  ApplePS2Trackpad
 *
 *  Created by Evan Lojewski on 7/24/09.
 *  Copyright 2009. All rights reserved.
 *
 */



#ifndef _APPLEPS2ELANTECHTOUCHPAD_H
#define _APPLEPS2ELANTECHTOUCHPAD_H

#include "ApplePS2MouseDevice.h"
#include <IOKit/hidsystem/IOHIPointing.h>


/*
 * Elantech Touchpad driver (v6)
 *
 * Copyright (C) 2007-2009 Arjan Opmeer <arjan@opmeer.net>
 *
 * This program is free software; you can redistribute it and/or modify it
 * under the terms of the GNU General Public License version 2 as published
 * by the Free Software Foundation.
 *
 * Trademarks are the property of their respective owners.
 */


// kET_** = Elantech Commands
#define kET_firmwareVersion			0x01
#define kET_getCapabilities			0x02
#define kET_readRegister			0x10
#define kET_writeRegister			0x11

#define kET_customCommand			0xF8


/*
 * Times to retry a ps2_command and millisecond delay between tries
 */
#define ETP_PS2_COMMAND_TRIES		3
#define ETP_PS2_COMMAND_DELAY		500

/*
 * Times to try to read back a register and millisecond delay between tries
 */
#define ETP_READ_BACK_TRIES		5
#define ETP_READ_BACK_DELAY		2000

/*
 * Register bitmasks for hardware version 1
 */
#define ETP_R10_ABSOLUTE_MODE		0x04
#define ETP_R11_4_BYTE_MODE		0x02

/*
 * Capability bitmasks
 */
#define ETP_CAP_HAS_ROCKER		0x04


// Version One X / Y absolute values
#define ABSOLUTE_X_MIN_V1		32
#define ABSOLUTE_X_MAX_V1		544
#define ABSOLUTE_Y_MIN_V1		32
#define ABSOLUTE_Y_MAX_V1		352

// Version Two X / Y absolute values
#define ABSOLUTE_X_MIN_V2		8
#define ABSOLUTE_X_MAX_V2		1144
#define ABSOLUTE_Y_MIN_V2		8
#define ABSOLUTE_Y_MAX_V2		760

#define ABSOLUTE_X_MIN_MULTI_FINGER		4
#define ABSOLUTE_X_MAX_MULTI_FINGER		284
#define ABSOLUTE_Y_MIN_MULTI_FINGER		4
#define ABSOLUTE_Y_MAX_MULTI_FINGER		188

struct elantech_data {
	unsigned char reg_10;
	unsigned char reg_11;
	unsigned char reg_20;
	unsigned char reg_21;
	unsigned char reg_22;
	unsigned char reg_23;
	unsigned char reg_24;
	unsigned char reg_25;
	unsigned char reg_26;
	unsigned char debug;
	unsigned char capabilities;
	unsigned char fw_version_maj;
	unsigned char fw_version_min;
	unsigned char hw_version;
	unsigned char paritycheck;
	unsigned char jumpy_cursor;
	unsigned char parity[256];
};

int elantech_detect(struct psmouse *psmouse, int set_properties);
int elantech_init(struct psmouse *psmouse);



// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// ApplePS2ElantechTouchpad Class Declaration
//

class ApplePS2ElantechTouchpad : public IOHIPointing 
	{
		OSDeclareDefaultStructors( ApplePS2ElantechTouchpad );
		
	private:
		ApplePS2MouseDevice * _device;
		UInt32                _interruptHandlerInstalled:1;
		UInt32                _powerControlHandlerInstalled:1;
		UInt8                 _packetBuffer[4];
		UInt8				  _hardwareVersion;
		UInt32                _packetByteCount;
		IOFixed               _resolution;
		UInt16                _touchPadVersion;
		UInt8                 _touchPadModeByte;
		
		virtual void   dispatchRelativePointerEventWithPacket( UInt8 * packet,
															  UInt32  packetSize );
		
		virtual void   setCommandByte( UInt8 setBits, UInt8 clearBits );
		virtual void   setSampleRateAndResolution( void );
		
		virtual void   setTapEnable( bool enable );
		virtual void   setTouchPadEnable( bool enable );
		
//#if _NO_TOUCHPAD_ENABLE_
		virtual UInt8  readRegister( UInt8 readReg );

		
		virtual UInt32 getTouchPadData( UInt8 dataSelector );
		virtual bool   setTouchPadModeByte( UInt8 modeByteValue,
										   bool  enableStreamMode = false );
//#endif
		virtual void   free();
		virtual void   interruptOccurred( UInt8 data );
		virtual void   setDevicePowerState(UInt32 whatToDo);
		

		
	protected:
		virtual IOItemCount buttonCount();
		virtual IOFixed     resolution();
		
	public:
		virtual bool init( OSDictionary * properties );
		virtual ApplePS2ElantechTouchpad * probe( IOService * provider,
                                               SInt32 *    score );
		
		virtual bool start( IOService * provider );
		virtual void stop( IOService * provider );
		
		virtual UInt32 deviceType();
		virtual UInt32 interfaceID();
		
		virtual IOReturn setParamProperties( OSDictionary * dict );
	};

#endif /* _APPLEPS2ELANTECHTOUCHPAD_H */
