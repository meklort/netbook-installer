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


enum scrollMethod { MEKLORT, VOODOO, FFSCROLL };



@interface SystemInformation : NSObject {
	//enum machine		machineType;
	enum scrollMethod	twoFingerScrolling;
	NSDictionary*		installedBootloader;
	NSDictionary*		bootloaderDict;
	UInt32 installedKernel;

	
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
	
//	NSString*	extensionsFolder;
	NSString*	bootPartition;
	NSString*	installPath;
	
	NSDictionary* machineInfo;

}

- (bool) dsdtInstalled;
- (NSDictionary*) bootloaderDict;
- (NSArray*) supportedBootloaders;
- (NSString*) getMachineString;
- (int) targetOS;
- (bool) keyboardPrefPaneInstalled;
- (bool) remoteCDEnabled;
- (bool) hibernationDissabled;
- (NSString*) bootPartition;
- (NSDictionary*) machineInfo;
- (NSString*) extensionsFolder;
- (void) installPath: (NSString*) path;
- (NSString*) installPath;
- (bool) quietBoot;
- (bool) bluetoothPatched;
- (BOOL) mirrorFriendlyGMA;
- (bool) efiHidden;
- (NSDictionary*) installedBootloader;
//- (enum machine) machineType;
//- (void) machineType: (enum machine) newMachineType;

- (NSUInteger) bluetoothVendorId;
- (NSUInteger) bluetoothDeviceId;

- (int) getKernelVersion: (NSString*) kernelPath;

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
- (BOOL) needsHelperPartition;

- (NSDictionary*) getFileSystemInformation: (NSString*) mountPoint;


@end
