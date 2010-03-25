//
//  NetbookBootMakerController.h
//  NetbookInstaller
//
//  Created by Evan Lojewski on 6/20/09.
//  Copyright 2009. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SystemInformation.h"
#import "Installer.h"


@interface NetbookBootMakerController : NSObject {
	SystemInformation* systemInfo;
	Installer*	installer;
	IBOutlet NSPopUpButton*		volumeList;
	
	IBOutlet NSProgressIndicator*	progressBar;
	IBOutlet NSTextField*	statusLabel;
	IBOutlet NSButton* prepareButton;
	
	BOOL installing;
	
}
- (IBAction) performInstall: (id) sender;

- (void) mountChange:(NSNotification *)notification;


- (NSArray*) getMountedVolumes;
- (void) updateVolumeMenu;

- (void) patchUSBDrive;
- (BOOL) installBootlaoder: (NSString*) image toDrive: (NSString*) drive;

- (BOOL) updatePorgressBar: (NSNumber*) percent;
- (BOOL) updateStatus: (NSString*) status;
- (BOOL) installFinished;
- (BOOL) installFailed;

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication;
- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender;

@end
