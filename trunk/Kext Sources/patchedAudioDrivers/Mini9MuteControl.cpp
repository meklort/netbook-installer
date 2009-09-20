/*
 *  Mini9MuteControl.cpp
 *  patchedAppleHDA
 *
 *  Created by Evan Lojewski on 8/9/09.
 *  Copyright 2009 __MyCompanyName__. All rights reserved.
 *
 */
#include <IOKit/IOLib.h>
#include <IOKit/audio/IOAudioToggleControl.h>
#include <IOKit/audio/IOAudioDefines.h>
#include <IOKit/IOTimerEventSource.h>

#include "Mini9MuteControl.h"
#include "Verbs.h"
#include "Widgets.h"

#define super IOAudioToggleControl

OSDefineMetaClassAndStructors(Mini9MuteControl, IOAudioToggleControl);

IOReturn Mini9MuteControl::performValueChange(OSObject *newValue) {
	//IOLog("Mini9MuteControl: performValueChange\n");
	OSNumber *v = OSDynamicCast(OSNumber, newValue);
	if (v == NULL) {
		IOLog("Mini9MuteControl: cast failure\n");
		return kIOReturnError;
	}
	setMute((v->unsigned32BitValue() != 0));
	return kIOReturnSuccess;
}
Mini9MuteControl* Mini9MuteControl::create() {
	Mini9MuteControl *control = new Mini9MuteControl;
	control->init();
	return control;
}
bool Mini9MuteControl::init() {
	_output = NULL;
	_mute = true;
	_ioreg = NULL;

	if (! super::init(_mute, kIOAudioControlChannelIDAll, kIOAudioControlChannelNameAll, 0,
									 kIOAudioToggleControlSubTypeMute, kIOAudioControlUsageOutput)) {
		IOLog("Mini9MuteControl: init: failed\n");

		return false;
	}
	//IOLog("Mini9MuteControl: init: success\n");

	return true;
}

void Mini9MuteControl::startUpdate() {
	mach_timespec_t		timeOut;
	
	timeOut.tv_sec = 0;
	timeOut.tv_nsec = 1000;
	

	IORegistryEntry *hdaDeviceEntry = IORegistryEntry::fromPath("IOService:/AppleACPIPlatformExpert/PCI0@0/AppleACPIPCI/HDEF");
	if (hdaDeviceEntry != NULL) {
		//IOLog("Mini9MuteControl: Found HDEF in IORegistery\n");
		IOService *service = OSDynamicCast(IOService, hdaDeviceEntry);
		if (service != NULL && service->getDeviceMemoryCount() != 0) {
			_ioreg = service->getDeviceMemoryWithIndex(0);
			
		} else
		{
			IOLog("Mini9MuteControl: Unabel to find service in IORegistery\n");

		}
		hdaDeviceEntry->release();
		setOutput(WIDGET_LINE_OUT);		// Default to line out
		setMute(_mute);	// Could call setPorperty() too
		
		
			// set polling timeout
		_pollTimeout = IOTimerEventSource::timerEventSource( this,
															OSMemberFunctionCast( IOTimerEventSource::Action,
																				 this, &Mini9MuteControl::outputPoller) );
		
		getWorkLoop()->addEventSource(_pollTimeout);
		
		_pollTimeout->setTimeoutMS(POLL_TIMEOUT);

	} else
	{
		//IOLog("Mini9MuteControl: startUpdate\n");

	}
}

UInt32 Mini9MuteControl::runVerb(UInt8 codec, UInt8 node, UInt16 verb, UInt16 payload)
{
	if (_ioreg == NULL) {
		return 0;
	}
	
	UInt32 returnVal;
	UInt32 status;
	UInt32 cmd;
	int i;
	
	if(verb & 0xFF0)
	{
		// 16 bit verb
		cmd = VERB_16BIT(codec, node, verb, payload);
	}
	else
	{
		cmd = VERB_4BIT(codec, node, verb, payload);

	}
	
	status = 1;
	_ioreg->writeBytes(0x60, &cmd, sizeof(cmd));
	_ioreg->writeBytes(0x68, &status, sizeof(status));

	for (i = 0; i < 1000; i++) {
		::IODelay(100);
		_ioreg->readBytes(0x68, &status, sizeof(status));
		if (status & 0x02) {
			_ioreg->readBytes(0x64, &cmd, sizeof(status));
			i = 2000;
		}
	}
	
	if (i > 1500) {
		returnVal = cmd;
	}
	else {
		IOLog("Mini9MuteControl: runVerb timed out.\n");

	}
	

	// Clear status
	status = 0x2;
	_ioreg->writeBytes(0x68, &status, sizeof(status));

	return returnVal;

	

}

bool Mini9MuteControl::corbEnabled()
{
	UInt8 returnVal;
	if(_ioreg == NULL)
	{
		return true;
	}
	
	_ioreg->readBytes(0x4C, &returnVal, sizeof(returnVal));
	if(returnVal) return true;
	else return false;

}

void Mini9MuteControl::setCorb(bool state)
{	
	UInt8 returnVal = state;
	int i;
	if(_ioreg == NULL)
	{
		return;
	}
	
	_ioreg->writeBytes(0x4C, &returnVal, sizeof(returnVal));
	
	for (i = 0; i < 1000; i++) {
		::IODelay(100);
		_ioreg->readBytes(0x4C, &returnVal, sizeof(returnVal));
		if (returnVal == state) {
			return;
		}
	}
	
	IOLog("Mini9MuteControl: request to change CORB status timed out.\n");
	return;
}


void Mini9MuteControl::setOutput(UInt8 output)
{
		// NOTE: this isn't teh correct class for this... should be in PatchedAppleAzaliaAudio... (aka, FIXME in future version)
	bool corbStat = corbEnabled();
	setCorb(false);

	
	_output = output;
	
	
	switch(output)
	{
		case WIDGET_HEAPHONES:
			IOLog("Mini9MuteControl: Switching to headphones\n");

			runVerb(0, WIDGET_HEAPHONES, 0x3B0, 0x64);		// unmute line out		// TODO: try 0x20
			runVerb(0, WIDGET_HEAPHONES, HDA_SET_EAPD, 0x02);	// Set headphones to enabled
			runVerb(0, WIDGET_HEAPHONES, HDA_PIN_CTRL, 0xC0);	// Set headphones to enabled (Was 0xc0)
			
			runVerb(0, WIDGET_LINE_OUT, 0x3B0, 0x80);			// mute line out
			break;
		case WIDGET_LINE_OUT:
			IOLog("Mini9MuteControl: Switching to speakers\n");
			runVerb(0, 0x23, 0x701, 0x05);	//	Set mux to speakers


			runVerb(0, WIDGET_LINE_OUT, 0x3B0, 0x00);		// unmute line out
			runVerb(0, WIDGET_LINE_OUT, HDA_SET_EAPD, 0x02);	// Set line in to enabled
			runVerb(0, WIDGET_LINE_OUT, HDA_PIN_CTRL, 0xC0);	// Set headphones to enabled

			
			runVerb(0, WIDGET_HEAPHONES, 0x3B0, 0x80);	// mute headponesß
			break;
			
		default:
			IOLog("Mini9MuteControl: Unknown output selected. Ignoring.\n");
			break;

	}
	
	setCorb(corbStat);

	return;
}

void Mini9MuteControl::setMute(bool mute)
{
		// TODO: dissable RIRB too
	bool corbStat = corbEnabled();
	setCorb(false);


	_mute = mute;
	
	switch(_output)
	{
		case WIDGET_HEAPHONES:
				//runVerb(0, _output, HDA_PIN_CTRL, (_mute ? 0x0 : 0x80));
			runVerb(0, _output, 0x3B0, (_mute ? 0x80 : 0x00));		// unmute line out
																	//runVerb(0, _output, 0x70c, (_mute ? 0x00 : 0x02));		// unmute line out

			break;
		case WIDGET_LINE_OUT:
				//runVerb(0, _output, HDA_PIN_CTRL, (_mute ? 0x0 : 0x40));
			runVerb(0, _output, 0x3B0, (_mute ? 0x80 : 0x00));		// unmute line out
																	//runVerb(0, _output, 0x70c, (_mute ? 0x00 : 0x02));		// unmute line out


			break;
			
		default:
			break;
			
	}
	
	setCorb(corbStat);
	return;
}

UInt8 Mini9MuteControl::determineOutput()
{
	bool corbStat = corbEnabled();
	setCorb(false);

	UInt8 returnVal;
	if(runVerb(0, WIDGET_HEAPHONES, HDA_GET_PINSENCE, 0x00))
	{
		returnVal = WIDGET_HEAPHONES;
	}
	else
	{
		returnVal = WIDGET_LINE_OUT;
	}
	
	setCorb(corbStat);

	return returnVal;


}


void Mini9MuteControl::outputPoller()
{
	UInt8 currentOutput = determineOutput();
	
	if(_output ^ currentOutput)
	{
		setOutput(currentOutput);
	}

	_pollTimeout->cancelTimeout();
	_pollTimeout->setTimeoutMS(POLL_TIMEOUT);

	
}

void Mini9MuteControl::updateMuteControl()
{
	setMute(_mute);
		//outputPoller();
}
