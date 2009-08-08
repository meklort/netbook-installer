//
//  UpdateExtraController.m
//  NetbookInstaller
//
//  Created by Evan Lojewski on 6/23/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "UpdateExtraController.h"


@implementation UpdateExtraController

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication {
	return YES;
}

- (IBAction) performInstall: (id) sender
{
	Installer* installer = [[Installer alloc] init];
	SystemInformation* systemInfo = [[SystemInformation alloc] init];

	
	[systemInfo determineInstallState];
	[installer systemInfo: systemInfo];


	if(![installer getAuthRef]) return;

	if([systemInfo targetOS] < KERNEL_VERSION(10, 5, 6))	// Less than Mac OS X 10.5.4
	{
		NSAlert *alert = [[[NSAlert alloc] init] autorelease];
		[alert addButtonWithTitle:NSLocalizedString(@"Continue", nil)];
		[alert setMessageText:NSLocalizedString(@"Unsupported Operating System", nil)];
		[alert setInformativeText:NSLocalizedString(@"You are running this applicaiton on an unsupported operating system. Please upgrade to Mac OS X 10.5.6 or later.", nil)];
		[alert setAlertStyle:NSWarningAlertStyle];
		[alert beginSheetModalForWindow:[NSApp mainWindow] modalDelegate:self didEndSelector:nil contextInfo:nil];
		
		
		
	} else
	{
		[installer copyDependencies];
		[installer generateExtensionsCache];
		[installer useSystemKernel];
	}	
	
	[installer release];
}


@end
