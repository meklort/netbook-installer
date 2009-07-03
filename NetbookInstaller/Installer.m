//
//  Installer.m
//  NetbookInstaller
//
//  Created by Evan Lojewski on 5/16/09.
//  Copyright 2009. All rights reserved.
//

#import "Installer.h"

@implementation Installer

- (id) initWithSender: (id) senderObject;
{
	sender = senderObject;
	return self;
}

- (void)remountTargetWithPermissions
{
	if([[systemInfo installPath] isEqualToString:@"/"]) return;
	NSMutableArray* nsargs = [[NSMutableArray alloc] init];
	
	[nsargs addObject: @"-u"];
	[nsargs addObject: @"-o"];
	[nsargs addObject: @"owners"];
	[nsargs addObject: [@"/dev/" stringByAppendingString: [systemInfo bootPartition]]];
	
	[self runCMD:"/sbin/mount" withArgs:nsargs];
	
//	system([[@"/sbin/mount -u -o owners /dev/" stringByAppendingString: [systemInfo bootPartition]] cStringUsingEncoding:NSASCIIStringEncoding]);
}

- (void) mountRamDisk
{	// TODOL port from carbon api to cocao api using NSFileManager
	NSString* ramdiskNumber;
	OSStatus err;
	FSRef ref;
	FSVolumeRefNum actualVolume;
	ByteCount *size = malloc(sizeof(ByteCount));
	GetVolParmsInfoBuffer	*buffer;
	
	[self unmountRamDisk];

	system("/usr/sbin/diskutil eraseVolume HFS+ ramdisk `hdid -nomount ram://523648`");
	

	err = FSPathMakeRef ( (const UInt8 *) [@"/Volumes/ramdisk/" fileSystemRepresentation], &ref, NULL );
	// get a FSVolumeRefNum from mountPath
	if ( noErr == err ) {
		FSCatalogInfo   catalogInfo;
		err = FSGetCatalogInfo ( &ref,
								kFSCatInfoVolume,
								&catalogInfo,
								NULL,
								NULL,
								NULL
								);
		if ( noErr == err ) {
			actualVolume = catalogInfo.volume;
		}
	}
	
	// TODO / FIXME  - I dont know what the size should be... 
	FSGetVolumeMountInfoSize(actualVolume, size);
	//buffer = (GetVolParmsInfoBuffer*) malloc(*size);
	buffer = malloc(1024);	// Yes, this means the file name can only by 1024characters long
	
	FSGetVolumeParms(actualVolume, buffer, *size);
	
	NSLog(@"Ramdisk Device: %s\n", (const char*)(*buffer).vMDeviceID);
	
	ramdiskNumber = [[NSString alloc] initWithCString:((const char*)(*buffer).vMDeviceID)];
	free(size);
	free(buffer);
	
	
	//[self unmountRamDisk];
	// Re mount the disk using diskutil, this way it doesn't ignore permissions
	NSLog(@"Remounting ramdisk");
	system([[@"/sbin/mount -u -o owners /dev/" stringByAppendingString: ramdiskNumber] cStringUsingEncoding:NSASCIIStringEncoding]);
	// Get the volume number for /Volumes/ramdisk
	NSLog(@"Permissions fixed");
	
}
	
- (void) unmountRamDisk
{
//	return;
//	diskutil eject /Volumes/ramdisk
	NSMutableArray* nsargs = [[NSMutableArray alloc] init];
	
	[nsargs addObject: @"eject"];
	[nsargs addObject: @"/Volumes/ramdisk/"];
	
	[self runCMD:"/usr/sbin/diskutil" withArgs:nsargs];
}
		
- (void) systemInfo: (SystemInformation*) info
{
	systemInfo = info;
}

- (BOOL) performInstall: (SystemInformation*) sysInfo
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	systemInfo = sysInfo;
	
	if([self isKindOfClass:[Installer class]])
	{
		if(![self getAuthRef]) 
		{
			return NO;
			[sender performSelectorOnMainThread:@selector(installFailed) withObject: nil waitUntilDone:NO];
		}
	}
	

	[self updateStatus:NSLocalizedString(@"Remounting target", nil)];
	[self remountTargetWithPermissions];
	[self updatePorgressBar: 0];

	
	[self updateStatus:NSLocalizedString(@"Creating ramdisk", nil)];
	[self mountRamDisk];
	[self updatePorgressBar: 7];



	// FIXME: [self updateBlah] doesnt seam to hapen. The gui needs to be in a seperate thread than the installer so that it can update the user interface and be responsive
	if([self installExtensions]) [self removePrevExtra];
	[self updatePorgressBar: 0];
	
	[self updateStatus:NSLocalizedString(@"Creating /Extra", nil)];
	[self installExtraFiles];
	[self updatePorgressBar: 3];
	

	[self updateStatus:NSLocalizedString(@"Installing Display Profiles", nil)];
	[self installDisplayProfile];
	[self updatePorgressBar: 1];

	[self updateStatus:NSLocalizedString(@"Installing Preference Panes", nil)];
	[self installPrefPanes];
	[self installLaunchAgents];
	[self updatePorgressBar: 1];
	

	[self updateStatus:NSLocalizedString(@"Instaling Power Managment bundle", nil)];
	[self installSystemConfiguration];
	[self updatePorgressBar: 1];
	
	if([sender regenerateDSDT] && !([sender installExtensions])) [self installDSDT];

	
	if([sender installExtensions]){
		[self makeDir:@"/Volumes/ramdisk/Extensions"];
		[self updateStatus:NSLocalizedString(@"Copying Dependencies", nil)];
		[self copyDependencies];
		NSLog(@"extensionsFolder: %@", [systemInfo extensionsFolder]);
		[self makeDir: [systemInfo extensionsFolder]];
		
		[self updatePorgressBar: 5];
		
		[self updateStatus:NSLocalizedString(@"Installing Extensions", nil)];
		[self installExtensions];
		[self installLocalExtensions];
		[self updatePorgressBar: 14];

		if([sender mirrorFriendlyGMA]) 
		{
			[self installMirrorFriendlyGraphics];
		}
		else 
		{
			[self updateStatus:NSLocalizedString(@"Patching GMA950 Extension", nil)];
			[self patchGMAkext];
			[self updatePorgressBar: 5];
		
			[self updateStatus:NSLocalizedString(@"Patching Framebuffer Extension", nil)];
			[self patchFramebufferKext];
			[self updatePorgressBar: 5];
		}
		
		[self updateStatus:NSLocalizedString(@"Patching Wireless Extension", nil)];
		[self patchIO80211kext];
		[self updatePorgressBar: 5];
		
		[self updateStatus:NSLocalizedString(@"Patching Bluetooth", nil)];
		[self patchBluetooth];
		[self updatePorgressBar: 5];
				
		[self generateExtensionsCache];
		[self useSystemKernel];
		
		[self installDSDT];

		

	}

	[self updateStatus:NSLocalizedString(@"Verifying Quiet Boot state", nil)];
	[self setQuietBoot:			[sender enableQuietBoot]];
	
	
	[self updateStatus:NSLocalizedString(@"Verifying Hibernation state", nil)];
	[self dissableHibernation:	[sender dissableHibernation]];
	
	[self updateStatus:NSLocalizedString(@"Verifying RemoteCD State", nil)];
	[self setRemoteCD:			[sender enableRemoteCD]]; // TODO: code this
	[self updatePorgressBar: 5];

	[self updateStatus:NSLocalizedString(@"Verifying Bootloader", nil)];
	if([sender bootloaderType] != NONE) [self installBootloader: [sender bootloaderType]];
	[self updatePorgressBar: 10];

	// These funcitons have not been coded yet
	if([sender hideFiles]) {
		if([systemInfo efiHidden])  [self showFiles];
		else						[self hideFiles];
	}
	
	if([sender fixBluetooth]) [self fixBluetooth];
	[self updatePorgressBar: 30];
	
	[self updateStatus:NSLocalizedString(@"Complete", nil)];

	[self unmountRamDisk];
	
	[sender performSelectorOnMainThread:@selector(installFinished) withObject: nil waitUntilDone:NO];



	
	

	[pool release];
	
	return YES;
}

- (BOOL) getAuthRef
{
	if(getuid() == 0) return YES;
	AuthorizationRef authorizationRef;
	
    AuthorizationItem right = { "com.mydellmini.Installer", 0, NULL, 0 };
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
	NSMutableArray* nsargs = [[NSMutableArray alloc] init];
	
	[nsargs addObject: @"-rf"];
	[nsargs addObject:source];
	[nsargs addObject:destination];
	
	return [self runCMD:"/bin/cp" withArgs:nsargs];
	
}

- (BOOL) moveFrom: (NSString*) source to: (NSString*) destination
{
	NSMutableArray* nsargs = [[NSMutableArray alloc] init];
	[nsargs addObject:@"-f"];
	
	[nsargs addObject:source];
	[nsargs addObject:destination];
	
	return [self runCMD:"/bin/mv" withArgs:nsargs];
	
}

- (BOOL) runCMD: (char*) command withArgs: (NSArray*) nsargs
{
	if(getuid() == 0)
	{
		return [self runCMDAsUser: command withArgs: nsargs];
	}
	else
	{
		return [self runCMDAsRoot: command withArgs: nsargs];
		
	}
}
		
- (BOOL) runCMDAsUser: (char*) command withArgs: (NSArray*) nsargs
{
	NSMutableString* run = [NSMutableString alloc];
	NSMutableString* commandString = [[NSMutableString alloc] initWithCString:command];
	NSMutableString* escapedString;
	int i = 0;
	
	
	//NSLog(@"%@", nsargs);
	int h = 0;
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
		
		escapedString = [[NSMutableString alloc] initWithString:[nsargs objectAtIndex:i]];
		int j = 0;
		while(j < [escapedString length])
		{
			if([escapedString characterAtIndex:j] == ' ')
			{
				[escapedString insertString:@"\\" atIndex:j];
				j++;	// To skip the space
			}
			j++;
		}
		
		//[run appendString:[[@"\"" stringByAppendingString: escapedString] stringByAppendingString:@"\""]];
		[run appendString:escapedString];
		
		i++;
	}
	NSLog(@"Executing: %@", run);
	system([run cStringUsingEncoding:NSASCIIStringEncoding]);	
	return YES;
}

- (BOOL) runCMDAsRoot: (char*) command withArgs: (NSArray*) nsargs
{
	FILE* pipe = NULL;
	char* args[([nsargs count]) + 1];
	int i = 0;
	OSStatus status;
	
	NSLog(@"Running %s", command);
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
	NSLog(@"Done running %s", command);

	
	if(status == 0) return YES;
	else return NO;
	
}

- (BOOL) hidePath: (NSString*) path
{
	NSMutableArray* nsargs = [[NSMutableArray alloc] init];
	
	
	[nsargs addObject: @"hidden"];
	[nsargs addObject:path];
	
	if(![self runCMD: (char*)[[[systemInfo installPath] stringByAppendingString: @"/usr/bin/chflags"] cStringUsingEncoding:NSASCIIStringEncoding] withArgs:nsargs])
	{
		return [self runCMD:"/usr/bin/chflags" withArgs:nsargs];	// rathen than distributing chflags, we just try running it in both locations
	} else return NO;
}

- (BOOL) showPath: (NSString*) path
{
	NSMutableArray* nsargs = [[NSMutableArray alloc] init];
	
	[nsargs addObject: @"nohidden"];
	[nsargs addObject:path];
	
	if(![self runCMD: (char*)[[[systemInfo installPath] stringByAppendingString: @"/usr/bin/chflags"] cStringUsingEncoding:NSASCIIStringEncoding] withArgs:nsargs])
	{
		return [self runCMD:"/usr/bin/chflags" withArgs:nsargs];	// rathen than distributing chflags, we just try running it in both locations
	} else return NO;
}


- (BOOL) setPermissions: (NSString*) perms onPath: (NSString*) path recursivly: (BOOL) recursiv
{
	NSMutableArray* nsargs = [[NSMutableArray alloc] init];
	
	if(recursiv) 	[nsargs addObject: @"-R"];
	[nsargs addObject:perms];
	[nsargs addObject:path];
	
	return [self runCMD:"/bin/chmod" withArgs:nsargs];


}

- (BOOL) setOwner: (NSString*) owner andGroup: (NSString*) group onPath: (NSString*) path recursivly: (BOOL) recursiv
{
	NSMutableArray* nsargs = [[NSMutableArray alloc] init];
	
	if(recursiv) 	[nsargs addObject: @"-R"];
	[nsargs addObject:[[owner stringByAppendingString: @":"] stringByAppendingString:group]];
	[nsargs addObject:path];
	
	return [self runCMD:"/usr/sbin/chown" withArgs:nsargs];
}


- (BOOL) makeDir: (NSString*) dir
{
	NSMutableArray* nsargs = [[NSMutableArray alloc] init];
	
	[nsargs addObject: @"-p"];
	[nsargs addObject:dir];
	
	return [self runCMD:"/bin/mkdir" withArgs:nsargs];
}

-(BOOL) deleteFile: (NSString*) file
{
	NSMutableArray* nsargs = [[NSMutableArray alloc] init];
	
	[nsargs addObject: @"-rf"];
	[nsargs addObject:file];
	
	return [self runCMD:"/bin/rm" withArgs:nsargs];
}











// Installer Options
- (BOOL) installBootloader: (enum bootloader) bootloaderType
{
	
	NSString* bootPath;
	if([systemInfo installedBootloader] == bootloaderType) NSLog(@"Bootloader already installed, insatlling anyways");
	
	switch(bootloaderType)
	{
		case CHAMELEON_R431:
			bootPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingString: @"/SupportFiles/bootloader/chameleon2/"];
			break;
		case PCEFIV9:
			bootPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingString: @"/SupportFiles/bootloader/pcefiv9/"];
			break;
		case PCEFIV10:
			bootPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingString: @"/SupportFiles/bootloader/pcefiv10/"];
		default:
			return YES;
	}
	
									
	NSMutableArray* nsargs = [[NSMutableArray alloc] init];
	
	[nsargs addObject: @"-f"];
	[nsargs addObject:[bootPath stringByAppendingString: @"/boot0"]];
	[nsargs addObject: @"-u"];
	[nsargs addObject: @"-y"];
	
	//FIXME: This breask when the partition number is multi digits.
	//[[@"/dev/r" stringByAppendingString: [[systemInfo bootPartition] substringToIndex:[[systemInfo bootPartition] length] - 2]]
	[nsargs addObject:[@"/dev/r" stringByAppendingString: [[systemInfo bootPartition] substringToIndex:[[systemInfo bootPartition] length] - 2]]];

	// TODO: Fdisk is included w/ OS X, it can be removed from the file and run from /usr/sbin/fdisk
	[self runCMD:(char*)[[bootPath stringByAppendingString: @"/fdisk"] cStringUsingEncoding:NSASCIIStringEncoding] withArgs:nsargs];


	NSMutableArray* nsargs2 = [[NSMutableArray alloc] init];

	[nsargs2 addObject:[@"if=" stringByAppendingString:[bootPath stringByAppendingString: @"boot1h"]]];
	[nsargs2 addObject:[@"of=/dev/r" stringByAppendingString: [systemInfo bootPartition]]];
	
	//[@"of=/dev/r" stringByAppendingString: [systemInfo bootPartition]]
	
	[self runCMD:"/bin/dd" withArgs:nsargs2];
	
	
	[self copyFrom:[bootPath stringByAppendingString: @"/boot"] toDir:[[systemInfo installPath] stringByAppendingString: @"/"]];
	[self hidePath:[[systemInfo installPath] stringByAppendingString: @"/boot"]];
	return YES;

}

- (BOOL) installExtensions
{
	BOOL status = YES;
	NSMutableArray* sourceExtensions = [[NSMutableArray alloc] initWithCapacity: 10];
	NSString* destinationExtensions =  [systemInfo extensionsFolder];

	// Install Extensions
	switch([systemInfo machineType]) {
		case MINI9:
			[sourceExtensions addObject: [[[NSBundle mainBundle] resourcePath] stringByAppendingString: @"/SupportFiles/Extensions/General/"]];			
			[sourceExtensions addObject: [[[NSBundle mainBundle] resourcePath] stringByAppendingString: @"/SupportFiles/Extensions/Mini 9 Extensions/"]];

			break;
			
		case VOSTRO_A90:
			[sourceExtensions addObject: [[[NSBundle mainBundle] resourcePath] stringByAppendingString: @"/SupportFiles/Extensions/General/"]];			
			[sourceExtensions addObject: [[[NSBundle mainBundle] resourcePath] stringByAppendingString: @"/SupportFiles/Extensions/Mini 9 Extensions/"]];
			break;
			
		case MINI10V:
			[sourceExtensions addObject: [[[NSBundle mainBundle] resourcePath] stringByAppendingString: @"/SupportFiles/Extensions/General/"]];			
			[sourceExtensions addObject: [[[NSBundle mainBundle] resourcePath] stringByAppendingString: @"/SupportFiles/Extensions/Mini 10v Extensions/"]];
			break;
			
		case LENOVO_S10:
			[sourceExtensions addObject: [[[NSBundle mainBundle] resourcePath] stringByAppendingString: @"/SupportFiles/Extensions/General/"]];			
			[sourceExtensions addObject: [[[NSBundle mainBundle] resourcePath] stringByAppendingString: @"/SupportFiles/Extensions/S10 Extensions/"]];
			break;
			
		default:
			[sourceExtensions addObject: [[[NSBundle mainBundle] resourcePath] stringByAppendingString: @"/SupportFiles/Extensions/General/"]];			
			break;
	}
	
	
	while([sourceExtensions count] > 0) {
		NSString* current = [sourceExtensions objectAtIndex: 0];
		[sourceExtensions removeObjectAtIndex: 0];
		if(![self copyFrom: current toDir: destinationExtensions]) status = NO;
	}
	
	
	return status;
}

- (BOOL) hideFiles
{
	[self hidePath:[[systemInfo installPath] stringByAppendingString: @"/boot"]];
	[self hidePath:[[systemInfo installPath] stringByAppendingString: @"/Extra"]];
	return YES;
}

- (BOOL) showFiles
{
	[self showPath:[[systemInfo installPath] stringByAppendingString: @"/boot"]];
	[self showPath:[[systemInfo installPath] stringByAppendingString: @"/Extra"]];
	return YES;
}

// TODO: This will ONLY work if you install the dsdt to /
- (BOOL) installDSDT
{
	// TODO: make the dsdt compile / decompiler into a framework / dylib

	[self makeDir: @"/Volumes/ramdisk/dsdt/"];
	[self copyFrom:[[[NSBundle mainBundle] resourcePath] stringByAppendingString: @"/SupportFiles/DSDTPatcher/"] toDir: @"/Volumes/ramdisk/dsdt/"];
	
	
	NSMutableArray* nsargs = [[NSMutableArray alloc] init];
	
	//[nsargs addObject: @"PWD=/Volumes/ramdisk/dsdt/"];
	//[nsargs addObject: @"/Volumes/ramdisk/dsdt/DSDTPatcher"];
	
	//[self runCMD:"/usr/bin/env" withArgs:nsargs];
	[self runCMD:"/Volumes/ramdisk/dsdt/DSDTPatcher" withArgs:nsargs];

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
	return YES;
}

- (BOOL) dissableHibernation: (BOOL) dissable 
{
	UInt8 state;
	NSFileManager* manager = [[NSFileManager alloc] init];
	
	
	// If the preference plist doesnt exist, copy a default one in.
	if(![manager fileExistsAtPath:[[systemInfo installPath] stringByAppendingString:@"/Library/Preferences/SystemConfiguration/com.apple.PowerManagement.plist"]])
	{
		[self copyFrom:[[[NSBundle mainBundle] resourcePath] stringByAppendingString: @"/SupportFiles/com.apple.PowerManagement.plist"] toDir: [[systemInfo installPath] stringByAppendingString:@"/Library/Preferences/SystemConfiguration/"]];
	}
	
	
	
	
	
	
	//if(([systemInfo hibernationDissabled]) ^ dissable)	// Setting have changed
	//{
		NSMutableDictionary*	propertyList= [[NSMutableDictionary alloc] initWithContentsOfFile: [[systemInfo installPath] stringByAppendingString:@"/Library/Preferences/SystemConfiguration/com.apple.PowerManagement.plist"]];
	
		NSMutableDictionary* powerStates = [[NSMutableDictionary alloc] initWithDictionary:[propertyList objectForKey: @"Custom Profile"]];
		NSMutableDictionary* acPowerState = [[NSMutableDictionary alloc] initWithDictionary:[powerStates objectForKey: @"AC Power"]];
		NSMutableDictionary* battPowerState = [[NSMutableDictionary alloc] initWithDictionary:[powerStates objectForKey: @"Battery Power"]];
	
		if(dissable) state = 0;
		else state = 3;
		
		[acPowerState   setObject: [NSNumber numberWithInt:state] forKey: @"Hibernate Mode"];
		[battPowerState setObject: [NSNumber numberWithInt:state] forKey: @"Hibernate Mode"];

		
		
		[powerStates setObject: acPowerState forKey: @"AC Power"];
		[powerStates setObject: battPowerState forKey: @"Battery Power"];
		[propertyList setObject: powerStates forKey: @"Custom Profile"];


		[propertyList writeToFile: @"/Volumes/ramdisk/com.apple.PowerManagement.plist" atomically: NO]; 
		if(state == 3) [self deleteFile:[[systemInfo installPath] stringByAppendingString: @"/var/vm/sleepimage"]];

		return [self copyFrom: @"/Volumes/ramdisk/com.apple.PowerManagement.plist" toDir:[[systemInfo installPath] stringByAppendingString: @"/Library/Preferences/SystemConfiguration/"]];
	//}
	//return YES;
}

- (BOOL) setQuietBoot: (BOOL) quietBoot
{
	NSMutableDictionary*	bootSettings =  [[NSMutableDictionary alloc] initWithContentsOfFile:[[[NSBundle mainBundle] resourcePath] stringByAppendingString: @"/SupportFiles/ExtraFiles/com.apple.Boot.plist"]];
	NSString* setting = [bootSettings objectForKey: @"Quiet Boot"];
	
	if([setting isEqualToString: @"Yes"] && quietBoot == false)
	{
		// Dissable Quiet Boot
		[bootSettings removeObjectForKey: @"Quiet Boot"];
		[bootSettings setObject:[NSNumber numberWithInt:5] forKey: @"Timeout"];
	}
	else if(![setting isEqualToString: @"Yes"] && quietBoot == true)
	{
		[bootSettings removeObjectForKey: @"Timeout"];
		[bootSettings setObject: @"Yes" forKey: @"Quiet Boot"];

	}
	[bootSettings writeToFile: @"/Volumes/ramdisk/com.apple.Boot.plist" atomically: NO];
	return [self copyFrom: @"/Volumes/ramdisk/com.apple.Boot.plist" toDir:[[systemInfo installPath] stringByAppendingString: @"/Extra/"]];
}

- (BOOL) fixBluetooth
{
	return [self deleteFile:[[systemInfo installPath] stringByAppendingString: @"/Library/Preferences/com.apple.Bluetooth.plist"]];
}




// Support Files
- (BOOL) installExtraFiles
{
	NSString* source = [[[NSBundle mainBundle] resourcePath] stringByAppendingString: @"/SupportFiles/ExtraFiles/"];
	//	[self makeDir: @"/Extra/"];
	return [self copyFrom: source toDir: [[systemInfo installPath] stringByAppendingString: @"/Extra/"]];
}

- (BOOL) installDisplayProfile
{
	NSString* source = [[[NSBundle mainBundle] resourcePath] stringByAppendingString: @"/SupportFiles/DisplayProfiles/"];
	return [self copyFrom: source toDir: [[systemInfo installPath] stringByAppendingString: @"/Library/ColorSync/Profiles/"]];
}

- (BOOL) installSystemConfiguration
{
	NSString* source = [[[NSBundle mainBundle] resourcePath] stringByAppendingString: @"/SupportFiles/SystemConfiguration/"];
	return [self copyFrom: source toDir: [[systemInfo installPath] stringByAppendingString: @"/System/Library/SystemConfiguration/"]];
}

- (BOOL) installPrefPanes
{
	NSString* source = [[[NSBundle mainBundle] resourcePath] stringByAppendingString: @"/SupportFiles/3rdPartyPrefPanes/"];
	return [self copyFrom: source toDir: [[systemInfo installPath] stringByAppendingString: @"/Library/PreferencePanes/"]];
}

- (BOOL) installSystemPrefPanes
{
	NSString* source = [[[NSBundle mainBundle] resourcePath] stringByAppendingString: @"/SupportFiles/PrefPanes/"];
	return [self copyFrom: source toDir: [[systemInfo installPath] stringByAppendingString: @"/System/Library/PreferencePanes/"]];
	
}

- (BOOL) installLaunchAgents
{
	NSString* source = [[[NSBundle mainBundle] resourcePath] stringByAppendingString: @"/SupportFiles/LaunchAgents/"];
	return [self copyFrom: source toDir: [[systemInfo installPath] stringByAppendingString: @"/Library/LaunchAgents/"]];
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
	
	UInt32 findBytes = 0x27A28086;
	UInt32 replaceBytes = 0x27AE8086;
	char findString[] = {'0', 'x', '2', '7', 'A', '2', '8', '0', '8', '6'};
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
	return NO;
}

- (BOOL) patchFramebufferKext
{
	// Find: 8680A227
	// Replace: 8680AE27
	
	HexEditor* editor = [HexEditor alloc];
	
	UInt32 findBytes = 0x27A28086;
	UInt32 replaceBytes = 0x27AE8086;
	char findString[] = {'0', 'x', '2', '7', 'A', '2', '8', '0', '8', '6'};
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
	return NO;
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
	return [self copyFrom: @"/Volumes/ramdisk/Info.plist" toDir: [[systemInfo extensionsFolder] stringByAppendingString: @"/IOBluetoothFamily.kext/Contents/PlugIns/BroadcomUSBBluetoothHCIController.kext/Contents/Info.plist"]];
}

//----------			installLocalExtensions			----------//
- (BOOL) installLocalExtensions
{
	BOOL status = YES;
	NSMutableArray* sourceExtensions = [[NSMutableArray alloc] initWithCapacity: 10];
	
	// Install Extensions
	switch([systemInfo machineType]) {
		case MINI9:
			[sourceExtensions addObject: [[[NSBundle mainBundle] resourcePath] stringByAppendingString: @"/SupportFiles/LocalExtensions/General/"]];			
			[sourceExtensions addObject: [[[NSBundle mainBundle] resourcePath] stringByAppendingString: @"/SupportFiles/LocalExtensions/Mini 9 Extensions/"]];
			
			break;
			
		case VOSTRO_A90:
			[sourceExtensions addObject: [[[NSBundle mainBundle] resourcePath] stringByAppendingString: @"/SupportFiles/LocalExtensions/General/"]];			
			[sourceExtensions addObject: [[[NSBundle mainBundle] resourcePath] stringByAppendingString: @"/SupportFiles/LocalExtensions/Mini 9 Extensions/"]];
			break;
			
		case MINI10V:
			[sourceExtensions addObject: [[[NSBundle mainBundle] resourcePath] stringByAppendingString: @"/SupportFiles/LocalExtensions/General/"]];			
			[sourceExtensions addObject: [[[NSBundle mainBundle] resourcePath] stringByAppendingString: @"/SupportFiles/LocalExtensions/Mini 10v Extensions/"]];
			break;
			
		case LENOVO_S10:
			[sourceExtensions addObject: [[[NSBundle mainBundle] resourcePath] stringByAppendingString: @"/SupportFiles/LocalExtensions/General/"]];			
			[sourceExtensions addObject: [[[NSBundle mainBundle] resourcePath] stringByAppendingString: @"/SupportFiles/LocalExtensions/S10 Extensions/"]];
			break;
			
		default:
			[sourceExtensions addObject: [[[NSBundle mainBundle] resourcePath] stringByAppendingString: @"/SupportFiles/LocalExtensions/General/"]];			
			break;
	}
	
	
	while([sourceExtensions count] > 0) {
		NSString* current = [sourceExtensions objectAtIndex: 0];
		[sourceExtensions removeObjectAtIndex: 0];
		if(![self copyFrom: current toDir: [[systemInfo installPath] stringByAppendingString: @"/System/Library/Extensions/"]]) status = NO;
	}
	
	
	return status;
}

//----------			copyDependencies			----------//
- (BOOL) copyDependencies
{
	NSString *whitelistString = [[NSString alloc] initWithContentsOfFile:[[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/kext_whitelist"]]; // reads file into memory as an NSString
	NSArray *whitelist = [whitelistString componentsSeparatedByString:@"\n"]; // each line, adjust character for line endings
	
	// These go into /Volumes/ramdisk/Extensions to be generated into an ext cache
	[self makeDir:[[systemInfo installPath] stringByAppendingString:@"/tmp/Extensions"]];
	int i = 0;
	while(i < [whitelist count])
	{
		[self copyFrom:[[[systemInfo installPath] stringByAppendingString: @"/System/Library/Extensions/"]stringByAppendingString:[whitelist objectAtIndex:i]] toDir:[[systemInfo installPath] stringByAppendingString:@"/tmp/Extensions/"]];
		i++;
	}

//	[self copyFrom:[[systemInfo installPath] stringByAppendingString: @"/System/Library/Extensions/"] toDir:[[systemInfo installPath] stringByAppendingString:@"/tmp/Extensions"]];
	//[self copyFrom:[[systemInfo installPath] stringByAppendingString: @"/System/Library/Extensions/"] toDir:[[systemInfo installPath] stringByAppendingString: [systemInfo extensionsFolder]]];
	
		
	return YES;
}


- (BOOL) installMirrorFriendlyGraphics
{
	NSString* source = [[[NSBundle mainBundle] resourcePath] stringByAppendingString: @"/SupportFiles/OldGMA/"];	 
	return [self copyFrom: source toDir: [systemInfo extensionsFolder]];
}



// This generates and mkext in <install>/Extra/Extensions.mkext FROM /Volumes/ramdisk/Extensions
- (BOOL) generateExtensionsCache
{
	NSLog(@"Copied /System/Library/Extensions");
	[self updateStatus:NSLocalizedString(@"Copying Extension dependencies", nil)];
		
	[self copyFrom: [[systemInfo extensionsFolder] stringByAppendingString:@"/"] toDir: [[systemInfo installPath] stringByAppendingString:@"/tmp/Extensions/"]];
	
	NSLog(@"Deleting blacklisted items");
	[self deleteFile:[[systemInfo installPath] stringByAppendingString:@"/tmp/Extensions/AppleTyMCEDriver.kext"]];

	
	//sudo kextcache -a i386 -m <installPath>/Extra/Extensions.mkext <installPath>/Extra/Mini9Ext/ /Sytem/Library/Extensions

	NSMutableArray* nsargs = [[NSMutableArray alloc] init];
	NSMutableArray* nsargs2 = [[NSMutableArray alloc] init];

	
	
	// Generate Extensions cache
	[nsargs addObject: @"-a"];
	[nsargs addObject: @"i386"];
	[nsargs addObject: @"-m"];
	
	
	[nsargs addObject:[[systemInfo installPath] stringByAppendingString: @"/Extra/Extensions.mkext"]];
	[nsargs addObject:[[systemInfo installPath] stringByAppendingString: @"/tmp/Extensions/"]];
	//[nsargs addObject:[systemInfo extensionsFolder]];
	
	[nsargs2 addObject: @"-a"];
	[nsargs2 addObject: @"i386"];
	[nsargs2 addObject: @"-m"];
	
	
	[nsargs2 addObject:[[systemInfo installPath] stringByAppendingString: @"/Extra/Extensions.mkext"]];
	[nsargs2 addObject:[[systemInfo installPath] stringByAppendingString: @"/System/Library/Extensions/"]];
	
		
	[self setPermissions: @"755" onPath: [[systemInfo installPath] stringByAppendingString:@"/tmp/Extensions/"] recursivly: YES];
	[self setOwner:@"root" andGroup:@"wheel" onPath: [[systemInfo installPath] stringByAppendingString:@"/tmp/Extensions/"] recursivly: YES];
	
	[self setPermissions: @"755" onPath: [[systemInfo installPath] stringByAppendingString:@"/System/Library/Extensions/"] recursivly: YES];
	[self setOwner:@"root" andGroup:@"wheel" onPath: [[systemInfo installPath] stringByAppendingString:@"/System/Library/Extensions/"] recursivly: YES];

	
	
	NSLog(@"Generating extensions Cache");
	setenv("_com_apple_kextd_skiplocks", "1", 1);	    // This let kexts cache run before the 5 minut delay imposed by kextd
	if([self runCMD:"/usr/sbin/kextcache" withArgs:nsargs])
	{
		return [self deleteFile:[[systemInfo installPath] stringByAppendingString:@"/tmp/Extensions/"]];
	} else return NO;
	
	
	// TODO: set correct permissions on these files...
	
}

- (BOOL) useLatestKernel
{
	NSMutableDictionary*	bootSettings =  [[NSMutableDictionary alloc] initWithContentsOfFile:[[[NSBundle mainBundle] resourcePath] stringByAppendingString: @"/SupportFiles/ExtraFiles/com.apple.Boot.plist"]];
	
	[bootSettings setObject: @"mach_kernel.10.5.6" forKey: @"Kernel"];
	
	[bootSettings writeToFile: @"/Volumes/ramdisk/com.apple.Boot.plist" atomically: NO];
	return [self copyFrom: @"/Volumes/ramdisk/com.apple.Boot.plist" toDir:[[systemInfo installPath] stringByAppendingString: @"/Extra/"]];
}

- (BOOL) useSystemKernel
{
	NSMutableDictionary*	bootSettings =  [[NSMutableDictionary alloc] initWithContentsOfFile:[[[NSBundle mainBundle] resourcePath] stringByAppendingString: @"/SupportFiles/ExtraFiles/com.apple.Boot.plist"]];
	
	[bootSettings setObject: @"mach_kernel" forKey: @"Kernel"];
	
	[bootSettings writeToFile: @"/Volumes/ramdisk/com.apple.Boot.plist" atomically: NO];
	return [self copyFrom: @"/Volumes/ramdisk/com.apple.Boot.plist" toDir:[[systemInfo installPath] stringByAppendingString: @"/Extra/"]];
}

- (BOOL) removePrevExtra
{
	return [self deleteFile:[[systemInfo installPath] stringByAppendingString: @"/Extra/"]];
}


- (BOOL) updatePorgressBar: (NSUInteger) percent
{
	
	[sender performSelectorOnMainThread:@selector(updatePorgressBar:) withObject: [[NSNumber alloc] initWithInt:percent] waitUntilDone:NO];
	return YES;
	//[progressBar setValue: [[NSNumber alloc] initWithInt: percent]];
	//[progressBar incrementBy: percent];
	//return YES;
}
- (BOOL) updateStatus: (NSString*) status
{
	[sender performSelectorOnMainThread:@selector(updateStatus:) withObject: status waitUntilDone:NO];
	//[statusLabel setStringValue:status];
	return YES;
}


@end
