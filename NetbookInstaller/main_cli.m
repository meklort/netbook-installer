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
	SystemInformation* systemInfo = [[SystemInformation alloc] init];
	Installer*	installer	= [[Installer alloc] init];

	[systemInfo setSourcePath: [[NSBundle mainBundle] resourcePath]];
	[installer setSourcePath: [[NSBundle mainBundle] resourcePath]];

	[systemInfo determineMachineType];
	
	ExtendedLog(@"Determine Install State");	
	if(argc > 1)
	{
		ExtendedLog(@"Determine partition from path");

		ExtendedLog(@"%s", argv[1]);
		[systemInfo determinePartitionFromPath: [[NSString alloc] initWithCString:argv[1] encoding: NSASCIIStringEncoding]];
	}
	else
	{
		[systemInfo determinePartitionFromPath: @"/"];
		
	}
	[systemInfo printStatus];

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
	[installer makeDir:[NSString stringWithFormat:@"%@/Extra/", [systemInfo installPath]]];	

	/// Time to actualy do the install
	[installer copyMachineFilesFrom: @"ExtraFiles/" toDir: @nbiExtrasPath];
	// Install and patch extensions
	
	[installer makeDir: [systemInfo extensionsFolder]];
	

	[installer copyMachineFilesFrom: @"DisplayProfiles/" toDir: @"/Library/ColorSync/Profiles/"];
	[installer copyMachineFilesFrom: @"3rdPartyPrefPanes/" toDir: @"/Library/PreferencePanes/"];
	[installer copyMachineFilesFrom: @"LaunchAgents/" toDir: @"/Library/LaunchAgents/"];
	[installer copyMachineFilesFrom: @"LaunchDaemons/" toDir: @"/Library/LaunchDaemons/"];
	[installer copyMachineFilesFrom: @"SystemConfiguration/" toDir: @"/System/Library/SystemConfiguration/"];		

	[installer installDSDT];
		

			
	if(strlen(argv[1]) == 1 && argv[1][0] == '/' && (argc == 1))
	{
		// preserve hibernation and quietboot settings
	}
	else
	{
		//[installer setQuietBoot:	YES];
		//[installer disableHibernation:	YES];
	}


	//	[installer setRemoteCD:			YES]; // This is not possilbe when running as root.
	
	// Install default bootlaoder
		
	// Install the gui
	
	//[installer copyDependencies];
	
	[installer installExtensions];
	[installer installLocalExtensions];
	
	//[installer patchGMAkext];
	//[installer patchFramebufferKext];
	//[installer patchIO80211kext];
	//[installer patchBluetooth];
	//[installer patchAppleUSBEHCI];
	[installer disableptmd];
	
	[installer generateExtensionsCache];
	
	[installer copyNBIImage];

	[installer installBootloader];

	[installer hideFiles];
	[installer unmountRamDisk];

	ExtendedLog(@"NetbookInstallerCLI Done");
	
	[pool release];
}
