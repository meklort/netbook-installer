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

- (NSString*) getMachineString
{
	
	switch(machineType)
	{
		case MINI9:
			return @"Mini 9";
			break;
		case VOSTRO_A90:
			return @"Vostro A9-";
			break;
		case MINI10V:
			return @"Mini 10v";
			break;
		case LENOVO_S10:
			return @"Lenovo S10";
			break;
		default:
			return @"Generic";
			break;
	}
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

- (NSString*) extensionsFolder
{
	return extensionsFolder;
}

- (bool) quietBoot
{
	return quietBoot;
}

- (bool) bluetoothPatched
{
	return bluetoothPatched;
}

- (bool) mirrorFriendlyGMA
{
	return mirrorFriendlyGMA;
}

-(bool) efiHidden
{
	return efiHidden;
}
- (enum machine) machineType
{
	return machineType;
}

- (void) machineType: (enum machine) newMachineType
{
	machineType = newMachineType;
}

- (enum bootloader) installedBootloader
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
	
	NSLog(@"Root Device: %s\n", (const char*)(*buffer).vMDeviceID);
	
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
	
	NSLog(@"Root Device: %s\n", (const char*)(*buffer).vMDeviceID);
	
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
	extensionsFolder = [NSString alloc];
	// Get the model
	int mib[2];
	char* model;
	size_t len;
	mib[0] = CTL_HW;
	mib[1] = HW_MODEL;
	len = sizeof(model);
	sysctl(mib, 2, NULL, &len, NULL, 0);
	model = malloc(len);
	sysctl(mib, 2, model, &len, NULL, 0);

	if(strcmp(model,"Inspiron 910") == 0)	{
		machineType = MINI9;
		extensionsFolder = [extensionsFolder initWithString:@"/Extra/Mini9Ext"];
		
	} else if(strcmp(model,"Vostro A90") == 0)	{
		machineType = VOSTRO_A90;
		extensionsFolder = [extensionsFolder initWithString:@"/Extra/VostroA90Ext"];
	
	} else if(strcmp(model,"Inspiron 1011") == 0)	{
		machineType = MINI10V;
		extensionsFolder = [extensionsFolder initWithString:@"/Extra/Mini10vExt"];
		
	} else if(strncmp(model, "Lenovo", strlen("Lenovo")) == 0)	{	// Bug in the S10 adds junk after "Lenovo"
		machineType = LENOVO_S10;
		extensionsFolder = [extensionsFolder initWithString:@"/Extra/LenovoS10Ext"];

	} else {
		machineType = UNKNOWN;
		extensionsFolder = [extensionsFolder initWithString:@"/Extra/CustomExtensions"];
	}
	
	extensionsFolder = [[NSString alloc] initWithString:[installPath stringByAppendingString: extensionsFolder]];
	NSLog(@"Extensions Directory: %@", extensionsFolder);
	free(model);
}

- (void) determineDSDTState
{
	NSFileManager* fileManager;
	fileManager = [NSFileManager defaultManager];

	dsdtInstalled = [fileManager fileExistsAtPath: [installPath stringByAppendingString: @"/Extra/DSDT.aml"]];
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
	NSBundle*	gmaFramebuffer = [[NSBundle alloc] initWithPath:[extensionsFolder stringByAppendingString:@"/AppleIntelIntegratedFramebuffer.kext/"]];
	mirrorFriendlyGMA = [[[gmaFramebuffer infoDictionary] valueForKey:@"CFBundleVersion"] isEqualToString:@"5.3.0"];
}

- (void) determineBluetoothState
{
	NSFileManager* fileManager;
	fileManager = [NSFileManager defaultManager];
	
	bluetoothPatched = [fileManager fileExistsAtPath: [installPath stringByAppendingString: @"/Library/Preferences/com.apple.Bluetooth.plist"]] ? false : true;
	
	switch(machineType)
	{
		case MINI9:
		case VOSTRO_A90:
			bluetoothVendorId = MINI9_BLUETOOTH_VENDOR;
			bluetoothDeviceId = MINI9_BLUETOOTH_DEVICE;
			break;
		case MINI10V:
			bluetoothVendorId = MINI10V_BLUETOOTH_VENDOR;
			bluetoothDeviceId = MINI10V_BLUETOOTH_DEVICE;
			break;
		case LENOVO_S10:
			bluetoothVendorId = S10_BLUETOOTH_VENDOR;
			bluetoothDeviceId = S10_BLUETOOTH_DEVICE;
			break;
		default:
			bluetoothVendorId = 0;
			bluetoothDeviceId = 0;
			break;
	}
	
	
	
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


- (void) determineBootloader
{
	// TODO: fixme This is causing a problem.
	NSData* bootloader = [[NSData alloc] initWithContentsOfFile:[installPath stringByAppendingString:@"/boot"]];
	unsigned char *digest;
	installedBootloader = NONE;
	UInt8 i = 0;
	UInt8 bootIndex = 0;
	
	struct uint128 knownMD5;
	NSRange replaceByte;

	NSMutableData* md5 =			[[NSMutableData alloc] initWithLength:16];
	NSData* bootmd5;


	

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


	// Determine which bootloader, these values are in checksum.h as well as SystemInformation.h
	while(installedBootloader == NONE && bootIndex < NUM_SUPPORTED_BOOTLOADERS)
	{
		knownMD5.lower = bootLoaderMD5[bootIndex][0];
		knownMD5.upper = bootLoaderMD5[bootIndex][1];

		bootmd5 = [[NSData alloc] initWithBytes:(const void *)&knownMD5 length:16];
		
		//[bootmd5 release];
		if([md5 isEqualToData:bootmd5]) installedBootloader = bootIndex;
		bootIndex++;

	}
	[bootloader release];
	[bootmd5 release];
	[md5 release];
	
}

- (int) targetOS
{
	return installedKernel;
}
- (BOOL) determineTargetOS
{
	installedKernel = [self getKernelVersion:[installPath stringByAppendingString:@"/mach_kernel"]];
	return YES;
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
	
- (int) getKernelVersion: (NSString*) path
{
	// Verify the target os version
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
	
}

@end
