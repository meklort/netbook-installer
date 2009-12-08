//
//  NetbookBootMakerController.h
//  NetbookInstaller
//
//  Created by Evan Lojewski on 6/20/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SystemInformation.h"
#import "Installer.h"


@interface NetbookBootMakerController : NSObject {
	SystemInformation*	systemInfo;
	Installer*			installer;
	IBOutlet NSPopUpButton*		volumeList;
	
	IBOutlet NSProgressIndicator*	progressBar;
	IBOutlet NSTextField*	statusLabel;
	IBOutlet NSButton* prepareButton;
	
	BOOL installing;
	
}
- (IBAction) performInstall: (id) sender;


- (NSArray*) getMountedVolumes;
- (void) updateVolumeMenu;


- (BOOL) patchDVDPartition: (NSString*) partition;
- (BOOL) patchOSInstall;
- (BOOL) patchmpkg;
- (BOOL) patchPrivateFramework;
- (BOOL) removePostInstallError;
- (BOOL) patchUtilitMenu;

- (void) mountChange:(NSNotification *)notification;
- (void) patchUSBDrive;

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication;
- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender;

- (BOOL) updateStatus: (NSString*) status;
- (BOOL) updatePorgressBar: (NSNumber*) percent;

@end
