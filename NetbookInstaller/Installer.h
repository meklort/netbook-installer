//
//  Installer.h
//  NetbookInstaller
//
//  Created by Evan Lojewski on 5/16/09.
//  Copyright 2009. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <SecurityFoundation/SFAuthorization.h>
#import "SystemInformation.h"
#import "NetbookInstallerController.h"
#import "HexEditor.h"


#define nbiRamdiskPath			"/Volumes/ramdisk"
#define nbiRamdiskName			"NetbookInstaller"
#define nbiAuthorizationRight	"com.meklort.netbookinstaller"

// Internal paths
#define nbiMachinePlist			"/SupportFiles/machine.plist"

#define nbiSupportFilesPath		"/SupportFiles/"

#define nbiBootloaderPath		"/bootloader/"
#define nbiDSDTPath				"/DSDTPatcher/"

#define nbiMachineFilesPath		"/machine/"
#define nbiMachineDSDTPath		"/DSDT Patches/"

// External paths
#define nbiExtrasPath			"/Extra/"
#define nbiExtraDSDTPath		"/Extra/DSDT.aml"


// Machine plist entries
#define nbiMachineGeneric		"General"
#define nbiMachineVisibleName	"Visible Name"
#define nbiMachineExtensions	"Extensions Directory"
#define nbiMachineSupportFiles	"Support Files"
#define nbiMachineDSDTPatches	"DSDT Patches"
#define nbiMachineKextBlacklist	"Kext Blacklist"


// other paths
#define chrootPath				"/usr/sbin/chroot"
#define touchPath				"/usr/bin/touch"
#define unmountPath				"/sbin/umount"
#define mountPath				"/sbin/mount"
@interface Installer : NSObject {
	SystemInformation*	systemInfo;
	NSString*			extensionsDirectory;
	AuthorizationRef	authRef;
	id					sender;

	NSString*			sourcePath;
	
}

// Get root authorization;
- (BOOL) getAuthRef;

- (BOOL) copyFrom: (NSString*) source toDir: (NSString*) destination;
- (BOOL) makeDir: (NSString*) dir;
- (BOOL) moveFrom: (NSString*) source to: (NSString*) destination;
- (BOOL) deleteFile: (NSString*) file;
- (BOOL) hidePath: (NSString*) path;
- (BOOL) showPath: (NSString*) path;

- (NSString*) runCMD: (char*) command withArgs: (NSArray*) nsargs;
- (NSString*) runCMDAsUser: (char*) command withArgs: (NSArray*) nsargs;
- (NSString*) runCMDAsRoot: (char*) command withArgs: (NSArray*) nsargs;



// TODO: make a BOM or similar to do this automaticaly... there really is no need for specific function


					
- (BOOL) setPermissions: (NSString*) perms onPath: (NSString*) path recursivly: (BOOL) recursiv;
- (BOOL) setOwner: (NSString*) owner andGroup: (NSString*) group onPath: (NSString*) path recursivly: (BOOL) recursiv;

// Installer Options
- (BOOL) installBootloader;
- (BOOL) installExtensions;
- (BOOL) hideFiles;
- (BOOL) showFiles;
- (BOOL) installDSDT;
- (BOOL) setRemoteCD: (BOOL) remoteCD;
- (BOOL) disableHibernation: (BOOL) hibernation;
- (BOOL) setQuietBoot: (BOOL) quietBoot;
- (BOOL) fixBluetooth;


// DSDT patch routines
- (BOOL) getDSDT;
- (BOOL) patchDSDT;
- (BOOL) patchDSDT: (BOOL) forcePatch;

- (BOOL) generateExtensionsCache;


- (void) systemInfo: (SystemInformation*) info;
- (BOOL) remountDiskFrom:(NSString*) source to: (NSString*) dest;
- (NSString*) mountRamDiskAt: (NSString*) path withName: (NSString*) name andSize: (UInt64) size andOptions: (NSString*) options;
- (void) mountRamDisk;
- (void) unmountRamDisk;
- (void) remountTargetWithPermissions;


- (BOOL) removePrevExtra;

- (BOOL) copyMachineFilesFrom: (NSString*) source toDir: (NSString*) destination;

//- (BOOL) patchPre1056mkext;

- (BOOL) repairExtensionPermissions;

- (BOOL) restoreBackupExtra;
- (BOOL) failGracefully;

- (BOOL) setPartitionActive;

- (void) setSourcePath: (NSString*) path;

- (BOOL) copyNBIImage;

- (BOOL) installLocalExtensions;
- (BOOL) disableptmd;
/********** Depreciated *************/
#if 0
// Kext support (patching and copying) -- TODO: make this a generic function / plist configurable / etc
- (BOOL) patchGMAkext;
- (BOOL) patchFramebufferKext;
- (BOOL) patchIO80211kext;
- (BOOL) patchBluetooth;
- (BOOL) patchAppleUSBEHCI;
- (BOOL) patchAppleHDA;

- (BOOL) useSystemKernel;
//- (BOOL) useLatestKernel;


- (BOOL) copyDependencies;
- (BOOL) removeBlacklistedKexts;

ss


#endif

@end


