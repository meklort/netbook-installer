//
//  PCI.m
//  NetbookInstaller
//
//  Created by Evan Lojewski on 11/7/09.
//  Copyright 2009. All rights reserved.
//

#import "PCI.h"


@implementation PCIDevice
/**
 ** initFromRoot
 **		Initializes the PCIDeivce by locating the AppleACPIPCI IOService
 **/

- (PCIDevice*)	initFromRoot
{
	kern_return_t		kr = noErr;
	

	kr = IOMasterPort( MACH_PORT_NULL, &masterPort);   
	if (kr == noErr) {
		selfEntry = IOServiceGetMatchingService( masterPort, IOServiceMatching("AppleACPIPCI"));
	}
	
	deviceProperties = nil;
	[self getDeviceProperties];
	
	return self;
}

/**
 ** initFromRoot
 **		Initializes the PCIDeivce with an already located io service.
 **/

- (PCIDevice*)	initWithEntry: (io_service_t) entry
{
	iterator = (io_iterator_t) NULL;
	selfEntry = entry;
	deviceProperties = nil;
	[self getDeviceProperties];
	
	return self;
}


- (NSDictionary*) getDeviceProperties
{
	if(deviceProperties != nil) return deviceProperties;
	if(!selfEntry) return nil;

	CFMutableDictionaryRef		dict;
	
	
	
	IORegistryEntryCreateCFProperties(selfEntry, 
									  &dict, 
									  kCFAllocatorDefault, 
									  kNilOptions ); 
	deviceProperties = (NSDictionary*) dict;
	
	return deviceProperties;
}	

- (PCIDevice*)	nextChild
{
	io_service_t childEntry;
	io_name_t className;
	kern_return_t kr;
	PCIDevice* child = [PCIDevice alloc];

	if(!iterator)
	{
		
		kr = IORegistryCreateIterator(masterPort, kIOServicePlane, kIORegistryIterateRecursively, &iterator);
		if(kr) NSLog(@"IORegistryCreateIterator Returned %d", kr);	//kIOReturnNoDevice

	}
	
	
	do
	{
		childEntry = IOIteratorNext(iterator);
		IOObjectGetClass(childEntry, className);
	} while (childEntry && strcmp(className, "IOPCIDevice") != 0);	// we only want IOPCIDevices
		
	if(!childEntry) {
		IOObjectRelease(iterator);
		iterator = (io_iterator_t) NULL;		// reset. The client should be able to handel a nil correctly...
		[child release];
		return nil;
	}
	
	child = [child initWithEntry:childEntry];
	
	return child;
}


- (UInt32)		deviceID
{
	NSData* data;
	
	if(deviceProperties && (data = [deviceProperties objectForKey:@"device-id"]))
	{
		return (UInt32) *((UInt32*)[data bytes]);
	} else {
		return 0;
	}

}


- (UInt32)		vendorID
{
	NSData* data;
	
	if(deviceProperties && (data = [deviceProperties objectForKey:@"vendor-id"]))
	{
		// NOTE: The data type is actualy a 64 bit number, not 32.
		return (UInt32) *((UInt32*)[data bytes]);
	} else {
		return 0;
	}

}

- (UInt32)		PCIClass		// read from "class-code"
{
	NSData* data;
	if(deviceProperties && (data = [deviceProperties objectForKey:@"class-code"]))
	{
		// NOTE: The data type is actualy a 64 bit number, not 32.
		return ((UInt32) *((UInt32*)[data bytes]) & 0xFFFF0000) >> 16;
	} else {
		return 0;
	}
}

- (UInt32)		PCISubClass;	// read from "class code"
{
	return 0;
	/*NSData* data;

	
	if(deviceProperties && (data = [deviceProperties objectForKey:@"class-code"]))
	{
		// NOTE: The data type is actualy a 64 bit number, not 32.
		return ((UInt32) *((UInt32*)[data bytes]) & 0xFF);

	} else {
		return 0;
	}*/
}

- (BOOL)		driverAvailable
{
	return 0;
}

- (void) printProperties
{

	NSLog(@"AppleACPIPCI properties: %@", deviceProperties);
}


@end
