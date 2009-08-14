/*
 *  Mini9MuteControl.h
 *  patchedAppleHDA
 *
 *  Created by Evan Lojewski on 8/9/09.
 *  Copyright 2009 __MyCompanyName__. All rights reserved.
 *
 */
#include <IOKit/audio/IOAudioToggleControl.h>

enum {
	kMCSleepState = 0,
	KMCActiveState,
	KMCTotalState
};

class Mini9MuteControl : public IOAudioToggleControl
{
	OSDeclareDefaultStructors(Mini9MuteControl);

	IOMemoryDescriptor *ioreg_;
	bool mute_;
	
public:
	virtual IOReturn performValueChange(OSObject *newValue);
	static Mini9MuteControl *create();
	virtual bool init();
	virtual void startUpdate();
	void updateMuteControl();
	
};
