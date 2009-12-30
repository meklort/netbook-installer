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
	
	IBOutlet NSButton*		bootloaderCheckbox;
	IBOutlet NSButton*		extensionsCheckbox;
	IBOutlet NSButton*		showhideFilesCheckbox;
	IBOutlet NSButton*		dsdtCheckbox;
	IBOutlet NSButton*		remoteCDCheckbox;
	IBOutlet NSButton*		hibernateChecbox;
	IBOutlet NSButton*		quietBootCheckbox;
	IBOutlet NSButton*		bluetoothCheckbox;		/// TODO: remove this when the bluetooth dev id / vendor id is determiend automaticaly.
	
	IBOutlet NSProgressIndicator*	progressBar;
	IBOutlet NSTextField*	warningLabel;
	IBOutlet NSTextField*	versionLabel;
	IBOutlet NSTextField*	statusLabel;
	
	IBOutlet NSPopUpButton*	targetVolume;
	IBOutlet NSPopUpButton*	bootloaderVersion;
	
	BOOL					installing;
	BOOL					initialized;
	
	
	
}

- (void) awakeFromNib;

- (void) updateBootloaderMenu;

- (IBAction) volumeChanged: (id) sender;
- (IBAction) openAboutWindow: (id) sender;

- (void) enableOptions;
- (void) enableOptions: (BOOL) state;

- (void) updateCheckboxes;

- (void) applicationDidFinishLaunching:(id)application;
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication;
- (void)applicationWillTerminate:(NSNotification *)aNotification;
- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender;

- (void) initializeApplication;

- (void) unknownMachineAlert:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo;

- (IBAction) performInstall: (id) sender;
- (IBAction) bootloaderModified: (id) sender;
- (IBAction) extensionsModified: (id) sender;

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

// Requested system State
- (BOOL) enableQuietBoot;
- (BOOL) dissableHibernation;
- (BOOL) enableRemoteCD;
- (BOOL) installExtensions;
- (NSDictionary*) bootloaderType;

- (BOOL) fixBluetooth;
- (BOOL) regenerateDSDT;
- (BOOL) fixBluetooth;
- (BOOL) toggleVisibility;
- (BOOL) hideFiles;

- (BOOL) updatePorgressBar: (NSNumber*) percent;
- (BOOL) updateStatus: (NSString*) status;
- (BOOL) installFinished;

- (void) updateVolumeMenu;
- (void) mountChange:(NSNotification *)notification ;

- (BOOL) performThreadedInstall;



@end
