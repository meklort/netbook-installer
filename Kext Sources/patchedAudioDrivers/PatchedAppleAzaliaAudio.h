/*
 *  PatchedAppleAzaliaAudio.h
 *  patchedAppleHDA
 *
 *  Created by Evan Lojewski on 8/11/09.
 *  Copyright 2009 __MyCompanyName__. All rights reserved.
 *
 */
#import "AppleAzaliaAudioDriver.h"
#import "Mini9MuteControl.h"

class PatchedAppleAzaliaAudioDriver : public AppleAzaliaAudioDriver
	{
		OSDeclareDefaultStructors(PatchedAppleAzaliaAudioDriver);
		
	public:
		
		virtual PatchedAppleAzaliaAudioDriver* probe (IOService *provider, SInt32 *score); 
		virtual IOReturn activateAudioEngine(IOAudioEngine *audioEngine, bool shouldStartAudioEngine);
};