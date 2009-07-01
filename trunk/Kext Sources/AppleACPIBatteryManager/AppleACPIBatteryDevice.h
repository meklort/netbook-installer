/*
 * Copyright (c) 2005 Apple Computer, Inc. All rights reserved.
 *
 * @APPLE_LICENSE_HEADER_START@
 * 
 * This file contains Original Code and/or Modifications of Original Code
 * as defined in and that are subject to the Apple Public Source License
 * Version 2.0 (the 'License'). You may not use this file except in
 * compliance with the License. Please obtain a copy of the License at
 * http://www.opensource.apple.com/apsl/ and read it before using this
 * file.
 * 
 * The Original Code and all software distributed under the License are
 * distributed on an 'AS IS' basis, WITHOUT WARRANTY OF ANY KIND, EITHER
 * EXPRESS OR IMPLIED, AND APPLE HEREBY DISCLAIMS ALL SUCH WARRANTIES,
 * INCLUDING WITHOUT LIMITATION, ANY WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE, QUIET ENJOYMENT OR NON-INFRINGEMENT.
 * Please see the License for the specific language governing rights and
 * limitations under the License.
 * 
 * @APPLE_LICENSE_HEADER_END@
 */

#ifndef __AppleACPIBatteryDevice__
#define __AppleACPIBatteryDevice__

#include <IOKit/IOService.h>
#include <IOKit/pwr_mgt/IOPMPowerSource.h>
#include <IOKit/acpi/IOACPIPlatformDevice.h>

#include "AppleACPIBatteryManager.h"


#define WATTS				0
#define AMPS				1
#define ACPI_MAX			0x7FFFFFFF
#define ACPI_UNKNOWN		0xFFFFFFFF

#define BATTERY_CHARGED		0
#define BATTERY_DISCHARGING	1
#define BATTERY_CHARGING	2
#define	BATTERY_CRITICAL	4

#define BIF_POWER_UNIT			0
#define BIF_DESIGN_CAPACITY		1
#define BIF_LAST_FULL_CAPACITY	2
#define BIF_TECHNOLOGY			3
#define	BIF_DESIGN_VOLTAGE		4
#define BIF_CAPACITY_WARNING	5
#define BIF_LOW_WARNING			6
#define BIF_GRANULARITY_1		7
#define BIF_GRANULARITY_2		8
#define BIF_MODEL_NUMBER		9
#define BIF_SERIAL_NUMBER		10
#define BIF_BATTERY_TYPE		11
#define BIF_OEM					12
#define BIF_CYCLE_COUNT			13

#define BST_STATUS				0
#define	BST_RATE				1
#define	BST_CAPACITY			2
#define	BST_VOLTAGE				3

#define NUM_BITS				32

#define kBatteryPollingDebugKey     "BatteryPollingPeriodOverride"

static const OSSymbol * unknownObjectKey		= OSSymbol::withCString("Unknown");
UInt32 GetValueFromArray(OSArray * array, UInt8 index);
OSSymbol *GetSymbolFromArray(OSArray * array, UInt8 index);


class AppleACPIBatteryManager;

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

class AppleACPIBatteryDevice : public IOPMPowerSource {
	OSDeclareDefaultStructors(AppleACPIBatteryDevice)

protected:
    AppleACPIBatteryManager *fProvider;
	IOWorkLoop              *fWorkLoop;
	IOTimerEventSource      *fPollTimer;
    IOTimerEventSource      *fBatteryReadAllTimer;
    uint16_t                fMachinePath;
    uint32_t                fPollingInterval;
    bool                    fPollingOverridden;

    bool                    fBatteryPresent;
    bool                    fACConnected;
	bool                    fACChargeCapable;
    OSArray                 *fCellVoltages;

    // Accessor for MaxError reading
    // Percent error in MaxCapacity reading
    void    setMaxErr(int error);
    int     maxErr(void);

    // ACPIBattery reports a device name
    void    setDeviceName(OSSymbol *sym);
    OSSymbol *deviceName(void);

    // Set when battery is fully charged;
    // Clear when battery starts discharging/AC is removed
    void    setFullyCharged(bool);
    bool    fullyCharged(void);

    // Time remaining estimate - as measured instantaneously
    void    setInstantaneousTimeToEmpty(int seconds);
    
    // Time remaining until full estimate - as measured instantaneously
    void    setInstantaneousTimeToFull(int seconds);
    
    // Instantaneous amperage
    void    setInstantAmperage(int mA);

    // Time remaining estimate - 1 minute average
    void    setAverageTimeToEmpty(int seconds);
    int     averageTimeToEmpty(void);

    // Time remaining until full estimate - 1 minute average
    void    setAverageTimeToFull(int seconds);
    int     averageTimeToFull(void);
    
    void    setManufactureDate(int date);
    int     manufactureDate(void);

    void    setSerialNumber(int sernum);
    int     serialNumber(void);

    // An OSData container of manufacturer specific data
    void    setManufacturerData(uint8_t *buffer, uint32_t bufferSize);

    void    oneTimeBatterySetup(void);
    
    void    constructAppleSerialNumber(void);

public:
	static AppleACPIBatteryDevice *ACPIBattery(void);

    virtual bool init(void);

	virtual bool start(IOService *provider);

    void    setPollingInterval(int milliSeconds);

    bool    pollBatteryState(int path = 0);
    
    IOReturn setPowerState(unsigned long which, IOService *whom);

    void    handleBatteryInserted(void);
    
    void    handleBatteryRemoved(void);

protected:
    void    logReadError( const char *error_type, 
                          uint16_t additional_error,
                          void *t);

    void    clearBatteryState(bool do_update);

    void    pollingTimeOut(void);
    
    void    incompleteReadTimeOut(void);

    void    rebuildLegacyIOBatteryInfo(void);

private:
	UInt32   fPowerUnit;
	UInt32   fDesignVoltage;
	UInt32   fCurrentVoltage;
	UInt32   fDesignCapacity;
	UInt32   fCurrentCapacity;
	UInt32   fMaxCapacity;
	UInt32   fCurrentRate;
	UInt32   fAverageRate;
	UInt32   fStatus;
	UInt32	 fCycleCount;

	OSSymbol *fDeviceName;
	OSSymbol *fSerial;
	OSSymbol *fType;
	OSSymbol *fManufacturer;
	OSData   *fManufacturerData;

	UInt8    fMaxErr;
	UInt16   fManufactureDate;
	UInt16   fSerialNumber;
	UInt16   fCellVoltage1;
	UInt16   fCellVoltage2;
	UInt16   fCellVoltage3;
	UInt16   fCellVoltage4;
	UInt16   fTemperature;

public:
	void    setDesignCapacity(unsigned int val);
    unsigned int designCapacity(void);

    void    setType(OSSymbol *sym);
    OSSymbol *Type(void);

	IOReturn setBatterySTA(UInt32 acpibat_bif);

	IOReturn setBatteryBIF(OSArray *acpibat_bif);

	IOReturn setBatteryBST(OSArray *acpibat_bst);

};


#endif