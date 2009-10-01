//
//  NetbookBootMakerController.m
//  NetbookInstaller
//
//  Created by Evan Lojewski on 6/20/09.
//  Copyright 2009. All rights reserved.
//

#import "NetbookBootMakerController.h"


@implementation NetbookBootMakerController

- (void) awakeFromNib {	
	// Listen for dvds being mounted
	NSNotificationCenter *notificationCenter = [[NSWorkspace sharedWorkspace] notificationCenter];
	[notificationCenter addObserver:self selector:@selector(mountChange:) name:NSWorkspaceDidMountNotification object:nil];
	[notificationCenter addObserver:self selector:@selector(mountChange:) name:NSWorkspaceDidUnmountNotification object:nil];


	installing = false;
	systemInfo = [[SystemInformation alloc] init];

	// This is run whenever ANY nib file is loaded
	[self updateVolumeMenu];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication {
	return YES;
}


- (IBAction) performInstall: (id) sender
{
	// Split this into a seperate thread
	
	if([volumeList selectedItem])
	{
		installing = YES;
		[progressBar setHidden:false];
		[progressBar startAnimation: sender];
		
		[prepareButton setEnabled:false];
		
		[NSThread detachNewThreadSelector:@selector(patchUSBDrive) toTarget: self withObject: nil];

//		[self patchUSBDrive];
	}
}

- (NSArray*) getMountedVolumes
{
	// TODO: do some error checking to verify that that volume actualy exists.
	return [[NSFileManager defaultManager] directoryContentsAtPath:@"/Volumes"];
}

- (void) updateVolumeMenu
{
	NSArray* options = [systemInfo installableVolumes: KERNEL_VERSION(10, 5, 0)];	// Any Leopard and beyond  (0.0.0 = no kernel required)
//	NSMutableArray* newOptions;
	
	NSMenuItem* current = [volumeList selectedItem];

	
	[volumeList removeAllItems];
	[volumeList addItemsWithTitles:options];
	[volumeList selectItemWithTitle:[current title]];
	
	
}

- (BOOL) patchDVDPartition: (NSString*) partition;
{

	
	[systemInfo determineInstallState];
	NSLog(@"%@", partition);
	[systemInfo determinePartitionFromPath: partition];
	

	
	[installer systemInfo: systemInfo];
	[self updateStatus:@"Remounting target"];
	[installer remountTargetWithPermissions];
	[self updatePorgressBar:[[NSNumber alloc] initWithInt: 5]];
	
	// remove the previos /Extra directory
	[installer deleteFile:[[systemInfo installPath] stringByAppendingString:@"/Extra"]];
	[installer deleteFile:[[systemInfo installPath] stringByAppendingString:@"/mach_kernel.10.5.6"]];
	
	// Copy the CLI and GUI installer
	[self updateStatus:NSLocalizedString(@"Installing NetbookInstaller Applications", nil)];	
	[installer deleteFile:[[systemInfo installPath] stringByAppendingString:@"/Applications/NetbookInstaller.app"]];
	[installer copyFrom:[[[NSBundle mainBundle] resourcePath] stringByAppendingString: @"/NetbookInstaller.app"] toDir:[[systemInfo installPath] stringByAppendingString:@"/Applications/"]];
	[installer copyFrom:[[[NSBundle mainBundle] resourcePath] stringByAppendingString: @"/SupportFiles/"] toDir:[[systemInfo installPath] stringByAppendingString:@"/Applications/NetbookInstaller.app/Contents/Resources/SupportFiles/"]];
	[installer copyFrom:[[[NSBundle mainBundle] resourcePath] stringByAppendingString: @"/bootMakerFiles/gptsync"] toDir:[[systemInfo installPath] stringByAppendingString:@"/usr/bin/gptsync"]];


	
	[self updatePorgressBar: [[NSNumber alloc] initWithInt:10]];
	
	// Patch OS Install
	[self updateStatus:NSLocalizedString(@"Adding post install commands", nil)];	
	[self patchOSInstall];
	[self updatePorgressBar: [[NSNumber alloc] initWithInt:10]];
	
	[self updateStatus:NSLocalizedString(@"Fixing bless errors", nil)];	
	[self removePostInstallError];
	[self updatePorgressBar: [[NSNumber alloc] initWithInt:10]];
	
	[self updateStatus:NSLocalizedString(@"Updating Utility menu", nil)];	
	[self patchUtilitMenu];
	[self updatePorgressBar: [[NSNumber alloc] initWithInt:10]];	
	/// Time to actualy do the install
	
	[self updateStatus:NSLocalizedString(@"Creating extra", nil)];	
	[installer removePrevExtra];
	[installer installExtraFiles];
	[self updatePorgressBar: [[NSNumber alloc] initWithInt:10]];
	
	// Install and patch extensions
	
	[installer makeDir: [systemInfo extensionsFolder]];
	

	[self updateStatus:NSLocalizedString(@"Installing dependencies files", nil)];	
	// This is ONLY untill I port at least dsdt retriever to objective c (should be relatively easy).
	
	// FIXME: Fix this
	/*
	[installer deleteFile:[[systemInfo installPath] stringByAppendingString:@"/usr/bin/xxd"]];
	[installer makeDir:@"/Volumes/ramdisk/usr"];
	[installer makeDir:@"/Volumes/ramdisk/usr/bin"];

	[installer setPermissions:@"777" onPath:@"/Volumes/ramdisk/usr/" recursivly:YES];


	NSLog(@"Running %s", (char*)[[[[NSBundle mainBundle] resourcePath] stringByAppendingString: @"/bootMakerFiles/xxdExtract.sh"] cStringUsingEncoding:NSASCIIStringEncoding]);

	
	[installer setPermissions:@"755" onPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingString: @"/bootMakerFiles/xxdExtract.sh"] recursivly:NO];

	[installer runCMD:(char*)[[[[NSBundle mainBundle] resourcePath] stringByAppendingString: @"/bootMakerFiles/xxdExtract.sh"] cStringUsingEncoding:NSASCIIStringEncoding] withArgs: [NSArray arrayWithObjects:[systemInfo installPath], nil]];
	[installer copyFrom:@"/Volumes/ramdisk/usr/bin/xxd" toDir:[[systemInfo installPath] stringByAppendingString:@"/usr/bin/"]];
	*/
	[installer copyFrom:[[[NSBundle mainBundle] resourcePath] stringByAppendingString: @"/bootMakerFiles/xxd"] toDir:[[systemInfo installPath] stringByAppendingString:@"/usr/bin/"]];

	// END FIXME
	
	// First run pm set? (this could be moved to the cli / installer
	[installer copyFrom:@"/Library/Preferences/SystemConfiguration/com.apple.PowerManagement.plist" toDir:[[systemInfo installPath] stringByAppendingString:@"/Library/Preferences/SystemConfiguration/"]];
	[self updatePorgressBar: [[NSNumber alloc] initWithInt:10]];
	
	//[installer installDSDT];
	
	
	
	[self updateStatus:NSLocalizedString(@"Setting up bootloader ", nil)];	

	[installer setQuietBoot:	NO];

	[installer dissableHibernation:	YES];

	NSString* bootloader = [[systemInfo bootloaderDict] objectForKey:@"Default Bootloader"];

	[installer installBootloader: [[[systemInfo bootloaderDict] objectForKey:@"Bootloaders"] objectForKey:bootloader]];
	//[installer installBootloader: DEFAULT_BOOTLOADER];
	[self updatePorgressBar: [[NSNumber alloc] initWithInt:10]];	

	[installer setPermissions: @"755" onPath: [[systemInfo installPath] stringByAppendingString:@"/Extra"] recursivly: YES];
	[installer setPermissions: @"755" onPath: [[systemInfo installPath] stringByAppendingString:@"/boot"] recursivly: NO];
	
	[installer setOwner:@"root" andGroup:@"wheel" onPath: [[systemInfo installPath] stringByAppendingString:@"/Extra"] recursivly: YES];
	[installer setOwner:@"root" andGroup:@"wheel" onPath: [[systemInfo installPath] stringByAppendingString:@"/boot"] recursivly: NO];
	
	[self updateStatus:NSLocalizedString(@"Creating extensions cache", nil)];	
	if([systemInfo targetOS] < KERNEL_VERSION(10, 5, 6))	// Less than Mac OS X 10.5.6
	{
		// This is ONLY going to be run from the install dvd, so we can copy these from the /
		[installer copyFrom:[[[NSBundle mainBundle] resourcePath] stringByAppendingString: @"/bootMakerFiles/Extensions.mkext"] toDir:[[systemInfo installPath] stringByAppendingString:@"/Extra/"]];
		[installer copyFrom:[[[NSBundle mainBundle] resourcePath] stringByAppendingString: @"/bootMakerFiles/mach_kernel.10.5.6"] toDir:[[systemInfo installPath] stringByAppendingString:@"/"]];
		[installer useLatestKernel];
		
	} else // any other vesion is officialy supported
	{
		[installer copyDependencies];
		[installer installExtensions];
		[installer installLocalExtensions];

		[installer patchGMAkext];
		[installer patchFramebufferKext];
		[installer patchIO80211kext];
		[installer patchBluetooth];
		[installer patchAppleUSBEHCI];
			//[installer patchAppleHDA];

		[installer generateExtensionsCache];
		[installer useSystemKernel];
	}
	[self updatePorgressBar: [[NSNumber alloc] initWithInt:20]];
		
	
	
	[installer hideFiles];

	[self updateStatus:NSLocalizedString(@"Done", nil)];	
	[installer unmountRamDisk];
	[self updatePorgressBar: [[NSNumber alloc] initWithInt:100]];

	
	[self performSelectorOnMainThread:@selector(installFinished) withObject: nil waitUntilDone:NO];

	return YES;
}

- (BOOL) patchmpkg
{
	NSMutableArray* nsargs = [[NSMutableArray alloc] init];
	[nsargs addObject: @"-x"];	
	[nsargs addObject: @"-f"];	

	[nsargs addObject:[[systemInfo installPath] stringByAppendingString: @"/System/Installation/Packages/OSInstall.mpkg"]];
	[nsargs addObject: @"-c"];	
	[nsargs addObject: @"/Volumes/ramdisk/OSInstallMPKG"];	
	
	
	[installer runCMD:"/usr/bin/xar" withArgs:nsargs];
	
	
	NSMutableDictionary* dict = [[NSMutableDictionary alloc] initWithContentsOfFile:@"/Volumes/ramdisk/OSInstallMPKG/Distribution"];
	
	
	return NO;
	
}

- (BOOL) patchPrivateFramework
{
	return NO;
}

- (BOOL) patchOSInstall
{
	NSMutableArray* nsargs = [[NSMutableArray alloc] init];
	//NSMutableArray* nsargs2 = [[NSMutableArray alloc] init];
	NSMutableArray* nsargs3 = [[NSMutableArray alloc] init];

	// Expand the package
	[nsargs addObject: @"--expand"];	
	[nsargs addObject:[[systemInfo installPath] stringByAppendingString: @"/System/Installation/Packages/OSInstall.pkg"]];
	[nsargs addObject: @"/Volumes/ramdisk/OSInstall"];	
	
	[installer runCMD:"/usr/sbin/pkgutil" withArgs:nsargs];
	
	// Add NetbookInstallerCLI as a postinstaller script
	[installer copyFrom:[[[NSBundle mainBundle] resourcePath] stringByAppendingString: @"/bootMakerFiles/postinstall"] toDir:@"/Volumes/ramdisk/OSInstall/Scripts/postinstall_actions/"];
	[installer setPermissions:@"755" onPath:@"/Volumes/ramdisk/OSInstall/Scripts/postinstall_actions/" recursivly:YES];
	// Backup the origional file.
	[installer moveFrom:[[systemInfo installPath] stringByAppendingString: @"/System/Installation/Packages/OSInstall.pkg"] to: [[systemInfo installPath] stringByAppendingString: @"/System/Installation/Packages/OSInstall.pkg.orig"]];

	
	// Create the patched package
	[nsargs3 addObject: @"--flatten"];	
	[nsargs3 addObject: @"/Volumes/ramdisk/OSInstall/"];	
	[nsargs3 addObject:[[systemInfo installPath] stringByAppendingString: @"/System/Installation/Packages/OSInstall.pkg"]];
	
	[installer runCMD:"/usr/sbin/pkgutil" withArgs:nsargs3];
		
	

	return YES;
}

- (BOOL) removePostInstallError
{
	[installer deleteFile:[[systemInfo installPath] stringByAppendingString:@"/usr/sbin/bless"]];
	return [installer copyFrom:[[[NSBundle mainBundle] resourcePath] stringByAppendingString: @"/bless"] toDir:[[systemInfo installPath] stringByAppendingString:@"/usr/sbin/"]];

	/*
	[installer deleteFile:[[systemInfo installPath] stringByAppendingString:@"/System/Installation/CDIS/Mac OS X Installer.app/Contents/Resources/OSXInstallAssistant.bundle/Contents/Resources/English.lproj/OSIPanel_PostInstallError.nib"]];
	return [installer copyFrom:[[systemInfo installPath] stringByAppendingString:@"/System/Installation/CDIS/Mac OS X Installer.app/Contents/Resources/OSXInstallAssistant.bundle/Contents/Resources/English.lproj/OSIPanel_PostInstallSuccess.nib"] \
				  toDir: [[systemInfo installPath] stringByAppendingString:@"/System/Installation/CDIS/Mac OS X Installer.app/Contents/Resources/OSXInstallAssistant.bundle/Contents/Resources/English.lproj/OSIPanel_PostInstallError.nib"]];
	 */
}

- (BOOL) patchUtilitMenu
{
	NSMutableArray* utilityMenu = [[NSMutableArray alloc] initWithContentsOfFile: [[systemInfo installPath] stringByAppendingString:@"/System/Installation/CDIS/Mac OS X Installer.app/Contents/Resources/InstallerMenuAdditions.plist"]];
	NSMutableDictionary* netbookInstallerItem = [[NSMutableDictionary alloc] init];
		
	[netbookInstallerItem setObject:@"/Applications/NetbookInstaller.app" forKey:@"Path"];
	
	[utilityMenu removeObject:netbookInstallerItem];	/// Delete any previos, we *could* just no add it tooo (woulld be better)
	[utilityMenu insertObject:netbookInstallerItem atIndex:0];
	
	[utilityMenu writeToFile:[[systemInfo installPath] stringByAppendingString:@"/tmp/InstallerMenuAdditions.plist"] atomically:NO];
	[installer deleteFile:[[systemInfo installPath] stringByAppendingString:@"/System/Installation/CDIS/Mac OS X Installer.app/Contents/Resources/InstallerMenuAdditions.plist"]];
	return [installer copyFrom: [[systemInfo installPath] stringByAppendingString:@"/tmp/InstallerMenuAdditions.plist"] toDir: [[systemInfo installPath] stringByAppendingString:@"/System/Installation/CDIS/Mac OS X Installer.app/Contents/Resources/"]];
	
}


- (void) mountChange:(NSNotification *)notification 
{
	[self updateVolumeMenu];
	NSString *devicePath = [[notification userInfo] objectForKey:@"NSDevicePath"];
	
	
	NSLog(@"Device did mount: %@", devicePath);
}



- (void) patchUSBDrive
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	installer = [[Installer alloc] init];
	
	
	if(![installer getAuthRef]) 
	{
		[self performSelectorOnMainThread:@selector(installFailed) withObject: nil waitUntilDone:NO];

		return;
	}
	[self updateStatus:NSLocalizedString(@"Creating ramdisk", nil)];	
	[installer mountRamDisk];
	[self updatePorgressBar: [[NSNumber alloc] initWithInt:5]];
	
	[self patchDVDPartition: [@"/Volumes/" stringByAppendingString: [[volumeList selectedItem] title]]];
	
	[installer unmountRamDisk];
	[pool release];

}

- (BOOL) updatePorgressBar: (NSNumber*) percent
{
	if([NSThread isMainThread])
	{
		[progressBar incrementBy: [percent intValue]];
	}
	else
	{
		[self performSelectorOnMainThread:@selector(updatePorgressBar:) withObject: percent waitUntilDone:NO];
	}
	return YES;
}
- (BOOL) updateStatus: (NSString*) status
{
	if([NSThread isMainThread])
	{
		NSLog(@"%@", status);
		[statusLabel setStringValue:status];
	}
	else
	{
		[self performSelectorOnMainThread:@selector(updateStatus:) withObject: status waitUntilDone:NO];
	}
	
	return YES;
}


- (BOOL) installFinished
{
//	[installButton setEnabled:true];
	[progressBar setHidden:true];
	[progressBar startAnimation: self];
	
	[prepareButton setEnabled:true];
	
	installing = NO;
	
	NSAlert *alert = [[[NSAlert alloc] init] autorelease];
	[alert addButtonWithTitle:NSLocalizedString(@"OK", nil)];
	[alert setMessageText:NSLocalizedString(@"Done", nil)];
	[alert setInformativeText:NSLocalizedString(@"Your USB device has been prepared. You may now boot from it on your netbook.", nil)];
	[alert setAlertStyle:NSWarningAlertStyle];
	[alert beginSheetModalForWindow:[NSApp mainWindow] modalDelegate:self didEndSelector:nil contextInfo:nil];
	
	
	return YES;
	
}

- (BOOL) installFailed
{
//	[installButton setEnabled:true];
	[progressBar setHidden:true];
	[progressBar startAnimation: self];
	
	[prepareButton setEnabled:true];
	
	NSAlert *alert = [[[NSAlert alloc] init] autorelease];
	[alert addButtonWithTitle:NSLocalizedString(@"Continue", nil)];
	[alert setMessageText:NSLocalizedString(@"Installation Failed", nil)];
	[alert setInformativeText:NSLocalizedString(@"The installation failed. Please look at consol.app for more information about the failure.", nil)];
	[alert setAlertStyle:NSWarningAlertStyle];
	[alert beginSheetModalForWindow:[NSApp mainWindow] modalDelegate:nil didEndSelector:nil contextInfo:nil];
	
	installing = NO;
	
	return YES;
	
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
	if(installing) return NSTerminateCancel;
	else return NSTerminateNow;
}


@end
