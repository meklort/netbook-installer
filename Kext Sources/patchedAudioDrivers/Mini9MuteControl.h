/*
 *  Mini9MuteControl.h
 *  patchedAppleHDA
 *
 *  Created by Evan Lojewski on 8/9/09.
 *  Copyright 2009 __MyCompanyName__. All rights reserved.
 *
 */
#include <IOKit/audio/IOAudioToggleControl.h>


#define POLL_TIMEOUT	1500

class Mini9MuteControl : public IOAudioToggleControl
{
	OSDeclareDefaultStructors(Mini9MuteControl);

	IOMemoryDescriptor*			_ioreg;
	bool						_mute;
	UInt8						_output;
	IOTimerEventSource*			_pollTimeout;
	
public:
	virtual UInt32		runVerb(UInt8 codec, UInt8 node, UInt16 verb, UInt16 payload);
	virtual IOReturn	performValueChange(OSObject *newValue);
	static Mini9MuteControl *create();
	virtual bool init();
	virtual void startUpdate();
	void updateMuteControl();
	bool corbEnabled();
	void setCorb(bool state);
	void setOutput(UInt8 output);
	void setMute(bool mute);
	UInt8 determineOutput();
	void outputPoller();


	
};
