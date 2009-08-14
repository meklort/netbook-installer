/* add your code here */
// __ZN14AppleHDAEngine17changeMuteHandlerEP8OSObjectP14IOAudioControlll
// 00009318 (__TEXT,__text) external __ZN14AppleHDAEngine19changeVolumeHandlerEP8OSObjectP14IOAudioControlll
// 0000a47e (__TEXT,__text) external __ZN14AppleHDAEngine22handlePowerStateChangeEm
// 00011c4c (__TEXT,__text) external __ZN14AppleHDAEngine28protectedChangeVolumeHandlerEP14IOAudioControlll

#include <IOKit/IOService.h>
#include <IOKit/IOLib.h>
#include "patchedAppleHDA.h"
#include "Mini9MuteControl.h"


// =============================================================================
// pacthedAppleHDA Class Implementation
//
#define self  PatchedAppleHDADriver
#define super AppleHDADriver
//OSDefineMetaClassAndStructors(AppleHDAEngine, IOService);

OSDefineMetaClassAndStructors(PatchedAppleHDADriver, AppleHDADriver);

bool PatchedAppleHDADriver::init(OSDictionary *properties)
{
	bool success = false;
	IOLog("PatchedAppleHDADriver::init\n");
	success = super::init(properties);
	IOLog("PatchedAppleHDaDriver::init done\n");
	
	// Overwriting functions...
//	performPowerStateChangePointer = &AppleHDADriver::performPowerStateChange;
//	this->performPowerStateChange = &AppleHDADriver::performPowerStateChange;
	//AppleHDADriver::performPowerStateChange = AppleHDADriver::performPowerStateChange; //&PatchedAppleHDADriver::performPowerStateChange;
//	IOReturn (*performPowerStateChangePointer)(IOAudioDevicePowerState oldPowerState, IOAudioDevicePowerState newPowerState, UInt32 *microsecondsUntilComplete);

	
	return success;
}

void PatchedAppleHDADriver::dispatchPowerStateToEngines(UInt32 engineID)
{
	IOLog("PatchedAppleHDA::Dispatching power state");
	super::dispatchPowerStateToEngines(engineID);
}


void PatchedAppleHDADriver::protectedPowerChange_sleep(IOAudioDevicePowerState state, bool boolVal)
{
	IOLog("PatchedAppleHDA::protectedPowerChange sleep %d", boolVal);
	super::protectedPowerChange_sleep(state, boolVal);
}

void PatchedAppleHDADriver::protectedPowerChange_active(IOAudioDevicePowerState state, bool boolVal)
{
	IOLog("PatchedAppleHDA::protectedPowerChange active %d", boolVal);
	super::protectedPowerChange_active(state, boolVal);
}

PatchedAppleHDADriver* PatchedAppleHDADriver::probe (IOService *provider, SInt32 
								  *score) 
{ 
	IOLog("PatchedAppleHDADriver::probe\n");
	
	super::probe(provider, score);
	*score = *score + 100;
	return this;
} 

IOReturn PatchedAppleHDADriver::performPowerStateChange(IOAudioDevicePowerState oldPowerState,
										 IOAudioDevicePowerState newPowerState,
										 UInt32 *microsecondsUntilComplete)
{
	IOLog("PatchedAppleHDADriver::performPowerStateChange\n");

	return super::performPowerStateChange(oldPowerState, newPowerState, microsecondsUntilComplete);	
}


void PatchedAppleHDADriver::audioEngineStarting()
{
	IOLog("PatchedAppleHDADriver::audioEngineStarting\n");
	super::audioEngineStarting();
}

void PatchedAppleHDADriver::audioEngineStopped()
{
	IOLog("PatchedAppleHDADriver::audioEngineStopped\n");
	super::audioEngineStopped();
}

IOReturn PatchedAppleHDADriver::activateAudioEngine(IOAudioEngine *audioEngine, bool shouldStartAudioEngine)
{
	IOReturn retVal;

	if (!audioEngine || !audioEngines) {
        return kIOReturnBadArgument;
    }
	
	char* className = (char*) audioEngine->getMetaClass()->getClassName();
	className = className + strlen(className) - strlen("Output");
	
	if(strcmp(className, "Output") == 0)
	{
		IOLog("PatchedAppleHDADriver::activateAudioEngine - creating mute control\n");
		/*Mini9MuteControl *mmc = Mini9MuteControl::create();
		audioEngine->addDefaultAudioControl( mmc);
		
		retVal = super::activateAudioEngine(audioEngine, shouldStartAudioEngine);
		
		mmc->startUpdate();*/
		
		retVal = super::activateAudioEngine(audioEngine, shouldStartAudioEngine);

		IOLog("PatchedAppleHDADriver::activateAudioEngine - *NOT* creating mute control\n");
	}
	else
	{
		retVal = super::activateAudioEngine(audioEngine, shouldStartAudioEngine);
	}
	
	
	IOLog("PatchedAppleHDADriver::activateAudioEngine\n");
	return retVal;

}

bool PatchedAppleHDADriver::createAudioEngine (OSArray * streamInterfaceNumberArray)
{
	IOLog("PatchedAppleHDADriver::createAudioEngine\n");
	return super::createAudioEngine(streamInterfaceNumberArray);
}

IOReturn PatchedAppleHDADriver::message( UInt32      type,
							IOService * provider,
							void *      arg )
{
	int argument = *(UInt32*) arg;
	/*switch(type) {
		default:
		case -532709375:
			break;
			// line in / hreadphone / speaker / etc changed
	}*/
	
	// 335707200 -> line in connected
	// 335707136 -> line in disconnected, switch to mic
	// 201358338 -> Headphones connected
	// 268467328 -> Headphones dissconected?
	// 268467202 -> SPDIF connected?
	// 201358464 -> SPDIF Disconnected?
	// 201358338 -> Main speakers connected?
	
	IOLog("PatchedAppleHDA::message - type = %d, %d\n", type, argument);
	return super::message(type, provider, arg);
}

