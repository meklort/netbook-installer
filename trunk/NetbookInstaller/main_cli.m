//
//  main.m
//  NetbookInstaller
//
//  Created by Evan Lojewski on 5/18/09.
//  Copyright 2009-2010. All rights reserved.
//


#import <Cocoa/Cocoa.h>
#import "SystemInformation.h"
#import "Installer.h"

int main(int argc, char *argv[])
{	
	
	// TODO: make sure everything is realeased properly... (It's not)
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSDictionary* infoDict;
	SystemInformation* systemInfo = [[SystemInformation alloc] init];
	Installer*	installer	= [[Installer alloc] init];

	
	
	
	infoDict = [[NSBundle mainBundle] infoDictionary];
	ExtendedLog(@"Determine Install State");
	[systemInfo determineInstallState];
	
	
	if(argc > 1)
	{
		ExtendedLog(@"Determine partition from path");

		ExtendedLog(@"%s", argv[1]);
		[systemInfo determinePartitionFromPath: [[NSString alloc] initWithCString:argv[1] encoding: NSASCIIStringEncoding]];
		// Else we use the default of /
	}
	
	ExtendedLog(@"Initialize installer State");


	[installer systemInfo: systemInfo];

	if([systemInfo targetOS] < KERNEL_VERSION(10, 6, 0))	
	{
		ExtendedLog(@"Unsupported operating system target. Must be at least 10.6\n");
		exit(-1);
	}

	[installer mountRamDisk];	
	[installer remountTargetWithPermissions];
	[installer removePrevExtra];
	
	/// Time to actualy do the install
	[installer installExtraFiles];
	// Install and patch extensions
	
	[installer makeDir: [systemInfo extensionsFolder]];
	

	[installer installDisplayProfile];
	[installer installPrefPanes];
	[installer installLaunchAgents];
		
	[installer installSystemConfiguration];
		
	[installer installDSDT];
		

			
	if(strlen(argv[1]) == 1 && argv[1][0] == '/' && (argc == 1))
	{
		// preserve hibernation and quietboot settings
	}
	else {
		[installer setQuietBoot:	NO];
		[installer disableHibernation:	YES];
		[installer copyFrom:@"/Applications/NetbookInstaller.app" toDir:[[systemInfo installPath] stringByAppendingString:@"/Applications/"]];

	}


	//	[installer setRemoteCD:			YES]; // This is not possilbe when running as root.
	
	// Install default bootlaoder
		
	// Install the gui
	
	[installer copyDependencies];
	
	[installer installExtensions];
	[installer installLocalExtensions];
	
	[installer patchGMAkext];
	[installer patchFramebufferKext];
	[installer patchIO80211kext];
	[installer patchBluetooth];
	[installer patchAppleUSBEHCI];
	
	
	[installer generateExtensionsCache];
	[installer useSystemKernel];
	
	//[installer makeDir:[[systemInfo installPath] stringByAppendingString:@"/Extra/Applications"]];

	
	// If no bootloader, we dont want to overwrite the bootloder on a current install unless requested
	if(![systemInfo installedBootloader]) [installer installBootloader: 	[[[systemInfo bootloaderDict] objectForKey: @"Bootloaders"] objectForKey: [[systemInfo bootloaderDict] objectForKey:@"Default Bootloader"]]];

	[installer hideFiles];
	[installer unmountRamDisk];

	ExtendedLog(@"Done");
	
	[pool release];
}
