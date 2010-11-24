//
//  NetbookInstallerController.m
//  NetbookInstaller
//
//  Created by Evan Lojewski on 5/15/09.
//  Copyright 2009-2010. All rights reserved.
//

#import "NetbookInstallerController.h"

@implementation NetbookInstallerController

/***
 ** awakeFromNib
 **		This function handles intializing the window before it is displayed. 
 **		It obtains the system info and sets the checkboxes and labels
 **
 ***/
- (void) awakeFromNib
{	
	// This is run whenever ANY nib file is loaded
	if(!initialized) [self initializeApplication];
}


- (IBAction) volumeChanged: (id) sender
{
//	ExtendedLog(@"Selected target: %@", [@"/Volumes/" stringByAppendingString:[[sender selectedItem] title]]);
	[systemInfo determinePartitionFromPath:[@"/Volumes/" stringByAppendingString:[[systemInfo installableVolumesWithKernel: MIN_VERSION] objectAtIndex:[targetVolume indexOfSelectedItem]]]];
 	[systemInfo printStatus];
}


- (void) initializeApplication
{
	NSDictionary* infoDict;
	systemInfo = [[SystemInformation alloc] init];
	appBundle = [NSBundle mainBundle];
	infoDict = [appBundle infoDictionary];
	NSNotificationCenter *notificationCenter = [[NSWorkspace sharedWorkspace] notificationCenter];
	
	[notificationCenter addObserver:self selector:@selector(mountChange:) name:NSWorkspaceDidMountNotification object:nil];
	[notificationCenter addObserver:self selector:@selector(mountChange:) name:NSWorkspaceDidUnmountNotification object:nil];
		
	[self updateVolumeMenu];

	
	
	// Set the version lable and window title (does not fully rebrand, but it's good enough)
	[mainWindow	  setTitle:		  [[infoDict objectForKey:@"CFBundleExecutable"] stringByAppendingFormat:@" %@", [infoDict objectForKey:@"CFBundleVersion"]]];	// Bundle Name would work as well
	 //[versionLabel setStringValue: [infoDict objectForKey:@"CFBundleVersion"]];
	
	// Initialize botloader dropdown
	

	 //[targetVolume setStringValue:[systemInfo bootPartition]];
}

/***
 ** isMachineSupported
 **		This function checks the system info class's machineType varaible 
 **		and insures that not only is it supported, but that the nessicary
 **		extensions exist.
 **
 ***/
- (BOOL) isMachineSupported
{
	if([[systemInfo getMachineString] isEqualToString:@"General"])
	{
		return NO;
	}
	else
	{
		return YES;
	}
}

/***
 ** applicationDidFinishLoading
 **		This function creates an alert if we are on an unsupported machine
 **		This is NOT in awake from nib because the alert cannot attach to the window
 **		when it isn't done being created / visible
 **
 ***/
- (void) applicationDidFinishLaunching:(id)application
{
	
	initialized = YES;
	if(![self isMachineSupported])
	{
		// Look into NSRunAlertPanel
		NSAlert *alert = [[[NSAlert alloc] init] autorelease];
		[alert addButtonWithTitle:NSLocalizedString(@"Continue", nil)];
		[alert addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
		[alert setMessageText:NSLocalizedString(@"Unsupported Device", nil)];
		[alert setInformativeText:NSLocalizedString(@"You are running this applicaiton on an unsupported device. Are you sure you want to continue?", nil)];
		[alert setAlertStyle:NSWarningAlertStyle];
		[alert beginSheetModalForWindow:mainWindow modalDelegate:self didEndSelector:@selector(unknownMachineAlert:returnCode:contextInfo:) contextInfo:nil];
	}
}

/***
 ** applicationShouldTerminateAfterLastWindowClosed
 **		This funciton tells Mac OS X to terminate the program when the windows close
 **
 ***/
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication
{
	return YES;
}


- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
	if(installing) return NSTerminateCancel;
	else return NSTerminateNow;
}

/***
 ** unknownMachineAlert
 **		This function handles the alert and exit's if the user selects cancel
 **
 ***/
- (void) unknownMachineAlert:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	if(returnCode == NSAlertSecondButtonReturn)
	{
		exit(-1);
	}
}

/***
 ** performInstall
 **		This function is called when the install button is pressed.
 **		It creates an installer and passes it needed information.
 **
 ***/
- (IBAction) performInstall:  (id) sender {
	if(![targetVolume selectedItem])
	{
		// do something, the install failed
		// TODO: Alert the user that the install failed
		NSAlert *alert = [[[NSAlert alloc] init] autorelease];
		[alert addButtonWithTitle:NSLocalizedString(@"Continue", nil)];
		[alert setMessageText:NSLocalizedString(@"Select a Target", nil)];
		[alert setInformativeText:NSLocalizedString(@"Please select a target volume to continue", nil)];
		[alert setAlertStyle:NSWarningAlertStyle];
		[alert beginSheetModalForWindow:mainWindow modalDelegate:nil didEndSelector:nil contextInfo:nil];
		return;
	}
	
	
	installing = YES;	// Dissable applicaiton closing while it's doing stuff
	[targetVolume setEnabled:false];
	[installButton setEnabled:false];
	[progressBar setHidden:false];
	[progressBar startAnimation: sender];
	
	NSString* target = [[systemInfo installableVolumesWithKernel: MIN_VERSION] objectAtIndex:[targetVolume indexOfSelectedItem]];
	if([self bootLoaderImagePath] && [systemInfo isInstallDVD:target])	
	{
		ExtendedLog(@"Install DVD detected");
		[NSThread detachNewThreadSelector:@selector(performThreadedBootdiskCreation) toTarget: self withObject: nil];
		
	}
	else
	{	
		ExtendedLog(@"Full Install detected");

		[NSThread detachNewThreadSelector:@selector(performThreadedInstall) toTarget: self withObject: nil];
		
	}
}

/***
 ** openAboutWindows
 **		This opens the about window by loading the about nib.
 **		The check is very simple and could (should) be much better / fixed
 **
 ***/
- (IBAction) openAboutWindow: (id) sender
{
	NSArray* windows;
	// TODO: Fix the check to ensure it really is not open
	
	// Check to make sure only one (the main window) exists.
	// Since there are only two possible windows (main + about), this is acceptable
	//if([[NSApp windows] count] < 2) [NSBundle loadNibNamed:@"about" owner:self];
	
	
	// Use
	
	int i = 0;
	windows = [NSApp windows];
	while(i < [windows count])
	{
		if([windows objectAtIndex:i]  && [[[windows objectAtIndex:i] title] isEqualToString:@"About"]) return;
		i++;
	}
	[NSBundle loadNibNamed:@"about" owner:self];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
	[systemInfo release];
}


- (void) setProgress: (double) progress
{
	[progressBar setDoubleValue:progress];
}



- (BOOL) updateProgressBar: (NSNumber*) percent
{
	[progressBar incrementBy: [percent intValue]];
	return YES;
}
- (BOOL) updateStatus: (NSString*) status
{
	ExtendedLog(@"%@", status);
	[statusLabel setStringValue:status];		
	return YES;
}	



- (void) updateVolumeMenu
{
	NSMutableArray* options = [[NSMutableArray alloc] initWithArray:[systemInfo installableVolumesWithKernel: MIN_VERSION]];	// Any Leopard and beyond  (0.0.0 = no kernel required)

	int i = 0;
	while(i < [options count])
	{
		if([self bootLoaderImagePath] != nil)
		{
			if([systemInfo isInstallDVD: [options objectAtIndex:i]])
			{
				[options replaceObjectAtIndex:i withObject:[[options objectAtIndex:i] stringByAppendingString:@" (Create Booter)"]];
			}
			else
			{
				[options replaceObjectAtIndex:i withObject:[[options objectAtIndex:i] stringByAppendingString:@" (Update Install)"]];
				
			}
		}
		else if(![systemInfo isInstallDVD: [options objectAtIndex:i]])
		{
			[options replaceObjectAtIndex:i withObject:[options objectAtIndex:i]];	
		}
		
		i++;
	}

	//	NSMutableArray* newOptions;
	
	NSMenuItem* current = [targetVolume selectedItem];
	
	[targetVolume removeAllItems];
	[targetVolume addItemsWithTitles:options];
	if([options count] == 1)
	{
		[targetVolume selectItemWithTitle:[options lastObject]];
		//	ExtendedLog(@"Selected target: %@", [@"/Volumes/" stringByAppendingString:[[targetVolume selectedItem] title]]);
		[systemInfo determinePartitionFromPath:[@"/Volumes/" stringByAppendingString:[[systemInfo installableVolumesWithKernel: MIN_VERSION] objectAtIndex:[targetVolume indexOfSelectedItem]]]];		
		// TODO: enable this
		[systemInfo printStatus];

	}
	else if(current)
	{
		[targetVolume selectItemWithTitle:[current title]];
	}
	
}

- (BOOL) installFinished
{
	[targetVolume setEnabled:true];
	[installButton setEnabled:true];
	[progressBar setHidden:true];
	[progressBar startAnimation: self];
	[self setProgress:0];	
	installing = NO;
	
	NSAlert *alert = [[[NSAlert alloc] init] autorelease];
	[alert addButtonWithTitle:NSLocalizedString(@"Continue", nil)];
	[alert setMessageText:NSLocalizedString(@"Installation Complete", nil)];
	[alert setInformativeText:NSLocalizedString(@"The installation Completed successfully.", nil)];
	[alert setAlertStyle:NSWarningAlertStyle];
	[alert beginSheetModalForWindow:mainWindow modalDelegate:nil didEndSelector:nil contextInfo:nil];
	

	return YES;
	
}

- (BOOL) installFailed
{
	[targetVolume setEnabled:true];
	[installButton setEnabled:true];
	[progressBar setHidden:true];
	[progressBar startAnimation: self];
	[self setProgress:0];	

	
	NSAlert *alert = [[[NSAlert alloc] init] autorelease];
	[alert addButtonWithTitle:NSLocalizedString(@"Continue", nil)];
	[alert setMessageText:NSLocalizedString(@"Installation Failed", nil)];
	[alert setInformativeText:NSLocalizedString(@"The installation failed. Please look at consol.app for more information about the failure.", nil)];
	[alert setAlertStyle:NSWarningAlertStyle];
	[alert beginSheetModalForWindow:mainWindow modalDelegate:nil didEndSelector:nil contextInfo:nil];

	installing = NO;
	
	return YES;
	
}

- (void) mountChange:(NSNotification *)notification 
{
	[self updateVolumeMenu];
	// TOOD: update the volume list.
	//NSString *devicePath = [[notification userInfo] objectForKey:@"NSDevicePath"];
	
	
//	ExtendedLog(@"Device did mount: %@", devicePath);
}

- (BOOL) performThreadedBootdiskCreation
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	NSString* target = [[systemInfo installableVolumesWithKernel: MIN_VERSION] objectAtIndex:[targetVolume indexOfSelectedItem]];
	ExtendedLog(@"Boot image path: %@", [self bootLoaderImagePath]);
	ExtendedLog(@"Drive: %@", [@"/Volumes/" stringByAppendingString:target]);
	if(![self installBootdisk: [self bootLoaderImagePath] toDrive: [@"/Volumes/" stringByAppendingString:target]])
	{
		[self performSelectorOnMainThread:@selector(installFailed) withObject: nil waitUntilDone:NO];
		[pool release];
		return NO;
	}
	
	[self performSelectorOnMainThread:@selector(installFinished) withObject: nil waitUntilDone:NO];
	[pool release];
	return YES;
}


- (BOOL) installBootdisk: (NSString*) image toDrive: (NSString*) drive
{
	NSMutableArray* nsargs;
	Installer* installer = [[Installer alloc] init];
	[installer systemInfo: systemInfo];
	[installer setSourcePath: [[NSBundle mainBundle] resourcePath]];
	[systemInfo setSourcePath: [[NSBundle mainBundle] resourcePath]];

	if(!image || ![installer getAuthRef])
	{
		return NO;
	}
	//	ExtendedLog("installBootDisk: %@ toDrive %@", image, drive);

	[systemInfo determineMachineType];

	
	NSScanner* scanner = [[NSScanner alloc] initWithString:[systemInfo bootPartition]];
	[scanner setCharactersToBeSkipped: [[NSCharacterSet decimalDigitCharacterSet] invertedSet]];
	[scanner setCharactersToBeSkipped: [[NSCharacterSet decimalDigitCharacterSet] invertedSet]];
	/*if([systemInfo hostOS] < KERNEL_VERSION(10,5,0))
	{
		[scanner scanInt:NULL];			// TODO: use scanInt on 10.4
	}
	else
	{
		[scanner scanInteger: NULL];	// scan past disk number
	}
	*/
	[scanner scanInt:NULL];			// scan past disk number

	NSString* bsdDisk = [[systemInfo bootPartition] substringToIndex:[scanner scanLocation]];		// strip off partition number
	
	[self updateStatus:@"Installing..."];
	
	// Image volume name is "NetbookBootLoader", unmount it if it exists
	nsargs = [[NSMutableArray alloc] initWithObjects:@"-f", @"/Volumes/NetbookBootLoader", nil];
	[installer runCMD:"/sbin/umount" withArgs:nsargs];
	[nsargs release];
	
	[self updateProgressBar: [NSNumber numberWithInt: 10]];
	
	// Install bootloader
	[self updateStatus:@"Installing Bootloader (boot0)"];
	
	nsargs = [[NSMutableArray alloc] init];
	
	[nsargs addObject: @"-f"];
	[nsargs addObject: [[[NSBundle mainBundle] resourcePath] stringByAppendingString: @"/BootMakerSupport/boot0"]];
	[nsargs addObject: @"-u"];
	[nsargs addObject: @"-y"];
	
	[nsargs addObject:[@"/dev/r" stringByAppendingString: bsdDisk]];
	
	ExtendedLog(@"Installing boot0 to /dev/r%@", bsdDisk);
	[installer runCMD:"/usr/sbin/fdisk" withArgs:nsargs];		// Lets not overwrite the disk bootsect, we really don't need it anyways since we set thepartition as active	
	[nsargs release];
	[self updateProgressBar: [NSNumber numberWithInt: 10]];
	
	[self updateStatus:@"Installing Bootloader (boot1h)"];
	
	// Install boot1h using dd
	nsargs = [[NSMutableArray alloc] init];
	[nsargs addObject:[@"if=" stringByAppendingString:[[[NSBundle mainBundle] resourcePath] stringByAppendingString: @"/BootMakerSupport/boot1h"]]];
	[nsargs addObject:[@"of=/dev/r" stringByAppendingString: [systemInfo bootPartition]]];
	[installer runCMD:"/bin/dd" withArgs:nsargs];
	[nsargs release];
	[self updateProgressBar: [NSNumber numberWithInt: 10]];
	
	
	[self updateStatus:@"Mounting Installer Image"];
	
	
	
	// Mount the Installer Image
	nsargs = [[NSArray alloc] initWithObjects:@"mount", image, nil];
	[installer runCMD:"/usr/bin/hdiutil" withArgs:nsargs];
	[nsargs release];
	[self updateProgressBar: [NSNumber numberWithInt: 5]];
	
	[self updateStatus:@"Installing bootloader (boot)"];
	
	// Copy in /Extra and /boot from the installer image
	[installer copyFrom:@"/Volumes/NetbookBootLoader/boot" toDir:[NSString stringWithFormat:@"%@/boot", drive]];
	[self updateProgressBar: [NSNumber numberWithInt: 10]];
	
	[self updateStatus:@"Installing Extra"];
	[installer copyFrom:[NSString stringWithFormat:@"%@/Extra", drive] toDir:[NSString stringWithFormat:@"%@/Extra.bak", drive]];
	[installer deleteFile:[NSString stringWithFormat:@"%@/Extra/", drive]];
	[installer makeDir:[NSString stringWithFormat:@"%@/Extra/", drive]];	
	// Preserve AdditionalExtensions, just in case
	[installer copyFrom:[NSString stringWithFormat:@"%@/Extra.bak/AdditionalExtensions", drive] toDir:[NSString stringWithFormat:@"%@/Extra/", drive]];
	[self updateProgressBar: [NSNumber numberWithInt: 15]];

	[installer copyFrom:@"/Volumes/NetbookBootLoader/Extra" toDir:[NSString stringWithFormat:@"%@/", drive]];
	[installer hideFiles];
	[self updateProgressBar: [NSNumber numberWithInt: 25]];
	
	
	[self updateStatus:@"Cleaning up..."];
	
	
	// Unmount the installer image, then we are done
	nsargs = [[NSMutableArray alloc] initWithObjects:@"-f", @"/Volumes/NetbookBootLoader", nil];
	[installer runCMD:"/sbin/umount" withArgs:nsargs];
	[nsargs release];
	[self updateProgressBar: [NSNumber numberWithInt: 30]];
	[self updateStatus:@"Done"];
	
	return YES;
}


- (BOOL) performThreadedInstall
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	Installer* installer = [[Installer alloc] init];
	[installer systemInfo: systemInfo];
	//systemInfo = sysInfo;
	
	if(![installer getAuthRef]) 
	{
		[self performSelectorOnMainThread:@selector(installFailed) withObject: nil waitUntilDone:NO];
		[pool release];
		return NO;
	}
	
	if([self bootLoaderImagePath])
	{
		// Cleanup if something is already mounted here.
		NSMutableArray* nsargs;
		nsargs = [[NSMutableArray alloc] initWithObjects:@"-f", @"/Volumes/Postboot", nil];
		[installer runCMD:"/sbin/umount" withArgs:nsargs];
		[nsargs release];
				
		nsargs = [[NSMutableArray alloc] initWithObjects:@"-f", @"/Volumes/NetbookBootLoader", nil];
		[installer runCMD:"/sbin/umount" withArgs:nsargs];
		[nsargs release];
		
		[self updateStatus:@"Mounting Installer Image"];
		// Mount the Installer Image
		nsargs = [[NSArray alloc] initWithObjects:@"mount", [self bootLoaderImagePath], @"-readonly", nil];
		[installer runCMD:"/usr/bin/hdiutil" withArgs:nsargs];
		[nsargs release];
		
		nsargs = [[NSArray alloc] initWithObjects:@"mount", @"/Volumes/NetbookBootLoader/Extra/Postboot.img", @"-readonly", nil];
		[installer runCMD:"/usr/bin/hdiutil" withArgs:nsargs];
		[nsargs release];
				
		[installer setSourcePath: @"/Volumes/Postboot/NetbookInstaller.app/Contents/Resources/"];
		[systemInfo setSourcePath: @"/Volumes/Postboot/NetbookInstaller.app/Contents/Resources/"];
	}
	else
	{
		[installer setSourcePath: [[NSBundle mainBundle] resourcePath]];
		[systemInfo setSourcePath: [[NSBundle mainBundle] resourcePath]];
	}
	[systemInfo determineMachineType];
	
	[self performSelectorOnMainThread:@selector(updateStatus:) withObject: NSLocalizedString(@"Remounting target", nil) waitUntilDone:NO];
	[installer remountTargetWithPermissions];
	[self performSelectorOnMainThread:@selector(updateProgressBar:) withObject: [NSNumber numberWithInt: 0] waitUntilDone:NO];

	
	[self performSelectorOnMainThread:@selector(updateStatus:) withObject: NSLocalizedString(@"Creating ramdisk", nil) waitUntilDone:NO];
	[installer mountRamDisk];
	[self performSelectorOnMainThread:@selector(updateProgressBar:) withObject: [NSNumber numberWithInt: 7] waitUntilDone:NO];
		
	//[self copyFrom:[[[[NSBundle mainBundle] resourcePath] stringByAppendingString: @"/SupportFiles/machine/General/ExtraFiles//UpdateExtra.app"] toDir:[[systemInfo installPath] stringByAppendingString: @"/Extra/"]];
	
	[self performSelectorOnMainThread:@selector(updateProgressBar:) withObject: [NSNumber numberWithInt: 0] waitUntilDone:NO];
	[self performSelectorOnMainThread:@selector(updateStatus:) withObject: NSLocalizedString(@"Creating /Extra", nil) waitUntilDone:NO];

	[installer removePrevExtra];
	//[installer installExtraFiles];
	[self performSelectorOnMainThread:@selector(updateProgressBar:) withObject: [NSNumber numberWithInt: 3] waitUntilDone:NO];
	
	
	[self performSelectorOnMainThread:@selector(updateStatus:) withObject: NSLocalizedString(@"Installing Display Profiles", nil) waitUntilDone:NO];
	[installer copyMachineFilesFrom: @"DisplayProfiles/" toDir: @"/Library/ColorSync/Profiles/"];
	[self performSelectorOnMainThread:@selector(updateProgressBar:) withObject: [NSNumber numberWithInt: 1] waitUntilDone:NO];
	
	[self performSelectorOnMainThread:@selector(updateStatus:) withObject: NSLocalizedString(@"Installing Preference Panes", nil) waitUntilDone:NO];
	[installer copyMachineFilesFrom: @"3rdPartyPrefPanes/" toDir: @"/Library/PreferencePanes/"];
	[installer copyMachineFilesFrom: @"LaunchAgents/" toDir: @"/Library/LaunchAgents/"];
	[installer copyMachineFilesFrom: @"LaunchDaemons/" toDir: @"/Library/LaunchDaemons/"];
	[self performSelectorOnMainThread:@selector(updateProgressBar:) withObject: [NSNumber numberWithInt: 1] waitUntilDone:NO];
	
	//[self performSelectorOnMainThread:@selector(updateStatus:) withObject: NSLocalizedString(@"Instaling Power Managment bundle", nil) waitUntilDone:NO];
	//[installer copyMachineFilesFrom: @"SystemConfiguration/" toDir: @"/System/Library/SystemConfiguration/"];
	//[self performSelectorOnMainThread:@selector(updateProgressBar:) withObject: [NSNumber numberWithInt: 1] waitUntilDone:NO];
	
	[self performSelectorOnMainThread:@selector(updateStatus:) withObject: NSLocalizedString(@"Regenerating DSDT.aml", nil) waitUntilDone:NO];
	//if([self regenerateDSDT]) 
	[installer installDSDT]; // modifed version of chameleon ensures origional dsdt is available.
	[self performSelectorOnMainThread:@selector(updateProgressBar:) withObject: [NSNumber numberWithInt: 1] waitUntilDone:NO];
	
	
	
	
	//[self makeDir:@"/Volumes/ramdisk/Extensions"];
	//[self performSelectorOnMainThread:@selector(updateStatus:) withObject: NSLocalizedString(@"Copying Dependencies", nil) waitUntilDone:NO];
	//[installer copyDependencies];
	//[self performSelectorOnMainThread:@selector(updateProgressBar:) withObject: [NSNumber numberWithInt: 5] waitUntilDone:NO];
	
	[self performSelectorOnMainThread:@selector(updateStatus:) withObject: NSLocalizedString(@"Installing Extensions", nil) waitUntilDone:NO];
	[installer installExtensions];
	[installer installLocalExtensions];
	[self performSelectorOnMainThread:@selector(updateProgressBar:) withObject: [NSNumber numberWithInt: 14] waitUntilDone:NO];
	
	//[self performSelectorOnMainThread:@selector(updateStatus:) withObject: NSLocalizedString(@"Patching GMA950 Extension", nil) waitUntilDone:NO];
	//[installer patchGMAkext];
	//[self performSelectorOnMainThread:@selector(updateProgressBar:) withObject: [NSNumber numberWithInt: 5] waitUntilDone:NO];
	
	//[self performSelectorOnMainThread:@selector(updateStatus:) withObject: NSLocalizedString(@"Patching Framebuffer Extension", nil) waitUntilDone:NO];
	//[installer patchFramebufferKext];
	//[self performSelectorOnMainThread:@selector(updateProgressBar:) withObject: [NSNumber numberWithInt: 5] waitUntilDone:NO];
	
	//[self performSelectorOnMainThread:@selector(updateStatus:) withObject: NSLocalizedString(@"Patching Wireless Extension", nil) waitUntilDone:NO];
	//[installer patchIO80211kext];
	//[self performSelectorOnMainThread:@selector(updateProgressBar:) withObject: [NSNumber numberWithInt: 5] waitUntilDone:NO];
	
	//[self performSelectorOnMainThread:@selector(updateStatus:) withObject: NSLocalizedString(@"Patching Bluetooth", nil) waitUntilDone:NO];
	//[installer patchBluetooth];
	//[self performSelectorOnMainThread:@selector(updateProgressBar:) withObject: [NSNumber numberWithInt: 5] waitUntilDone:NO];
	
	//[self performSelectorOnMainThread:@selector(updateStatus:) withObject: NSLocalizedString(@"Patching USB", nil) waitUntilDone:NO];
	//[installer patchAppleUSBEHCI];
	//[installer patchAppleHDA];
	
	[self performSelectorOnMainThread:@selector(updateStatus:) withObject: NSLocalizedString(@"Generating Extension Caches", nil) waitUntilDone:NO];
	[installer generateExtensionsCache];
	//[installer useSystemKernel];

	[self performSelectorOnMainThread:@selector(updateStatus:) withObject: NSLocalizedString(@"Verifying Quiet Boot state", nil) waitUntilDone:NO];
	[installer setQuietBoot: YES];
	
	
	[self performSelectorOnMainThread:@selector(updateStatus:) withObject: NSLocalizedString(@"Verifying Hibernation state", nil) waitUntilDone:NO];
	[installer disableHibernation: YES];
	
	[self performSelectorOnMainThread:@selector(updateStatus:) withObject: NSLocalizedString(@"Verifying RemoteCD State", nil) waitUntilDone:NO];
	[installer setRemoteCD:YES];
	
	[self performSelectorOnMainThread:@selector(updateProgressBar:) withObject: [NSNumber numberWithInt: 5] waitUntilDone:NO];
	
	[self performSelectorOnMainThread:@selector(updateStatus:) withObject: NSLocalizedString(@"Verifying Bootloader", nil) waitUntilDone:NO];
	ExtendedLog(@"Installing bootloader");
	[installer installBootloader];
	[self performSelectorOnMainThread:@selector(updateProgressBar:) withObject: [NSNumber numberWithInt: 10] waitUntilDone:NO];
	
	[installer disableptmd];

	[installer copyNBIImage];
	
	[installer hideFiles];

	
	//if([self fixBluetooth]) [installer fixBluetooth];
	[self performSelectorOnMainThread:@selector(updateProgressBar:) withObject: [NSNumber numberWithInt: 30] waitUntilDone:NO];
	
	[installer unmountRamDisk];

	
	// Cleanup.
	if([self bootLoaderImagePath])
	{
		[installer copyFrom:@"/Volumes/NetbookBootLoader/Extra/Postboot.img" toDir:@"/Extra/NetbookInstaller.img"];
		
		NSMutableArray* nsargs;
		nsargs = [[NSMutableArray alloc] initWithObjects:@"-f", @"/Volumes/Postboot", nil];
		[installer runCMD:"/sbin/umount" withArgs:nsargs];
		[nsargs release];
				
		nsargs = [[NSMutableArray alloc] initWithObjects:@"-f", @"/Volumes/NetbookBootLoader", nil];
		[installer runCMD:"/sbin/umount" withArgs:nsargs];
		[nsargs release];		
	}	
	
	
	[installer release];

	[self performSelectorOnMainThread:@selector(updateStatus:) withObject: NSLocalizedString(@"Done", nil) waitUntilDone:NO];
	[self performSelectorOnMainThread:@selector(installFinished) withObject: nil waitUntilDone:NO];
	
	
	[pool release];
	
	return YES;
}

- (NSString*) bootLoaderImagePath
{
	NSString* image = [[[NSBundle mainBundle] resourcePath] stringByAppendingString: @"/BootMakerSupport/NetbookBootLoader.img"];
	if(![[NSFileManager defaultManager] fileExistsAtPath: image])
	{
		//ExtendedLog(@"Unable to locate %@", image);
		return nil;
	}
	else
	{
		return image;
	}
}


@end
