/*
 * Copyright (c) 2002 Apple Computer, Inc. All rights reserved.
 *
 * @APPLE_LICENSE_HEADER_START@
 * 
 * The contents of this file constitute Original Code as defined in and
 * are subject to the Apple Public Source License Version 1.2 (the
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

/**
 *
 * Two finger scroll implimentation by Meklort
 * Copyright (c) 2009
 *
 **/

#include <IOKit/assert.h>
#include <IOKit/IOLib.h>
#include <IOKit/hidsystem/IOHIDParameter.h>
#include <IOKit/hidevent/IOHIDEventService.h>

#include <IOKit/IOTimerEventSource.h>

#include "ApplePS2SynapticsTouchPad.h"


#define ABS(a)	   (((a) < 0) ? -(a) : (a))


// =============================================================================
// ApplePS2SynapticsTouchPad Class Implementation
//

#define super IOHIPointing
OSDefineMetaClassAndStructors(ApplePS2SynapticsTouchPad, IOHIPointing);

UInt32 ApplePS2SynapticsTouchPad::deviceType()
{ return NX_EVS_DEVICE_TYPE_MOUSE; };

UInt32 ApplePS2SynapticsTouchPad::interfaceID()
{ return NX_EVS_DEVICE_INTERFACE_BUS_ACE; };

IOItemCount ApplePS2SynapticsTouchPad::buttonCount() { return 2; };
IOFixed     ApplePS2SynapticsTouchPad::resolution()  { return _resolution; };
IOFixed     ApplePS2SynapticsTouchPad::scrollResolution()  { return _resolution; };


// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

bool ApplePS2SynapticsTouchPad::init( OSDictionary * properties )
{
    //
    // Initialize this object's minimal state. This is invoked right after this
    // object is instantiated.
    //
    
    if (!super::init(properties))  return false;

    _device                    = 0;
	_prevButtons			   = 0;
    _interruptHandlerInstalled = false;
	_packetByteCount           = 0;
    _resolution                = ((int)(UNKNOWN_RESOLUTION_X * 25.4)) << 16; // UNKNOWN is used untill it cna be read from the device.
    _touchPadModeByte          = 0; //GESTURES_MODE_BIT; //| ABSOLUTE_MODE_BIT;	// We like absolute mode
	
	_tapped = false;
	_dragging = false;
	_dragLocked = false;
	_packetByteCount = 0;
	_settleTime = 0;
	_streamdt = 0;
	_streamdx = 0;
	_streamdy = 0;
	
	// Defaults...
	_prefScrollMode			= SCROLL_MODE_NONE;
	_prefGestureMode		= GESTURE_MODE_SCROLL;	// tread 3 fingers as two
	_prefHorizScroll		= false;
	_prefClicking			= false;
	_prefDragging			= false;
	_prefDragLock			= false;
	_prefSwapButtons		= false;
	_prefIgnoreAccidental	= true;
	
	_prefOneFingerThreshold		= Z_LIGHT_FINGER;
	_prefTwoFingerThreshold		= 250;
	_prefThreeFingerThreshold	= 650;
	
	_prefHysteresis				= .08;	// 8 percent

	_prefScrollArea				= .05;
	_prefScrollSpeed			= 1.3;
	_prefTrackSpeed				= 1.6;
	_prefClickDelay				= 280000;
	_prefReleaseDelay			= 400000;
	_prevDX = 0;
	_prevDY = 0;
	
	
	_keyboard = NULL;
		

    return true;
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

ApplePS2SynapticsTouchPad *
ApplePS2SynapticsTouchPad::probe( IOService * provider, SInt32 * score )
{
    //
    // The driver has been instructed to verify the presence of the actual
    // hardware we represent. We are guaranteed by the controller that the
    // mouse clock is enabled and the mouse itself is disabled (thus it
    // won't send any asynchronous mouse data that may mess up the
    // responses expected by the commands we send it).
    //

    ApplePS2MouseDevice * device  = (ApplePS2MouseDevice *) provider;
    PS2Request *          request = device->allocateRequest();
    bool                  success = false;
    
    if (!super::probe(provider, score) || !request) return 0;

    //
    // Send an "Identify TouchPad" command and see if the device is
    // a Synaptics TouchPad based on its response.  End the command
    // chain with a "Set Defaults" command to clear all state.
    //

    request->commands[0].command  = kPS2C_SendMouseCommandAndCompareAck;
    request->commands[0].inOrOut  = kDP_SetDefaultsAndDisable;
    request->commands[1].command  = kPS2C_SendMouseCommandAndCompareAck;
    request->commands[1].inOrOut  = kDP_SetMouseResolution;
    request->commands[2].command  = kPS2C_SendMouseCommandAndCompareAck;
    request->commands[2].inOrOut  = (kST_IdentifyTouchpad >> 6) & 0x3;
    request->commands[3].command  = kPS2C_SendMouseCommandAndCompareAck;
    request->commands[3].inOrOut  = kDP_SetMouseResolution;
    request->commands[4].command  = kPS2C_SendMouseCommandAndCompareAck;
    request->commands[4].inOrOut  = (kST_IdentifyTouchpad >> 4) & 0x3;
    request->commands[5].command  = kPS2C_SendMouseCommandAndCompareAck;
    request->commands[5].inOrOut  = kDP_SetMouseResolution;
    request->commands[6].command  = kPS2C_SendMouseCommandAndCompareAck;
    request->commands[6].inOrOut  = (kST_IdentifyTouchpad >> 2) & 0x3;
    request->commands[7].command  = kPS2C_SendMouseCommandAndCompareAck;
    request->commands[7].inOrOut  = kDP_SetMouseResolution;
    request->commands[8].command  = kPS2C_SendMouseCommandAndCompareAck;
    request->commands[8].inOrOut  = kST_IdentifyTouchpad & 0x3;
    request->commands[9].command  = kPS2C_SendMouseCommandAndCompareAck;
    request->commands[9].inOrOut  = kDP_GetMouseInformation;	// 24bit data structure
    request->commands[10].command = kPS2C_ReadDataPort;
    request->commands[10].inOrOut = 0;		// Read first byte
    request->commands[11].command = kPS2C_ReadDataPort;
    request->commands[11].inOrOut = 0;		// Read second byte
    request->commands[12].command = kPS2C_ReadDataPort;
    request->commands[12].inOrOut = 0;		// REad third byte
    request->commands[13].command = kPS2C_SendMouseCommandAndCompareAck;
    request->commands[13].inOrOut = kDP_SetDefaultsAndDisable;
    request->commandsCount = 14;
    device->submitRequestAndBlock(request);

	_touchpadIntormation = 0;
	_touchpadIntormation = request->commands[10].inOrOut | (request->commands[11].inOrOut << 8) | (request->commands[12].inOrOut << 16);
	
    if ( request->commandsCount == 14 &&
         request->commands[11].inOrOut == 0x47 )
    {
        _touchPadVersion = (request->commands[12].inOrOut & 0x0f) << 8
                         |  request->commands[10].inOrOut;

        //
        // Only support 4.x or later touchpads.
        //

        if ( _touchPadVersion >= 0x400 ) success = true;
    }

    device->freeRequest(request);

    return (success) ? this : 0;
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

bool ApplePS2SynapticsTouchPad::start( IOService * provider )
{ 
    //
    // The driver has been instructed to start. This is called after a
    // successful probe and match.
    //

    if (!super::start(provider)) return false;

    //
    // Maintain a pointer to and retain the provider object.
    //

    _device = (ApplePS2MouseDevice *) provider;
    _device->retain();

    //
    // Announce hardware properties.
    //

    IOLog("ApplePS2Trackpad: Synaptics TouchPad v%d.%d\n",
          (UInt8)(_touchPadVersion >> 8), (UInt8)(_touchPadVersion));
	setProperty("TouchpadInfo"	, _touchpadIntormation, sizeof(_touchpadIntormation));


	//getSerialNumber();
	getCapabilities();
	getExtendedCapabilities();
	getModelID();
	
	_scaleFactor = ( ((double)	 model_resolution[(INFO_SENSOR & 0x0f)][1] * model_dimensions[(INFO_SENSOR & 0x0f)][0]) ) / 
								(model_resolution[(INFO_SENSOR & 0x0f)][0] * model_dimensions[(INFO_SENSOR & 0x0f)][1]);
	
	_resolution = (int)(model_resolution[(INFO_SENSOR & 0x0f)][0] * 25.4) << 16;
	_resolution /= _scaleFactor;
	
	
	IOLog("ApplePS2Trackpad: Detected toucpad controller \"%s\" (ModelID: 0x%X)\n", model_names[INFO_SENSOR & 0x0f], (unsigned int)_modelId);	// anding with 0x0f because we only have 16 versions stored in the char array
	IOLog("ApplePS2Trackpad: Initializing resolution to %d dpi\n", (int)(model_resolution[(INFO_SENSOR & 0x0f)][0] * 25.4));
	IOLog("ApplePS2Trackpad: Compensating for geometry, setting resolution to %d dpi\n", (int)_resolution >> 16);

	IOLog("ApplePS2Trackpad: Capabilities 0x%X\n", (unsigned int) (_capabilties));
	
	if(CAP_W_MODE || EXT_W_MODE) 	{
		_touchPadModeByte |= W_MODE_BIT | ABSOLUTE_MODE_BIT | RATE_MODE_BIT;
		
		IOLog("ApplePS2Trackpad: W Mode Supported :D\n");
		if(CAP_PALM_DETECT)	IOLog("ApplePS2Trackpad: Palm detection Supported :D\n");
		if(CAP_MULTIFINGER)	IOLog("ApplePS2Trackpad: Multiple finger detection Supported :D\n");
		else	IOLog("ApplePS2Trackpad: Multiple finger detection NOT Supported :(\n");
		
		if(EXT_W_MODE) IOLog("ApplePS2Trackpad: Trackpad supports extended W mode\n");
		if(EXT_PEAK_DETECT) IOLog("ApplePS2Trackpad: Using peak detection method\n");
	} else {
		IOLog("ApplePS2Trackpad: W Mode not available, defaulting to Z mode :(\n");
		_touchPadModeByte |= ABSOLUTE_MODE_BIT | RATE_MODE_BIT;

	}
	
	
    setProperty(kIOHIDScrollResolutionKey, _resolution, 32);
	setProperty(kIOHIDPointerResolutionKey, _resolution, 32);

	//---------          Keyboard dissable code				---------/
	// This is probably a very bad way to do this, and was copied from Fredrik Andersson
	IOService* keyboard = IOService::waitForService( IOService::serviceMatching("ApplePS2Keyboard"));
	if(!keyboard)							IOLog("ApplePS2Trackpad: No keyboard interface\n");
	_keyboard = OSDynamicCast( IOHIKeyboard, keyboard );
	if (!_keyboard)							IOLog("ApplePS2Trackpad: Failed to abstract IOHIKeyboard\n");
	if (!_keyboard->_keyboardEventTarget)	IOLog("ApplePS2Trackpad: IOHIKeyboard does not have any target!\n");


	
	//
    // Write the TouchPad mode byte value.
    //

    setTouchPadModeByte(_touchPadModeByte);

    //
    // Advertise the current state of the tapping feature.
    //

    setProperty("Clicking", GESTURES, 8);

    //
    // Must add this property to let our superclass know that it should handle
    // trackpad acceleration settings from user space.  Without this, tracking
    // speed adjustments from the mouse prefs panel have no effect.
    //
	// This is handeled in this driver
    //setProperty(kIOHIDPointerAccelerationTypeKey, kIOHIDTrackpadAccelerationType);
	
    //
    // Install our driver's interrupt handler, for asynchronous data delivery.
    //

    _device->installInterruptAction(this, OSMemberFunctionCast(PS2InterruptAction, this, &ApplePS2SynapticsTouchPad::interruptOccurred));
    _interruptHandlerInstalled = true;

    //
    // Enable the mouse clock (should already be so) and the mouse IRQ line.
    //

    setCommandByte( kCB_EnableMouseIRQ, kCB_DisableMouseClock );

    //
    // Finally, we enable the trackpad itself, so that it may start reporting
    // asynchronous events.
    //

    setTouchPadEnable(true);
	setStreamMode(true);

    //
	// Install our power control handler.
	//

	_device->installPowerControlAction( this, OSMemberFunctionCast(PS2PowerControlAction, this,
										&ApplePS2SynapticsTouchPad::setDevicePowerState));
	_powerControlHandlerInstalled = true;
	
	
	_dragTimeout = IOTimerEventSource::timerEventSource( this,
														OSMemberFunctionCast( IOTimerEventSource::Action,
																					this, &ApplePS2SynapticsTouchPad::draggingTimeout) );
	
	// Attach to our parent's work look fo rthe timer
	getWorkLoop()->addEventSource(_dragTimeout);

    return true;
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

void ApplePS2SynapticsTouchPad::stop( IOService * provider )
{
    //
    // The driver has been instructed to stop.  Note that we must break all
    // connections to other service objects now (ie. no registered actions,
    // no pointers and retains to objects, etc), if any.
    //

    assert(_device == provider);

    //
    // Disable the mouse itself, so that it may stop reporting mouse events.
    //

    setTouchPadEnable(false);

    //
    // Disable the mouse clock and the mouse IRQ line.
    //

    setCommandByte( kCB_DisableMouseClock, kCB_EnableMouseIRQ );

	getWorkLoop()->removeEventSource(_dragTimeout);
	
    //
    // Uninstall the interrupt handler.
    //

    if ( _interruptHandlerInstalled )  _device->uninstallInterruptAction();
    _interruptHandlerInstalled = false;

    //
    // Uninstall the power control handler.
    //

    if ( _powerControlHandlerInstalled ) _device->uninstallPowerControlAction();
    _powerControlHandlerInstalled = false;
	

	super::stop(provider);
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

void ApplePS2SynapticsTouchPad::free()
{
    //
    // Release the pointer to the provider object.
    //

    if (_device)
    {
        _device->release();
        _device = 0;
    }

    super::free();
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

void ApplePS2SynapticsTouchPad::interruptOccurred( UInt8 data )
{
    //
    // This will be invoked automatically from our device when asynchronous
    // events need to be delivered. Process the trackpad data. Do NOT issue
    // any BLOCKING commands to our device in this context.
    //
    // Ignore all bytes until we see the start of a packet, otherwise the
    // packets may get out of sequence and things will get very confusing.
    //
	
	// In relative mode, 0x08 should be 1. In absolute mode, 0x08 should be 0
	if (_packetByteCount == 0){
		if(data == kSC_Acknowledge) return;
		else if(RELATIVE_MODE && !(data & 0x08)) return;
		else if(ABSOLUTE_MODE && (data & 0x08)) {
			setDevicePowerState(kPS2C_EnableDevice);	// The device had a brown out, reset it to absolute mode
			return;
		}
    }

	
	
	
    //
    // Add this byte to the packet buffer. If the packet is complete, that is,
    // we have the three bytes, dispatch this packet for processing.
    //

    _packetBuffer[_packetByteCount++] = data;
    
	
    if (RELATIVE_MODE  && (_packetByteCount == RELATIVE_PACKET_SIZE))
    {
		AbsoluteTime now;
		clock_get_uptime((uint64_t *)&now);
		
		// TODO: credit link. Also, verify 16700000ULL * 30....
		if(_prefIgnoreAccidental && (int)_keyboard->_codeToRepeat!=-1 && ((now.lo - _keyboard->_lastEventTime.lo)<(16700000ULL)*30))
		{
			// Do nothing
			// We are ignoring this packet...
			// TODO: We MIGHT not want to ignore button presss... (aka, just make it a DEFAULT_EVENT)
		}
		else
		{
			dispatchRelativePointerEventWithRelativePacket(_packetBuffer, RELATIVE_PACKET_SIZE, now);
		}
		
        _packetByteCount = 0;
	} else if (ABSOLUTE_MODE && (_packetByteCount == ABSOLUTE_PACKET_SIZE)) {
		AbsoluteTime now;
		clock_get_uptime((uint64_t *)&now);

		// TODO: credit link. Also, verify 16700000ULL * 30....
		if(_prefIgnoreAccidental && (int)_keyboard->_codeToRepeat!=-1 && ((now.lo - _keyboard->_lastEventTime.lo)<(16700000ULL)*30))
		{
			// Do nothing
			// We are ignoring this packet...
			// TODO: We MIGHT not want to ignore button presss... (aka, just make it a DEFAULT_EVENT)
		}
		else
		{
			dispatchRelativePointerEventWithAbsolutePacket(_packetBuffer, ABSOLUTE_PACKET_SIZE, now);

		}
		
		
		
		_packetByteCount = 0;
	}
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

void ApplePS2SynapticsTouchPad::
dispatchRelativePointerEventWithAbsolutePacket( UInt8 * packet,
									   UInt32  packetSize, AbsoluteTime now )
{
	// Packet without W mode disabled	(twice as long as relative mode, first two bits specify which type and packet (10 = Abs, pkt 1 -- 11 = Abs, pkt2), 
	//	7		6		5			4			3		2		1		0
	
	//	{1}		{0}		Finger		Reserved	{0}		Gesture Right	Left
	//	Y11		Y10		Y9			Y8			X11		X10		X9		X8			(Y 11..8) (X 11..8)
	//	Z7		Z6		Z5			Z4			Z3		Z2		Z1		Z0			(Z  7..0)
	//	{1}		{1}		Y12			X12			{0}		Gesture	Right	Left		(Y12) (X12)
	//	X7		X6		X5			X4			X3		X2		X1		X0			(X 7..0)
	//	Y7		Y6		Y5			Y4			Y3		Y2		Y1		Y0			(Y 7..0)
	
	// With W mode enabed
	//	7		6		5			4			3		2		1		0
	
	//	{1}		{0}		W3			W2			{0}		W1		Right	Left		(W 3..2) (W1)
	//	Y11		Y10		Y9			Y8			X11		X10		X9		X8			(Y 11..8) (X 11..8)
	//	Z7		Z6		Z5			Z4			Z3		Z2		Z1		Z0			(Z  7..0)
	//	{1}		{1}		Y12			X12			{0}		W0		R/D		R/L			(W0) (Y12) (X12)
	//	X7		X6		X5			X4			X3		X2		X1		X0			(X 7..0)
	//	Y7		Y6		Y5			Y4			Y3		Y2		Y1		Y0			(Y 7..0)
		
	UInt8	buttons;
	UInt32	absX, absY;
	UInt8	pressureZ;
	UInt8	Wvalue;
	UInt8	prevEvent = _event;
	UInt8	numFingers;
	uint32_t currentTime, second;
	
    // the values we need to properly calculate averages - required for jump prevention.
	SInt32  xavg, yavg, xsensitivity, ysensitivity, sensitivity = 0;

    // these are related to low-speed jitter on the trackpad.  They could be
	// tunable, but these are pretty solid defaults and they cancel out
	// the jitters.
	UInt32 low_speed_threshold = 20;
	UInt8  squelch_level = 3;
	UInt8  min_movement = 2;


	clock_get_system_microtime(&second, &currentTime);
	
	
	uint64_t dt = ((second - _prevPacketSecond) * 1000000) + (currentTime - _prevPacketTime);	// There MIGHT be a problem when this wrapps around, we may want to add a check later on
	_streamdt += dt;

	
	
	if(!_prefSwapButtons)
		buttons =			(packet[0] & 0x3);	// buttons =  last two bits of byte one of packet
	else 
		buttons = ((packet[0] & 0x01) << 1) | ((packet[0] & 0x02) >> 1); 
	pressureZ =			packet[2];												//	  (max value is 255)
	absX =				(packet[4] | ((packet[1] & 0x0F) << 8) | ((packet[3] & 0x10) << 8));
	absY =				(packet[5] | ((packet[1] & 0xF0) << 4) | ((packet[3] & 0x20) << 7));
	if(W_MODE) Wvalue = ((packet[3] & 0x4) >> 2) | ((packet[0] & 0x30) >> 2) | ((packet[0] & 0x4) >> 1);	// (max value = 15)
	else Wvalue = W_FINGER_MIN;

	// Averate the dx values, this is an exponential decaying average
	SInt32 dx = (absX - _prevX);
	SInt32 dy = (absY - _prevY);	// Y is negative for ps2 (according to synaptics)
	
	
	// Begin JayK modifications

	/*
	 IOLog("abs: %d,%d,\tdiff: %d,%d, avg: %d,%d\n", absX, absY, dx, dy, _xaverage,_yaverage);
	 if (ABS(dx) > 550 || ABS(dy) > 550) {
	 IOLog("Over Max Jump Threshold\n");
	 }*/
	
	// Jump prevention code - by Jay Kuri (jayk@cpan.org) 
	//
	// If distance spikes, the trackpad thinks we are zooming across the pad.  
	// This is probably NOT what we want. So if we get a change in any direction 
	// higher than 550 and it is significantly faster acceleration than our 
	// previous average, we kill the position and pretend like we've been 
	// here all along.  This smooths out our crazy pointer jumps.

	/*
	if ( 
		(ABS(dx) > 600 || ABS(dy) > 600) &&
		((ABS(dx - _xaverage) > 300) ||
		 (ABS(dy - _yaverage) > 300))) {
		
		IOLog("ApplePS@Trackpad: Acceleration: %ld, %ld", (ABS(dx - _xaverage)), (ABS(dy - _yaverage)));
		if(
		   (_prevX != 0 && _prevY != 0) &&
		   (absX != 0 && absY != 0)
			) IOLog("ApplePS2Trackpad: Jump detected, squashing. old: %ld,%ld \tnew: %ld,%ld\n",_prevX,_prevY, absX,absY);

		_xaverage = dx;
		_yaverage = dy;
		dx = 0;
		dy = 0;
	}

    // Compute averages of x and y movement.  This helps us figure out 
	// if we just accelerated off the chart which is how we detect the trackpad jump
	if (_xaverage == 0) {
        _xaverage = dx;
	}
	if (_yaverage == 0) {
		_yaverage = dy;
	}
	
	//xavg = _xaverage;
	//yavg = _yaverage;
	
	dx = _xaverage = (_xaverage + 2 * dx) /3;
	dy = _yaverage = (_yaverage + 2 * dy) /3;
	
	//xsensitivity = ABS(_xaverage - (_xaverage + dx) /2);

	//ysensitivity = ABS(_yaverage - yavg);

	/* 
	 * The sensitivity level is higher the faster the finger
	 * is moving. It also tends to be higher in the middle
	 * of a touchpad motion than on either end
	 *
	 * Note - sensitivity gets to 0 when moving slowly - so
	 * we add 1 to it to give it a meaningful value in that case.
	 */
	//sensitivity = (xsensitivity & ysensitivity)+1;

	/* 
	 * If either our x or y change is greater than our
	 * hi/low speed threshold - we do the high-speed
	 * absolute to relative calculation otherwise we
	 * do the low-speed calculation.
	 */
	/*if (ABS(dx) > ABS(low_speed_threshold) ||
		ABS(dy) > ABS(low_speed_threshold)) {
	*/	
		dy /= _scaleFactor;
		
		// Scale dx and dy bassed on the type of movement. This does not need to happen after event calculation because IF the event changes, dx and dy are reset to 0
		if((_event & (SCROLLING | VERTICAL_SCROLLING | HORIZONTAL_SCROLLING)) == 0) {
			dx *= _prefTrackSpeed;
			dy *= _prefTrackSpeed;
		} else {
			dx = 2 * dx * _prefScrollSpeed;
			dy = 2 * dy * _prefScrollSpeed;
		}
		if(ABS(dx) < ACCELERATION_TABLE_SIZE) ABS(dx) == dx ? dx = accelerationTable[ABS(dx)] : dx = -accelerationTable[ABS(dx)];
		if(ABS(dy) < ACCELERATION_TABLE_SIZE) ABS(dy) == dy ? dy = accelerationTable[ABS(dy)] : dy = -accelerationTable[ABS(dy)];

	/*} else {
		*//* 
		 * This is the low speed calculation.
		 * We simply check to see if our movement
		 * is more than our minimum movement threshold
		 * and if it is - set the movement to 1 in the
		 * correct direction.
		 * NOTE - Normally this would result in pointer
		 * movement that was WAY too fast.  This works
		 * due to the movement squelch we do later.
		 */
		/*if (dx < -min_movement)
			dx = -1;
		else if (dx > min_movement)
			dx = 1;
		else
			dx = 0;
		if (dy < -min_movement)
			dy = -1;
		else if (dy > min_movement)
			dy = 1;
		else
			dy = 0;
	}*/
	
	/* 
	 * ok - the squelch process.  Take our sensitivity value
	 * and add it to the current squelch value - if squelch
	 * is less than our squelch threshold we kill the movement,
	 * otherwise we reset squelch and pass the movement through.
	 * Since squelch is cumulative - when mouse movement is slow
	 * (around sensitivity 1) the net result is that only
	 * 1 out of every squelch_level packets is
	 * delivered, effectively slowing down the movement.
	 */
	
/*	_squelch += sensitivity;
	if (_squelch < squelch_level) {
		IOLog("Squelch");
		dx = 0;
		dy = 0;
	} else {
		_squelch = 0;
    }
*/
	// End jayk jump modifications
	
	_streamdx += dx;
	_streamdy += dy;
	
	
	numFingers = 4;
	// Finger detection algorithm
	if(W_MODE && CAP_MULTIFINGER)											// Touchpad is multitouch capable
	{
		if(pressureZ < _prefOneFingerThreshold)											numFingers = 0;
		else if(Wvalue == W_TWOFINGERS)					numFingers = 2;	
		else if(Wvalue == W_THREEPLUS)				numFingers = 3;
		else										numFingers = 1;

	} 
	else if(W_MODE)																// Touchpad is W Mode enabled
	{
		// Yay for hysterisys (only for going from a larger number to smaller.
		
		// If a button is pressed, assume one finger is on the touchpad only.
		
		if(_prevNumFingers == 0)
		{
			if(pressureZ < _prefOneFingerThreshold)											numFingers = 0;
			else
			{
//				if(_dragging) _dragTimeout->cancelTimeout();
				     if(((Wvalue * pressureZ) < _prefTwoFingerThreshold)  || buttons)						numFingers = 1;
				else if(((Wvalue * pressureZ) < _prefThreeFingerThreshold))						numFingers = 2;
				else																			numFingers = 3;
			}
		}
		else if (_prevNumFingers == 1)
		{
			if(pressureZ < (_prefOneFingerThreshold * (1 - _prefHysteresis)))				numFingers = 0;
			else if(((Wvalue * pressureZ) < _prefTwoFingerThreshold)  || buttons)						numFingers = 1;
			else if(((Wvalue * pressureZ) < _prefThreeFingerThreshold))						numFingers = 2;
			else																			numFingers = 3;
			
		}
		else if (_prevNumFingers == 2)
		{
			if(pressureZ < (_prefOneFingerThreshold * (1 - _prefHysteresis)))						numFingers = 0;
			else if(((Wvalue * pressureZ) < (_prefTwoFingerThreshold  * (1 - _prefHysteresis)))  || buttons)	numFingers = 1;
			else if(((Wvalue * pressureZ) < _prefThreeFingerThreshold))				numFingers = 2;
			else																					numFingers = 3;
		}
		else if (_prevNumFingers == 3) 
		{
			if(pressureZ < (_prefOneFingerThreshold * (1 - _prefHysteresis)))						numFingers = 0;
			else if(((Wvalue * pressureZ) < (_prefTwoFingerThreshold  * (1 - _prefHysteresis)))  || buttons)	numFingers = 1;
			else if((Wvalue < 12) || (pressureZ * Wvalue < (_prefThreeFingerThreshold * (1 - _prefHysteresis))))				numFingers = 2;
			else																					numFingers = 3;
			
		}

	} 
	else																		// Touchpad does not suport W mode
	{
		if(pressureZ < _prefOneFingerThreshold)											numFingers = 0;
		numFingers = 1;
	}
	
	if(numFingers == 3) {
		switch(_prefGestureMode)
		{
			case GESTURE_MODE_NONE:
				numFingers = 0;				// Treat as scrolling
				break;
			case GESTURE_MODE_SCROLL:
				numFingers = 2;				// Dissable the trackpad
				break;
			case GESTURE_MODE_ENABLED:
			default:
				// Ignored, we keep numFingers = 3
				break;
		}
	}
	//if(_prevNumFingers ^ numFingers) IOLog("Number of Fingers: %d, from %d\n", numFingers, _prevNumFingers);
	
	//IOLog("Num FIngers: %d, W: %d, Z: %d, W*Z: %d\n", numFingers, Wvalue, pressureZ, Wvalue * pressureZ);
//	else if(
		
	
	
	
	

	// Wait for the data to stabalize, if its below Z_LIGHT_FINGER, we treat it as a new stream
	if(dt > 20000 || numFingers == 0) {
		_event = DEFAULT_EVENT;	// We reset dx and dy untill it is a reliable number (Z MUST be larger than 8 for it to be reliable)
	}
	else if(_event & (VERTICAL_SCROLLING | HORIZONTAL_SCROLLING | DRAGGING));	// These are events that are persistant
	else
	{
			switch(numFingers)
			{
				case 1:
					_event = MOVEMENT;
					break;
				case 2:
					if(_prefScrollMode == SCROLL_MODE_TWO_FINGER) _event = SCROLLING;
					else											_event = MOVEMENT;
					break;
				case 3:
					_event = SWIPE;	// Do nothing, swipe event is set later on
					break;
				default:
					_event = DEFAULT_EVENT;
					break;
			}
	}	

	if(prevEvent == SWIPE && _settleTime) _event = SWIPE;
	
	// If the event has just changed, OR if it has recently changed, let the touchpad settle
	if((prevEvent ^ _event) || _settleTime) {
		/***		Edge Scrolling Calculations		***/
		if(prevEvent == DEFAULT_EVENT && (_prefScrollMode == SCROLL_MODE_EDGE) &&
		   (absX > (ABSOLUTE_X_MAX * (1 - _prefScrollArea)))) _event = VERTICAL_SCROLLING;
		else if(prevEvent == DEFAULT_EVENT && (_prefScrollMode == SCROLL_MODE_EDGE) && _prefHorizScroll &&
			(absY < (ABSOLUTE_Y_MIN * (1 + (_prefScrollArea / 2))))) _event = HORIZONTAL_SCROLLING;
		

		
		/**			Scrolling Calculations			***/
		if(prevEvent != SCROLLING || _event != SCROLLING ||  _settleTime == 1) {
		   dx = 0;		
		   dy = 0;
		} else if(_event != SCROLLING){
			_event = SCROLLING;
		} 
		   
		
		
		
		/***		Event Changed calculations		***/
		if(!_settleTime) {
			//IOLog("prevEvent: %d,\tevent: %d\n", _prevEvent, _event);
			/***		New Stream Calculations			***/
			if(prevEvent == DEFAULT_EVENT)
			{
				_settleTime = 2; // we SHOULD have already settle, but just in case
				_streamdx = 0;
				_streamdy = 0;
				if(_event != SCROLLING) {
					dy = 0;
					dx = 0;
					_prevDX = 0;
					_prevDY = 0;
				}
				_streamdt = 0;
				if(_dragging) {
					_dragTimeout->cancelTimeout();
					_dragging = false;
					_event = DRAGGING;
				}

			/***		End of Stream Calculations		***/
			}
			else if(_event == DEFAULT_EVENT)
			{
				switch(prevEvent)
				{
					case SCROLLING:
						if(numFingers == 3) _settleTime = 5;
						else _settleTime = 10;
						_event = SCROLLING;
						if(_prefClicking && _prefSecondaryClick && TAPPING) {
							buttons = RIGHT_CLICK;
							_event = MOVEMENT;
						}

						break;
						
					case MOVEMENT:
						_settleTime = 5;
						if(!_prefClicking) break;
						
						if(TAPPING) {
							if(!_prefDragging)
							{
								buttons = LEFT_CLICK;
							}
							else
							{
								if(_dragLocked)
									_dragLocked = false;
								else
								{
									//IOLog("First tap\n");
									_tapped = true;
									_dragTimeout->setTimeoutUS(_prefClickDelay);			// Set timout to send tap event if no double tap
								}
							}
						}
						
						
						break;
						
					case DRAGGING:
						_settleTime = 10;
						if(TAPPING) 
						{
							if(_dragLocked) {
								_dragLocked = false;
								_event = DEFAULT_EVENT;
							} else {
								
								//IOLog("Double Clicking...\n");
								// We should be doing a double click now, instead of a drag
								dispatchRelativePointerEvent(0, 0, 1, now);
								dispatchRelativePointerEvent(0, 0, 0, now);	// Release the button so we can send a double click event
								buttons = 0x01;
								_tapped = false;
								_event = MOVEMENT;
								//_dragLocked = false;	// This will be removed soon
							}
							_event = DEFAULT_EVENT;	// Cancel the draggin event (aka, we are no longer drag locked
						}
						else
						{
							_dragging = true;
							_dragTimeout->setTimeoutUS(_prefReleaseDelay);			// Set timout to send tap event if no double tap
							//IOLog("Setting drag timeout\n");
							_event = DEFAULT_EVENT;

							//IOLog("Setting dragging...");
							//_event = DRAGGING;
						}
						
						break;
						
					case ZOOMING:
						/*static IOHIDEvent *     zoomEvent (
														   AbsoluteTime            timeStamp,
														   IOFixed                 x,
														   IOFixed                 y,
														   IOFixed                 z,
														   IOOptionBits            options = 0);
						 */
//						IOHIDEvent* me;
//						me = IOHIDEvent::zoomEvent(timeStamp, data->scrollWheel.pointDeltaAxis2<<16, data->scrollWheel.pointDeltaAxis1<<16, data->scrollWheel.pointDeltaAxis3<<16, options);

						/*
						 IOHIDEventType kIOHIDEventTypeZooming
						 */
						
						/*IOHIDEvent* event = new IOHIDEvent;
						event->initWithType(kIOHIDEventTypeZoom);
						IOHIDSwipeEventData* swipe = (IOHIDZoomEventData*)event->_data;
						
						swipe->swipeMask = 0;
						
						IOHIDSystem::instance()->dispatchEvent(event, 0);*/
						
					case SWIPE:
						if(numFingers == 0)	// end of swipe
						{
							//if(_streamdx /*<< 1*/ > _streamdy)	// Swipe left / right
							{
								if(_streamdx > 25) dispatchSwipeEvent(kIOHIDSwipeRight, now);
								else if(_streamdx < -25) dispatchSwipeEvent(kIOHIDSwipeLeft, now);
							}
							/*else if( _streamdy << 1 > _streamdx)
							{
								if(_streamdy > 100) dispatchSwipeEvent(kIOHIDSwipeUp, now);
								else if(_streamdy < -100) dispatchSwipeEvent(kIOHIDSwipeDown, now);
							}*/								
							_event = DEFAULT_EVENT;	// no more swiping
						} else if (!_settleTime) _settleTime = 15;

						//dispatchAbsoluteEvent(
					case HORIZONTAL_SCROLLING:
					case VERTICAL_SCROLLING:
					case DEFAULT_EVENT:
						_settleTime = 10;
						break;
				}
			} else {
				// _event != DEFAULT_EVENT && prevEvent != DEFAULT_EVENT
				if(_event != SCROLLING) _settleTime = 10;
//				else _settleTime
				dx = 0;
				dy = 0;
			}
		} else _settleTime--;
		
		
		
		
		/***		Dragging Calculations			***/
		if(_event == DRAGGING);
		else if(_prefClicking && _prefDragging && _tapped && _streamdt < _prefClickDelay && _event == MOVEMENT) {
			_event = DRAGGING;
			_tapped = false;
			_dragging = false;
			if(_prefDragLock) _dragLocked = true;
			//IOLog("Dragging mode\n");
			_dragTimeout->cancelTimeout();	// Cancel the timeout, the _tapped = false also does this
			//	if(_prefDragLock) _dragLocked = true;
		}
	}	

	//if(prevEvent 

	
	// Lets send the button / movement / scrolling events
	switch(_event) {
		case HORIZONTAL_SCROLLING:
			dispatchScrollWheelEvent(0,  -1 * dx, 0, now);
			//dispatchRelativePointerEvent(0, 0, buttons, now);
			break;
		case VERTICAL_SCROLLING:
			dispatchScrollWheelEvent(dy, 0,		  0, now);
			//dispatchRelativePointerEvent(0, 0, buttons, now);
			break;
		case SCROLLING:
			if(_prefHorizScroll == false) dx = 0;
			else {
				// TODO: fix this
				if(ABS(dy) << 2 > ABS(dx)) dx = 0;		// dx has been  << 2, sox dy << 2 gives ut the origional.,  << 1 gives us >> 1
				else if(ABS(dx) >> 2 > ABS(dy)) dy = 0;		// dx has been << 2, so >> 3 gives us  >> 1
				//if(ABS(dy) << 1 > ABS(dx)) dx = 0;		// dx has been  << 2, sox dy << 2 gives ut the origional.,  << 1 gives up >> 1
				//else if(ABS(dx) << 1 > ABS(dy)) dy = 0;		// dx has been << 2, so >> 3 gives us  >> 1
			}
			
			dispatchScrollWheelEvent(dy, -1 * dx, 0, now);
			//dispatchRelativePointerEvent(0, 0, buttons, now);
			break;
			
		case DRAGGING:
			if(buttons) {
				//_dragLocked = false;
				_event = MOVEMENT;
				_tapped = false;
				_dragging = false;
				_dragLocked = false;
				buttons = 0;
			}
			else buttons = 0x01; //_dragLocked | _tapped;
			
		case MOVEMENT:
			buttons |= _dragging;
			dy *= -1;	// PS2 spec has the direction backwards from what the os wants (lower left corner is the orign, verses upper left)
			dispatchRelativePointerEvent((SInt32) dx, (SInt32) dy, buttons, now);
			break;
		// No mevement, just send button presses
		case ZOOMING:
			// Calculate zoom amount
		case SWIPE:
		case DEFAULT_EVENT:
		default:
			buttons |= _dragging;
			dispatchRelativePointerEvent(0, 0, buttons, now);
			break;
	}
	
	//IOLog("Buttons: %d, Dragging: %d, Tapped: %d\n", buttons, _dragging, _tapped);
	
	_prevX = absX;
	_prevY = absY;
	_prevDX = dx;
	_prevDY = dy;
	_prevNumFingers = numFingers;
	_prevPacketSecond = second;
	_prevPacketTime = currentTime;
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

void ApplePS2SynapticsTouchPad::
	dispatchSwipeEvent ( IOHIDSwipeMask swipeType, AbsoluteTime now)
{
	switch(swipeType)
	{
		case kIOHIDSwipeUp:
		case kIOHIDSwipeDown:
			break;
		case kIOHIDSwipeLeft:
			// Key down
			IOLog("Swipe left\n");
			_keyboard->dispatchKeyboardEvent( 0x37, true, now);		// 0x37 = Command
			_keyboard->dispatchKeyboardEvent( 0x21, true, now);
			// Key up
			_keyboard->dispatchKeyboardEvent( 0x37, false, now);
			_keyboard->dispatchKeyboardEvent( 0x21, false, now);
			break;
		case kIOHIDSwipeRight:
			IOLog("Swipe right\n");
			// Key down
			_keyboard->dispatchKeyboardEvent( 0x37, true, now);		// 0x37 = Command
			_keyboard->dispatchKeyboardEvent( 0x1e, true, now);
			// Key up
			_keyboard->dispatchKeyboardEvent( 0x37, false, now);
			_keyboard->dispatchKeyboardEvent( 0x1e, false, now);
			
			break;
		default:
			break;
	}
	
	/**
	
	IOLog("Dispatching swipe event: %d\n", swipeType);
	IOHIDEvent* event = new IOHIDEvent;
	event->initWithTypeTimeStamp(kIOHIDEventTypeSwipe, now);
	
	((IOHIDSwipeEventData*) event->_data)->swipeMask = swipeType;
	
	
	IOHIDSystem::instance()->dispatchEvent(event, NULL);
	 
	 **/
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

void ApplePS2SynapticsTouchPad::
     dispatchRelativePointerEventWithRelativePacket( UInt8 * packet,
                                             UInt32  packetSize, AbsoluteTime now )
{
    //
    // Process the three byte relative format packet that was retreived from the
    // trackpad. The format of the bytes is as follows:
    //
    //  7  6  5  4  3  2  1  0
    // -----------------------
    // YO XO YS XS  1  M  R  L
    // X7 X6 X5 X4 X3 X3 X1 X0  (X delta)
    // Y7 Y6 Y5 Y4 Y3 Y2 Y1 Y0  (Y delta)
    //

    UInt32       buttons;
    SInt32       dx, dy;
	uint32_t	 currentTime, second;
	UInt8		 prevEvent;


	clock_get_uptime((uint64_t *)&now);
	clock_get_system_microtime(&second, &currentTime);
    
	// Swap buttons as requested by a user
#ifdef BUTTONS_SWAPED
	buttons = 0;
    if ( (packet[0] & 0x1) ) buttons |= 0x2;  // left button   (bit 0 in packet)
    if ( (packet[0] & 0x2) ) buttons |= 0x1;  // right button  (bit 1 in packet)	
	if ( (packet[0] & 0x4) ) buttons |= 0x4;  // middle button (bit 2 in packet)
#else 
	buttons = (packet[0] & 0x7);	// buttons =  last three bits of byte one of packet = middle, right, left
#endif

	
	// Emulate a middle button
	// TODO: add a short (a few ms pause) to each button press so that if they both are pressed within a timeframe, we get the middle button
	if ( (buttons & 0x3)  == 0x03)   {
		//buttons = 0x4;		// Middle button
		buttons = 0;	// This is for scrolling
		_event = MOVEMENT;
		_prevButtons = 0x4;
	} else if ((_prevButtons & 0x4) == 0x4) {
		// Wait for the button states to clean
		if(buttons == 0) {
			prevEvent = _event;
			_prevButtons = 0;
		}
		buttons = 0;

	} else {
		_prevButtons = buttons;
	}
	
	
    dx = ((packet[0] & 0x10) ? 0xffffff00 : 0 ) | packet[1];
    dy = -(((packet[0] & 0x20) ? 0xffffff00 : 0 ) | packet[2]);
    
    //IOLog("Displatching event with dx: %d \tdy: %d\n", dx, dy);
	switch(_event) {
		case SCROLLING:
			// Send scroll event
			// TOD: mke the scaler work over multiple packets(dont drop decmals)
			dispatchScrollWheelEvent(dy * -.2, dx * -.2, 0, now);
			break;
		case MOVEMENT:
		default:
			dispatchRelativePointerEvent(dx, dy, buttons, now);
			break;
	}
	_prevPacketSecond = second;
	_prevPacketTime = currentTime;

}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

void ApplePS2SynapticsTouchPad::setTouchPadEnable( bool enable )
{
    //
    // Instructs the trackpad to start or stop the reporting of data packets.
    // It is safe to issue this request from the interrupt/completion context.
    //

    PS2Request * request = _device->allocateRequest();
    if ( !request ) return;

    // (mouse enable/disable command)
    request->commands[0].command = kPS2C_SendMouseCommandAndCompareAck;
    request->commands[0].inOrOut = (enable)?kDP_Enable:kDP_SetDefaultsAndDisable;
    request->commandsCount = 1;
    _device->submitRequestAndBlock(request);
    _device->freeRequest(request);
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

UInt32 ApplePS2SynapticsTouchPad::getTouchPadData( UInt8 dataSelector )
{
    PS2Request * request     = _device->allocateRequest();
    UInt32       returnValue = (UInt32)(-1);

    if ( !request ) return returnValue;

    // Disable stream mode before the command sequence.
    request->commands[0].command  = kPS2C_SendMouseCommandAndCompareAck;
    request->commands[0].inOrOut  = kDP_SetDefaultsAndDisable;

    // 4 set resolution commands, each encode 2 data bits.
    request->commands[1].command  = kPS2C_SendMouseCommandAndCompareAck;
    request->commands[1].inOrOut  = kDP_SetMouseResolution;
    request->commands[2].command  = kPS2C_SendMouseCommandAndCompareAck;
    request->commands[2].inOrOut  = (dataSelector >> 6) & 0x3;

    request->commands[3].command  = kPS2C_SendMouseCommandAndCompareAck;
    request->commands[3].inOrOut  = kDP_SetMouseResolution;
    request->commands[4].command  = kPS2C_SendMouseCommandAndCompareAck;
    request->commands[4].inOrOut  = (dataSelector >> 4) & 0x3;

    request->commands[5].command  = kPS2C_SendMouseCommandAndCompareAck;
    request->commands[5].inOrOut  = kDP_SetMouseResolution;
    request->commands[6].command  = kPS2C_SendMouseCommandAndCompareAck;
    request->commands[6].inOrOut  = (dataSelector >> 2) & 0x3;

    request->commands[7].command  = kPS2C_SendMouseCommandAndCompareAck;
    request->commands[7].inOrOut  = kDP_SetMouseResolution;
    request->commands[8].command  = kPS2C_SendMouseCommandAndCompareAck;
    request->commands[8].inOrOut  = (dataSelector >> 0) & 0x3;

    // Read response bytes.
    request->commands[9].command  = kPS2C_SendMouseCommandAndCompareAck;
    request->commands[9].inOrOut  = kDP_GetMouseInformation;
    request->commands[10].command = kPS2C_ReadDataPort;
    request->commands[10].inOrOut = 0;
    request->commands[11].command = kPS2C_ReadDataPort;
    request->commands[11].inOrOut = 0;
    request->commands[12].command = kPS2C_ReadDataPort;
    request->commands[12].inOrOut = 0;

    request->commandsCount = 13;
    _device->submitRequestAndBlock(request);

    if (request->commandsCount == 13) // success?
    {
        returnValue = ((UInt32)request->commands[10].inOrOut << 16) |
                      ((UInt32)request->commands[11].inOrOut <<  8) |
                      ((UInt32)request->commands[12].inOrOut);
    }

    _device->freeRequest(request);

    return returnValue;
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

bool ApplePS2SynapticsTouchPad::setTouchPadModeByte( UInt8 modeByteValue,
                                                     bool  enableStreamMode )
{
    PS2Request * request = _device->allocateRequest();
    bool         success;

    if ( !request ) return false;

    // Disable stream mode before the command sequence. (This doesnt actualy dissable stream mode, according to teh specifications)
    request->commands[0].command  = kPS2C_SendMouseCommandAndCompareAck;
    request->commands[0].inOrOut  = kDP_SetDefaultsAndDisable;

    // 4 set resolution commands, each encode 2 data bits.
    request->commands[1].command  = kPS2C_SendMouseCommandAndCompareAck;
    request->commands[1].inOrOut  = kDP_SetMouseResolution;
    request->commands[2].command  = kPS2C_SendMouseCommandAndCompareAck;
    request->commands[2].inOrOut  = (modeByteValue >> 6) & 0x3;

    request->commands[3].command  = kPS2C_SendMouseCommandAndCompareAck;
    request->commands[3].inOrOut  = kDP_SetMouseResolution;
    request->commands[4].command  = kPS2C_SendMouseCommandAndCompareAck;
    request->commands[4].inOrOut  = (modeByteValue >> 4) & 0x3;

    request->commands[5].command  = kPS2C_SendMouseCommandAndCompareAck;
    request->commands[5].inOrOut  = kDP_SetMouseResolution;
    request->commands[6].command  = kPS2C_SendMouseCommandAndCompareAck;
    request->commands[6].inOrOut  = (modeByteValue >> 2) & 0x3;

    request->commands[7].command  = kPS2C_SendMouseCommandAndCompareAck;
    request->commands[7].inOrOut  = kDP_SetMouseResolution;
    request->commands[8].command  = kPS2C_SendMouseCommandAndCompareAck;
    request->commands[8].inOrOut  = (modeByteValue >> 0) & 0x3;

    // Set sample rate 20 to set mode byte 2. Older pads have 4 mode
    // bytes (0,1,2,3), but only mode byte 2 remain in modern pads.
    request->commands[9].command  = kPS2C_SendMouseCommandAndCompareAck;
    request->commands[9].inOrOut  = kDP_SetMouseSampleRate;
    request->commands[10].command = kPS2C_SendMouseCommandAndCompareAck;
    request->commands[10].inOrOut = 20;

    request->commands[11].command  = kPS2C_SendMouseCommandAndCompareAck;
    request->commands[11].inOrOut  = enableStreamMode ?
                                     kDP_Enable :
                                     kDP_SetMouseScaling1To1; /* Nop */

    request->commandsCount = 12;
    _device->submitRequestAndBlock(request);

    success = (request->commandsCount == 12);

    _device->freeRequest(request);
    
    return success;
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

void ApplePS2SynapticsTouchPad::setCommandByte( UInt8 setBits, UInt8 clearBits )
{
    //
    // Sets the bits setBits and clears the bits clearBits "atomically" in the
    // controller's Command Byte.   Since the controller does not provide such
    // a read-modify-write primitive, we resort to a test-and-set try loop.
    //
    // Do NOT issue this request from the interrupt/completion context.
    //

    UInt8        commandByte;
    UInt8        commandByteNew;
    PS2Request * request = _device->allocateRequest();

    if ( !request ) return;

    do
    {
        // (read command byte)
        request->commands[0].command = kPS2C_WriteCommandPort;
        request->commands[0].inOrOut = kCP_GetCommandByte;
        request->commands[1].command = kPS2C_ReadDataPort;
        request->commands[1].inOrOut = 0;
        request->commandsCount = 2;
        _device->submitRequestAndBlock(request);

        //
        // Modify the command byte as requested by caller.
        //

        commandByte    = request->commands[1].inOrOut;
        commandByteNew = (commandByte | setBits) & (~clearBits);

        // ("test-and-set" command byte)
        request->commands[0].command = kPS2C_WriteCommandPort;
        request->commands[0].inOrOut = kCP_GetCommandByte;
        request->commands[1].command = kPS2C_ReadDataPortAndCompare;
        request->commands[1].inOrOut = commandByte;
        request->commands[2].command = kPS2C_WriteCommandPort;
        request->commands[2].inOrOut = kCP_SetCommandByte;
        request->commands[3].command = kPS2C_WriteDataPort;
        request->commands[3].inOrOut = commandByteNew;
        request->commandsCount = 4;
        _device->submitRequestAndBlock(request);

        //
        // Repeat this loop if last command failed, that is, if the
        // old command byte was modified since we first read it.
        //

    } while (request->commandsCount != 4);  

    _device->freeRequest(request);
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// This method is used by the prefrences pane to communicate with the driver (currently only supports clicking) called when IORegistryEntrySetCFProperties
IOReturn ApplePS2SynapticsTouchPad::setParamProperties( OSDictionary * dict )
{
	// Scrolling stuff
	if(OSDynamicCast(OSNumber,  dict->getObject(kTPScrollMode)))			_prefScrollMode		= ((OSNumber * )OSDynamicCast(OSNumber, dict->getObject(kTPScrollMode)))->unsigned8BitValue();
	if(OSDynamicCast(OSBoolean, dict->getObject(kTPHorizScroll)))			_prefHorizScroll	= ((OSBoolean * )OSDynamicCast(OSBoolean, dict->getObject(kTPHorizScroll)))->getValue();
	if(OSDynamicCast(OSNumber, dict->getObject(kTPScrollArea)))				_prefScrollArea		= (.006 *		((OSNumber * )OSDynamicCast(OSNumber, dict->getObject(kTPScrollArea)))->unsigned32BitValue());

	// Gestures
	if(OSDynamicCast(OSNumber,  dict->getObject(kTPGestureMode)))			_prefGestureMode		= ((OSNumber * )OSDynamicCast(OSNumber, dict->getObject(kTPGestureMode)))->unsigned8BitValue();

	
	// Clicking stuff
	if(OSDynamicCast(OSBoolean, dict->getObject(kTPTapToClick)))			_prefClicking		= ((OSBoolean * )OSDynamicCast(OSBoolean, dict->getObject(kTPTapToClick)))->getValue();
	if(OSDynamicCast(OSBoolean, dict->getObject(kTPDraggin)))				_prefDragging		= ((OSBoolean * )OSDynamicCast(OSBoolean, dict->getObject(kTPDraggin)))->getValue();
	if(OSDynamicCast(OSBoolean, dict->getObject(kTPDragLock)))				_prefDragLock		= ((OSBoolean * )OSDynamicCast(OSBoolean, dict->getObject(kTPDragLock)))->getValue();
	if(OSDynamicCast(OSBoolean, dict->getObject(kTPSecondaryClick)))		_prefSecondaryClick		= ((OSBoolean * )OSDynamicCast(OSBoolean, dict->getObject(kTPSecondaryClick)))->getValue();
	if(OSDynamicCast(OSBoolean, dict->getObject(kTPSwapButtons)))			_prefSwapButtons		= ((OSBoolean * )OSDynamicCast(OSBoolean, dict->getObject(kTPSwapButtons)))->getValue();

	
	// Sensitivity stuff
	if(OSDynamicCast(OSNumber, dict->getObject(kTPOneFingerThreshold)))		_prefOneFingerThreshold		= Z_LIGHT_FINGER + (2 * ( 10 - ((OSNumber * )OSDynamicCast(OSNumber, dict->getObject(kTPOneFingerThreshold)))->unsigned32BitValue()));
	if(OSDynamicCast(OSNumber, dict->getObject(kTPTwoFingerThreshold)))		_prefTwoFingerThreshold		= (215 + 20 *	(10 - ((OSNumber * )OSDynamicCast(OSNumber, dict->getObject(kTPTwoFingerThreshold)))->unsigned32BitValue()));
	if(OSDynamicCast(OSNumber, dict->getObject(kTPThreeFingerThreshold)))	_prefThreeFingerThreshold	= (650 + 20 *	(10 - ((OSNumber * )OSDynamicCast(OSNumber, dict->getObject(kTPThreeFingerThreshold)))->unsigned32BitValue()));
	
	// Speed stuff
	if(OSDynamicCast(OSNumber, dict->getObject(kTPScrollSpeed)))			_prefScrollSpeed	= .9 + (.2 *	((OSNumber * )OSDynamicCast(OSNumber, dict->getObject(kTPScrollSpeed)))->unsigned32BitValue());
	if(OSDynamicCast(OSNumber, dict->getObject(kTPTrackSpeed)))				_prefTrackSpeed		= .4 + (.2 *			((OSNumber * )OSDynamicCast(OSNumber, dict->getObject(kTPTrackSpeed)))->unsigned32BitValue());
	
	// Delays when dragging
	if(OSDynamicCast(OSNumber, dict->getObject(kTPClickDelay)))				_prefClickDelay		= ((OSNumber * )OSDynamicCast(OSNumber, dict->getObject(kTPClickDelay)))->unsigned32BitValue();
	if(OSDynamicCast(OSNumber, dict->getObject(kTPReleaseDelay)))			_prefReleaseDelay		= ((OSNumber * )OSDynamicCast(OSNumber, dict->getObject(kTPReleaseDelay)))->unsigned32BitValue();


	// If the various prefClicking values have changes, things might be weird, so we reset these values just in case.
	_dragLocked = false;
	_dragging = false;
	_tapped = false;


    return super::setParamProperties(dict);
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

void ApplePS2SynapticsTouchPad::setDevicePowerState( UInt32 whatToDo )
{
    switch ( whatToDo )
    {
        case kPS2C_DisableDevice:
            setTouchPadEnable( false );
            break;

        case kPS2C_EnableDevice:
			//
            // Must not issue any commands before the device has
            // completed its power-on self-test and calibration.
            //
            IOSleep(1000);
            setTouchPadModeByte( _touchPadModeByte );
            //
            // Enable the mouse clock (should already be so) and the
            // mouse IRQ line.
            //
            setCommandByte( kCB_EnableMouseIRQ, kCB_DisableMouseClock );

            //
            // Clear packet buffer and various values to avoid issues caused by
            // stale values.
            //

            _packetByteCount = 0;
			_streamdx = 0;
			_streamdy = 0;
			_settleTime = 0;
			_tapped = false;
			_dragLocked = false;

            //
            // Finally, we enable the trackpad itself, so that it may
            // start reporting asynchronous events.
            //

            setTouchPadEnable( true );
            break;
    }
}

//-----------------------------------------------------------------------------//
bool   ApplePS2SynapticsTouchPad::setRelativeMode() {
	if((_touchPadModeByte & ABSOLUTE_MODE_BIT) != 0) { // if the bit is changed
		_touchPadModeByte &= ~(ABSOLUTE_MODE_BIT);
		setTouchPadModeByte(_touchPadModeByte, true);
	}
	return true;
}

// this is not needed (just use the setModeByte command)
bool   ApplePS2SynapticsTouchPad::setAbsoluteMode() {
	if((_touchPadModeByte & ABSOLUTE_MODE_BIT) == 0) {	// If the bit is changed
		_touchPadModeByte |= ABSOLUTE_MODE_BIT;
		setTouchPadModeByte(_touchPadModeByte, true);
	}
	return true;
}

bool   ApplePS2SynapticsTouchPad::setStreamMode( bool enable ) {
	PS2Request * request = _device->allocateRequest();
    bool         success;
	
    if ( !request ) return false;
	
    // Enable steaming mode
    request->commands[0].command  = kPS2C_SendMouseCommandAndCompareAck;
    request->commands[0].inOrOut  = kDP_SetMouseStreamMode;
	// We really should data mode as well
	
	request->commandsCount = 1;
    _device->submitRequestAndBlock(request);
	
	success = (request->commandsCount == 1);
	_device->freeRequest(request);
 	
	return success;
}

bool ApplePS2SynapticsTouchPad::getModelID()
{
	_modelId = getTouchPadData(kST_getModelID);
	if(_modelId != 0) return true;
	return false;
}

bool ApplePS2SynapticsTouchPad::getCapabilities()
{
	bool success = false;
	UInt32 capabilities;
	capabilities = getTouchPadData(kST_getCapabilities);
	if((capabilities & 0x00FF00 == 0x004700)) success = true;	
	
	
	_capabilties = ((capabilities & 0xFF0000) >> 8) | (capabilities & 0x0000FF);

	
	return success;
}

bool ApplePS2SynapticsTouchPad::getExtendedCapabilities()
{
	bool success = false;
	
	if(CAP_N_EXTENDED_QUERY)
	{
		_extendedCapabilitied = getTouchPadData(kST_getExtendedModelID);
		success = true;
	} 
	else
	{
		_extendedCapabilitied = 0;
		success = false;
	}
	
	
	return success;
}


bool   ApplePS2SynapticsTouchPad::identifyTouchpad() {
	_touchpadIntormation = getTouchPadData(kST_IdentifyTouchpad);
	
	/*_touchpadIntormation = request->commands[10].inOrOut | (request->commands[11].inOrOut << 8) | (request->commands[12].inOrOut << 16);
	
    if ( request->commandsCount == 14 &&
		request->commands[11].inOrOut == 0x47 )
    {
        _touchPadVersion = (request->commands[12].inOrOut & 0x0f) << 8
		|  request->commands[10].inOrOut;
	*/
	return true;
}

bool   ApplePS2SynapticsTouchPad::getTouchpadModes() {
	return false;
}
bool   ApplePS2SynapticsTouchPad::getSerialNumber() {
	UInt32 prefix = 0;
	UInt32 serialNumber = 0;
	prefix =getTouchPadData(kST_getSerialNumberPrefix);
	serialNumber = getTouchPadData(kST_getSerialNumberSuffix);
	
	_serialNumber = (serialNumber | ((prefix & 0xFFF) << 24));
	
	setProperty("Serial Number", _serialNumber, sizeof(_serialNumber));
	return true;
}
bool   ApplePS2SynapticsTouchPad::getResolutions() {
	return false;
}

bool   ApplePS2SynapticsTouchPad::draggingTimeout() {
	AbsoluteTime now;
	//if(_tapped) {
	_dragLocked = false;		// Should NEVER be true when we enter here
	_tapped = false;
	_dragging = false;
	_event = MOVEMENT;
	
	_dragTimeout->cancelTimeout();
	clock_get_uptime((uint64_t *)&now);
	dispatchRelativePointerEvent(0, 0, 0x01, now);	// Now we send the tap event, since the second tap timed out.
	dispatchRelativePointerEvent(0, 0, 0x00, now);	// Now we send the tap event, since the second tap timed out.
	
	//}

	return true;
}