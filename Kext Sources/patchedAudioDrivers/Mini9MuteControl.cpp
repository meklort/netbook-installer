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
#include "Mini9MuteControl.h"

#define super IOAudioToggleControl

OSDefineMetaClassAndStructors(Mini9MuteControl, IOAudioToggleControl);

IOReturn Mini9MuteControl::performValueChange(OSObject *newValue) {
	//IOLog("Mini9MuteControl: performValueChange\n");
	OSNumber *v = OSDynamicCast(OSNumber, newValue);
	if (v == NULL) {
		IOLog("Mini9MuteControl: cast failure\n");
		return kIOReturnError;
	}
	mute_ = (v->unsigned32BitValue() != 0);
	updateMuteControl();
	return kIOReturnSuccess;
}
Mini9MuteControl* Mini9MuteControl::create() {
	Mini9MuteControl *control = new Mini9MuteControl;
	control->init();
	return control;
}
bool Mini9MuteControl::init() {
	mute_ = true;
	if (! super::init(mute_, kIOAudioControlChannelIDAll, kIOAudioControlChannelNameAll, 0,
									 kIOAudioToggleControlSubTypeMute, kIOAudioControlUsageOutput)) {
		IOLog("Mini9MuteControl: init: failed\n");

		return false;
	}
	//IOLog("Mini9MuteControl: init: success\n");

	ioreg_ = NULL;
	return true;
}

void Mini9MuteControl::startUpdate() {
	mach_timespec_t		timeOut;
	
	timeOut.tv_sec = 0;
	timeOut.tv_nsec = 1000;
	
/*	IOService* patchedAppleHDA = IOService::waitForService(IOService::serviceMatching ("PatchedAppleHDADriver"), &timeOut);
	if(!patchedAppleHDA) patchedAppleHDA = IOService::waitForService(IOService::serviceMatching ("PatchedAppleAzaliaAudioDriver"), &timeOut);

			
	if(patchedAppleHDA)
	{
		//									CodecGeneric->CondecFunc   ->CodecDriver  ->CodecDevice  ->Controller   ->HDEF device
		patchedAppleHDA = patchedAppleHDA->getProvider()->getProvider()->getProvider()->getProvider()->getProvider()->getProvider();
		IOLog("Mini9MuteControl: Drevice driver found, mem count = %d", patchedAppleHDA->getDeviceMemoryCount());
	} else
	{
		IOLog("Mini9MuteControl: Unable to find patched driver", patchedAppleHDA->getDeviceMemoryCount());
	}
*/
	IORegistryEntry *hdaDeviceEntry = IORegistryEntry::fromPath("IOService:/AppleACPIPlatformExpert/PCI0@0/AppleACPIPCI/HDEF");
	if (hdaDeviceEntry != NULL) {
		//IOLog("Mini9MuteControl: Found HDEF in IORegistery\n");
		IOService *service = OSDynamicCast(IOService, hdaDeviceEntry);
		if (service != NULL && service->getDeviceMemoryCount() != 0) {
			ioreg_ = service->getDeviceMemoryWithIndex(0);
			
		} else
		{
			IOLog("Mini9MuteControl: Unabel to find service in IORegistery\n");

		}
		hdaDeviceEntry->release();
		updateMuteControl();	// Could call setPorperty() too

	} else
	{
		//IOLog("Mini9MuteControl: startUpdate\n");

	}
}
void Mini9MuteControl::updateMuteControl() {
	//return;
	if (ioreg_ == NULL) {
		return;
	}
	IOLog("Mini9MuteControl: %s\n", mute_ ? "Muting" : "Unmuting");
	// write the command
	UInt32 cmd = 0x01470c00 | (mute_ ? 0x0 : 0x2);
	ioreg_->writeBytes(0x60, &cmd, sizeof(cmd));
	UInt16 status = 1;
	ioreg_->writeBytes(0x68, &status, sizeof(status));
	// wait for response
	for (int i = 0; i < 1000; i++) {
		::IODelay(100);
		ioreg_->readBytes(0x68, &status, sizeof(status));
		if (status & 0x2) {
			goto Success;
		}
	}
	// timeout
	IOLog("Mini9MuteControl: request to change EAPD status timed out.\n");
Success:
	// clear Immediate Result Valid flag
	status = 0x2;
	ioreg_->writeBytes(0x68, &status, sizeof(status));
//	IOLog("Mini9MuteControl: done\n");
}

