//
//  SystemInformation.m
//  NetbookInstaller
//
//  Created by Evan Lojewski on 5/15/09.
//  Copyright 2009. All rights reserved.
//

#import "SystemInformation.h"
#import <IOKit/IOKitLib.h>
#import <Foundation/NSPropertyList.h>

#import <sys/sysctl.h>
#import <openssl/md5.h>
#import "checksum.h"



@implementation SystemInformation


- (bool) dsdtInstalled
{
	return dsdtInstalled;
	
}
- (NSDictionary*) bootloaderDict
{
	return bootloaderDict;
}
- (NSString*) extensionsFolder
{
	return [[installPath stringByAppendingString: @"/Extra/"] stringByAppendingString:[machineInfo objectForKey:@"Extensions Directory"]];
}

- (NSString*) getMachineString
{
	return [machineInfo objectForKey:@"Long Name"];
}

- (bool) keyboardPrefPaneInstalled
{
	return keyboardPrefPaneInstalled;
}

- (bool) remoteCDEnabled
{
	return remoteCDEnabled;
}

- (bool) hibernationDissabled
{
	return hibernationDissabled;
}
- (NSDictionary*) machineInfo
{
	return machineInfo;
}

- (NSString*) bootPartition
{
	return bootPartition;
}

- (NSString*) installPath
{
	//NSLog(@"Retuning install path");
	//NSLog(installPath);
	return installPath;
}

- (void) installPath: (NSString*) path
{
}

- (bool) quietBoot
{
	return quietBoot;
}

- (bool) bluetoothPatched
{
	return bluetoothPatched;
}

- (BOOL) mirrorFriendlyGMA
{
	return mirrorFriendlyGMA;
}

-(bool) efiHidden
{
	return efiHidden;
}
/*- (enum machine) machineType
{
	return machineType;
}*/

/*- (void) machineType: (enum machine) newMachineType
{
	machineType = newMachineType;
}*/

- (NSDictionary*) installedBootloader
{
	return installedBootloader;
}

- (NSUInteger) bluetoothVendorId
{
	return bluetoothVendorId;
}
- (NSUInteger) bluetoothDeviceId
{
	return bluetoothDeviceId;
}


- (void) determineInstallState;
{
	bootloaderDict =  [[NSDictionary alloc] initWithContentsOfFile:[[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/SupportFiles/bootloader.plist"]];	
	[self determinebootPartition];
	[self determineMachineType];
	
	[self determineDSDTState];
	[self determineRemoteCDState];
	[self determineBluetoothState];


	[self determineHibernateState];
	[self determineQuiteBootState];
	[self determineHiddenState];
	[self determineGMAVersion];
	[self determinekeyboardPrefPaneInstalled];

	//	NSLog(@"state");
	
}

// code example from http://snipplr.com/view/1645/given-a-mount-path-retrieve-a-usb-device-name/
- (void) determinebootPartition
{
	// TODOL port from carbon api to cocao api using NSFileManager
	OSStatus err;
	FSRef ref;
	FSVolumeRefNum actualVolume;
	ByteCount *size = malloc(sizeof(ByteCount));
	GetVolParmsInfoBuffer	*buffer;
	
	err = FSPathMakeRef ( (const UInt8 *) [@"/" fileSystemRepresentation], &ref, NULL );
	installPath = @"/";
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
	
//	NSLog(@"Root Device: %s\n", (const char*)(*buffer).vMDeviceID);
	
	bootPartition = [[NSString alloc] initWithCString:((const char*)(*buffer).vMDeviceID)];
	
	[self determineTargetOS];
	[self determineBootloader];
	
	

	
	free(size);
	free(buffer);
	
}

//TODO: fix this as it currently crashes when a BAD path is sent
- (void) determinePartitionFromPath: (NSString*) path
{
	OSStatus err;
	FSRef ref;
	FSVolumeRefNum actualVolume;
	ByteCount *size = malloc(sizeof(ByteCount));
	GetVolParmsInfoBuffer	*buffer;
	
	err = FSPathMakeRef ( (const UInt8 *) [path fileSystemRepresentation], &ref, NULL );
	
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
	buffer = malloc(1024);
	
	FSGetVolumeParms(actualVolume, buffer, *size);
	
//	NSLog(@"Root Device: %s\n", (const char*)(*buffer).vMDeviceID);
	
	bootPartition = [[NSString alloc] initWithCString:((const char*)(*buffer).vMDeviceID)];
	installPath = [[NSString alloc] initWithString:path];
	
	[self determineTargetOS];

	[self determineBootloader];

	[self determineMachineType];
	[self determineDSDTState];
	[self determineRemoteCDState];
	[self determineBluetoothState];
	
	[self determineHibernateState];
	[self determineQuiteBootState];
	[self determineHiddenState];
	[self determineGMAVersion];
	[self determinekeyboardPrefPaneInstalled];

	free(size);
	free(buffer);


}

- (void) determineMachineType
{
//	NSLog(@"machine type");
	NSDictionary*	machineplist= [NSDictionary dictionaryWithContentsOfFile:[[[NSBundle mainBundle]  resourcePath] stringByAppendingString:@"/SupportFiles/machine.plist"]];	
	NSEnumerator *enumerator = [machineplist objectEnumerator];
	NSDictionary* currentModel;
	
	int mib[2];
	char* model;
	size_t len;
	mib[0] = CTL_HW;
	mib[1] = HW_MODEL;
	len = sizeof(model);
	sysctl(mib, 2, NULL, &len, NULL, 0);
	model = malloc(len);
	sysctl(mib, 2, model, &len, NULL, 0);
	
	machineInfo = nil;
	NSLog(@"Searching for %@", [NSString stringWithCString: model]);
	while ((currentModel = [enumerator nextObject])) {
		if([[currentModel objectForKey:@"Model Name"] length] <= strlen(model) && [[currentModel objectForKey:@"Model Name"] isEqualToString:[[NSString stringWithCString: model] substringToIndex:[[currentModel objectForKey:@"Model Name"] length]]])
		{
			machineInfo = [[NSDictionary alloc] initWithDictionary:currentModel copyItems:YES];
			break;
		}
	}
	
	if(!machineInfo)
	{
		machineInfo = [[NSDictionary alloc] initWithDictionary:[machineplist objectForKey:@"General"] copyItems:YES];
	}
	
	if(!machineInfo) {
		NSLog(@"Unable to determine machine information, failing");
		exit(-1);	// ALERT / FAIL
	} else {
		NSLog(@"%@", machineInfo);
	}

	free(model);
}

- (void) determineDSDTState
{
	NSFileManager* fileManager;
	fileManager = [NSFileManager defaultManager];

	dsdtInstalled = [fileManager fileExistsAtPath: [installPath stringByAppendingString: @"/Extra/DSDT.aml"]];
//	NSLog(@"DSDT");
}

- (void) determineRemoteCDState
{
	NSDictionary *dict;	
	dict = (NSDictionary*)CFPreferencesCopyMultiple(NULL,
													CFSTR("com.apple.NetworkBrowser"),
													kCFPreferencesCurrentUser,
													kCFPreferencesAnyHost);
	
	remoteCDEnabled = ([[dict objectForKey:@"EnableODiskBrowsing"] boolValue] &&
					   [[dict objectForKey:@"ODSSupported"] boolValue]);

}

- (void) determineHibernateState
{
	NSDictionary*	propertyList= [NSDictionary dictionaryWithContentsOfFile:[installPath stringByAppendingString: @"/Library/Preferences/SystemConfiguration/com.apple.PowerManagement.plist"]];
	
	if(!propertyList) {
		hibernationDissabled = false;
		return;
	}
	
	NSDictionary* powerStates = [propertyList objectForKey:@"Custom Profile"];
	NSDictionary* acPowerState = [powerStates objectForKey:@"AC Power"];
	NSDictionary* battPowerState = [powerStates objectForKey:@"Battery Power"];

	
	//NSLog(@"%@", [acPowerState valueForKey:@"Hibernate Mode"]);
	//NSLog(@"%@", [battPowerState valueForKey:@"Hibernate Mode"]);

	// If hibernation is enabled
	if(  [[acPowerState valueForKey:@"Hibernate Mode"] intValue] == 0 && 
	[[battPowerState valueForKey:@"Hibernate Mode"] intValue] == 0)
	{
		hibernationDissabled = true;
	}
	else
	{
		hibernationDissabled = false;
	}
	

}

- (void) determineQuiteBootState
{
	NSDictionary *	propertyList= [NSDictionary dictionaryWithContentsOfFile:[installPath stringByAppendingString: @"/Extra/com.apple.Boot.plist"]];
	NSString* quiet = [propertyList valueForKey:@"Quiet Boot"];
	
	quietBoot = [quiet isEqualToString:@"Yes"];
	

}

- (void) determineGMAVersion
{
	// MD5?
	NSBundle*	gmaFramebuffer = [[NSBundle alloc] initWithPath:[installPath stringByAppendingString:[@"/Extra/" stringByAppendingString:[[machineInfo objectForKey:@"Extensions Directory"] stringByAppendingString:@"/AppleIntelIntegratedFramebuffer.kext/"]]]];
	mirrorFriendlyGMA = [[[gmaFramebuffer infoDictionary] valueForKey:@"CFBundleVersion"] isEqualToString:@"5.3.0"];
}

- (void) determineBluetoothState
{
	NSFileManager* fileManager;
	fileManager = [NSFileManager defaultManager];
	
	bluetoothPatched = [fileManager fileExistsAtPath: [installPath stringByAppendingString: @"/Library/Preferences/com.apple.Bluetooth.plist"]] ? false : true;
	
	bluetoothVendorId = [[machineInfo objectForKey:@"Bluetooth Vendor ID"] intValue];
	bluetoothDeviceId = [[machineInfo objectForKey:@"Bluetooth Device ID"] intValue];
	
}

- (void) determineHiddenState
{
	const char* path = "/Extra";
	struct stat fileStatus;
	stat(path, &fileStatus);
	
	efiHidden = (fileStatus.st_flags & UF_HIDDEN);
}

- (void) determinekeyboardPrefPaneInstalled
{	NSDictionary *	propertyList= [NSDictionary dictionaryWithContentsOfFile:[installPath stringByAppendingString: @"/System/Library/PreferencePanes/Keyboard.prefPane/Contents/version.plist"]];

	//NSBundle*	prefPane = [[NSBundle alloc] initWithPath:@"/System/Library/PreferencePanes/Keyboard.prefPane/"];
	keyboardPrefPaneInstalled = [[propertyList valueForKey:@"SourceVersion"] isEqualToString:@"1020000"];
}

- (NSArray*) supportedBootloaders
{
	NSDictionary* bootloaders = [bootloaderDict objectForKey:@"Bootloaders"];
	NSDictionary* loader;
	NSEnumerator* enumerator = [bootloaders keyEnumerator];
	NSMutableArray* returnArray = [[NSMutableArray alloc] init];
	
	// Only return installable AND latest version
	while(loader = [enumerator nextObject])
	{
		// TODO: possibly copy array instead of including a refrence to the variable
		if([[[bootloaders objectForKey:loader] objectForKey:@"Installable"] isEqualToNumber:[NSNumber numberWithBool:YES]]) [returnArray addObject:[bootloaders objectForKey:loader]];

	}
	
	return returnArray;
}

- (void) determineBootloader
{
	// TODO: fix bug with bootloaderDict.
//	if(!bootloaderDict) 

	NSLog(@"%@", bootloaderDict);
	NSDictionary* allbootloaders = [bootloaderDict objectForKey:@"Bootloaders"];
	NSLog(@"%@", installPath);

	NSDictionary* booter;
	NSEnumerator* bootloaders = [allbootloaders keyEnumerator];

	NSData* bootloader = [[NSData alloc] initWithContentsOfFile:[installPath stringByAppendingString:@"/boot"]];
	NSRange replaceByte;
	NSMutableData* md5 =			[[NSMutableData alloc] initWithLength:16];
//	NSData* bootmd5;

	
	unsigned char *digest;
	UInt8 i = 0;
	installedBootloader = nil;


	

	if(!bootloader || [bootloader length] == 0)
	{
		return;
	}	
	digest = MD5([bootloader bytes], [bootloader length], NULL);

	
	// Convert the string into an NSData type
	while(digest[i] != 0) {
		replaceByte.location = 16 - (i + 1);
		replaceByte.length = 1;
		[md5 replaceBytesInRange:replaceByte withBytes:&(digest[i]) length:1];
		i++;
	}

	NSLog(@"%@", md5);

	while((booter = [bootloaders nextObject]) && (installedBootloader == nil))
	{
		if([md5 isEqualToData:[[[bootloaderDict objectForKey:@"Bootloaders"] objectForKey:booter] objectForKey:@"MD5"]]) installedBootloader = [[NSDictionary alloc] initWithDictionary:booter copyItems:YES];
	}
	
	
	[bootloader release];
//	[bootmd5 release];
	[md5 release];
	
}

- (int) targetOS
{
	return installedKernel;
}
- (BOOL) determineTargetOS
{
	// Use the following for / detection only
/*	gestaltSystemVersionMajor
	gestaltSystemVersionMinor
	gestaltSystemVersionBugFix*/
	
	installedKernel = [self getKernelVersion: installPath];
	return YES;
	
//	NSLog(@"Determining OS Version");
	// TODO: read value from SystemVersion.plist instead
//	installedKernel = [self getKernelVersion:[installPath stringByAppendingString:@"/mach_kernel"]];
//	return YES;
}

- (NSArray*) installableVolumes: (int) minVersions
{
	NSMutableArray* volumes = (NSMutableArray*) [[NSFileManager defaultManager] directoryContentsAtPath:@"/Volumes"];
	
	// TODO: verify that the media is read / write
	
	int i = 0;
	while(i < [volumes count])
	{
		if([self getKernelVersion:[@"/Volumes/" stringByAppendingString:[[volumes objectAtIndex:i] stringByAppendingString:@"/mach_kernel"]]] < minVersions)
		{
			// Boot unsupported, remove volume from the list
			//NSLog(@"Removing %@", [volumes objectAtIndex:i]);
			[volumes removeObjectAtIndex:i];
			//i++;
		}
		else
		{
			//NSLog(@"Keeping %@", [volumes objectAtIndex:i]);

			i++;
		}
	}
	
	return volumes;
	
	
		
	
	
	
}
	
- (int) getKernelVersion: (NSString*) kernelPath
{
	NSString* path = [kernelPath stringByReplacingOccurrencesOfString:@"/mach_kernel" withString:@"/"];

	int majorVersion, minorVersion, bugfixVersion;
	NSScanner* scanner;
	NSDictionary* systemVersion = [[NSDictionary alloc] initWithContentsOfFile:[path stringByAppendingString:@"/System/Library/CoreServices/SystemVersion.plist"]];
	NSString* versionString = [systemVersion objectForKey:@"ProductVersion"];
	if(!versionString) return 0;
	//if(!versionString) return 10 << 4 | 5 << 2 | 8;
	versionString = [versionString stringByReplacingOccurrencesOfString:@"." withString:@" "];
	//NSLog(@"%@", versionString);
	scanner = [NSScanner scannerWithString:versionString];
	
	[scanner scanInt:&majorVersion];
	[scanner scanInt:&minorVersion];
	[scanner scanInt:&bugfixVersion];
	// Use the following for / detection only
	/*	gestaltSystemVersionMajor
	 gestaltSystemVersionMinor
	 gestaltSystemVersionBugFix*/
	NSLog(@"Kernel: %d", KERNEL_VERSION(majorVersion, minorVersion, bugfixVersion));
	return KERNEL_VERSION(majorVersion, minorVersion, bugfixVersion);
	
	// TODO: do the following if SystemVersion.plist doesnt exist (aka, the boot partition)
	
	/*// Find last / and use it as the root, if we cant find SystemVersion, fall back to the md5
	//NSDictionary* systemVersion = [[NSDictionary alloc] initWithContentsOfFile:@"/System/Library/CoreServices/SystemVersion.plist"];
	//NSString* versionString = [systemVersion objectForKey:@"ProductVersion"];

	
	
	// Verify the target os version (possibly use SystemVersion here, falling back to md5
	NSData* kernel = [[NSData alloc] initWithContentsOfFile:path];
	unsigned char *digest;
	SInt8 returnVal = -2;
	UInt8 i = 0;
	UInt8 index = 0;
	
	struct uint128 knownMD5;
	NSRange replaceByte;
	
	NSMutableData* md5 =			[[NSMutableData alloc] initWithLength:16];
	NSData* kernelMD5;
	
	
	if(!kernel)
	{
		returnVal = -2;
	}
	else
	{
		returnVal =  -1;
		digest = MD5([kernel bytes], [kernel length], NULL);
	
	
	
		// Convert the string into an NSData type
		while(digest[i] != 0) {
			replaceByte.location = 16 - (i + 1);
			replaceByte.length = 1;
			[md5 replaceBytesInRange:replaceByte withBytes:&(digest[i]) length:1];
			i++;
		}
	
		// Determine which bootloader, these values are in checksum.h as well as SystemInformation.h
		while((returnVal == -1) && index < NUM_KERNELS)
		{
			knownMD5.lower = kernelVersionMD5[index][0];
			knownMD5.upper = kernelVersionMD5[index][1];
			
			kernelMD5 = [[NSData alloc] initWithBytes:(const void *)&knownMD5 length:16];
			
			//[bootmd5 release];
			if([md5 isEqualToData:kernelMD5]) returnVal = index;
			index++;
			
		}
		
		[kernel release];
		[kernelMD5 release];
		[md5 release];
	}
	
	//NSLog(@"Kernel at %@ is 10.5.%d", path, returnVal);

	return returnVal;
	*/
}

@end
