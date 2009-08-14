/*
 *  PatchedAppleAzaliaAudio.cpp
 *  PatchedAppleAzaliaAudioDriver
 *
 *  Created by Evan Lojewski on 8/11/09.
 *  Copyright 2009 __MyCompanyName__. All rights reserved.
 *
 */
#include <IOKit/pci/IOPCIDevice.h>
#include <IOKit/IOService.h>
#include <IOKit/IOLib.h>
#include <IOKit/IOCommandGate.h>
#include <IOKit/audio/IOAudioDevice.h>

#include "PatchedAppleAzaliaAudio.h"
#include "Mini9MuteControl.h"


// =============================================================================
// pacthedAppleHDA Class Implementation
//
#define self  PatchedAppleAzaliaAudioDriver
#define super AppleAzaliaAudioDriver

OSDefineMetaClassAndStructors(PatchedAppleAzaliaAudioDriver, AppleAzaliaAudioDriver);


PatchedAppleAzaliaAudioDriver* PatchedAppleAzaliaAudioDriver::probe (IOService *provider, SInt32 
													 *score) 
{ 
	// Ensure that we are loaded instead of AppleAzaliaAudio.
	super::probe(provider, score);
	*score = *score + 100;
	return this;
} 


IOReturn PatchedAppleAzaliaAudioDriver::activateAudioEngine(IOAudioEngine *audioEngine, bool shouldStartAudioEngine)
{
	// AppleAzaiaAudio doesnt actualy override this class, we are overriding the IOAudioDevice method
	IOReturn retVal;
	char* className;
	
	if (audioEngine == NULL) {
        return kIOReturnBadArgument;
    }
	
	className = (char*) audioEngine->getMetaClass()->getClassName();
	className = className + strlen(className) - strlen("Output");
	
	if(strcmp(className, "Output") == 0)	// There's probably a better way (such as asking the engine if it's output...)
	{
		IOLog("PatchedAppleHDADriver::activateAudioEngine - creating mute control\n");
		Mini9MuteControl* muteControl = Mini9MuteControl::create();
		audioEngine->addDefaultAudioControl( muteControl );
		 
		retVal = super::activateAudioEngine(audioEngine, shouldStartAudioEngine);
		 
		muteControl->startUpdate();	// Unmute the speakers
		
		muteControl->release();
	}
	else
	{
		retVal = super::activateAudioEngine(audioEngine, shouldStartAudioEngine);
	}
	
	return retVal;
	
}