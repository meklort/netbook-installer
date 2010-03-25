//
//  NetbookBootMakerController.m
//  NetbookInstaller
//
//  Created by Evan Lojewski on 6/20/09.
//  Copyright 2009-2010. All rights reserved.
//

#import "NetbookBootMakerController.h"

@implementation NetbookBootMakerController

- (void) awakeFromNib {	
	// Listen for dvds being mounted
	NSNotificationCenter *notificationCenter = [[NSWorkspace sharedWorkspace] notificationCenter];
	[notificationCenter addObserver:self selector:@selector(mountChange:) name:NSWorkspaceDidMountNotification object:nil];
	[notificationCenter addObserver:self selector:@selector(mountChange:) name:NSWorkspaceDidUnmountNotification object:nil];

	installer = [[Installer alloc] init];
	systemInfo = [[SystemInformation alloc] init];
	installing = false;

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
	NSError *err = [NSError alloc];
	// TODO: do some error checking to verify that that volume actualy exists.
	return [[NSFileManager defaultManager] contentsOfDirectoryAtPath:@"/Volumes" error:&err];
}

- (void) updateVolumeMenu
{
	NSArray* options = [systemInfo installableVolumesWithKernel: MIN_VERSION andInstallDVD: YES];	// Any Leopard and beyond  (0.0.0 = no kernel required)
//	NSMutableArray* newOptions;
	
	NSMenuItem* current = [volumeList selectedItem];
	
	[volumeList removeAllItems];
	[volumeList addItemsWithTitles:options];
	if([options count] == 1)
	{
		[volumeList selectItemWithTitle:[options lastObject]];
	}
	else if(current)
	{
		[volumeList selectItemWithTitle:[current title]];
	}
	
	
	
}
- (void) patchUSBDrive
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	if(![installer getAuthRef]) 
	{
		[self performSelectorOnMainThread:@selector(installFailed) withObject: nil waitUntilDone:NO];
		[pool release];

		return;
	}

	[systemInfo determinePartitionFromPath:[@"/Volumes/" stringByAppendingString:[volumeList titleOfSelectedItem]]];
	 [installer systemInfo: systemInfo];

	if(![self installBootlaoder: [[[NSBundle mainBundle] resourcePath] stringByAppendingString: @"/BootMakerSupport/NetbookBootLoader.img"] toDrive: [@"/Volumes/" stringByAppendingString:[volumeList titleOfSelectedItem]]])
	{
		[self performSelectorOnMainThread:@selector(installFailed) withObject: nil waitUntilDone:NO];
		[pool release];
		return;
	}
	
	[self performSelectorOnMainThread:@selector(installFinished) withObject: nil waitUntilDone:NO];


	[pool release];
}

- (BOOL) installBootlaoder: (NSString*) image toDrive: (NSString*) drive
{
	NSMutableArray* nsargs;
	
	if(![[NSFileManager defaultManager] fileExistsAtPath: image]) return NO;
	
	NSScanner* scanner = [[NSScanner alloc] initWithString:[systemInfo bootPartition]];
	[scanner setCharactersToBeSkipped: [[NSCharacterSet decimalDigitCharacterSet] invertedSet]];
	[scanner scanInteger: NULL];	// scan past disk number
	
	NSString* bsdDisk = [[systemInfo bootPartition] substringToIndex:[scanner scanLocation]];		// strip off partition number

	[self updateStatus:@"Installer..."];

	// Image volume name is "NetbookBootLoader", unmount it if it exists
	nsargs = [[NSMutableArray alloc] initWithObjects:@"-f", @"/Volumes/NetbookBootLoader", nil];
	[installer runCMD:"/sbin/umount" withArgs:nsargs];
	[nsargs release];
	
	[self updatePorgressBar: [NSNumber numberWithInt: 10]];
	
	// Install bootloader
	[self updateStatus:@"Installing Bootloader (boot0)"];

	nsargs = [[NSMutableArray alloc] init];
	
	[nsargs addObject: @"-f"];
	[nsargs addObject: [[[NSBundle mainBundle] resourcePath] stringByAppendingString: @"/BootMakerSupport/boot0"]];
	[nsargs addObject: @"-u"];
	[nsargs addObject: @"-y"];
	
	[nsargs addObject:[@"/dev/r" stringByAppendingString: bsdDisk]];
	[installer runCMD:"/usr/sbin/fdisk" withArgs:nsargs];		// Lets not overwrite the disk bootsect, we really don't need it anyways since we set thepartition as active	
	[nsargs release];
	[self updatePorgressBar: [NSNumber numberWithInt: 10]];

	[self updateStatus:@"Installing Bootloader (boot1h)"];

	// Install boot1h using dd
	nsargs = [[NSMutableArray alloc] init];
	[nsargs addObject:[@"if=" stringByAppendingString:[[[NSBundle mainBundle] resourcePath] stringByAppendingString: @"/BootMakerSupport/boot1h"]]];
	[nsargs addObject:[@"of=/dev/r" stringByAppendingString: [systemInfo bootPartition]]];
	[installer runCMD:"/bin/dd" withArgs:nsargs];
	[nsargs release];
	[self updatePorgressBar: [NSNumber numberWithInt: 10]];

	
	[self updateStatus:@"Mounting Installer Image"];

	
	
	// Mount the Installer Image
	nsargs = [[NSArray alloc] initWithObjects:@"mount", image, nil];
	[installer runCMD:"/usr/bin/hdiutil" withArgs:nsargs];
	[nsargs release];
	[self updatePorgressBar: [NSNumber numberWithInt: 5]];

	[self updateStatus:@"Installing bootloader (boot)"];

	// Copy in /Extra and /boot from the installer image
	[installer copyFrom:@"/Volumes/NetbookBootLoader/boot" toDir:[NSString stringWithFormat:@"%@/boot", drive]];
	[self updatePorgressBar: [NSNumber numberWithInt: 10]];
	
	[self updateStatus:@"Installing Extra"];


	[installer copyFrom:@"/Volumes/NetbookBootLoader/Extra" toDir:[NSString stringWithFormat:@"%@/", drive]];
	[installer hideFiles];
	[self updatePorgressBar: [NSNumber numberWithInt: 35]];

	[self updateStatus:@"Cleaning up..."];

	 
	// Unmount the installer image, then we are done
	nsargs = [[NSMutableArray alloc] initWithObjects:@"-f", @"/Volumes/NetbookBootLoader", nil];
	[installer runCMD:"/sbin/umount" withArgs:nsargs];
	[nsargs release];
	[self updatePorgressBar: [NSNumber numberWithInt: 30]];
	[self updateStatus:@"Done"];

	
	
	

	
	return YES;
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
		ExtendedLog(@"%@", status);
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


- (void) mountChange:(NSNotification *)notification 
{
	[self updateVolumeMenu];
	// TOOD: update the volume list.
	//NSString *devicePath = [[notification userInfo] objectForKey:@"NSDevicePath"];
	
	
	//	ExtendedLog(@"Device did mount: %@", devicePath);
}



@end
