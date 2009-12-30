//
//  UpdateExtraController.m
//  NetbookInstaller
//
//  Created by Evan Lojewski on 6/23/09.
//  Copyright 2009. All rights reserved.
//

// TODO: verify that this software is running on supported hardware.

#import "UpdateExtraController.h"


@implementation UpdateExtraController

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication {
	return YES;
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
	if(installing) return NSTerminateCancel;
	else return NSTerminateNow;
}


- (IBAction) updateExtra:  (id) sender {
	installing = YES;	// Dissable applicaiton closing while it's doing stuff
	[installButton setEnabled:false];
	[progressBar setHidden:false];
	[progressBar startAnimation: sender];
	
	[NSThread detachNewThreadSelector:@selector(performThreadedInstall) toTarget: self withObject: nil];
	
	
	
	// TODO:  Force a restart if needed
	
	//[progressBar setHidden:true];
	//[progressBar stopAnimation: sender];
	
}


- (BOOL) performThreadedInstall
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];	

	
	[self performInstall:self];
	
	[self performSelectorOnMainThread:@selector(installFinished) withObject: nil waitUntilDone:NO];
	
	
	[pool release];
	
	return YES;
}

- (BOOL) performInstall: (id) sender
{
	Installer* installer = [[Installer alloc] init];
	SystemInformation* systemInfo = [[SystemInformation alloc] init];

	
	[systemInfo determineInstallState];
	[installer systemInfo: systemInfo];


	if(![installer getAuthRef]) 
	{
		[self performSelectorOnMainThread:@selector(installFailed) withObject: nil waitUntilDone:NO];
		[installer release];
		[systemInfo release];

		return NO;
	}
	

	[installer mountRamDisk];
	
//	if([systemInfo targetOS] < KERNEL_VERSION(10, 5, 6))	// Less than Mac OS X 10.5.4
//	{
//		NSAlert *alert = [[[NSAlert alloc] init] autorelease];
//		[alert addButtonWithTitle:NSLocalizedString(@"Continue", nil)];
//		[alert setMessageText:NSLocalizedString(@"Unsupported Operating System", nil)];
//		[alert setInformativeText:NSLocalizedString(@"You are running this applicaiton on an unsupported operating system. Please upgrade to Mac OS X 10.5.6 or later.", nil)];
//		[alert setAlertStyle:NSWarningAlertStyle];
//		[alert beginSheetModalForWindow:[NSApp mainWindow] modalDelegate:self didEndSelector:nil contextInfo:nil];
//		
//		
//		
//	} else
	{
		[installer copyDependencies];
		[installer generateExtensionsCache];
		[installer useSystemKernel];
	}	
	[installer unmountRamDisk];
	
	[installer release];
	return YES;
}

- (BOOL) installFinished
{
	[installButton setEnabled:true];
	[progressBar setHidden:true];
	[progressBar startAnimation: self];
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
	[installButton setEnabled:true];
	[progressBar setHidden:true];
	[progressBar startAnimation: self];

	
	NSAlert *alert = [[[NSAlert alloc] init] autorelease];
	[alert addButtonWithTitle:NSLocalizedString(@"Continue", nil)];
	[alert setMessageText:NSLocalizedString(@"Installation Failed", nil)];
	[alert setInformativeText:NSLocalizedString(@"The installation failed. Please look at consol.app for more information about the failure.", nil)];
	[alert setAlertStyle:NSWarningAlertStyle];
	[alert beginSheetModalForWindow:mainWindow modalDelegate:nil didEndSelector:nil contextInfo:nil];
	
	installing = NO;
	
	return YES;
	
}


@end
