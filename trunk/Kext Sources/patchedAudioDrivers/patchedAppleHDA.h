/*
 * Copyright (c) 1998-2000 Apple Computer, Inc. All rights reserved.
 *
 * @@APPLE_LICENSE_HEADER_START@@
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
 * @@APPLE_LICENSE_HEADER_END@@
 */

#include <IOKit/audio/IOAudioDevice.h>
//#include "AppleHDADriver.h"

enum {
	kNVRAMTypeNone = 0,
	kNVRAMTypeIOMem,
	kNVRAMTypePort,
	
	kNVRAMImageSize = 0x2000
};

class AppleHDAEngine {
};


class AppleHDADriver : public IOAudioDevice
	{
		OSDeclareDefaultStructors(AppleHDADriver);
		
	public:

		virtual bool init(OSDictionary *properties);
		virtual void free();
		virtual bool start(IOService *provider);
		virtual void stop(IOService *provider);
		virtual bool willTerminate(IOService *provider, IOOptionBits options);
		virtual bool initHardware(IOService *provider);
		
		virtual IOReturn    message( UInt32      type,
									IOService * provider,
									void *      arg );
				
		
		virtual IOReturn performPowerStateChange(IOAudioDevicePowerState oldPowerState,
												 IOAudioDevicePowerState newPowerState,
												 UInt32 *microsecondsUntilComplete);

		
		virtual void audioEngineStarting();
		virtual void audioEngineStopped();
		virtual IOReturn activateAudioEngine(IOAudioEngine *audioEngine, bool shouldStartAudioEngine);
		virtual	bool createAudioEngine (OSArray * streamInterfaceNumberArray);

		// This is jsut a placeholde, TODO: fixme
		char* pathMapString ;
		char* spdifInString ;
		char* kextNameString ;
		char* layoutIDString ;
		char* muteGpioString ;
		char* pathMapsString ;
		int VAGRampString ;
		int codecIDString ;
		int layoutsString ;
		int lineOutString ;
		int lineInString ;
		int nodeIDString ;
		int spdifOutString ;
		int headphoneString ;
		int mClassDebugMask ;
		int pathMapIDString ;
		int deviceNameString ;
		int microphoneString ;
		int pathMapRefString;
		int ampPreDelayString ;
		int cpuSpecificString ;
		int mikeyDriverString ;
		int ampPostDelayString ;
		int powerProfileString ;
		int extMicrophoneString ;
		int CODEC_SpecificString ;
		int extMicrophone2String ;
		int lineInProviderString ;
		int platformDriverString ;
		int deviceShortNameString ;
		int forceWakeToIdleString ;
		int internalSpeakerString ;
		int afgLowPowerStateString ;
		int layoutIDPropertyString ;
		int manufacturerNameString ;
		int modelNameToMatchString ;
		int ioAudioPowerStateString ;
		int CommonPeripheralDSPString ;
		int mikeyAfgLowPowerStateString ;
		int powerProfile_builtInAudioString ;
		int powerProfile_powerIdentityString ;
		int powerProfile_idlePowerLevelString ;
		int powerProfile_currentPowerLevelString ;
		int powerProfile_maximumPowerLimitString;		
		
		
		// TODO: Verify paramiter list for the __String() functions
		
		
		virtual void getUCState(UInt32, UInt32, UInt32, UInt32, UInt32, void*);
		virtual void setUCState(UInt32, UInt32, UInt32, UInt32, UInt32, void*);
		virtual void validatePath(OSArray* paths);
		virtual void validatePathGroup(OSArray* group);

		virtual IOReturn newUserClient(task* , void* ,UInt32, IOUserClient**);
		virtual void getUCDiagState(UInt32, UInt32, UInt32, UInt32, void*);
		virtual void setUCDiagState(UInt32, UInt32, UInt32, UInt32, void*);
		virtual void idlePowerLevel();
		virtual void runPeriodicTasks(OSObject* task, void* arg0 = 0, void* arg1 = 0, void* arg2 = 0, void* arg3 = 0);
		virtual void currentPowerLevel();
		virtual void maximumPowerLimit();
		virtual void powerChangeAction(OSObject* action, void* arg0 = 0, void* arg1 = 0, void* arg2 = 0, void* arg3 = 0);
		virtual IOReturn setAggressiveness(long unsigned int, long unsigned int);
		virtual void loadPlatformDriver(IOService* driver);
		virtual void setPowerProperties(UInt32, UInt32, UInt32);
		virtual void systemWillShutdown(UInt32);
		virtual void setPeriodicPollTimer();
		virtual void unloadPlatformDriver();
		virtual void deletePowerProperties();
		virtual void setPowerStateToActive();
		virtual void createAudioInputEngine(OSArray*);
		virtual void createAudioOutputEngine(OSArray*);
		virtual void selectMicInputOnPowerUp();
		virtual void handleUnsolicitedResponse(OSObject*, void* arg0 = 0, void* arg1 = 0, void* arg2 = 0, void* arg3 = 0);
		virtual void handleUnsolicitedResponse(void *, void * , void * , void *);
		virtual void periodicPollTimerCallBack(OSObject*, IOTimerEventSource*);
		virtual void protectedRunPeriodicTasks();
		virtual void translateTagToStatefulTag(UInt32, UInt32*);
		virtual void gatherPowerDataFromEngines(UInt32);
		
	//	virtual void protectedPowerChangeAction();
		virtual void protectedPowerChange_idle(IOAudioDevicePowerState, bool);
		virtual void protectedPowerChange_sleep(IOAudioDevicePowerState, bool);
		virtual void protectedPowerChange_active(IOAudioDevicePowerState, bool);
		
		virtual void dispatchPowerStateToEngines(UInt32);
		virtual void setAFGPowerForJackDetection(UInt32, bool, bool);
		virtual void scheduleDelayedIdlePowerState();
		virtual void sendMessageToAppleMikeyDriver(UInt32, UInt32);
		virtual void runPeriodicPollTimerEventHandler();
		virtual void startPowerManagementTimerForEngine(AppleHDAEngine*, bool);
		virtual void dispatchPowerStateToAppleMikeyDriver(UInt32);
		virtual void sendHeadphoneJackStateToAppleMikeyDriver();
		virtual void logTags(UInt32, UInt32);

		

		//		AppleHDADriver::validatePath((OSArray*) path)
		/*
		0000409a AppleHDADriver::validatePath((OSArray*) path)
		00006e8a AppleHDADriver newUserClient EP4 task PvmP (IOUserClient*)
		00067a14 AppleHDADriver mClassDebugMask E
		0000223a AppleHDADriver runPeriodicTasks((OSObject*) task) PvS2_S2_S2_
		000044e2 AppleHDADriver powerChangeAction EP8OSObjectPvS2_S2_S2_
		00003c42 AppleHDADriver loadPlatformDriver EP9IOServicePPv
		00003db2 AppleHDADriver unloadPlatformDriver EPv
		00005bdc AppleHDADriver handleUnsolicitedResponse EP8 OSObject PvS2_S2_S2_
		00005c64 AppleHDADriver handleUnsolicitedResponse EPvS0_S0_S0_
		000021ae AppleHDADriver periodicPollTimerCallBack EP8 OSObject P18 IOTimerEventSource
		000067f6 AppleHDADriver protectedRunPeriodicTasks Ev
		0000455c AppleHDADriver protectedPowerChangeAction EPvS0_S0_S0_
		000020a6 AppleHDADriver MetaClassC1Ev
		000020e0 AppleHDADriver MetaClassC2Ev
*/
	};

class PatchedAppleHDADriver : public AppleHDADriver
	{
		static int (*orig_halt_restart)(unsigned int type);

//		IOReturn (AppleHDADriver::*performPowerStateChangePointer)(IOAudioDevicePowerState oldPowerState, IOAudioDevicePowerState newPowerState, UInt32 *microsecondsUntilComplete);

		
		OSDeclareDefaultStructors(PatchedAppleHDADriver);
	/*	
	private:
		UInt32         _nvramType;
		volatile UInt8 *_nvramData;
		volatile UInt8 *_nvramPort;
	*/	
	public:
		virtual bool init(OSDictionary *properties);

		virtual void dispatchPowerStateToEngines(UInt32);
		virtual PatchedAppleHDADriver* PatchedAppleHDADriver::probe (IOService *provider, SInt32 *score); 
		virtual void protectedPowerChange_sleep(IOAudioDevicePowerState, bool);
		virtual void protectedPowerChange_active(IOAudioDevicePowerState, bool);


		
		virtual IOReturn performPowerStateChange(IOAudioDevicePowerState oldPowerState,
												 IOAudioDevicePowerState newPowerState,
												 UInt32 *microsecondsUntilComplete);
		
		virtual IOReturn message( UInt32      type,
												IOService * provider,
								 void *      arg );
		
		
		virtual void audioEngineStarting();
		virtual void audioEngineStopped();
		virtual IOReturn activateAudioEngine(IOAudioEngine *audioEngine, bool shouldStartAudioEngine);
		virtual	bool createAudioEngine (OSArray * streamInterfaceNumberArray);
/*
		bool start(IOService *provider);
		
		virtual IOReturn read(IOByteCount offset, UInt8 *buffer,
							  IOByteCount length);
		virtual IOReturn write(IOByteCount offset, UInt8 *buffer,
							   IOByteCount length);*/
	};