//
//  SystemInformation.h
//  NetbookInstaller
//
//  Created by Evan Lojewski on 5/15/09.
//  Copyright 2009. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <CoreServices/CoreServices.h>

#import <sys/stat.h>
#import <unistd.h>

struct uint128 {
	UInt64 upper;
	UInt64 lower;
};

#define MINI9_BLUETOOTH_VENDOR			16700
#define MINI9_BLUETOOTH_DEVICE			668

#define MINI10V_BLUETOOTH_VENDOR		0
#define MINI10V_BLUETOOTH_DEVICE		0

#define S10_BLUETOOTH_VENDOR			0
#define S10_BLUETOOTH_DEVICE			0

#define DEFAULT_BOOTLOADER				CHAMELEON_R431

enum machine { MINI9, VOSTRO_A90, MINI10V, LENOVO_S10, UNKNOWN};
enum bootloader { CHAMELEON_R431, PCEFIV9, PCEFIV10, NONE};
enum scrollMethod { MEKLORT, VOODOO, FFSCROLL };



@interface SystemInformation : NSObject {
	enum machine		machineType;
	enum scrollMethod	twoFingerScrolling;
	enum bootloader		installedBootloader;
	SInt8 installedKernel;

	
	int		efiVersion;
	int		netbookInstallerVersion;
	
	NSUInteger	bluetoothVendorId;
	NSUInteger	bluetoothDeviceId;
	
	bool		dsdtInstalled;
	bool		keyboardPrefPaneInstalled;
	bool		remoteCDEnabled;
	bool		hibernationDissabled;
	bool		quietBoot;
	bool		bluetoothPatched;
	bool		mirrorFriendlyGMA;
	bool		efiHidden;
	
	NSString*	extensionsFolder;
	NSString*	bootPartition;
	NSString*	installPath;

}

- (bool) dsdtInstalled;
- (NSString*) getMachineString;
- (int) targetOS;
- (bool) keyboardPrefPaneInstalled;
- (bool) remoteCDEnabled;
- (bool) hibernationDissabled;
- (NSString*) bootPartition;
- (NSString*) extensionsFolder;
- (void) installPath: (NSString*) path;
- (NSString*) installPath;
- (bool) quietBoot;
- (bool) bluetoothPatched;
- (bool) mirrorFriendlyGMA;
- (bool) efiHidden;
- (enum bootloader) installedBootloader;
- (enum machine) machineType;
- (void) machineType: (enum machine) newMachineType;

- (NSUInteger) bluetoothVendorId;
- (NSUInteger) bluetoothDeviceId;

- (void) determineInstallState;
- (void) determineMachineType;
- (void) determinebootPartition;
- (void) determinePartitionFromPath: (NSString*) path;
- (void) determineDSDTState;
- (void) determineRemoteCDState;
- (void) determineHibernateState;
- (void) determineQuiteBootState;
- (void) determineGMAVersion;
- (void) determineHiddenState;
- (void) determineBluetoothState;
- (void) determinekeyboardPrefPaneInstalled;
- (void) determineBootloader;
- (BOOL) determineTargetOS;

- (int) getKernelVersion: (NSString*) path;
- (NSArray*) installableVolumes: (int) minVersions;


@end
