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


@interface Installer : NSObject {
	SystemInformation*	systemInfo;
	NSString*			extensionsDirectory;
	AuthorizationRef	authRef;
	id					sender;

	
}

- (BOOL) performInstall: (SystemInformation*) systemInfo;

// Get root authorization;
- (BOOL) getAuthRef;

- (BOOL) copyFrom: (NSString*) source toDir: (NSString*) destination;
- (BOOL) makeDir: (NSString*) dir;
- (BOOL) moveFrom: (NSString*) source to: (NSString*) destination;
- (BOOL) deleteFile: (NSString*) file;
- (BOOL) hidePath: (NSString*) path;
- (BOOL) showPath: (NSString*) path;

- (BOOL) runCMD: (char*) command withArgs: (NSArray*) nsargs;
- (BOOL) runCMDAsUser: (char*) command withArgs: (NSArray*) nsargs;
- (BOOL) runCMDAsRoot: (char*) command withArgs: (NSArray*) nsargs;



// TODO: make a BOM or similar to do this automaticaly... there really is no need for specific function
- (BOOL) installDisplayProfile;
- (BOOL) installPrefPanes;
- (BOOL) installLaunchAgents;
- (BOOL) installSystemPrefPanes;
- (BOOL) installSystemConfiguration;
- (BOOL) installExtraFiles;

- (BOOL) updateStatus: (NSString*) status;
- (BOOL) updatePorgressBar: (NSUInteger) percent;

					
- (BOOL) setPermissions: (NSString*) perms onPath: (NSString*) path recursivly: (BOOL) recursiv;
- (BOOL) setOwner: (NSString*) owner andGroup: (NSString*) group onPath: (NSString*) path recursivly: (BOOL) recursiv;

// Installer Options
- (BOOL) installBootloader: (enum bootloader) bootloaderType;
- (BOOL) installExtensions;
- (BOOL) hideFiles;
- (BOOL) showFiles;
- (BOOL) installDSDT;
- (BOOL) setRemoteCD: (BOOL) remoteCD;
- (BOOL) dissableHibernation: (BOOL) hibernation;
- (BOOL) setQuietBoot: (BOOL) quietBoot;
- (BOOL) fixBluetooth;

- (BOOL) installMirrorFriendlyGraphics;


// DSD patch routines
- (BOOL) getDSDT;
- (BOOL) patchDSDT;
- (BOOL) patchDSDT: (BOOL) forcePatch;

// Kext support (patching and copying)
- (BOOL) patchGMAkext;
- (BOOL) patchFramebufferKext;
- (BOOL) patchIO80211kext;
- (BOOL) patchBluetooth;
- (BOOL) installLocalExtensions;
- (BOOL) copyDependencies;

- (BOOL) generateExtensionsCache;


- (id) initWithSender: (id) sender;
- (void) systemInfo: (SystemInformation*) info;
- (void) mountRamDisk;
- (void) unmountRamDisk;
- (void)remountTargetWithPermissions;

- (BOOL) useSystemKernel;
- (BOOL) useLatestKernel;

- (BOOL) removePrevExtra;


@end

#import "InstallerCLI.h"

