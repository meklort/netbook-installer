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
	[installer copyFrom:[[[NSBundle mainBundle] resourcePath] stringByAppendingString: @"/bootMakerFiles/xxd"] toDir:@"/tmp/xxd/xxd"];

	return [[NSFileManager defaultManager] fileExistsAtPath:@"/tmp/bless/bless"] & [[NSFileManager defaultManager] fileExistsAtPath:@"/tmp/xxd/xxd"];
	
}

@end

int main(int argc, char *argv[])
{	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	ExtendedLog(@"NetbookBootMakerCLI: Patches read only root file systems.\n");
	BOOL isDir = NO;
	if(!([[NSFileManager defaultManager] fileExistsAtPath:@"/System/Installation/" isDirectory:&isDir]) && !isDir)
	{
		// We are NOT on an Install DVD, exit out.
		ExtendedLog(@"NetbookBootMakerCLI: Not on an Install DVD, exiting.\n");
		exit(0);
	}
	
		// TODO: make sure everything is realeased properly... (It's not)
	Installer* installer = [[Installer alloc] init];
	NetbookBootMakerCLI *cli = [[NetbookBootMakerCLI alloc] initWithInstaller: installer];
	SystemInformation* systemInfo = [[SystemInformation alloc] init];
	//NSFileHandle* unmountScript;
	NSString* packages;
	NSString* menuItems;
	NSString* bless;
	NSString* xxd;
	
	
		//UInt64 ramdiskSize;
	
	[systemInfo determineInstallState];
	[systemInfo determinePartitionFromPath: @"/"];
	[installer systemInfo: systemInfo];
	

	
	
	
	[installer mountRamDiskAt:@"/tmp/" withName: @"NBITemp" andSize:(10 * 1024 * 1024) andOptions:@"union,owners"];
	packages =	[NSString stringWithString: [installer mountRamDiskAt:@"/tmp/Packages/" withName: @"Packages" andSize:(10 * 1024 * 1024) andOptions:@"owners"]];
	menuItems =	[NSString stringWithString: [installer mountRamDiskAt:@"/tmp/MenuItems/" withName: @"MenuItems" andSize:(10 * 1024 * 1024) andOptions:@"owners"]];
	bless =		[NSString stringWithString: [installer mountRamDiskAt:@"/tmp/bless/" withName: @"Bless" andSize:(10 *1024 * 1024) andOptions:@"owners"]];
	xxd =		[NSString stringWithString: [installer mountRamDiskAt:@"/tmp/xxd/" withName: @"dsdtHelper" andSize:(10 *1024 * 1024) andOptions:@"owners"]];

		// ramdiskSize = size of NetbookInstaller
	[installer mountRamDiskAt:@"/Applications/" withName: @"NBIApplication" andSize:(64 * 1024 * 1024) andOptions:@"union,owners"];
	[installer copyFrom:[[[NSBundle mainBundle] resourcePath] stringByAppendingString: @"/NetbookInstaller.app"] toDir:@"/Applications/"];
	[installer copyFrom:[[[NSBundle mainBundle] resourcePath] stringByAppendingString: @"/SupportFiles/"] toDir:@"/Applications/NetbookInstaller.app/Contents/Resources/SupportFiles/"];

	[cli patchUtilitMenu];
	
	if([systemInfo targetOS] < KERNEL_VERSION(10, 6, 0))	
	{
		ExtendedLog(@"Unsupported operating system target. Must be at least Mac OS X Snow Leoaprd.\n");
		[cli removePostInstallError];
		[installer remountDiskFrom: menuItems to:@"/System/Installation/CDIS/Mac OS X Installer.app/Contents/Resources/"];
		[installer remountDiskFrom: xxd to: @"/usr/bin/"];
	}
	else
	{
		[cli removePostInstallError];
		[cli patchOSInstall];
		[installer remountDiskFrom: menuItems to:@"/System/Installation/CDIS/Mac OS X Installer.app/Contents/Resources/"];
		[installer remountDiskFrom: bless to: @"/usr/sbin/"];
		[installer remountDiskFrom: xxd to: @"/usr/bin/"];
		[installer remountDiskFrom: packages to: @"/System/Installation/Packages/"];

	}
	

	

	

	// post install umount script.
	NSMutableString* fileString = [[NSMutableString alloc] init];
	[fileString appendFormat:@"umount -f %@\n", bless];
	[fileString appendFormat:@"umount -f %@\n", xxd];
	[fileString appendFormat:@"umount -f %@\n", menuItems];
	[fileString appendFormat:@"umount -f %@\n", packages];
	[fileString appendString:@"umount -f /Applications/\n"];

	//[fileString appendString:@"umount -f /tmp/\n"];

	//NSError* err;
	//NSString* unmountScript = @"/tmp/unmount.sh";
	//[fileString writeToFile:unmountScript atomically:NO encoding:NSASCIIStringEncoding error:&err];
	//[installer setPermissions:@"755" onPath:unmountScript recursivly:NO];
	
	
	[pool release];
}





