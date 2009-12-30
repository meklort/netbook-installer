//
//  main.m
//  NetbookInstaller
//
//  Created by Evan Lojewski on 5/18/09.
//  Copyright 2009. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SystemInformation.h"
#import "Installer.h"
#import "main_bootmakercli.h"



@interface NetbookBootMakerCLI : NSObject
{
	Installer* installer;
}
- (NetbookBootMakerCLI*) initWithInstaller: (Installer*) install;
- (BOOL) patchUtilitMenu;
- (BOOL) patchOSInstall;
- (BOOL) removePostInstallError;

@end

@implementation NetbookBootMakerCLI

- (NetbookBootMakerCLI*) initWithInstaller: (Installer*) install
{
	[self init];
	installer = install;
	return self;
}

- (BOOL) patchUtilitMenu
{
	NSMutableArray* utilityMenu = [[NSMutableArray alloc] initWithContentsOfFile:@"/System/Installation/CDIS/Mac OS X Installer.app/Contents/Resources/InstallerMenuAdditions.plist"];
	NSMutableDictionary* netbookInstallerItem = [[NSMutableDictionary alloc] init];
	
	[netbookInstallerItem setObject:@"/Applications/NetbookInstaller.app" forKey:@"Path"];
	
	[utilityMenu removeObject:netbookInstallerItem];	/// Delete any previos, we *could* just no add it tooo (woulld be better)
	[utilityMenu insertObject:netbookInstallerItem atIndex:0];
	
	[utilityMenu writeToFile:@"/tmp/MenuItems/InstallerMenuAdditions.plist" atomically:NO];
		//[installer deleteFile:@"/System/Installation/CDIS/Mac OS X Installer.app/Contents/Resources/InstallerMenuAdditions.plist"];
		//	return [installer copyFrom:@"/tmp/InstallerMenuAdditions.plist" toDir:@"/tmp/MenuItems/"];
	return YES;
	
}

- (BOOL) patchOSInstall
{
	NSMutableArray* nsargs = [[NSMutableArray alloc] init];
		//NSMutableArray* nsargs2 = [[NSMutableArray alloc] init];
	NSMutableArray* nsargs3 = [[NSMutableArray alloc] init];
	
		// Expand the package
	[nsargs addObject: @"--expand"];	
	[nsargs addObject: @"/System/Installation/Packages/OSInstall.pkg"];
	[nsargs addObject: @"/tmp/OSInstall"];	
	[installer setPermissions:@"755" onPath:@"/tmp/OSInstall/Scripts/postinstall_actions/" recursivly:NO];

	[installer runCMD:"/System/Library/Frameworks/ApplicationServices.framework/Frameworks/CoreGraphics.framework/Resources/pkgutil" withArgs:nsargs];
	
		// Add NetbookInstallerCLI as a postinstaller script
	[installer copyFrom:[[[NSBundle mainBundle] resourcePath] stringByAppendingString: @"/bootMakerFiles/postinstall"] toDir:@"/tmp/OSInstall/Scripts/postinstall_actions/"];
	[installer setPermissions:@"755" onPath:@"/tmp/OSInstall/Scripts/postinstall_actions/" recursivly:YES];
		// Backup the origional file.
		//[installer moveFrom: @"/System/Installation/Packages/OSInstall.pkg" to: @"/System/Installation/Packages/OSInstall.pkg.orig"];
		// OS X's union fs doesn't work right on read only file systems, you *cannot* delete or move files, only overwrite them.
	
	
		// Create the patched package
	[nsargs3 addObject: @"--flatten"];	
	[nsargs3 addObject: @"/tmp/OSInstall/"];	
	[nsargs3 addObject: @"/tmp/Packages/OSInstall.pkg"];
	
		// TODO: determine cmd location via mount point for /dev/md0
	[installer runCMD:"/System/Library/Frameworks/ApplicationServices.framework/Frameworks/CoreGraphics.framework/Resources/pkgutil" withArgs:nsargs3];
	
	
	
	return YES;
}

- (BOOL) removePostInstallError
{
	[installer copyFrom:[[[NSBundle mainBundle] resourcePath] stringByAppendingString: @"/bless"] toDir:@"/tmp/bless/bless"];
	[installer copyFrom:[[[NSBundle mainBundle] resourcePath] stringByAppendingString: @"/bootMakerFiles/xxd"] toDir:@"/tmp/bless/"];
	return [[NSFileManager defaultManager] fileExistsAtPath:@"/tmp/bless/bless"];
}

@end

int main(int argc, char *argv[])
{	
	NSLog(@"NetbookBootMakerCLI: Patches read only root file systems.\n");
		// TODO: make sure everything is realeased properly... (It's not)
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	Installer* installer = [[Installer alloc] init];
	NetbookBootMakerCLI *cli = [[NetbookBootMakerCLI alloc] initWithInstaller: installer];
	SystemInformation* systemInfo = [[SystemInformation alloc] init];
	//NSFileHandle* unmountScript;
	NSString* packages;
	NSString* menuItems;
	NSString* bless;
	
	
		//UInt64 ramdiskSize;
	
	[systemInfo determineInstallState];
	[systemInfo determinePartitionFromPath: @"/"];
	[installer systemInfo: systemInfo];
	
	
	
	
	[installer mountRamDiskAt:@"/tmp/" withSize:(10 * 1024 * 1024) andOptions:@"union,owners"];
	packages =	[NSString stringWithString: [installer mountRamDiskAt:@"/tmp/Packages/" withSize:(10 * 1024 * 1024) andOptions:@"owners"]];
	menuItems =	[NSString stringWithString: [installer mountRamDiskAt:@"/tmp/MenuItems/" withSize:(10 * 1024 * 1024) andOptions:@"owners"]];
	bless =		[NSString stringWithString: [installer mountRamDiskAt:@"/tmp/bless/" withSize:(10 *1024 * 1024) andOptions:@"owners"]];

		// ramdiskSize = size of NetbookInstaller
	[installer mountRamDiskAt:@"/Applications/" withSize:(20 * 1024 * 1024) andOptions:@"union,owners"];
	[installer copyFrom:[[[NSBundle mainBundle] resourcePath] stringByAppendingString: @"/NetbookInstaller.app"] toDir:@"/Applications/"];
	[installer copyFrom:[[[NSBundle mainBundle] resourcePath] stringByAppendingString: @"/SupportFiles/"] toDir:@"/Applications/NetbookInstaller.app/Contents/Resources/SupportFiles/"];

	[cli patchUtilitMenu];
	
	if([systemInfo targetOS] < KERNEL_VERSION(10, 6, 0))	
	{
		NSLog(@"Unsupported operating system target. Must be at least 10.6, not patching installer\n");
	}
	else
	{
		[cli removePostInstallError];
		[cli patchOSInstall];
	}
	

	
	[installer remountDiskFrom: packages to: @"/System/Installation/Packages/"];
	[installer remountDiskFrom: menuItems to:@"/System/Installation/CDIS/Mac OS X Installer.app/Contents/Resources/"];
	[installer remountDiskFrom: bless to: @"/usr/sbin/"];

	// post install umount script.
	/*unmountScript = [NSFileHandle fileHandleForWritingAtPath: @"/tmp/unmount.sh"];
	NSMutableString fileString* = [[NSMutableString alloc] init];
	[fileString appendString:@"umount /usr/sbin/\n"];
	[fileString appendString:@"umount /System/Installation/CDIS/Mac OS X Installer.app/Contents/Resources/\n"];
	[fileString appendString:@"umount /System/Installation/Packages/\n"];
	[fileString appendString:@"umount /tmp/\n"];
	NSData* fileData = [[NSData alloc] initWithBytes:[fileString cString] length:[fileString length]];
	[unmountScript writeData:fileData];
	[unmountScript closeFile];
	[installer setPermissions:@"755" onPath:@"/tmp/unmount.sh" recursivly:NO];
	*/
	
	[pool release];
}





