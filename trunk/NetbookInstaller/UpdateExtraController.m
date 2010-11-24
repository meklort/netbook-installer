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
	[systemInfo setSourcePath: [[NSBundle mainBundle] resourcePath]];
	[systemInfo determineMachineType];
	[systemInfo determinePartitionFromPath:@"/"];
	
	[installer systemInfo: systemInfo];
	[installer setSourcePath: [[NSBundle mainBundle] resourcePath]];



	if(![installer getAuthRef]) 
	{
		[self performSelectorOnMainThread:@selector(installFailed) withObject: nil waitUntilDone:NO];
		[installer release];
		[systemInfo release];

		return NO;
	}
	

	[installer mountRamDisk];
	[installer generateExtensionsCache];
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
