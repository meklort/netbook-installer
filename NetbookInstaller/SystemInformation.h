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




@interface SystemInformation : NSObject {
	NSDictionary*		bootloaderDict;
	UInt32 installedKernel;
	UInt32 hostKernel;

	NSString*	sourcePath;

	
	//int		efiVersion;
	//int		netbookInstallerVersion;
	
	NSUInteger	bluetoothVendorId;
	unsigned int	bluetoothDeviceId;
	
	BOOL		dsdtInstalled;
	BOOL		remoteCDEnabled;
	BOOL		hibernationDissabled;
	BOOL		quietBoot;
	BOOL		bluetoothPatched;
	BOOL		efiHidden;
	BOOL		generic;
	
	BOOL		is64bit;
	
//	NSString*	extensionsFolder;
	NSString*	bootPartition;
	NSString*	installPath;
	
	NSDictionary* machineInfo;

}
- (id) init;
- (BOOL) dsdtInstalled;
- (NSDictionary*) bootloaderDict;
- (NSArray*) supportedBootloaders;
- (NSString*) getMachineString;
- (NSInteger) hostOS;
- (NSInteger) targetOS;
- (BOOL) remoteCDEnabled;
- (BOOL) hibernationDissabled;
- (NSString*) bootPartition;
- (NSDictionary*) machineInfo;
- (NSString*) extensionsFolder;
- (void) installPath: (NSString*) path;
- (NSString*) installPath;
- (BOOL) quietBoot;
- (BOOL) bluetoothPatched;
- (BOOL) efiHidden;
- (BOOL) is64bit;

//- (enum machine) machineType;
//- (void) machineType: (enum machine) newMachineType;

- (NSUInteger) bluetoothVendorId;
- (NSUInteger) bluetoothDeviceId;

- (NSInteger) getKernelVersion: (NSString*) kernelPath;

- (void) determineMachineType;
- (void) determinebootPartition;
- (void) determinePartitionFromPath: (NSString*) path;
- (void) determineDSDTState;
- (void) determineRemoteCDState;
- (void) determineHibernateState;
- (void) determineQuiteBootState;
- (void) determineArchitecture;
- (void) determineHiddenState;
- (BOOL) hiddenStateOfPath: (NSString*) path;
- (void) determineBluetoothState;
- (BOOL) determineTargetOS;

- (BOOL) isInstallDVD: (NSString*) path;
- (BOOL) isInstall: (NSString*) path;


//- (NSArray*) installableVolumes: (int) minVersions;
- (NSArray*) installableVolumesWithKernel: (int) minVersions;

- (BOOL) needsHelperPartition;

- (NSDictionary*) getFileSystemInformation: (NSString*) mountPoint;

- (void) genericMachineType;

- (void) printStatus;

- (NSString*) getModelString;

- (void) setSourcePath: (NSString*) path;
@end
