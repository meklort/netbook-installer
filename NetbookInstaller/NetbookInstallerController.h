//
//  NetbookInstallerController.h
//  NetbookInstaller
//
//  Created by Evan Lojewski on 5/15/09.
//  Copyright 2009. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SystemInformation.h"
#import "Installer.h"


@interface NetbookInstallerController : NSObject {
	SystemInformation*	systemInfo;
	NSBundle*			appBundle;
	IBOutlet NSWindow*			mainWindow;
	
	
	IBOutlet NSButton*		installButton;
		
	IBOutlet NSProgressIndicator*	progressBar;
	IBOutlet NSTextField*	versionLabel;
	IBOutlet NSTextField*	statusLabel;
	
	IBOutlet NSPopUpButton*	targetVolume;
	
	BOOL					installing;
	BOOL					initialized;
	
	
	
}

- (void) awakeFromNib;


- (IBAction) volumeChanged: (id) sender;
- (IBAction) openAboutWindow: (id) sender;


- (void) applicationDidFinishLaunching:(id)application;
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication;
- (void)applicationWillTerminate:(NSNotification *)aNotification;
- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender;

- (void) initializeApplication;

- (void) unknownMachineAlert:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo;

- (IBAction) performInstall: (id) sender;

- (BOOL) isMachineSupported;
/*
 - (IBAction) showHideFilesModified: (id) sender;
 - (IBAction) dsdtModified: (id) sender;
- (IBAction) keyboardPrefPaneModified: (id) sender;
 - (IBAction) remoteCDModified: (id) sender;
 - (IBAction) hibernateModified: (id) sender;
 - (IBAction) quietBootModified: (id) sender;
 - (IBAction) bluetoothModified: (id) sender;
 */

- (void) setProgress: (double) progress;

- (BOOL) updateProgressBar: (NSNumber*) percent;
- (BOOL) updateStatus: (NSString*) status;
- (BOOL) installFinished;

- (void) updateVolumeMenu;
- (void) mountChange:(NSNotification *)notification ;

- (BOOL) performThreadedInstall;
- (BOOL) performThreadedBootdiskCreation;

- (BOOL) installBootdisk: (NSString*) image toDrive: (NSString*) drive;
- (NSString*) bootLoaderImagePath;


@end
