//
//  Installer.m
//  NetbookInstaller
//
//  Created by Evan Lojewski on 5/16/09.
//  Copyright 2009. All rights reserved.
//

#import "Installer.h"

@implementation Installer


- (void)remountTargetWithPermissions
{
	NSLog(@"SystemInfo = %@", systemInfo);
	if([[systemInfo installPath] isEqualToString:@"/"]) return;
	
	NSArray* nsargs = [[NSArray alloc] initWithObjects: 
						@"-u", @"-o", @"owners", [@"/dev/" stringByAppendingString: [systemInfo bootPartition]], nil];

	
	[self runCMD:"/sbin/mount" withArgs:nsargs];
	
	[nsargs release];
	
//	system([[@"/sbin/mount -u -o owners /dev/" stringByAppendingString: [systemInfo bootPartition]] cStringUsingEncoding:NSASCIIStringEncoding]);
}

- (void) mountRamDisk
{	
	[self unmountRamDisk];
	// TODO: Ensure that /Volumes/ramdisk doesnt exist

	// replace with runCMDasUser
	system("/usr/sbin/diskutil eraseVolume HFS+ ramdisk `hdid -nomount ram://523648`");

	NSLog(@"Remounting ramdisk");

	system([@"/sbin/mount -u -o owners /Volumes/ramdisk" cStringUsingEncoding:NSASCIIStringEncoding]);

	NSLog(@"Permissions fixed");
	
}
	
- (void) unmountRamDisk
{
//	diskutil eject /Volumes/ramdisk
	NSArray* nsargs = [[NSArray alloc] initWithObjects: 
					   @"eject", @"/Volumes/ramdisk/", nil];


	[self runCMD:"/usr/sbin/diskutil" withArgs:nsargs];
	[nsargs release];
}
		
- (void) systemInfo: (SystemInformation*) info
{
	systemInfo = info;
}

- (BOOL) getAuthRef
{
	if(getuid() == 0) return YES;
	AuthorizationRef authorizationRef;
	
    AuthorizationItem right = { "com.meklort.netbookinstaller", 0, NULL, 0 };
	AuthorizationItem admin = { kAuthorizationRightExecute, 0, NULL, 0};
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
		//NSLog(@"RDPPFramework NSFileManager+RDPPFrameworkAdditions secureCopy:toPath:authenticate: failed to create AuthorizationRef.  Return code was %d", status);
		return NO;
	}	
	
	// We only use this were we are copying to /Library so always athorize.
	status = AuthorizationCopyRights(authorizationRef, &rightSet, kAuthorizationEmptyEnvironment, flags, NULL);
	if (status!=errAuthorizationSuccess)
	{
		//NSLog(@"RDPPFramework NSFileManager+RDPPFrameworkAdditions secureCopy:toPath:authenticate: failed to authorize.  Return code was %d", status);
		return NO;
	}
	
	authRef = authorizationRef;
	
	return YES;
}



- (BOOL) copyFrom: (NSString*) source toDir: (NSString*) destination
{
	BOOL returnVal = NO;
	NSArray* nsargs = [[NSArray alloc] initWithObjects:@"-rf", source, destination, nil];
	
	returnVal = [self runCMD:"/bin/cp" withArgs:nsargs];
	
	[nsargs release];
	
	return returnVal;
	
}

- (BOOL) moveFrom: (NSString*) source to: (NSString*) destination
{
	BOOL returnVal;
	NSArray* nsargs = [[NSArray alloc] initWithObjects:@"-f", source, destination, nil];

	
	returnVal = [self runCMD:"/bin/mv" withArgs:nsargs];
	
	[nsargs release];
	
	return returnVal;
	
}

- (BOOL) runCMD: (char*) command withArgs: (NSArray*) nsargs
{
	if(getuid() == 0)
	{
		// we are already root, so we dont neet to escilate our privleges
		return [self runCMDAsUser: command withArgs: nsargs];
	}
	else
	{
		// We are a regular user. We need to escilate our privledges.
		return [self runCMDAsRoot: command withArgs: nsargs];
		
	}
}
		
- (BOOL) runCMDAsUser: (char*) command withArgs: (NSArray*) nsargs
{
	NSMutableString* run = [NSMutableString alloc];
	NSMutableString* commandString = [[NSMutableString alloc] initWithCString:command];
	NSMutableString* escapedString;
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
	
	while(i < [nsargs count])
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
	//NSLog(@"Executing: %@", run);
	// TODO: change away from system and twards one of teh exec commands. We also may need to catch the output or return codes of any command we run (instead of retuning YES)
	system([run cStringUsingEncoding:NSASCIIStringEncoding]);	
	
	if(run != nil) [run release];
	if(commandString != nil) [commandString release];
	if(escapedString != nil) [escapedString release];
	return YES;
}

- (BOOL) runCMDAsRoot: (char*) command withArgs: (NSArray*) nsargs
{
	FILE* pipe = NULL;
	char* args[([nsargs count]) + 1];
	int i = 0;
	OSStatus status;
	
	while(i < [nsargs count])
	{
		args[i] = (char*)[[nsargs objectAtIndex:i] cStringUsingEncoding:NSASCIIStringEncoding];
		i++;
	}
	args[i] = NULL;

	status = AuthorizationExecuteWithPrivileges(authRef, command, kAuthorizationFlagDefaults, args, &pipe);
	
	char string[10];
	if(status == 0) while(fgets(string, 10, pipe) != NULL);	// Block untill command has completed

	fclose(pipe);

	
	if(status == 0) return YES;
	else return NO;
	
}

- (BOOL) hidePath: (NSString*) path
{
	BOOL returnVal = NO;

	// /Volumes/target/usr/bin/chflag hidden path

	NSArray* nsargs = [[NSArray alloc] initWithObjects:@"hidden", path, nil];
	
	if(!(returnVal = [self runCMD: (char*)[[[systemInfo installPath] stringByAppendingString: @"/usr/bin/chflags"] cStringUsingEncoding:NSASCIIStringEncoding] withArgs:nsargs]))
	{
		returnVal = [self runCMD:"/usr/bin/chflags" withArgs:nsargs];	// rathen than distributing chflags, we just try running it in both locations
	}
	
	[nsargs release];
	
	return returnVal;
}



- (BOOL) showPath: (NSString*) path
{
	// /Volumes/target/usr/bin/chflag nohidden path
	BOOL returnVal = NO;
	
	NSArray* nsargs = [[NSArray alloc] initWithObjects:@"nohidden", path, nil];
	
	if(!(returnVal = [self runCMD: (char*)[[[systemInfo installPath] stringByAppendingString: @"/usr/bin/chflags"] cStringUsingEncoding:NSASCIIStringEncoding] withArgs:nsargs]))
	{
		returnVal = [self runCMD:"/usr/bin/chflags" withArgs:nsargs];	// rathen than distributing chflags, we just try running it in both locations
	}
	
	[nsargs release];
	
	return returnVal;
	
}


- (BOOL) setPermissions: (NSString*) perms onPath: (NSString*) path recursivly: (BOOL) recursiv
{
	// /bin/chmod [-R] perms path

	NSMutableArray* nsargs = [[NSMutableArray alloc] init];
	
	if(recursiv) 	[nsargs addObject: @"-R"];
	[nsargs addObject:perms];
	[nsargs addObject:path];
	
	return [self runCMD:"/bin/chmod" withArgs:nsargs];


}

- (BOOL) setOwner: (NSString*) owner andGroup: (NSString*) group onPath: (NSString*) path recursivly: (BOOL) recursiv
{
	// /usr/sbin/chown [-R] owner:group path
	NSMutableArray* nsargs = [[NSMutableArray alloc] init];
	
	if(recursiv) 	[nsargs addObject: @"-R"];
	[nsargs addObject:[[owner stringByAppendingString: @":"] stringByAppendingString:group]];
	[nsargs addObject:path];
	
	return [self runCMD:"/usr/sbin/chown" withArgs:nsargs];
}


- (BOOL) makeDir: (NSString*) dir
{
	BOOL returnVal = NO;
	// /bin/mkdir -p dir

	NSArray* nsargs = [[NSArray alloc] initWithObjects:@"-p", dir, nil];
	
	returnVal = [self runCMD:"/bin/mkdir" withArgs:nsargs];
	
	[nsargs release];
	
	return returnVal;
}

-(BOOL) deleteFile: (NSString*) file
{
	BOOL returnVal = NO;
	// /bin/rm -rf file

	NSArray* nsargs = [[NSArray alloc] initWithObjects:@"-rf", file, nil];
	
	returnVal = [self runCMD:"/bin/rm" withArgs:nsargs];
	
	[nsargs release];
	
	return returnVal;
	
}







// Installer Options
- (BOOL) installBootloader: (NSDictionary*) bootloaderType
{
	NSScanner* scanner = [[NSScanner alloc] initWithString:[systemInfo bootPartition]];
	[scanner setCharactersToBeSkipped: [[NSCharacterSet decimalDigitCharacterSet] invertedSet]];
	[scanner scanInteger: NULL];	// scan past disk number
	
	NSString* bsdDisk = [[systemInfo bootPartition] substringToIndex:[scanner scanLocation]];		// strip off partition number
	
	/**
	 ** Warning - 10.6 hack follows, to be removed in the future... (or at least make it not hackish)
	 **/
	if([systemInfo targetOS] >= KERNEL_VERSION(10,6,0))
	{
		// Force correct bootloader
		bootloaderType = [[[systemInfo bootloaderDict] objectForKey:@"Bootloaders"] objectForKey:@"Chameleon R640"];
	}
	
	
	
	if(!bootloaderType) {
		NSLog(@"Unable to install bootlaoder: no value passed");
		return NO;
	} else {
		NSLog(@"Installing booter to /dev/r%@", [systemInfo bootPartition]);
	}
	NSString* bootPath;
	if([[systemInfo installedBootloader] isEqualToDictionary:bootloaderType]) NSLog(@"Bootloader already installed, insatlling anyways");
	
	bootPath = [[[[NSBundle mainBundle] resourcePath] stringByAppendingString: @"/SupportFiles/bootloader/"] stringByAppendingString:[bootloaderType objectForKey:@"Visible Name"]];
	
	bootPath = [bootPath stringByAppendingString:@"/"];
	NSMutableArray* nsargs = [[NSMutableArray alloc] init];
	
	[nsargs addObject: @"-f"];
	[nsargs addObject:[bootPath stringByAppendingString: @"/boot0"]];
	[nsargs addObject: @"-u"];
	[nsargs addObject: @"-y"];
	
	[nsargs addObject:[@"/dev/r" stringByAppendingString: bsdDisk]];

//	[self runCMD:(char*)[[bootPath stringByAppendingString: @"/fdisk"] cStringUsingEncoding:NSASCIIStringEncoding] withArgs:nsargs];
	[self runCMD:"/usr/sbin/fdisk" withArgs:nsargs];


	NSMutableArray* nsargs2 = [[NSMutableArray alloc] init];

	[nsargs2 addObject:[@"if=" stringByAppendingString:[bootPath stringByAppendingString: @"boot1h"]]];
	[nsargs2 addObject:[@"of=/dev/r" stringByAppendingString: [systemInfo bootPartition]]];
	
	
	[self runCMD:"/bin/dd" withArgs:nsargs2];
	
	[self copyFrom:[bootPath stringByAppendingString: @"/boot"] toDir:[[systemInfo installPath] stringByAppendingString: @"/"]];
	[self hidePath:[[systemInfo installPath] stringByAppendingString: @"/boot"]];
	
	[nsargs	 release];
	[nsargs2 release];
	[scanner release];
	
	return YES;

}

- (BOOL) installExtensions
{
	BOOL status = YES;
	NSMutableArray* sourceExtensions = [[NSMutableArray alloc] initWithCapacity: 10];
	NSString* destinationExtensions =  [[[systemInfo installPath] stringByAppendingString: @"/Extra/"] stringByAppendingString:[[systemInfo machineInfo] objectForKey:@"Extensions Directory"]];
	NSEnumerator* sources;
	NSString* source;

	
	if([systemInfo targetOS] >= KERNEL_VERSION(10, 6, 0))
	{
		// Copy in 10.6 Extensions
		[sourceExtensions addObject: [[[[[NSBundle mainBundle] resourcePath] stringByAppendingString: @"/SupportFiles/machine/"] stringByAppendingString: [[systemInfo machineInfo] objectForKey:@"Long Name"]] stringByAppendingString: @"/10.6 Extensions/"]];
		if(![@"General" isEqualToString:[[systemInfo machineInfo] objectForKey:@"Long Name"]]) [sourceExtensions addObject: [[[NSBundle mainBundle] resourcePath] stringByAppendingString: @"/SupportFiles/machine/General/10.6 Extensions/"]];
		
	}
	else
	{
		// Copy in 10.5 Extensions
		[sourceExtensions addObject: [[[[[NSBundle mainBundle] resourcePath] stringByAppendingString: @"/SupportFiles/machine/"] stringByAppendingString: [[systemInfo machineInfo] objectForKey:@"Long Name"]] stringByAppendingString: @"/10.5 Extensions/"]];
		if(![@"General" isEqualToString:[[systemInfo machineInfo] objectForKey:@"Long Name"]]) [sourceExtensions addObject: [[[NSBundle mainBundle] resourcePath] stringByAppendingString: @"/SupportFiles/machine/General/10.5 Extensions/"]];
	}

	
	[sourceExtensions addObject: [[[[[NSBundle mainBundle] resourcePath] stringByAppendingString: @"/SupportFiles/machine/"] stringByAppendingString: [[systemInfo machineInfo] objectForKey:@"Long Name"]] stringByAppendingString: @"/Extensions/"]];

	if(![@"General" isEqualToString:[[systemInfo machineInfo] objectForKey:@"Long Name"]]) [sourceExtensions addObject: [[[NSBundle mainBundle] resourcePath] stringByAppendingString: @"/SupportFiles/machine/General/Extensions/"]];
	
	
	
	sources = [sourceExtensions objectEnumerator];	// An enumerator could hav ebeen used too
	while(source = [sources nextObject]) {
		if(![self copyFrom: source toDir: destinationExtensions]) status = NO;
	}
	
	
	[sourceExtensions release];
	return status;
}

- (BOOL) hideFiles
{
	// Hidding /boot, /Extra, /Extra.bak
	[self hidePath:[[systemInfo installPath] stringByAppendingString: @"/boot"]];
	[self hidePath:[[systemInfo installPath] stringByAppendingString: @"/Extra"]];
	[self hidePath:[[systemInfo installPath] stringByAppendingString: @"/Extra.bak"]];

	return YES;
}

- (BOOL) showFiles
{
	// Showing /boot, /Extra, /Extra.bak
	[self showPath:[[systemInfo installPath] stringByAppendingString: @"/boot"]];
	[self showPath:[[systemInfo installPath] stringByAppendingString: @"/Extra"]];
	[self showPath:[[systemInfo installPath] stringByAppendingString: @"/Extra.bakb"]];

	return YES;
}

- (BOOL) installDSDT
{
	// TODO: make the dsdt compile / decompiler into a framework / dylib

	[self makeDir: @"/Volumes/ramdisk/dsdt/"];
	[self makeDir: @"/Volumes/ramdisk/dsdt/patches"];
	[self copyFrom:[[[NSBundle mainBundle] resourcePath] stringByAppendingString: @"/SupportFiles/DSDTPatcher/"] toDir: @"/Volumes/ramdisk/dsdt/"];

	[self copyFrom:[[[[NSBundle mainBundle] resourcePath] stringByAppendingString: @"/SupportFiles/machine/General"] stringByAppendingString:@"/DSDT Patches/"]  toDir: @"/Volumes/ramdisk/dsdt/patches/"];
	[self copyFrom:[[[[[NSBundle mainBundle] resourcePath] stringByAppendingString: @"/SupportFiles/machine/"] stringByAppendingString:[[systemInfo machineInfo] objectForKey:@"Long Name"]] stringByAppendingString:@"/DSDT Patches/"]  toDir: @"/Volumes/ramdisk/dsdt/patches/"];

	NSMutableDictionary* genPatches= [NSMutableDictionary dictionaryWithDictionary: [[[NSDictionary dictionaryWithContentsOfFile:[[[NSBundle mainBundle]  resourcePath] stringByAppendingString:@"/SupportFiles/machine.plist"]] objectForKey:@"General"] objectForKey: @"DSDT Patches"]];	

	NSDictionary* patches = [[systemInfo machineInfo] objectForKey:@"DSDT Patches"];

	NSMutableString* configFile = [[NSMutableString alloc] initWithString:@""];
	NSEnumerator* keys = [patches keyEnumerator];
	NSString* key;
	NSError* error;
	
	while(key = [keys nextObject])
	{
		[genPatches setObject:[patches objectForKey:key] forKey:key];
	}
	keys = [genPatches keyEnumerator];
	
	while(key = [keys nextObject])
	{
		[configFile appendString:@":"];
		[configFile appendString:key];
		[configFile appendString:@":"];
		[configFile appendString:[genPatches objectForKey:key]];
		[configFile appendString:@":\r\n"];
	}
	
	[configFile writeToFile:@"/Volumes/ramdisk/config" atomically:NO encoding:NSASCIIStringEncoding error:&error];
	[self copyFrom:@"/Volumes/ramdisk/config" toDir:@"/Volumes/ramdisk/dsdt/"];

	NSMutableArray* nsargs = [[NSMutableArray alloc] init];
	
	[self runCMD:"/Volumes/ramdisk/dsdt/DSDTPatcher" withArgs:nsargs];

	
	[configFile release];
	[nsargs release];
	
	// The dsdt patcher doesnt konw where to put it, so we do it here.
	return [self copyFrom: @"/Volumes/ramdisk/dsdt/Volumes/ramdisk/dsdt/dsdt.aml" toDir:[[systemInfo installPath] stringByAppendingString: @"/Extra/"]];

}

// FIXME: This will not work when run as root
- (BOOL) setRemoteCD: (BOOL) remoteCD
{

	NSMutableDictionary *dict;
	NSDictionary* save;		// TOOD: test as it may not be needed

	dict = [[NSMutableDictionary alloc] initWithDictionary:(NSDictionary*)CFPreferencesCopyMultiple(NULL,
													CFSTR("com.apple.NetworkBrowser"),
													kCFPreferencesCurrentUser,
													kCFPreferencesAnyHost)];
	
	
	if(([[dict objectForKey: @"EnableODiskBrowsing"] boolValue] && [[dict objectForKey: @"ODSSupported"] boolValue]) == remoteCD) return YES;
	
	[dict setObject:[[NSNumber alloc] initWithBool:remoteCD] forKey: @"EnableODiskBrowsing"];
	[dict setObject:[[NSNumber alloc] initWithBool:remoteCD] forKey: @"ODSSupported"];
	
	
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
	
	return YES;
}

- (BOOL) dissableHibernation: (BOOL) dissable 
{
	UInt8 state;
	NSFileManager* manager = [NSFileManager defaultManager];
	
	// If the preference plist doesnt exist, copy a default one in.
	if(![manager fileExistsAtPath:[[systemInfo installPath] stringByAppendingString:@"/Library/Preferences/SystemConfiguration/com.apple.PowerManagement.plist"]])
	{
		[self makeDir:[[systemInfo installPath] stringByAppendingString:@"/Library/Preferences/SystemConfiguration/"]];
		if(![@"General" isEqualToString:[[systemInfo machineInfo] objectForKey:@"Long Name"]]) [self copyFrom:[[[NSBundle mainBundle] resourcePath] stringByAppendingString: @"/SupportFiles/machine/General/Preferences/com.apple.PowerManagement.plist"] toDir: [[systemInfo installPath] stringByAppendingString:@"/Library/Preferences/SystemConfiguration/"]];
		[self copyFrom:[[[[[NSBundle mainBundle] resourcePath] stringByAppendingString: @"/SupportFiles/machine/"] stringByAppendingString: [[systemInfo machineInfo] objectForKey:@"Long Name"]] stringByAppendingString: @"/Preferences/com.apple.PowerManagement.plist"] toDir: [[systemInfo installPath] stringByAppendingString:@"/Library/Preferences/SystemConfiguration/"]];

	}
	
	
	NSMutableDictionary*	propertyList= [[NSMutableDictionary alloc] initWithContentsOfFile: [[systemInfo installPath] stringByAppendingString:@"/Library/Preferences/SystemConfiguration/com.apple.PowerManagement.plist"]];
	
	NSMutableDictionary* powerStates = [[NSMutableDictionary alloc] initWithDictionary:[propertyList objectForKey: @"Custom Profile"]];
	NSMutableDictionary* acPowerState = [[NSMutableDictionary alloc] initWithDictionary:[powerStates objectForKey: @"AC Power"]];
	NSMutableDictionary* battPowerState = [[NSMutableDictionary alloc] initWithDictionary:[powerStates objectForKey: @"Battery Power"]];
	
	if(dissable) state = 3;
	else state = 0;
		
	[acPowerState   setObject: [NSNumber numberWithInt:state] forKey: @"Hibernate Mode"];
	[battPowerState setObject: [NSNumber numberWithInt:state] forKey: @"Hibernate Mode"];


		
	[powerStates setObject: acPowerState forKey: @"AC Power"];
	[powerStates setObject: battPowerState forKey: @"Battery Power"];
	[propertyList setObject: powerStates forKey: @"Custom Profile"];


	[propertyList writeToFile: @"/Volumes/ramdisk/com.apple.PowerManagement.plist" atomically: NO]; 
	if(state == 3) [self deleteFile:[[systemInfo installPath] stringByAppendingString: @"/var/vm/sleepimage"]];
	
	[propertyList release];
	[acPowerState release];
	[battPowerState release];

	return [self copyFrom: @"/Volumes/ramdisk/com.apple.PowerManagement.plist" toDir:[[systemInfo installPath] stringByAppendingString: @"/Library/Preferences/SystemConfiguration/"]];
}

- (BOOL) setQuietBoot: (BOOL) quietBoot
{
	NSMutableDictionary*	bootSettings =  [[NSMutableDictionary alloc] initWithContentsOfFile:[[systemInfo installPath] stringByAppendingString: @"/Extra/com.apple.Boot.plist"]];
	if(!bootSettings) {
		bootSettings =  [[NSMutableDictionary alloc] initWithContentsOfFile:[[[NSBundle mainBundle] resourcePath] stringByAppendingString: @"/SupportFiles/machine/General/ExtraFiles/com.apple.Boot.plist"]];
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
	
	return [self copyFrom: @"/Volumes/ramdisk/com.apple.Boot.plist" toDir:[[systemInfo installPath] stringByAppendingString: @"/Extra/"]];
}

- (BOOL) fixBluetooth
{
	return [self deleteFile:[[systemInfo installPath] stringByAppendingString: @"/Library/Preferences/com.apple.Bluetooth.plist"]];
}

- (BOOL) copyMachineFilesFrom: (NSString*) source toDir: (NSString*) destination
{
	if(![@"General" isEqualToString:[[systemInfo machineInfo] objectForKey:@"Long Name"]]) [self copyFrom: [[[[NSBundle mainBundle] resourcePath] stringByAppendingString: @"/SupportFiles/machine/General/"] stringByAppendingString:source] toDir: [[systemInfo installPath] stringByAppendingString: destination]];
	return [self copyFrom: [[[[[[NSBundle mainBundle] resourcePath] stringByAppendingString: @"/SupportFiles/machine/"] stringByAppendingString: [[systemInfo machineInfo] objectForKey:@"Long Name"]] stringByAppendingString: @"/"] stringByAppendingString:source] toDir: [[systemInfo installPath] stringByAppendingString: destination]];

	
//	return YES;
}


// Support Files
- (BOOL) installExtraFiles
{
	// TODO: remove all of these functions, have been replaced by copyMachineFilesFrom: toDir:
	return [self copyMachineFilesFrom: @"ExtraFiles/" toDir: @"/Extra/"];
}

- (BOOL) installDisplayProfile
{
	return [self copyMachineFilesFrom: @"DisplayProfiles/" toDir: @"/Library/ColorSync/Profiles/"];
}

- (BOOL) installSystemConfiguration
{
	return [self copyMachineFilesFrom: @"SystemConfiguration/" toDir: @"/System/Library/SystemConfiguration/"];
}

- (BOOL) installPrefPanes
{
	return [self copyMachineFilesFrom: @"3rdPartyPrefPanes/" toDir: @"/Library/PreferencePanes/"];
}

- (BOOL) installSystemPrefPanes
{
	return [self copyMachineFilesFrom: @"PrefPanes/" toDir: @"/System/Library/PreferencePanes/"];
}

- (BOOL) installLaunchAgents
{
	[self copyMachineFilesFrom: @"LaunchAgents/" toDir: @"/Library/LaunchAgents/"];
	return [self copyMachineFilesFrom: @"LaunchDaemons/" toDir: @"/Library/LaunchDaemons/"];

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


// Kext support (patching and copying)
- (BOOL) patchGMAkext
{
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
	[ids addObject: @"pci14e4,4320"];
	[ids addObject: @"pci14e4,4324"];
	[ids addObject: @"pci14e4,4329"];
	[ids addObject: @"pci14e4,432a"];

	
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



- (BOOL) patchAppleUSBEHCI
{
	NSMutableDictionary* infoPlist;
	[self copyFrom:[[systemInfo installPath] stringByAppendingString: @"/System/Library/Extensions/IOUSBFamily.kext"] toDir:[systemInfo extensionsFolder]];
	infoPlist = [[NSMutableDictionary alloc] initWithContentsOfFile:[[systemInfo installPath] stringByAppendingString: @"/System/Library/Extensions/IOUSBFamily.kext/Contents/PlugIns/AppleUSBEHCI.kext/Contents/Info.plist"]];

	[infoPlist setObject:@"1.0" forKey:@"OSBundleCompatibleVersion"];
	[infoPlist writeToFile: @"/Volumes/ramdisk/Info.plist" atomically:NO];
	
	[infoPlist release];

	return [self copyFrom: @"/Volumes/ramdisk/Info.plist" toDir: [[systemInfo extensionsFolder] stringByAppendingString: @"/IOUSBFamily.kext/Contents/PlugIns/AppleUSBEHCI.kext/Contents/Info.plist"]];

}



//----------			installLocalExtensions			----------//
- (BOOL) installLocalExtensions
{
	BOOL status = YES;
	NSMutableArray* sourceExtensions = [[NSMutableArray alloc] init];
	
//	NSString* destinationExtensions =  [[[systemInfo installPath] stringByAppendingString: @"/Extra/"] stringByAppendingString:[[systemInfo machineInfo] objectForKey:@"Extensions Directory"]];
	
	// This is really ONLY for clamshell display.kext
	NSString* destinationExtensions =  [[systemInfo installPath] stringByAppendingString: @"/System/Library/Extensions/"];
	//NSString* destinationExtensions = [systemInfo extensionsFolder];
	
	[sourceExtensions addObject: [[[[[NSBundle mainBundle] resourcePath] stringByAppendingString: @"/SupportFiles/machine/"] stringByAppendingString: [[systemInfo machineInfo] objectForKey:@"Long Name"]] stringByAppendingString: @"/LocalExtensions/"]];	
	if(![@"General" isEqualToString:[[systemInfo machineInfo] objectForKey:@"Long Name"]]) [sourceExtensions addObject: [[[NSBundle mainBundle] resourcePath] stringByAppendingString: @"/SupportFiles/machine/General/LocalExtensions/"]];
	
	
	
	// An iterator could hav ebeen used too
	while([sourceExtensions count] > 0) {
		NSString* current = [sourceExtensions objectAtIndex: 0];
		[sourceExtensions removeObjectAtIndex: 0];
		if(![self copyFrom: current toDir: destinationExtensions]) status = NO;
	}
	
	[sourceExtensions release];
	
	return status;
}



//----------			copyDependencies			----------//
- (BOOL) copyDependencies
{
	if(
	   (([systemInfo hostOS] >= KERNEL_VERSION(10, 6, 0)) && ([systemInfo targetOS] >= KERNEL_VERSION(10, 6, 0))) ||	// 10.6 to any
	   (([systemInfo hostOS] <  KERNEL_VERSION(10, 6, 0)) && ([systemInfo targetOS] <  KERNEL_VERSION(10, 6, 0)))		// 10.5 to 10.5
	   )
	{
		[self makeDir:@"/Volumes/ramdisk/Extensions"];
		[self copyFrom:[[systemInfo installPath] stringByAppendingString: @"/System/Library/Extensions/"] toDir:@"/Volumes/ramdisk/Extensions/"];
	}
	else 
	{
		// Only use the white list if you are creating a 10.6 USB boot disk and re are not on 10.6. This is due to an updated kextcache that will *NOT* run on 10.5 even in a chroot
		NSString *whitelistString = [[NSString alloc] initWithContentsOfFile:[[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/kext_whitelist"]]; // reads file into memory as an NSString
		NSArray *whitelist = [whitelistString componentsSeparatedByString:@"\n"]; // each line, adjust character for line endings
		
		int i = 0;
		while(i < [whitelist count])
		{
			if(![[whitelist objectAtIndex:i] isEqualToString:@""]) [self copyFrom:[[[systemInfo installPath] stringByAppendingString: @"/System/Library/Extensions/"]stringByAppendingString:[whitelist objectAtIndex:i]] toDir:[systemInfo extensionsFolder]];
			i++;
		}
		
	}

	
	
	// Move to a grey list or similar"
	[self deleteFile:@"/Volumes/ramdisk/Extensions/AppleHDA.kext"];

	//[self copyFrom:[[systemInfo installPath] stringByAppendingString: @"/System/Library/Extensions/"] toDir:[[systemInfo installPath] stringByAppendingString: [systemInfo extensionsFolder]]];
	
		
	return YES;
}


- (BOOL) installMirrorFriendlyGraphics
{
	NSString* source = [[[NSBundle mainBundle] resourcePath] stringByAppendingString: @"/SupportFiles/OldGMA/"];	 
	return [self copyFrom: source toDir: [systemInfo extensionsFolder]];
}



// This generates and mkext in <install>/Extra/Extensions.mkext FROM /Volumes/ramdisk/Extensions
// FIXME: this is very (extremely?) ugly, I absolutely will rework this. If I dont and you see it in svn, let me know.
- (BOOL) generateExtensionsCache
{
	[self setOwner:@"root" andGroup:@"wheel" onPath: [systemInfo installPath] recursivly: NO];
	
	
	[self setPermissions: @"644" onPath: @"/Volumes/ramdisk/Extensions/" recursivly: YES];
	[self setOwner:@"root" andGroup:@"wheel" onPath: @"/Volumes/ramdisk/Extensions/" recursivly: YES];
	
//	[self setPermissions: @"755" onPath: [[systemInfo installPath] stringByAppendingString:@"/System/Library/Extensions/"] recursivly: YES];
//	[self setOwner:@"root" andGroup:@"wheel" onPath: [[systemInfo installPath] stringByAppendingString:@"/System/Library/Extensions/"] recursivly: YES];
	
	[self setPermissions: @"755" onPath: [systemInfo extensionsFolder] recursivly: YES];
	[self setOwner:@"root" andGroup:@"wheel" onPath: [systemInfo extensionsFolder] recursivly: YES];
	
	// Remove prvious mkexts
	[self deleteFile:[[systemInfo installPath] stringByAppendingString: @"/Extra/Extensions.mkext"]];

	
	if((([systemInfo hostOS] >= KERNEL_VERSION(10, 6, 0)) && ([systemInfo targetOS] >= KERNEL_VERSION(10, 6, 0))) || [systemInfo targetOS] <= KERNEL_VERSION(10, 6, 0))
	{
		
		[self deleteFile:[[systemInfo installPath] stringByAppendingString: @"/System/Library/Extensions.mkext"]];
		[self deleteFile:[[systemInfo installPath] stringByAppendingString: @"/System/Library/Caches/com.apple.kext.caches/Startup/Extensions.mkext"]];
		
		
		NSLog(@"Copied /System/Library/Extensions");	
		
		// Copy /Extra/Extensions/* to /Volumes/ramdisk/Extensions, overwriting any /S/L/E kexts previously copied there in [self copyDep]
		[self copyFrom: [[systemInfo extensionsFolder] stringByAppendingString:@"/"] toDir: @"/Volumes/ramdisk/Extensions/"];
		
		[self removeBlacklistedKexts];
		
		//sudo kextcache -a i386 -m <installPath>/Extra/Extensions.mkext <installPath>/Extra/Mini9Ext/ /Sytem/Library/Extensions
		
		NSMutableArray* nsargs4 = [[NSMutableArray alloc] init];
		NSMutableArray* nsargs5 = [[NSMutableArray alloc] init];
		//	NSMutableArray* nsargs6 = [[NSMutableArray alloc] init];
		
		
		
		
		NSArray* nsargs = [[NSArray alloc] initWithObjects:[systemInfo installPath], 
						   @"/usr/sbin/kextcache", @"-a", @"i386", @"-m", @"/Extra/Extensions.mkext", @"/Volumes/ramdisk/Extensions/", nil];
		
		
		
		
		
		// kextcache -a i386 -m /System/Library/Extensions.mkext /System/Library/Extensions/
		
		//chroot "$3" /usr/sbin/kextcache -system-caches
		
		NSArray* nsargs2 = [[NSArray alloc] initWithObjects:[systemInfo installPath], 
							@"/usr/sbin/kextcache", @"-a", @"i386", @"-m", @"/System/Library/Extensions.mkext", @"/System/Library/Extensions/", nil];
		
		
		// kextcache -l -m /System/Library/Caches/com.apple.kext.caches/Startup/Extensions.mkext /System/Library/Extensions/
		
		NSArray* nsargs3 = [[NSArray alloc] initWithObjects:[systemInfo installPath], 
							@"/usr/sbin/kextcache", @"-a", @"i386", @"-l", @"-m", @"/System/Library/Caches/com.apple.kext.caches/Startup/Extensions.mkext", @"/System/Library/Extensions/", nil];
		
		
	
		
		
		NSLog(@"Generating extensions Cache");
		setenv("_com_apple_kextd_skiplocks", "1", 1);	    // This let kexts cache run before the 5 minut delay imposed by kextd
		
		
		// Remount ramdisk so it's visible in the chroot
		NSDictionary* info = [ systemInfo getFileSystemInformation: @"/Volumes/ramdisk"];
		
		// Unmount ramdisk
		[nsargs4 addObject:@"unmount"];
		[nsargs4 addObject:@"-force"];
		
		[nsargs4 addObject:@"/Volumes/ramdisk"];
		[self runCMD:"/usr/bin/hdiutil" withArgs:nsargs4];
		
		[self makeDir:[[systemInfo installPath] stringByAppendingString:@"/Volumes/ramdisk"]];
		
		// Remount ramdisk
		[nsargs5 addObject:@"-t"];
		[nsargs5 addObject:@"hfs"];
		[nsargs5 addObject:[info objectForKey:@"Mounted From"]];
		[nsargs5 addObject:[[systemInfo installPath] stringByAppendingString:@"/Volumes/ramdisk"]];
		[self runCMD:"/sbin/mount" withArgs:nsargs5];
		
		
		
		if( [self runCMD:"/usr/sbin/chroot" withArgs:nsargs])
		{
			[self runCMD:"/usr/sbin/chroot" withArgs:nsargs2];
			if([systemInfo targetOS] >= KERNEL_VERSION(10, 6, 0)) [self runCMD:"/usr/sbin/chroot" withArgs:nsargs3];
			
			[self makeDir:@"/Volumes/ramdisk"];
			
			
			// Unmount ramdisk
			[nsargs4 removeLastObject];
			[nsargs4 addObject:[[systemInfo installPath] stringByAppendingString:@"/Volumes/ramdisk"]];
			[self runCMD:"/usr/bin/hdiutil" withArgs:nsargs4];
			
			// Remount ramdisk
			[nsargs5 removeLastObject];
			[nsargs5 addObject:@"/Volumes/ramdisk"];
			[self runCMD:"/sbin/mount" withArgs:nsargs5];
			
			
			
			[self deleteFile:[[systemInfo installPath] stringByAppendingString:@"/Volumes/ramdisk"]];
			
			[nsargs4 release];
			[nsargs5 release];
			[nsargs3 release];
			[nsargs2 release];
			[nsargs release];

			return YES;
		}
		else {
			[self makeDir:@"/Volumes/ramdisk"];
			
			// Unmount ramdisk
			[nsargs4 removeLastObject];
			[nsargs4 addObject:[[systemInfo installPath] stringByAppendingString:@"/Volumes/ramdisk"]];
			[self runCMD:"/usr/bin/hdiutil" withArgs:nsargs4];
			
			// Remount ramdisk
			[nsargs5 removeLastObject];
			[nsargs5 addObject:@"/Volumes/ramdisk"];
			[self runCMD:"/sbin/mount" withArgs:nsargs5];
			
			[nsargs4 release];
			[nsargs5 release];
			[nsargs3 release];
			[nsargs2 release];
			[nsargs release];
			[self deleteFile:[[systemInfo installPath] stringByAppendingString:@"/Volumes/ramdisk"]];
			return NO;
			
		}
		
	}
	else
	{
		NSArray* nsargs = [[NSArray alloc] initWithObjects:@"-a", @"i386", @"-m", [[systemInfo installPath] stringByAppendingString:@"/Extra/Extensions.mkext"], [systemInfo extensionsFolder], nil];	// This should only happen on 10.5 -> 10.6 dvd pathing
		[self runCMD:"/usr/sbin/kextcache" withArgs:nsargs];
		
		[nsargs release];
		return YES;


	}
}

// Legacy, used for pre 10.5.6 boot dvd's (Aka, remove this when 10.5.x support is dropped
- (BOOL) useLatestKernel
{
	NSMutableDictionary*	bootSettings =  [[NSMutableDictionary alloc] initWithContentsOfFile:[[[NSBundle mainBundle] resourcePath] stringByAppendingString: @"/SupportFiles/machine/General/ExtraFiles/com.apple.Boot.plist"]];
	
	[bootSettings setObject: @"mach_kernel.10.5.6" forKey: @"Kernel"];
	
	[bootSettings writeToFile: @"/Volumes/ramdisk/com.apple.Boot.plist" atomically: NO];
	[bootSettings release];
	return [self copyFrom: @"/Volumes/ramdisk/com.apple.Boot.plist" toDir:[[systemInfo installPath] stringByAppendingString: @"/Extra/"]];
}

// legacy, used when transitioning form a pre 10.5.6 install to a 10.5.6+ install. Remove when 10.5.x support is dropped
- (BOOL) useSystemKernel
{
	NSMutableDictionary*	bootSettings =  [[NSMutableDictionary alloc] initWithContentsOfFile:[[[NSBundle mainBundle] resourcePath] stringByAppendingString: @"/SupportFiles/machine/General/ExtraFiles/com.apple.Boot.plist"]];
	
	[bootSettings setObject: @"mach_kernel" forKey: @"Kernel"];
	
	[bootSettings writeToFile: @"/Volumes/ramdisk/com.apple.Boot.plist" atomically: NO];
	[bootSettings release];
	if([self copyFrom: @"/Volumes/ramdisk/com.apple.Boot.plist" toDir:[[systemInfo installPath] stringByAppendingString: @"/Extra/"]])
	{
		return [self deleteFile:[[systemInfo installPath] stringByAppendingString: @"/mach_kernel.10.5.6"]];
	} else {
		return NO;
	}
}

- (BOOL) removePrevExtra
{
	[self makeDir:[[systemInfo installPath] stringByAppendingString: @"/Extra.bak/"]];
	[self copyFrom:[[systemInfo installPath] stringByAppendingString: @"/Extra/"] toDir:[[systemInfo installPath] stringByAppendingString: @"/Extra.bak"]];
	[self deleteFile:[[systemInfo installPath] stringByAppendingString: @"/Extra/"]];
	[self installExtraFiles];
	[self makeDir:[[systemInfo installPath] stringByAppendingString: @"/Extra/"]];
	// Copy old files in
	[self copyFrom:[[systemInfo installPath] stringByAppendingString: @"/Extra.bak/dsdt.aml"] toDir:[[systemInfo installPath] stringByAppendingString: @"/Extra/"]];
	[self copyFrom:[[systemInfo installPath] stringByAppendingString: @"/Extra.bak/com.apple.Boot.plist"] toDir:[[systemInfo installPath] stringByAppendingString: @"/Extra/"]];
	[self copyFrom:[[systemInfo installPath] stringByAppendingString: @"/Extra.bak/Extensions.mkext"] toDir:[[systemInfo installPath] stringByAppendingString: @"/Extra/"]];


	return YES;
}


- (BOOL) removeBlacklistedKexts
{
	NSLog(@"Remove blacklisted items");
	NSDictionary*	machineplist= [[NSDictionary dictionaryWithContentsOfFile:[[[NSBundle mainBundle]  resourcePath] stringByAppendingString:@"/SupportFiles/machine.plist"]] objectForKey:@"General"];	

	NSArray* blacklist = [[systemInfo machineInfo] objectForKey:@"Kext Blacklist"];
	NSEnumerator* kexts = [blacklist objectEnumerator];

	// Remove machien specific extension
	NSString* kext;
	while((kext = [kexts nextObject]))
	{
		NSLog(@"Removing %@", kext);
		if(![kext isEqualToString:@""])
		{
			// TODO: verify kext does not go below root. (aka Security issue)
			[self makeDir:   [[systemInfo installPath] stringByAppendingString:@"/System/Library/BackupExtensions/"]];
			[self copyFrom:  [[systemInfo installPath] stringByAppendingFormat:@"/System/Library/Extensions/%@", kext] toDir:[[systemInfo installPath] stringByAppendingString:@"/System/Library/BackupExtensions/"]];
			[self deleteFile:[[systemInfo installPath] stringByAppendingFormat:@"/Volumes/ramdisk/Extensions/%@", kext]];
			[self deleteFile:[[systemInfo installPath] stringByAppendingFormat:@"/System/Library/Extensions/%@", kext]];
		}
	}
	
	
	// Repeat for Generic extensions blacklist
	kexts = [[machineplist objectForKey:@"Kext Blacklist"] objectEnumerator];
	while((kext = [kexts nextObject]))
	{
		NSLog(@"Removing %@", kext);
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

- (BOOL) patchPre1056mkext
{
	return NO;
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

@end
