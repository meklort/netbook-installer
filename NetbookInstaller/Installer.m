//
//  Installer.m
//  NetbookInstaller
//
//  Created by Evan Lojewski on 5/16/09.
//  Copyright 2009-2010. All rights reserved.
//

#import "Installer.h"

@implementation Installer



/***
 ** remountTargetWithPermissions
 **		Remounts [systemInfo installPath] with the owners option enabled
 **
 ***/
- (void)remountTargetWithPermissions
{
	if([[systemInfo installPath] isEqualToString:@"/"]) return;
	
	NSArray* nsargs = [[NSArray alloc] initWithObjects: 
					   @"-u", @"-o", @"owners", [@"/dev/" stringByAppendingString: [systemInfo bootPartition]], nil];	
	[self runCMD:"/sbin/mount" withArgs:nsargs];
	
	[nsargs release];
}


/***
 ** remountTargetWithPermissions
 **		Mounts a ramdisk to /Volumes/ramdisk with 256mb of space.
 **
 ***/
- (void) mountRamDisk
{	
	[self unmountRamDisk];
	
	[self mountRamDiskAt: @nbiRamdiskPath withName: @nbiRamdiskName andSize: (512 * 1024 * 1024) andOptions: nil];
	[self setPermissions:@"777" onPath:@nbiRamdiskPath recursivly:YES];
	
	// TODO: Ensure that /Volumes/ramdisk doesnt exist
	
	// replace with runCMDasUser
	//system("/usr/sbin/diskutil eraseVolume HFS+ ramdisk `hdid -nomount ram://523648`");
	
	//	ExtendedLog(@"Remounting ramdisk");
	
	//	system([@"/sbin/mount -u -o owners /Volumes/ramdisk" cStringUsingEncoding:NSASCIIStringEncoding]);
	
	//	ExtendedLog(@"Permissions fixed");
}

/***
 ** remountDiskFrom:(NSString*) source to: (NSString*) dest 
 **		Remounts a disk from one bsddevice to a file system path, using unionfs
 **		@args
 **			source:	The BSD disk to remount
 **			dest:	The file system path to mount the disk to, using union.
 **
 ***/
- (BOOL) remountDiskFrom:(NSString*) source to: (NSString*) dest //withOptions: (NSString*) Options
{	
	NSMutableArray* nsargs1 = [[NSMutableArray alloc] init];
	NSMutableArray* nsargs2 = [[NSMutableArray alloc] init];

	
	if(![[NSFileManager defaultManager] fileExistsAtPath:dest])
	{
		[self makeDir:dest];
		if(![[NSFileManager defaultManager] fileExistsAtPath:dest])
		{
			ExtendedLog(@"Mountpoint does not exist, exiting");
			return NO;	// Unable to create mountpoint
		}
	}
	
	// Unmount ramdisk
	[nsargs1 addObject:source];
	[self runCMD:"/sbin/umount" withArgs:nsargs1];
	
	[nsargs2 addObject:@"-t"];
	[nsargs2 addObject:@"hfs"];
	[nsargs2 addObject:@"-o"];
	[nsargs2 addObject:@"union"];
	
	[nsargs2 addObject:source];
	[nsargs2 addObject:dest];
	
	[self runCMD:"/sbin/mount" withArgs:nsargs2];
	
	
	[nsargs1 release];
	[nsargs2 release];
	
	ExtendedLog(@"Remount of %@ to %@ finished.", source, dest);
	return YES;
}


- (NSString*) mountRamDiskAt: (NSString*) path withName: (NSString*) name andSize: (UInt64) size andOptions: (NSString*) options
{
	NSString* device;
	size = size / 512 + 1;
	
	
	if(![[NSFileManager defaultManager] fileExistsAtPath:path])
	{
		[self makeDir:path];
		if(![[NSFileManager defaultManager] fileExistsAtPath:path])
		{
			ExtendedLog(@"Mountpoint does not exist, exiting");
			return nil;	// Unable to create mountpoint
		}
	}
	
	if(!size) 
	{
		ExtendedLog(@"Unable to determine ramdisk size, exiting");
		return nil;	// unable to create a ramdisk with no size
	}
	
	
	NSArray* nsargs = [[NSArray alloc] initWithObjects: 
		@"attach", @"-nomount", [NSString stringWithFormat:@"ram://%lld", size], nil];
	
	
	
	device = [[self runCMD: "/usr/bin/hdiutil" withArgs: nsargs] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	[nsargs release];
	
	
	if(![[NSFileManager defaultManager] fileExistsAtPath:device])
	{
		ExtendedLog(@"Unable to locate created ramdisk.");
		return nil;	// Unable to find created ramdisk
	}
	
	
	
	if(!name) name = @"Untitled";

	nsargs = [[NSArray alloc] initWithObjects: 
			  @"-v", name, device, nil];
	[self runCMD:"/sbin/newfs_hfs" withArgs:nsargs];
	[nsargs release];
	
	
	if((!options || [options isEqualToString:@""]))
	{
		nsargs = [[NSArray alloc] initWithObjects: 
				  @"-t",
				  @"hfs",
				  device,
				  path, 
				  nil];
	}
	else
	{
		nsargs = [[NSArray alloc] initWithObjects: 
				  @"-t",
				  @"hfs",
				  @"-o",
				  options,
				  device,
				  path, 
				  nil];
	}
	
	[self runCMD:"/sbin/mount" withArgs:nsargs];
	//	ExtendedLog(@"RAMDisk %@ (size: %d) mounted at %@", device, size / 512, path);
	
	ExtendedLog(@"Ramdisk %@ (%@) mounted at %@.", path, name, device);

	[nsargs release];
	
	
	return device;
	
	
	//runCMD
}

- (void) unmountRamDisk
{	
	if([[NSFileManager defaultManager] fileExistsAtPath:@nbiRamdiskPath]) 
	{
		//	diskutil eject /Volumes/ramdisk
		NSArray* nsargs = [[NSArray alloc] initWithObjects: 
						   @nbiRamdiskPath, nil];
		
		
		[self runCMD:"/sbin/umount" withArgs:nsargs];
		[nsargs release];
		// Drive should be unmounted now, however it is still in memory
		
		
		
		NSDictionary* info = [ systemInfo getFileSystemInformation: @nbiRamdiskPath];
		
		nsargs = [[NSArray alloc] initWithObjects: 
				  [info objectForKey:@"Mounted From"], nil];
		
		
		
		
		[self runCMD:"/usr/sbin/diskutil" withArgs:nsargs];
		[nsargs release];
	}	
	
	if([[NSFileManager defaultManager] fileExistsAtPath:@nbiRamdiskPath]) 
	{
		[self deleteFile:@nbiRamdiskPath];
	}
	
	
}

- (void) systemInfo: (SystemInformation*) info
{
	systemInfo = info;
}

- (BOOL) getAuthRef
{
	if(getuid() == 0) return YES;	// already running as root, no need to request authorization.
	AuthorizationRef authorizationRef;
	
    AuthorizationItem right = { nbiAuthorizationRight, 0, NULL, 0 };		// who we are
	AuthorizationItem admin = { "system.privilege.admin", 0, NULL, 0};			// exec rights
	AuthorizationItem rights[2];
	rights[0] = right;
	rights[1] = admin;
    AuthorizationRights rightSet = { 2, rights };
	OSStatus status;
	//MyAuthorizedCommand myCommand;
    AuthorizationFlags flags = kAuthorizationFlagDefaults | kAuthorizationFlagPreAuthorize | kAuthorizationFlagInteractionAllowed | kAuthorizationFlagExtendRights;
	
	
	/// Create a new authorization reference which will later be passed to the tool.
	status = AuthorizationCreate(NULL, kAuthorizationEmptyEnvironment, flags, &authorizationRef);
	if (status != errAuthorizationSuccess)
	{
		//ExtendedLog(@"RDPPFramework NSFileManager+RDPPFrameworkAdditions secureCopy:toPath:authenticate: failed to create AuthorizationRef.  Return code was %d", status);
		return NO;
	}	
	
	// We only use this were we are copying to /Library so always athorize.
	status = AuthorizationCopyRights(authorizationRef, &rightSet, kAuthorizationEmptyEnvironment, flags, NULL);
	
	if (status!=errAuthorizationSuccess)
	{
		//ExtendedLog(@"RDPPFramework NSFileManager+RDPPFrameworkAdditions secureCopy:toPath:authenticate: failed to authorize.  Return code was %d", status);
		return NO;
	}
	
	authRef = authorizationRef;
	
	return YES;
}



- (BOOL) copyFrom: (NSString*) source toDir: (NSString*) destination
{
	BOOL returnVal = NO;
	
	if(![[NSFileManager defaultManager] fileExistsAtPath:source]) return NO;
	
	
	NSArray* nsargs = [[NSArray alloc] initWithObjects:@"-rf", source, destination, nil];
	
	returnVal = ([self runCMD:"/bin/cp" withArgs:nsargs] ? YES : NO);
	
	[nsargs release];
	
	returnVal &= [[NSFileManager defaultManager] fileExistsAtPath:destination];

	if(returnVal == NO)
	{
		ExtendedLog(@"Copy from %@ to %@ failed", source, destination);
	}
	else
	{
		ExtendedLog(@"Copy from %@ to %@ succeded", source, destination);

	}
	return returnVal;
	
}

- (BOOL) moveFrom: (NSString*) source to: (NSString*) destination
{
	BOOL returnVal;
	
	if(![[NSFileManager defaultManager] fileExistsAtPath:source]) return NO;
	
	NSArray* nsargs = [[NSArray alloc] initWithObjects:@"-f", source, destination, nil];
	
	
	returnVal = ([self runCMD:"/bin/mv" withArgs:nsargs] ? YES : NO);
	
	[nsargs release];
	
	returnVal = [[NSFileManager defaultManager] fileExistsAtPath:destination];	// This doesn't actualy check that it worked... also, permissions might be an issue
	
	if(returnVal == NO)
	{
		ExtendedLog(@"Move from %@ to %@ failed", source, destination);
	}
	else
	{
		ExtendedLog(@"Move from %@ to %@ succeded", source, destination);
		
	}
	
	
	return returnVal;
	
}

- (NSString*) runCMD: (char*) command withArgs: (NSArray*) nsargs
{
	NSString* returnString;
	if(getuid() == 0)
	{
		// we are already root, so we dont neet to escilate our privleges
		returnString = [self runCMDAsUser: command withArgs: nsargs];
	}
	else
	{
		// We are a regular user. We need to escilate our privledges.
		returnString = [self runCMDAsRoot: command withArgs: nsargs];
		
	}
	
	//ExtendedLog(@"RunCMD: %s returned %@", command, returnString);
	//ExtendedLog(@"RunCMD %s arguments: %@", command, nsargs);
	
	return returnString;
}

- (NSString*) runCMDAsUser: (char*) command withArgs: (NSArray*) nsargs
{
	FILE* pipe = NULL;
	
	NSMutableString* run = [NSMutableString alloc];
	NSMutableString* commandString = [[NSMutableString alloc] initWithCString:command];
	NSMutableString* escapedString;
	
	NSMutableString* returnString = [[NSMutableString alloc] initWithString:@""];
	
	int i = 0;
	int h = 0;
	
	// Escape any white spaces
	while(h < [commandString length])
	{
		if([commandString characterAtIndex:h] == ' ')
		{
			[commandString insertString:@"\\" atIndex:h];
			h++;	// To skip the space
		}
		h++;
	}
	
	run = [run initWithString:commandString];
	
	while(nsargs && i < [nsargs count])
	{
		[run appendString:@" "];
		
		if(escapedString != nil) [escapedString release];
		escapedString = [[NSMutableString alloc] initWithString:[nsargs objectAtIndex:i]];
		
		int j = 0;
		// Excape any whitespaces
		while(j < [escapedString length])
		{
			if([escapedString characterAtIndex:j] == ' ')
			{
				[escapedString insertString:@"\\" atIndex:j];
				j++;	// To skip the space
			}
			j++;
		}
		
		[run appendString:escapedString];
		
		i++;
	}
	//ExtendedLog(@"Executing: %@", run);
	// TODO: change away from system and twards one of the exec commands. We also may need to catch the output or return codes of any command we run (instead of retuning YES)
	//	ExtendedLog(@"Executing %@ as current user", run);
	
	pipe = popen([run cStringUsingEncoding:NSASCIIStringEncoding], "r");	
	//	sleep(2);
	
	char string[10];
	if((pipe != NULL) && (pipe != (void*)-1)) 
	{
		while(fgets(string, 10, pipe) != NULL)
		{
			[returnString appendFormat:@"%s", string];
		}
	}
	
	pclose(pipe);
	
	
	//	exec
	
	if(run != nil) [run release];
	if(commandString != nil) [commandString release];
	if(escapedString != nil) [escapedString release];
	
	if((pipe != NULL) && (pipe != (void*)-1)) 
	{
		return returnString;
	} else {
		[returnString release];
		return nil;
	}
	
}

- (NSString*) runCMDAsRoot: (char*) command withArgs: (NSArray*) nsargs
{
	NSMutableString* returnString = [[NSMutableString alloc] initWithString:@""];
	
	FILE* pipe = NULL;
	char* args[([nsargs count]) + 1];
	int i = 0;
	OSStatus status;
	
	while(nsargs && i < [nsargs count])
	{
		args[i] = (char*)[[nsargs objectAtIndex:i] cStringUsingEncoding:NSASCIIStringEncoding];
		i++;
	}
	args[i] = NULL;
	//	ExtendedLog(@"Executing %s as root with args %@", command, nsargs);
	status = AuthorizationExecuteWithPrivileges(authRef, command, kAuthorizationFlagDefaults, args, &pipe);
	//	sleep(2);
	char string[10];
	if(status == 0) 
	{
		while(fgets(string, 10, pipe) != NULL)
		{
			[returnString appendFormat:@"%s", string];
		}
	}
	
	fclose(pipe);
	
	
	if(status == 0) return returnString;
	else
	{
		[returnString release];
		return nil;
	}
	
}

- (BOOL) hidePath: (NSString*) path
{
	BOOL returnVal;
	// /Volumes/target/usr/bin/chflag hidden path
	
	NSArray* nsargs = [[NSArray alloc] initWithObjects:@"hidden", path, nil];
	
	if(!(returnVal = ([self runCMD: (char*)[[[systemInfo installPath] stringByAppendingString: @"/usr/bin/chflags"] cStringUsingEncoding:NSASCIIStringEncoding] withArgs:nsargs] ? YES : NO)))
	{
		returnVal = ([self runCMD:"/usr/bin/chflags" withArgs:nsargs] ? YES : NO);	// rathen than distributing chflags, we just try running it in both locations
		
	} else returnVal = NO;
	
	[nsargs release];
	
	return [systemInfo hiddenStateOfPath: path];
}



- (BOOL) showPath: (NSString*) path
{
	// /Volumes/target/usr/bin/chflag nohidden path
	BOOL returnVal = NO;
	
	NSArray* nsargs = [[NSArray alloc] initWithObjects:@"nohidden", path, nil];
	
	if(!(returnVal = ([self runCMD: (char*)[[[systemInfo installPath] stringByAppendingString: @"/usr/bin/chflags"] cStringUsingEncoding:NSASCIIStringEncoding] withArgs:nsargs] ? YES : NO)))
	{
		returnVal = ([self runCMD:"/usr/bin/chflags" withArgs:nsargs] ? YES : NO);	// rathen than distributing chflags, we just try running it in both locations
	}
	
	[nsargs release];
	
	return ![systemInfo hiddenStateOfPath: path];
	
}

- (BOOL) disableptmd
{
	NSArray* nsargs = [[NSArray alloc] initWithObjects:@"write", [[systemInfo installPath] stringByAppendingString: @"/System/Library/LaunchDaemons/com.apple.platform.ptmd"], @"RunAtLoad", @"false", nil];
	return [self runCMD:"/usr/bin/defaults" withArgs:nsargs] ? YES : NO;

}


- (BOOL) setPermissions: (NSString*) perms onPath: (NSString*) path recursivly: (BOOL) recursiv
{
	// /bin/chmod [-R] perms path
	
	NSMutableArray* nsargs = [[NSMutableArray alloc] init];
	
	if(recursiv) 	[nsargs addObject: @"-R"];
	[nsargs addObject:perms];
	[nsargs addObject:path];
	
	return ([self runCMD:"/bin/chmod" withArgs:nsargs] ? YES : NO);
	
	
}

- (BOOL) setOwner: (NSString*) owner andGroup: (NSString*) group onPath: (NSString*) path recursivly: (BOOL) recursiv
{
	// /usr/sbin/chown [-R] owner:group path
	NSMutableArray* nsargs = [[NSMutableArray alloc] init];
	
	if(recursiv) 	[nsargs addObject: @"-R"];
	[nsargs addObject:[[owner stringByAppendingString: @":"] stringByAppendingString:group]];
	[nsargs addObject:path];
	
	return ([self runCMD:"/usr/sbin/chown" withArgs:nsargs] ? YES : NO);
}


- (BOOL) makeDir: (NSString*) dir
{
	if([[NSFileManager defaultManager] fileExistsAtPath:dir]) return YES;	// already exists
	
	BOOL returnVal = NO;
	// /bin/mkdir -p dir
	
	NSArray* nsargs = [[NSArray alloc] initWithObjects:@"-p", dir, nil];
	
	returnVal = ([self runCMD:"/bin/mkdir" withArgs:nsargs] ? YES : NO);
	
	[nsargs release];
	
	if([[NSFileManager defaultManager] fileExistsAtPath:dir]) return NO;	// unable to create path
	
	
	return returnVal;
}

-(BOOL) deleteFile: (NSString*) file
{
	if(![[NSFileManager defaultManager] fileExistsAtPath:file]) return YES;	// never existed
	
	BOOL returnVal = NO;
	// /bin/rm -rf file
	
	NSArray* nsargs = [[NSArray alloc] initWithObjects:@"-rf", file, nil];
	
	returnVal = ([self runCMD:"/bin/rm" withArgs:nsargs] ? YES : NO);
	
	[nsargs release];
	
	if(![[NSFileManager defaultManager] fileExistsAtPath:file]) return YES;	// deleted
	
	
	return returnVal;
	
}







// Installer Options
- (BOOL) installBootloader
{
	NSScanner* scanner = [[NSScanner alloc] initWithString:[systemInfo bootPartition]];
	[scanner setCharactersToBeSkipped: [[NSCharacterSet decimalDigitCharacterSet] invertedSet]];
	/*
	if([systemInfo hostOS] < KERNEL_VERSION(10,5,0))
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
	
	
	ExtendedLog(@"Installing booter to /dev/r%@", [systemInfo bootPartition]);

	NSString* bootPath;
	bootPath = [sourcePath stringByAppendingFormat: @"/%s/%s/", nbiSupportFilesPath, nbiBootloaderPath];
	//	bootPath = [[[[sourcePath stringByAppendingString: @nbiSupportFilesPath] stringByAppendingString: @nbiBootloaderPath] stringByAppendingString:[bootloaderType objectForKey:@nbiMachineVisibleName]];
	
	bootPath = [bootPath stringByAppendingString:@"/"];
	NSMutableArray* nsargs = [[NSMutableArray alloc] init];
	
	[nsargs addObject: @"-f"];
	[nsargs addObject:[bootPath stringByAppendingString: @"/boot0"]];
	[nsargs addObject: @"-u"];
	[nsargs addObject: @"-y"];
	
	[nsargs addObject:[@"/dev/r" stringByAppendingString: bsdDisk]];
	
	[self setPermissions:@"755" onPath:[sourcePath stringByAppendingString: @"/SupportFiles/fdisk440"] recursivly:NO];
	char* fdisk = (char*)[[sourcePath stringByAppendingString: @"/SupportFiles/fdisk440"] cStringUsingEncoding:NSASCIIStringEncoding];
	[self runCMD:fdisk withArgs:nsargs];		// Lets not overwrite the disk bootsect, we really don't need it anyways since we set thepartition as active
	
	NSMutableArray* nsargs2 = [[NSMutableArray alloc] init];
	
	[nsargs2 addObject:[@"if=" stringByAppendingString:[bootPath stringByAppendingString: @"boot1h"]]];
	[nsargs2 addObject:[@"of=/dev/r" stringByAppendingString: [systemInfo bootPartition]]];
	
	
	[self runCMD:"/bin/dd" withArgs:nsargs2];
	[self copyFrom:[bootPath stringByAppendingString: @"/modules"] toDir:[[systemInfo installPath] stringByAppendingString: @"/Extra/"]];	
	[self copyFrom:[bootPath stringByAppendingString: @"/boot"] toDir:[[systemInfo installPath] stringByAppendingString: @"/"]];
	[self hidePath:[[systemInfo installPath] stringByAppendingString: @"/boot"]];
	
	[nsargs	 release];
	[nsargs2 release];
	[scanner release];
	
	[self setPartitionActive];
	
	return YES;
	
}

- (BOOL) installExtensions
{
	[self makeDir:@"/Volumes/ramdisk/Extensions"];

	BOOL status = YES;
	NSMutableArray* sourceExtensions = [[NSMutableArray alloc] initWithCapacity: 10];
	NSString* destinationExtensions =  [[[systemInfo installPath] stringByAppendingString: @nbiExtrasPath] stringByAppendingString:[[systemInfo machineInfo] objectForKey:@nbiMachineExtensions]];
	NSEnumerator* sources;
	NSString* source;
	
	
	//	if([systemInfo targetOS] >= KERNEL_VERSION(10, 6, 0))
	//	{
	// Copy in 10.6 Extensions
	[sourceExtensions addObject: [[[[sourcePath  stringByAppendingString: @nbiSupportFilesPath] stringByAppendingString: @nbiMachineFilesPath] stringByAppendingString: [[systemInfo machineInfo] objectForKey:@nbiMachineSupportFiles]] stringByAppendingString: @"/10.6 Extensions/"]];
	if(![@nbiMachineGeneric isEqualToString:[[systemInfo machineInfo] objectForKey:@nbiMachineSupportFiles]]) [sourceExtensions addObject: [sourcePath stringByAppendingString: @"/SupportFiles/machine/General/10.6 Extensions/"]];
	
	//	}
	//	else
	//	{
	//		// Copy in 10.5 Extensions
	//		[sourceExtensions addObject: [[[[sourcePath  stringByAppendingString: @nbiSupportFilesPath] stringByAppendingString: @nbiMachineFilesPath] stringByAppendingString: [[systemInfo machineInfo] objectForKey:@nbiMachineSupportFiles]] stringByAppendingString: @"/10.5 Extensions/"]];
	//		if(![@nbiMachineGeneric isEqualToString:[[systemInfo machineInfo] objectForKey:@nbiMachineSupportFiles]]) [sourceExtensions addObject: [sourcePath stringByAppendingString: @"/SupportFiles/machine/General/10.5 Extensions/"]];
	//	}
	
	
	[sourceExtensions addObject: [[[[sourcePath  stringByAppendingString: @nbiSupportFilesPath] stringByAppendingString: @nbiMachineFilesPath] stringByAppendingString: [[systemInfo machineInfo] objectForKey:@nbiMachineSupportFiles]] stringByAppendingString: @"/Extensions/"]];
	
	if(![@nbiMachineGeneric isEqualToString:[[systemInfo machineInfo] objectForKey:@nbiMachineSupportFiles]]) [sourceExtensions addObject: [sourcePath stringByAppendingString: @"/SupportFiles/machine/General/Extensions/"]];
	
	
	
	sources = [sourceExtensions objectEnumerator];	// An enumerator could hav ebeen used too
	while(source = [sources nextObject]) {
		if(![self copyFrom: source toDir: destinationExtensions]) status = NO;
	}
	
	
	[sourceExtensions release];
	return status;
}

- (BOOL) hideFiles
{
	BOOL returnVal = YES;
	// Hidding /boot, /Extra, /Extra.bak
	returnVal &= [self hidePath:[[systemInfo installPath] stringByAppendingString: @"/boot"]];
	returnVal &= [self hidePath:[[systemInfo installPath] stringByAppendingString: @"/Extra"]];
	returnVal &= [self hidePath:[[systemInfo installPath] stringByAppendingString: @"/Extra.bak"]];
	
	return returnVal;
}

- (BOOL) showFiles
{
	BOOL returnVal = YES;
	
	// Showing /boot, /Extra, /Extra.bak
	returnVal &= ![self showPath:[[systemInfo installPath] stringByAppendingString: @"/boot"]];
	returnVal &= ![self showPath:[[systemInfo installPath] stringByAppendingString: @"/Extra"]];
	returnVal &= ![self showPath:[[systemInfo installPath] stringByAppendingString: @"/Extra.bakb"]];
	
	return returnVal;
}

- (BOOL) installDSDT
{
	NSMutableArray* genPatches;
	NSArray* patches;
	
	// Cleanup, delete old dsdt from DelEFI
	[self deleteFile:[[systemInfo installPath] stringByAppendingString: @"/DSDT.aml"]];
	// TODO: make the dsdt compile / decompiler into a framework / dylib
	
	[self makeDir: @"/Volumes/ramdisk/dsdt/"];
	[self makeDir: @"/Volumes/ramdisk/dsdt/patches"];
	
	// Copy dsdt files / patches into ramdisk
	[self copyFrom: [sourcePath stringByAppendingFormat:@"/%s/%s", nbiSupportFilesPath, nbiDSDTPath] toDir: @"/Volumes/ramdisk/dsdt/"];		// Machine specific filae
	[self copyFrom: [sourcePath stringByAppendingFormat: @"/%s/%s/%s/%s/", nbiSupportFilesPath, nbiMachineFilesPath, nbiMachineGeneric, nbiMachineDSDTPath] toDir: @"/Volumes/ramdisk/dsdt/patches/"];	// generic files
	
	if(![@nbiMachineGeneric isEqualToString:[[systemInfo machineInfo] objectForKey:@nbiMachineSupportFiles]])
	{
		// TODO: verify file exists
		[self copyFrom: [sourcePath stringByAppendingFormat: @"/%s/%s/%@/%s/", nbiSupportFilesPath, nbiMachineFilesPath, [[systemInfo machineInfo] objectForKey:@nbiMachineSupportFiles], nbiMachineDSDTPath] toDir: @"/Volumes/ramdisk/dsdt/patches/"];
		//[self copyFrom:[[[[[sourcePath stringByAppendingString: @nbiSupportFilesPath]  stringByAppendingString: @nbiMachineFilesPath] stringByAppendingString:[[systemInfo machineInfo] objectForKey:@nbiMachineSupportFiles]] stringByAppendingString:@nbiMachineDSDTPath]  toDir: @"/Volumes/ramdisk/dsdt/patches/"];
		
		genPatches = [NSMutableArray arrayWithArray: [[[NSDictionary dictionaryWithContentsOfFile:[sourcePath stringByAppendingString:@nbiMachinePlist]] objectForKey:@"General"] objectForKey: @"DSDT Patches"]];	
		patches = [[systemInfo machineInfo] objectForKey:@nbiMachineDSDTPatches];
		
	} else {
		
		genPatches = [[systemInfo machineInfo] objectForKey:@nbiMachineDSDTPatches];
		
	}
	
	
	
	NSMutableString* configFile = [[NSMutableString alloc] initWithString:@""];
	NSString* patchFile;
	NSString* lookFor;
	NSDictionary* patchDict;

	NSEnumerator* dictionaries;
	
	if(![@nbiMachineGeneric isEqualToString:[[systemInfo machineInfo] objectForKey:@nbiMachineSupportFiles]])
	{
		dictionaries = [patches objectEnumerator];
		
		while(patchDict = [dictionaries nextObject])
		{
			[genPatches addObject:patchDict];
		}
	}
	
	dictionaries = [genPatches objectEnumerator];
	
	while(patchDict = [dictionaries nextObject])
	{
		patchFile = [[patchDict allKeys] lastObject];
		lookFor = [[patchDict allValues] lastObject];

		if(![[NSFileManager defaultManager] fileExistsAtPath:[@"/Volumes/ramdisk/dsdt/patches/" stringByAppendingFormat:@"%@.txt", patchFile] ])
		{
			ExtendedLog(@"Unable to locate %@, skipping", [@"/Volumes/ramdisk/dsdt/patches/" stringByAppendingFormat:@"%@.txt", patchFile]);
			continue; // file doesn't exist, skipping
		}
		
		[configFile appendString:@":"];
		[configFile appendString:patchFile];
		[configFile appendString:@":"];
		[configFile appendString:lookFor];
		[configFile appendString:@":\r\n"];
	}
	if([configFile length])
	{
		NSError* error;
		
		[self deleteFile:@"/Volumes/ramdisk/dsdt/config"];
		[configFile writeToFile:@"/Volumes/ramdisk/config" atomically:NO encoding:NSASCIIStringEncoding error:&error];
		[self copyFrom:@"/Volumes/ramdisk/config" toDir:@"/Volumes/ramdisk/dsdt/"];
		[self deleteFile:@"/Volumes/ramdisk/config"];
	}
	
	
	NSMutableArray* nsargs = [[NSMutableArray alloc] init];
	[self runCMD:"/Volumes/ramdisk/dsdt/DSDTPatcher" withArgs:nsargs];
	
	
	[configFile release];
	[nsargs release];
	
	// The dsdt patcher doesnt konw where to put it, so we do it here.
	[self copyFrom: @"/Volumes/ramdisk/dsdt/Volumes/ramdisk/dsdt/dsdt.aml" toDir:[[systemInfo installPath] stringByAppendingString: @"/Extra/DSDT.aml"]];
	
	return [[NSFileManager defaultManager] fileExistsAtPath:@nbiExtraDSDTPath];
	
	
}

// FIXME: This will not work when run as root
- (BOOL) setRemoteCD: (BOOL) remoteCD
{
	/// defaults write com.apple.NetworkBrowser EnableODiskBrowsing -bool true
	/// defaults write com.apple.NetworkBrowser ODSSupported -bool true

	
	NSMutableArray* nsargs = [[NSMutableArray alloc] init];
	[nsargs addObject:@"write"];
	[nsargs addObject:@"com.apple.NetworkBrowser"];
	[nsargs addObject:@"EnableODiskBrowsing"];
	[nsargs addObject:@"-bool"];
	[nsargs addObject:remoteCD ? @"true" : @"false"];

	[self runCMD:"defaults" withArgs:nsargs];

	[nsargs replaceObjectAtIndex:2 withObject:@"ODSSupported"];
	[self runCMD:"defaults" withArgs:nsargs];

	[nsargs release];
	
	return YES;
	
	NSMutableDictionary *dict;
	NSDictionary* save;		// TOOD: test as it may not be needed
	
	dict = [[NSMutableDictionary alloc] initWithDictionary:(NSDictionary*)CFPreferencesCopyMultiple(NULL,
																									CFSTR("com.apple.NetworkBrowser"),
																									kCFPreferencesCurrentUser,
																									kCFPreferencesAnyHost)];
	
	
	if(([[dict objectForKey: @"EnableODiskBrowsing"] boolValue] && [[dict objectForKey: @"ODSSupported"] boolValue]) == remoteCD) return YES;
	
	[dict setObject:[NSNumber numberWithBool: remoteCD] forKey: @"EnableODiskBrowsing"];
	[dict setObject:[NSNumber numberWithBool: remoteCD] forKey: @"ODSSupported"];
	
	
	save = [[NSDictionary alloc] initWithDictionary: dict];
	
	// Save the preference file (for this uesr).
	// I could have used the NSDicionary like all of the other preference files, but this is probably better
	CFPreferencesSetMultiple ((CFDictionaryRef) dict,
							  NULL,
							  CFSTR("com.apple.NetworkBrowser"),
							  kCFPreferencesCurrentUser,
							  kCFPreferencesAnyHost);
	
	[dict release];
	[save release];
	
	return YES;	// TODO: verify
}

- (BOOL) disableHibernation: (BOOL) disable 
{
	UInt8 state;
	NSFileManager* manager = [NSFileManager defaultManager];
	
	// If the preference plist doesnt exist, copy a default one in.
	if(![manager fileExistsAtPath:[[systemInfo installPath] stringByAppendingString:@"/Library/Preferences/SystemConfiguration/com.apple.PowerManagement.plist"]])
	{
		[self makeDir:[[systemInfo installPath] stringByAppendingString:@"/Library/Preferences/SystemConfiguration/"]];
		if(![@"General" isEqualToString:[[systemInfo machineInfo] objectForKey:@"Support Files"]]) [self copyFrom:[sourcePath stringByAppendingString: @"/SupportFiles/machine/General/Preferences/com.apple.PowerManagement.plist"] toDir: [[systemInfo installPath] stringByAppendingString:@"/Library/Preferences/SystemConfiguration/"]];
		[self copyFrom:[[[sourcePath stringByAppendingString: @"/SupportFiles/machine/"] stringByAppendingString: [[systemInfo machineInfo] objectForKey:@"Support Files"]] stringByAppendingString: @"/Preferences/com.apple.PowerManagement.plist"] toDir: [[systemInfo installPath] stringByAppendingString:@"/Library/Preferences/SystemConfiguration/"]];
		
	}
	
	
	NSMutableDictionary*	propertyList= [[NSMutableDictionary alloc] initWithContentsOfFile: [[systemInfo installPath] stringByAppendingString:@"/Library/Preferences/SystemConfiguration/com.apple.PowerManagement.plist"]];
	
	NSMutableDictionary* powerStates = [[NSMutableDictionary alloc] initWithDictionary:[propertyList objectForKey: @"Custom Profile"]];
	NSMutableDictionary* acPowerState = [[NSMutableDictionary alloc] initWithDictionary:[powerStates objectForKey: @"AC Power"]];
	NSMutableDictionary* battPowerState = [[NSMutableDictionary alloc] initWithDictionary:[powerStates objectForKey: @"Battery Power"]];
	
	if(disable) state = 0;
	else state = 3;
	
	[acPowerState   setObject: [NSNumber numberWithInt:state] forKey: @"Hibernate Mode"];
	[battPowerState setObject: [NSNumber numberWithInt:state] forKey: @"Hibernate Mode"];
	
	
	
	[powerStates setObject: acPowerState forKey: @"AC Power"];
	[powerStates setObject: battPowerState forKey: @"Battery Power"];
	[propertyList setObject: powerStates forKey: @"Custom Profile"];
	
	
	[propertyList writeToFile: @"/Volumes/ramdisk/com.apple.PowerManagement.plist" atomically: NO]; 
	if(disable) [self deleteFile:[[systemInfo installPath] stringByAppendingString: @"/var/vm/sleepimage"]];
	
	[propertyList release];
	[acPowerState release];
	[battPowerState release];
	
	return [self copyFrom: @"/Volumes/ramdisk/com.apple.PowerManagement.plist" toDir:[[systemInfo installPath] stringByAppendingString: @"/Library/Preferences/SystemConfiguration/"]];
}

- (BOOL) setQuietBoot: (BOOL) quietBoot
{
	NSMutableDictionary*	bootSettings = NULL; //=  [[NSMutableDictionary alloc] initWithContentsOfFile:[[systemInfo installPath] stringByAppendingString: @"/Extra/com.apple.Boot.plist"]];
	//if(!bootSettings) {
	bootSettings =  [[NSMutableDictionary alloc] initWithContentsOfFile:[sourcePath stringByAppendingString: @"/SupportFiles/machine/General/ExtraFiles/com.apple.Boot.plist"]];
	//}
	
	if(!bootSettings) {
		ExtendedLog(@"Unable to set boot plist");
	}
	
	NSString* setting = [bootSettings objectForKey: @"Quiet Boot"];
	
	if([setting isEqualToString: @"Yes"] && quietBoot == false)
	{
		// Dissable Quiet Boot
		[bootSettings removeObjectForKey: @"Quiet Boot"];
		[bootSettings setObject:[NSNumber numberWithInt:5] forKey: @"Timeout"];
	}
	else if(![setting isEqualToString: @"Yes"] && quietBoot == true)
	{
		// Enable quiet boot
		[bootSettings removeObjectForKey: @"Timeout"];
		[bootSettings setObject: @"Yes" forKey: @"Quiet Boot"];
		
	}
	[bootSettings writeToFile: @"/Volumes/ramdisk/com.apple.Boot.plist" atomically: NO];
	
	[bootSettings release];
	
	[self copyFrom: @"/Volumes/ramdisk/com.apple.Boot.plist" toDir:[[systemInfo installPath] stringByAppendingString: @"/Extra/"]];
	return [[NSFileManager defaultManager] fileExistsAtPath:@"/Volumes/ramdisk/com.apple.Boot.plist"];
	// TODO: more verification
	
}

- (BOOL) fixBluetooth	// delete bluetooth prefrence file
{
	if(![[NSFileManager defaultManager] fileExistsAtPath:@"/Library/Preferences/com.apple.Bluetooth.plist"]) return YES;
	
	[self deleteFile:[[systemInfo installPath] stringByAppendingString: @"/Library/Preferences/com.apple.Bluetooth.plist"]];
	return ![[NSFileManager defaultManager] fileExistsAtPath:@"/Library/Preferences/com.apple.Bluetooth.plist"];
	
}

- (BOOL) copyMachineFilesFrom: (NSString*) source toDir: (NSString*) destination
{
	// TODO: verify soure and dest exist first.
	if(![@"General" isEqualToString:[[systemInfo machineInfo] objectForKey:@"Support Files"]]) [self copyFrom: [[sourcePath stringByAppendingString: @"/SupportFiles/machine/General/"] stringByAppendingString:source] toDir: [[systemInfo installPath] stringByAppendingString: destination]];
	return [self copyFrom: [[[[sourcePath stringByAppendingString: @"/SupportFiles/machine/"] stringByAppendingString: [[systemInfo machineInfo] objectForKey:@"Support Files"]] stringByAppendingString: @"/"] stringByAppendingString:source] toDir: [[systemInfo installPath] stringByAppendingString: destination]];
	
	
	//	return YES;
}


// DSD patch routines
- (BOOL) getDSDT
{
	return NO;
}

- (BOOL) patchDSDT
{
	return NO;
}

- (BOOL) patchDSDT: (BOOL) forcePatch
{
	return NO;
}















// This generates and mkext in <install>/Extra/Extensions.mkext FROM /Volumes/ramdisk/Extensions
// FIXME: this is very (extremely?) ugly, I absolutely will rework this. If I dont and you see it in svn, let me know.
- (BOOL) generateExtensionsCache
{

	[self setOwner:@"root" andGroup:@"wheel" onPath: [systemInfo installPath] recursivly: NO];
	
	[self setPermissions: @"644" onPath: @"/Volumes/ramdisk/Extensions/" recursivly: YES];
	[self setOwner:@"root" andGroup:@"wheel" onPath: @"/Volumes/ramdisk/Extensions/" recursivly: YES];

	[self setPermissions: @"755" onPath: [systemInfo extensionsFolder] recursivly: YES];
	[self setOwner:@"root" andGroup:@"wheel" onPath: [systemInfo extensionsFolder] recursivly: YES];
	
	// Remove prvious mkexts
	[self deleteFile:[[systemInfo installPath] stringByAppendingString: @"/Extra/Extensions.mkext"]];
	
	if([systemInfo hostOS] >= KERNEL_VERSION(10, 6, 0))			// 10.6 host
	{
		
		// /System/Library/Extensions is for 10.5, not 10.6, remove it
		[self deleteFile:[[systemInfo installPath] stringByAppendingString: @"/System/Library/Extensions.mkext"]];
		
		//[self deleteFile:[[systemInfo installPath] stringByAppendingString: @"/System/Library/Caches/com.apple.kext.caches/Startup/Extensions.mkext"]];
		
		
		//ExtendedLog(@"Copied /System/Library/Extensions");	
		
		// Copy /Extra/Extensions/* to /Volumes/ramdisk/Extensions, overwriting any /S/L/E kexts previously copied there in [self copyDep]
		[self copyFrom: [[systemInfo extensionsFolder] stringByAppendingString:@"/../AdditionalExtensions/"] toDir:@"/Volumes/ramdisk/Extensions/"];
		[self copyFrom: [[systemInfo extensionsFolder] stringByAppendingString:@"/"] toDir: @"/Volumes/ramdisk/Extensions/"];
		
		[self setPermissions: @"644" onPath: @"/Volumes/ramdisk/Extensions/" recursivly: YES];
		[self setOwner:@"root" andGroup:@"wheel" onPath: @"/Volumes/ramdisk/Extensions/" recursivly: YES];

		
		//sudo kextcache -a i386 -m <installPath>/Extra/Extensions.mkext <installPath>/Extra/Mini9Ext/ /Sytem/Library/Extensions
		NSArray* nsargs;
		NSArray* nsargs2;
		//NSArray* nsargs3;
		NSMutableArray* nsargs4 = [[NSMutableArray alloc] init];
		NSMutableArray* nsargs5 = [[NSMutableArray alloc] init];
		//	NSMutableArray* nsargs6 = [[NSMutableArray alloc] init];
		
		
		
		if([systemInfo is64bit]  || [@nbiMachineGeneric isEqualToString:[[systemInfo machineInfo] objectForKey:@nbiMachineSupportFiles]])
		{
			// 64bit is supported, or we are generic	(aka, NetbookBootMaker)
			nsargs = [[NSArray alloc] initWithObjects:[systemInfo installPath], 
					  @"/usr/sbin/kextcache"/*, @"-a", @"i386"*/, @"-m", @"/Extra/Extensions.mkext", @"/Volumes/ramdisk/Extensions/", nil];
		}
		else
		{
			// 32bit only
			nsargs = [[NSArray alloc] initWithObjects:[systemInfo installPath], 
					  @"/usr/sbin/kextcache", @"-a", @"i386", @"-m", @"/Extra/Extensions.mkext", @"/Volumes/ramdisk/Extensions/", nil];
			
		}
		
		
		
		
		
		// kextcache -a i386 -m /System/Library/Extensions.mkext /System/Library/Extensions/
		
		//chroot "$3" /usr/sbin/kextcache -system-caches
		nsargs2 = [[NSArray alloc] initWithObjects:[systemInfo installPath], 
					@"/usr/sbin/kextcache", @"-system-mkext", nil];
		
		/*
		 // kextcache -l -m /System/Library/Caches/com.apple.kext.caches/Startup/Extensions.mkext /System/Library/Extensions/
		 if([systemInfo is64bit]  || [@nbiMachineGeneric isEqualToString:[[systemInfo machineInfo] objectForKey:@nbiMachineSupportFiles]])
		 {
		 // 64bit is supported, or we are generic	(aka, NetbookBootMaker)	
		 nsargs3 = [[NSArray alloc] initWithObjects:[systemInfo installPath], 
		 @"/usr/sbin/kextcache", @"-l", @"-m", @"/System/Library/Caches/com.apple.kext.caches/Startup/Extensions.mkext", @"/System/Library/Extensions/", nil];
		 }
		 else
		 {
		 // 32bit		
		 nsargs3 = [[NSArray alloc] initWithObjects:[systemInfo installPath], 
		 @"/usr/sbin/kextcache", @"-a", @"i386", @"-l", @"-m", @"/System/Library/Caches/com.apple.kext.caches/Startup/Extensions.mkext", @"/System/Library/Extensions/", nil];
		 
		 }
		 
		 
		 
		 */
		
		
		ExtendedLog(@"Generating extensions Cache");
		setenv("_com_apple_kextd_skiplocks", "1", 1);	    // This lets kextcache run before the 5 minute delay imposed by kextd
		
		
		// Remount ramdisk so it's visible in the chroot
		NSDictionary* info = [ systemInfo getFileSystemInformation: @nbiRamdiskPath];	// info on ramdisk
		
		// Unmount ramdisk
		[nsargs4 addObject:[info objectForKey:@"Mounted From"]];
		[self runCMD:"/sbin/umount" withArgs:nsargs4];
		
		[self makeDir:[[systemInfo installPath] stringByAppendingString:@nbiRamdiskPath]];
		
		// Remount ramdisk
		[nsargs5 addObject:@"-t"];
		[nsargs5 addObject:@"hfs"];
		[nsargs5 addObject:[info objectForKey:@"Mounted From"]];
		[nsargs5 addObject:[[systemInfo installPath] stringByAppendingString:@nbiRamdiskPath]];
		[self runCMD:"/sbin/mount" withArgs:nsargs5];
		
		
		
		if( [self runCMD:"/usr/sbin/chroot" withArgs:nsargs])
		{
			[self runCMD:"/usr/sbin/chroot" withArgs:nsargs2];
			//target os check nolonger needed, we can assume 10.6
			//if([systemInfo targetOS] >= KERNEL_VERSION(10, 6, 0))
			//[self runCMD:"/usr/sbin/chroot" withArgs:nsargs3];
			
			//[self makeDir:@nbiRamdiskPath];
			
			
			// Unmount ramdisk
			[nsargs4 removeLastObject];
			[nsargs4 addObject:[[systemInfo installPath] stringByAppendingString:@nbiRamdiskPath]];
			[self runCMD:"/sbin/umount" withArgs:nsargs4];
			
			// Remount ramdisk
			//[nsargs5 removeLastObject];
			//[nsargs5 addObject:@nbiRamdiskPath];
			//[self runCMD:"/sbin/mount" withArgs:nsargs5];
			
			
			
			//[self deleteFile:[[systemInfo installPath] stringByAppendingString:@nbiRamdiskPath]];
			
			[nsargs4 release];
			[nsargs5 release];
			//[nsargs3 release];
			[nsargs2 release];
			[nsargs release];
			
			//[self runCMD:chrootPath withArgs:[[NSArray alloc] initWithObjects:[systemInfo installPath], @touchPath, @"/Extra/Extensions.mkext", nil]];
			[self copyFrom:  [[systemInfo installPath] stringByAppendingString:@"/System/Library/CoreServices/SystemVersion.plist"] toDir:[[systemInfo installPath] stringByAppendingString:@"/Extra/SystemVersion.LastPatched.plist"]];

			return YES;
		}
		else {
			[self makeDir:@nbiRamdiskPath];
			
			// Unmount ramdisk
			//[nsargs4 removeLastObject];
			//[nsargs4 addObject:[[systemInfo installPath] stringByAppendingString:@nbiRamdiskPath]];
			[self runCMD:unmountPath withArgs:nsargs4];
			
			// Remount ramdisk
			[nsargs5 removeLastObject];
			[nsargs5 addObject:@nbiRamdiskPath];
			[self runCMD:mountPath withArgs:nsargs5];
			
			[nsargs4 release];
			[nsargs5 release];
			//[nsargs3 release];
			//[nsargs2 release];
			[nsargs release];
			[self deleteFile:[[systemInfo installPath] stringByAppendingString:@nbiRamdiskPath]];
			return NO;
			
		}
		
	}
	else
	{
		NSArray* nsargs;
		
		if([systemInfo is64bit]  || [@nbiMachineGeneric isEqualToString:[[systemInfo machineInfo] objectForKey:@nbiMachineSupportFiles]])
		{
			// 64bit is supported, or we are generic	(aka, NetbookBootMaker)	
			nsargs = [[NSArray alloc] initWithObjects:@"-m", [[systemInfo installPath] stringByAppendingString:@"/Extra/Extensions.mkext"], [systemInfo extensionsFolder], nil];	// This should only happen on 10.5 -> 10.6 dvd pathing
		}
		else
		{
			// 32bit		
			nsargs = [[NSArray alloc] initWithObjects:@"-a", @"i386", @"-m", [[systemInfo installPath] stringByAppendingString:@"/Extra/Extensions.mkext"], [systemInfo extensionsFolder], nil];	// This should only happen on 10.5 -> 10.6 dvd pathing
		}
		
		[self runCMD:"/usr/sbin/kextcache" withArgs:nsargs];
		
		[nsargs release];
		return YES;
		
		
	}
}

- (BOOL) removePrevExtra
{
	if([[NSFileManager defaultManager] fileExistsAtPath:[[systemInfo installPath] stringByAppendingString: @"/Extra/"]])
	{
		
		if(![[NSFileManager defaultManager] fileExistsAtPath:[[systemInfo installPath] stringByAppendingString: @"/Extra.bak/"]])
		{
			[self makeDir:[[systemInfo installPath] stringByAppendingString: @"/Extra.bak/"]];
		}
		[self deleteFile:[[systemInfo installPath] stringByAppendingString: @"/Extra.bak/AdditionalExtensions"]];	// delete previous AdditionalExtensions
		[self copyFrom:[[systemInfo installPath] stringByAppendingString: @"/Extra/"] toDir:[[systemInfo installPath] stringByAppendingString: @"/Extra.bak"]];
		[self deleteFile:[[systemInfo installPath] stringByAppendingString: @"/Extra/"]];
		
		
	}
	
	[self makeDir:[[systemInfo installPath] stringByAppendingString: @"/Extra/"]];
	
	if([[NSFileManager defaultManager] fileExistsAtPath:[[systemInfo installPath] stringByAppendingString: @"/Extra.bak/"]])
	{
		[self copyFrom:[[systemInfo installPath] stringByAppendingString: @"/Extra.bak/DSDT.aml"] toDir:[[systemInfo installPath] stringByAppendingString: @"/Extra/DSDT.aml"]];
		//[self copyFrom:[[systemInfo installPath] stringByAppendingString: @"/Extra.bak/com.apple.Boot.plist"] toDir:[[systemInfo installPath] stringByAppendingString: @"/Extra/"]];
		[self copyFrom:[[systemInfo installPath] stringByAppendingString: @"/Extra.bak/Extensions.mkext"] toDir:[[systemInfo installPath] stringByAppendingString: @"/Extra/"]];
		[self copyFrom:[[systemInfo installPath] stringByAppendingString: @"/Extra.bak/AdditionalExtensions/"] toDir:[[systemInfo installPath] stringByAppendingString: @"/Extra/AdditionalExtensions/"]];
		[self copyFrom:[[systemInfo installPath] stringByAppendingString: @"/Extra.bak/NetbookInstaller.img"] toDir:[[systemInfo installPath] stringByAppendingString: @"/Extra/"]];
		[self copyFrom:[[systemInfo installPath] stringByAppendingString: @"/Extra.bak/UpdateExtra.app/"] toDir:[[systemInfo installPath] stringByAppendingString: @"/Extra/UpdateExtra.app/"]];
		
	}

	[self copyMachineFilesFrom: @"ExtraFiles/" toDir: @nbiExtrasPath];

	return YES;
}



- (BOOL) repairExtensionPermissions
{
	// repair directory
	
	
	NSArray* nsargs = [[NSArray alloc] initWithObjects:
					   [[systemInfo installPath] stringByAppendingString:@"/System/Library/Extensions/"],
					   @"-type", @"f",
					   @"-exec", @"/bin/chmod", @"644", @"{}", @";",
					   nil
					   ];
	
	NSArray* nsargs2 = [[NSArray alloc] initWithObjects:
						[[systemInfo installPath] stringByAppendingString:@"/System/Library/Extensions/"],
						@"-type", @"d",
						@"-name", @"MacOS",	// files in MacOS are executables and need the executable bit set
						@"-exec", @"/bin/chmod", @"-R", @"755", @"{}", @";",
						nil
						];
	
	NSArray* nsargs3 = [[NSArray alloc] initWithObjects:
						[[systemInfo installPath] stringByAppendingString:@"/System/Library/Extensions/"],
						@"-type", @"d",
						@"-exec", @"/bin/chmod", @"755", @"{}", @";",
						nil
						];
	[self runCMD:"/usr/bin/find" withArgs:nsargs];
	[self runCMD:"/usr/bin/find" withArgs:nsargs2];
	[self runCMD:"/usr/bin/find" withArgs:nsargs3];
	
	[nsargs release];
	[nsargs2 release];
	[nsargs3 release];
	
	return YES;
}

- (BOOL) restoreBackupExtra
{
	[self deleteFile:[[systemInfo installPath] stringByAppendingString:@"/Extra"]];
	[self copyFrom:[[systemInfo installPath] stringByAppendingString:@"/Extra.bak"] toDir:[[systemInfo installPath] stringByAppendingString:@"/Extra"]];
	return YES;
}

- (BOOL) failGracefully
{
	
	[self restoreBackupExtra];
	[self performSelectorOnMainThread:@selector(installFailed) withObject: nil waitUntilDone:NO];
	return YES;
}

- (BOOL) setPartitionActive
{
	int bootDisk;
	int bootPartition;
	NSScanner* scanner = [[NSScanner alloc] initWithString:[systemInfo bootPartition]];
	[scanner setCharactersToBeSkipped: [[NSCharacterSet decimalDigitCharacterSet] invertedSet]];
	[scanner scanInt: &bootDisk];	// scan past disk number
	[scanner scanInt: &bootPartition];	// scan past disk number
	
	NSArray* nsargs = [[NSArray alloc] initWithObjects:[NSString stringWithFormat:@"%d", bootDisk], [NSString stringWithFormat:@"%d", bootPartition], nil];	// This should only happen on 10.5 -> 10.6 dvd pathing
	
	[self setPermissions:@"755" onPath:[sourcePath stringByAppendingString: @"/SupportFiles/setActive.sh"] recursivly:NO];
	[self setPermissions:@"755" onPath:[sourcePath stringByAppendingString: @"/SupportFiles/gdisk"] recursivly:NO];
	
	[self runCMD: (char*)[[sourcePath stringByAppendingString: @"/SupportFiles/setActive.sh"] cStringUsingEncoding:NSASCIIStringEncoding] withArgs:nsargs];
	[nsargs release];
	return YES;
	
}

- (BOOL) copyNBIImage
{
	///[self copyFrom:[[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"NetbookInstaller.img"] toDir:[[systemInfo installPath] stringByAppendString:@"/Extra/"]
	return NO;

}

- (void) setSourcePath: (NSString*) path
{
	sourcePath = path;
}



//----------			installLocalExtensions			----------//
- (BOOL) installLocalExtensions
{
	//#warning  installLocalExtensions is depreciated
	
	BOOL status = YES;
	NSMutableArray* sourceExtensions = [[NSMutableArray alloc] init];
	
	//	NSString* destinationExtensions =  [[[systemInfo installPath] stringByAppendingString: @"/Extra/"] stringByAppendingString:[[systemInfo machineInfo] objectForKey:@"Extensions Directory"]];
	
	// This is really ONLY for clamshell display.kext
	NSString* destinationExtensions =  [[systemInfo installPath] stringByAppendingString: @"/System/Library/Extensions/"];
	//NSString* destinationExtensions = [systemInfo extensionsFolder];
	
	[sourceExtensions addObject: [[[sourcePath stringByAppendingString: @"/SupportFiles/machine/"] stringByAppendingString: [[systemInfo machineInfo] objectForKey:@"Support Files"]] stringByAppendingString: @"/LocalExtensions/"]];	
	if(![@"General" isEqualToString:[[systemInfo machineInfo] objectForKey:@"Support Files"]]) [sourceExtensions addObject: [sourcePath stringByAppendingString: @"/SupportFiles/machine/General/LocalExtensions/"]];
	
	if([systemInfo targetOS] >= KERNEL_VERSION(10,6,3))		// The kext inside is an audio kext from 10.6.2, install it over 10.6.3's.
	{
		// TODO: binhack applehda instead
		[self moveFrom:[[systemInfo installPath] stringByAppendingString: @"/System/Library/Extensions/AppleHDA.kext"] to:[[systemInfo installPath] stringByAppendingString: @"/System/Library/Extensions/AppleHDA.kext.10.6.3"]];
		[sourceExtensions addObject: [sourcePath stringByAppendingString: @"/SupportFiles/machine/General/10.6.3 LocalExtensions/"]];	
	}
	
	
	
	// An iterator could have been used too...
	while([sourceExtensions count] > 0) {
		NSString* current = [sourceExtensions objectAtIndex: 0];
		[sourceExtensions removeObjectAtIndex: 0];
		if(![self copyFrom: current toDir: destinationExtensions]) status = NO;
	}
	
	[sourceExtensions release];
	
	return status;
}



/************** Depreciated Functions *****************/
/** TODO: Remove depreciated functions **/
#if 0
- (BOOL) patchAppleUSBEHCI
{
#warning  patchAppleUSBEHCI is depreciated
	
	return NO;
	NSMutableDictionary* infoPlist;
	[self copyFrom:[[systemInfo installPath] stringByAppendingString: @"/System/Library/Extensions/IOUSBFamily.kext"] toDir:[systemInfo extensionsFolder]];
	infoPlist = [[NSMutableDictionary alloc] initWithContentsOfFile:[[systemInfo installPath] stringByAppendingString: @"/System/Library/Extensions/IOUSBFamily.kext/Contents/PlugIns/AppleUSBEHCI.kext/Contents/Info.plist"]];
	
	[infoPlist setObject:@"1.0" forKey:@"OSBundleCompatibleVersion"];
	[infoPlist writeToFile: @"/Volumes/ramdisk/Info.plist" atomically:NO];
	
	[infoPlist release];
	
	return [self copyFrom: @"/Volumes/ramdisk/Info.plist" toDir: [[systemInfo extensionsFolder] stringByAppendingString: @"/IOUSBFamily.kext/Contents/PlugIns/AppleUSBEHCI.kext/Contents/Info.plist"]];
	
}


- (BOOL) patchAppleHDA
{
#warning  patchAppleHDA is depreciated
	
	NSMutableDictionary* infoPlist;
	[self copyFrom:[[systemInfo installPath] stringByAppendingString: @"/System/Library/Extensions/AppleHDA.kext"] toDir:[systemInfo extensionsFolder]];
	infoPlist = [[NSMutableDictionary alloc] initWithContentsOfFile:[[systemInfo installPath] stringByAppendingString: @"/System/Library/Extensions/AppleHDA.kext/Contents/Info.plist"]];
	
	[infoPlist setObject:@"1.0" forKey:@"OSBundleCompatibleVersion"];
	[infoPlist writeToFile: @"/Volumes/ramdisk/Info.plist" atomically:NO];
	
	[infoPlist release];
	
	return [self copyFrom: @"/Volumes/ramdisk/Info.plist" toDir: [[systemInfo extensionsFolder] stringByAppendingString: @"/AppleHDA.kext/Contents/Info.plist"]];
	
}

// Kext support (patching and copying)
- (BOOL) patchGMAkext
{
#warning patchGMAkext is depreciated
	
	[self copyFrom:[[systemInfo installPath] stringByAppendingString: @"/System/Library/Extensions/AppleIntelGMA950.kext"] toDir:[systemInfo extensionsFolder]];	
	// Find: 8680A227
	// Replace: 8680AE72
	
	HexEditor* editor = [HexEditor alloc];
	
	UInt32 findBytes =    0x27A28086;
	UInt32 replaceBytes = 0x27AE8086;
	char findString[] =    {'0', 'x', '2', '7', 'A', '2', '8', '0', '8', '6'};
	char replaceString[] = {'0', 'x', '2', '7', 'A', 'E', '8', '0', '8', '6'};
	
	
	// Patch the binary file
	NSData* find = [[NSData alloc] initWithBytes:&findBytes length:4];
	NSData* replace = [[NSData alloc] initWithBytes:&replaceBytes length:4];
	[self copyFrom:[[systemInfo installPath] stringByAppendingString: @"/System/Library/Extensions/AppleIntelGMA950.kext"] toDir:[systemInfo extensionsFolder]];
	editor = [editor initWithData:[[NSData alloc] initWithContentsOfFile:[[systemInfo installPath] stringByAppendingString: @"/System/Library/Extensions/AppleIntelGMA950.kext/Contents/MacOS/AppleIntelGMA950"]]];
	[editor find: find andReplace: replace];
	[[editor data] writeToFile: @"/Volumes/ramdisk/AppleIntelGMA950" atomically: NO];
	[self copyFrom: @"/Volumes/ramdisk/AppleIntelGMA950" toDir:[[systemInfo extensionsFolder] stringByAppendingString: @"/AppleIntelGMA950.kext/Contents/MacOS/"]];	
	
	[find release];
	[replace release];
	
	
	// Patch the Info.plist, and NSDictionary would have worked as well.
	find = [[NSData alloc] initWithBytes:findString length:10];
	replace = [[NSData alloc] initWithBytes:replaceString length:10];
	
	editor = [editor initWithData:[[NSData alloc] initWithContentsOfFile:[[systemInfo installPath] stringByAppendingString: @"/System/Library/Extensions/AppleIntelGMA950.kext/Contents/Info.plist"]]];
	[editor find: find andReplace: replace];
	[[editor data] writeToFile: @"/Volumes/ramdisk/Info.plist" atomically: NO];
	[self copyFrom: @"/Volumes/ramdisk/Info.plist" toDir:[[systemInfo extensionsFolder] stringByAppendingString: @"/AppleIntelGMA950.kext/Contents/"]];	
	
	[find release];
	[replace release];
	[editor release];
	return YES;
}

- (BOOL) patchFramebufferKext
{
#warning patchFramebufferKext is depreciated
	
	// Find: 8680A227
	// Replace: 8680AE27
	
	HexEditor* editor = [HexEditor alloc];
	
	UInt32 findBytes =    0x27A28086;
	UInt32 replaceBytes = 0x27AE8086;
	char findString[] =    {'0', 'x', '2', '7', 'A', '2', '8', '0', '8', '6'};
	char replaceString[] = {'0', 'x', '2', '7', 'A', 'E', '8', '0', '8', '6'};
	
	
	// Patch the binary file
	NSData* find = [[NSData alloc] initWithBytes:&findBytes length:4];
	NSData* replace = [[NSData alloc] initWithBytes:&replaceBytes length:4];
	[self copyFrom:[[systemInfo installPath] stringByAppendingString: @"/System/Library/Extensions/AppleIntelIntegratedFramebuffer.kext"] toDir:[systemInfo extensionsFolder]];
	editor = [editor initWithData:[[NSData alloc] initWithContentsOfFile:[[systemInfo installPath] stringByAppendingString: @"/System/Library/Extensions/AppleIntelIntegratedFramebuffer.kext/AppleIntelIntegratedFramebuffer"]]];
	[editor find: find andReplace: replace];
	[[editor data] writeToFile: @"/Volumes/ramdisk/AppleIntelIntegratedFramebuffer" atomically: NO];
	[self copyFrom: @"/Volumes/ramdisk/AppleIntelIntegratedFramebuffer" toDir:[[systemInfo extensionsFolder] stringByAppendingString: @"/AppleIntelIntegratedFramebuffer.kext/"]];	
	
	[find release];
	[replace release];
	
	
	// Patch the Info.plist, and NSDictionary would have worked as well.
	find = [[NSData alloc] initWithBytes:findString length:10];
	replace = [[NSData alloc] initWithBytes:replaceString length:10];
	
	editor = [editor initWithData:[[NSData alloc] initWithContentsOfFile:[[systemInfo installPath] stringByAppendingString: @"/System/Library/Extensions/AppleIntelIntegratedFramebuffer.kext/Info.plist"]]];
	[editor find: find andReplace: replace];
	[[editor data] writeToFile: @"/Volumes/ramdisk/Info.plist" atomically: NO];
	[self copyFrom: @"/Volumes/ramdisk/Info.plist" toDir:[[systemInfo extensionsFolder] stringByAppendingString: @"/AppleIntelIntegratedFramebuffer.kext/"]];	
	
	[find release];
	[replace release];
	[editor release];
	return YES;
}

- (BOOL) patchIO80211kext
{
#warning patchIO80211kext is depreciated

	NSMutableDictionary* plist = [[NSMutableDictionary alloc] initWithContentsOfFile:[[systemInfo installPath] stringByAppendingString: @"/System/Library/Extensions/IO80211Family.kext/Contents/PlugIns/AppleAirPortBrcm4311.kext/Contents/Info.plist"]];
	NSMutableDictionary *personalities, *bcmpci;
	NSMutableArray* ids;
	[self copyFrom:[[systemInfo installPath] stringByAppendingString: @"/System/Library/Extensions/IO80211Family.kext"] toDir:[systemInfo extensionsFolder]];	
	
	personalities = [[NSMutableDictionary alloc] initWithDictionary:[plist objectForKey: @"IOKitPersonalities"]];
	
	bcmpci = [[NSMutableDictionary alloc] initWithDictionary:[personalities objectForKey: @"Broadcom 802.11 PCI"]];
	ids = [[NSMutableArray alloc] initWithArray:[bcmpci objectForKey: @"IONameMatch"]];
	
	[ids addObject: @"pci14e4,4306"];
	[ids addObject: @"pci14e4,4309"];
	[ids addObject: @"pci14e4,4315"];
	[ids addObject: @"pci14e4,4329"];
	[ids addObject: @"pci14e4,432a"];
	[ids addObject: @"pci14e4,4737"];
	
	if([systemInfo targetOS] <= KERNEL_VERSION(10, 6, 4))
	{
		// 10.6.5 already has theses device id's inscluded.
		// TODO: change this to only add id's if they aren't already there, then this check isn't needed.
		[ids addObject: @"pci14e4,4313"];		
		[ids addObject: @"pci14e4,4320"];
		[ids addObject: @"pci14e4,4324"];
		[ids addObject: @"pci14e4,4353"];
	}
	
	
	
	[bcmpci setObject:ids forKey: @"IONameMatch"];
	[personalities setObject:bcmpci forKey: @"Broadcom 802.11 PCI"];
	[plist setObject:personalities forKey: @"IOKitPersonalities"];
	
	// Save the file and write it to the new one
	[plist writeToFile: @"/Volumes/ramdisk/Info.plist" atomically: NO];
	
	[self copyFrom: @"/Volumes/ramdisk/Info.plist" toDir:[[systemInfo extensionsFolder] stringByAppendingString: @"/IO80211Family.kext/Contents/PlugIns/AppleAirPortBrcm4311.kext/Contents/"]];	
	
	[ids release];
	[bcmpci release];
	[personalities release];
	[plist release];
	
	return YES;
}

//----------			patchBluetooth			----------//
- (BOOL) patchBluetooth
{
#warning  patchBluetooth is depreciated
	if([systemInfo targetOS] <= KERNEL_VERSION(10, 6, 2))
	{
		if(![systemInfo bluetoothDeviceId] || ![systemInfo bluetoothVendorId]) return NO;	// Unknown device / vendor
																							// TODO: if unknown, search through IORegistery
		
		[self copyFrom:[[systemInfo installPath] stringByAppendingString: @"/System/Library/Extensions/IOBluetoothFamily.kext"] toDir:[systemInfo extensionsFolder]];
		
		NSMutableDictionary* plist = [[NSMutableDictionary alloc] initWithContentsOfFile:[[systemInfo installPath] stringByAppendingString: @"/System/Library/Extensions/IOBluetoothFamily.kext/Contents/PlugIns/BroadcomUSBBluetoothHCIController.kext/Contents/Info.plist"]];
		NSMutableDictionary* properties = [[NSMutableDictionary alloc] initWithDictionary:[plist objectForKey: @"IOKitPersonalities"]];
		NSMutableDictionary* bcmusb = [[NSMutableDictionary alloc] initWithDictionary:[properties objectForKey: @"Broadcom2046FamilyUSBBluetoothHCIController_37A"]];
		
		[bcmusb setObject:[[NSNumber alloc] initWithInt:[systemInfo bluetoothDeviceId]] forKey: @"idProduct"];
		[bcmusb setObject:[[NSNumber alloc] initWithInt:[systemInfo bluetoothVendorId]] forKey: @"idVendor"];
		
		[properties setObject: bcmusb forKey: @"Broadcom2046FamilyUSBBluetoothHCIController_37A"];
		[plist setObject: properties forKey: @"IOKitPersonalities"];
		
		[plist writeToFile: @"/Volumes/ramdisk/Info.plist" atomically:NO];
		
		[bcmusb release];
		[properties release];
		[plist release];
		
		
		return [self copyFrom: @"/Volumes/ramdisk/Info.plist" toDir: [[systemInfo extensionsFolder] stringByAppendingString: @"/IOBluetoothFamily.kext/Contents/PlugIns/BroadcomUSBBluetoothHCIController.kext/Contents/Info.plist"]];
	}
	else
	{
		// hack: 10.6.3 doesn't play nicely with alegacy bluetooth plist for the mini 10v.
		//[self deleteFile:[[systemInfo extensionsFolder] stringByAppendingString: @"/IOBluetoothFamily.kext/Contents/PlugIns/BroadcomUSBBluetoothHCIController.kext/Contents/Info.plist"]];
		//[self deleteFile:[[systemInfo extensionsFolder] stringByAppendingString: @"/IOBluetoothFamily.kext/Contents/PlugIns/BroadcomUSBBluetoothHCIController.kext/Contents/Info.plist"]];
		
		return YES;
	}
}


// Legacy, used for pre 10.5.6 boot dvd's (Aka, remove this when 10.5.x support is dropped
//- (BOOL) useLatestKernel
//{
//	NSMutableDictionary*	bootSettings =  [[NSMutableDictionary alloc] initWithContentsOfFile:[sourcePath stringByAppendingString: @"/SupportFiles/machine/General/ExtraFiles/com.apple.Boot.plist"]];
//	
//	[bootSettings setObject: @"mach_kernel_10_5_6" forKey: @"Kernel"];
//	
//	[bootSettings writeToFile: @"/Volumes/ramdisk/com.apple.Boot.plist" atomically: NO];
//	[bootSettings release];
//	return [self copyFrom: @"/Volumes/ramdisk/com.apple.Boot.plist" toDir:[[systemInfo installPath] stringByAppendingString: @"/Extra/"]];
//}

// legacy, used when transitioning form a pre 10.5.6 install to a 10.5.6+ install. Remove when 10.5.x support is dropped
- (BOOL) useSystemKernel
{
#warning  useSystemKernel is depreciated
	
	NSMutableDictionary*	bootSettings =  [[NSMutableDictionary alloc] initWithContentsOfFile:[sourcePath stringByAppendingString: @"/SupportFiles/machine/General/ExtraFiles/com.apple.Boot.plist"]];
	
	[bootSettings setObject: @"mach_kernel" forKey: @"Kernel"];
	
	[bootSettings writeToFile: @"/Volumes/ramdisk/com.apple.Boot.plist" atomically: NO];
	[bootSettings release];
	if([self copyFrom: @"/Volumes/ramdisk/com.apple.Boot.plist" toDir:[[systemInfo installPath] stringByAppendingString: @"/Extra/"]])
	{
		bootSettings =  [[NSMutableDictionary alloc] initWithContentsOfFile:[sourcePath stringByAppendingString: @"/SupportFiles/machine/General/ExtraFiles/com.apple.Boot.plist"]];
		if(![[bootSettings objectForKey: @"Kernel"] isEqualToString:@"mach_kernel_10_5_6"])
		{
			[bootSettings release];
			return [self deleteFile:[[systemInfo installPath] stringByAppendingString: @"/mach_kernel_10_5_6"]];
		} 
		else {
			[bootSettings release];
			ExtendedLog(@"Unable to revert to system kernel, keeping mach_kernel_10_5_6");
			return NO;
		}
		
	} else {
		return NO;
	}
}

//----------			copyDependencies			----------//
- (BOOL) copyDependencies
{
#warning  copyDependencies is depreciated
	
	//[self removeBlacklistedKexts];
	[self makeDir:@"/Volumes/ramdisk/Extensions"];
	//[self copyFrom:[[systemInfo installPath] stringByAppendingString: @"/System/Library/Extensions/"] toDir:@"/Volumes/ramdisk/Extensions/"];
	
	return YES;
}

- (BOOL) removeBlacklistedKexts
{
#warning removeBlacklistedKexts is depreciated
	ExtendedLog(@"Remove blacklisted items");
	NSDictionary*	machineplist= [[NSDictionary dictionaryWithContentsOfFile:[sourcePath stringByAppendingString:@nbiMachinePlist]] objectForKey:@"General"];	
	
	NSArray* blacklist = [[systemInfo machineInfo] objectForKey:@"Kext Blacklist"];
	NSEnumerator* kexts = [blacklist objectEnumerator];
	
	// Remove machien specific extension
	NSString* kext;
	while((kext = [kexts nextObject]))
	{
		ExtendedLog(@"Removing %@", kext);
		if(![kext isEqualToString:@""])
		{
			// TODO: verify kext does not go below root or /S/L/E. (aka Security)
			// TODO: verify kext is removed
			[self makeDir:   [[systemInfo installPath] stringByAppendingString:@"/System/Library/BackupExtensions/"]];
			[self copyFrom:  [[systemInfo installPath] stringByAppendingFormat:@"/System/Library/Extensions/%@", kext] toDir:[[systemInfo installPath] stringByAppendingString:@"/System/Library/BackupExtensions/"]];
			[self deleteFile:[[systemInfo installPath] stringByAppendingFormat:@"/System/Library/Extensions/%@", kext]];
			
		}
	}
	
	
	// Repeat... (non generic machines, otherwise this would happen twice)
	kexts = [[machineplist objectForKey:@nbiMachineKextBlacklist] objectEnumerator];
	while(![@nbiMachineGeneric isEqualToString:[[systemInfo machineInfo] objectForKey:@nbiMachineSupportFiles]] && ((kext = [kexts nextObject])))
	{
		ExtendedLog(@"Removing %@", kext);
		if(![kext isEqualToString:@""])
		{
			// TODO: verify kext does not go below root. (aka Security issue)
			[self makeDir:   [[systemInfo installPath] stringByAppendingString:@"/System/Library/BackupExtensions/"]];
			[self copyFrom:  [[systemInfo installPath] stringByAppendingFormat:@"/Volumes/ramdisk/Extensions/%@", kext] toDir:[[systemInfo installPath] stringByAppendingString:@"/System/Library/BackupExtensions/"]];
			[self deleteFile:[[systemInfo installPath] stringByAppendingFormat:@"/Volumes/ramdisk/Extensions/%@", kext]];
			[self deleteFile:[[systemInfo installPath] stringByAppendingFormat:@"/System/Library/Extensions/%@", kext]];
		}
	}
	
	return YES;
}



#endif

@end