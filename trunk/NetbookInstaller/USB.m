//
//  USB.m
//  NetbookInstaller
//
//  Created by Evan Lojewski on 11/7/09.
//  Copyright 2009. All rights reserved.
//

#import "USB.h"


@implementation USBDevice

/**
 ** initWithEntry
 **		Initializes the PCIDeivce with an already located io service.
 **/

- (USBDevice*)	initWithEntry: (io_service_t) entry
{
	io_name_t className;

	iterator = (io_iterator_t) NULL;
	selfEntry = entry;
	deviceProperties = nil;

	IOObjectGetClass(selfEntry, className);

	if(strcmp(className, "AppleUSBUHCI") != 0 ||
	   strcmp(className, "AppleUSBEHCI") != 0) return nil;
	return self;
}


- (NSDictionary*) getDevicePropertiesOnDevice: (io_service_t) device
{
	if(!device) return nil;

	CFMutableDictionaryRef		dict;
	
	
	
	IORegistryEntryCreateCFProperties(selfEntry, 
									  &dict, 
									  kCFAllocatorDefault, 
									  kNilOptions ); 
	deviceProperties = (NSDictionary*) dict;
	
	return deviceProperties;
}	


- (void) parseChildren
{
	io_service_t childEntry;
	kern_return_t kr;	
	if(!iterator)
	{
		
		kr = IORegistryCreateIterator(masterPort, kIOServicePlane, kIORegistryIterateRecursively, &iterator);
		if(kr) ExtendedLog(@"IORegistryCreateIterator Returned %d", kr);	//kIOReturnNoDevice
		
	}
	
	
	do
	{
		childEntry = IOIteratorNext(iterator);
		[self getDevicePropertiesOnDevice: childEntry];
		[self printProperties];
		// Log
		
	} while (childEntry);
	
	IOObjectRelease(iterator);
	iterator = (io_iterator_t)0;		// reset. The client should be able to handel a nil correctly...
}



- (UInt32)		deviceID
{
	NSData* data;
	
	if(deviceProperties && (data = [deviceProperties objectForKey:@"idProduct"]))
	{
		return (UInt32) *((UInt32*)[data bytes]);
	} else {
		if(deviceProperties && (data = [deviceProperties objectForKey:@"device-id"]))
		{
			return (UInt32) *((UInt32*)[data bytes]);
		}
		else
		{
			return 0;
		}
	}

}


- (UInt32)		vendorID
{
	/** NOTE: Only call on children **/
	
	NSData* data;
	
	if(deviceProperties && (data = [deviceProperties objectForKey:@"idVendor"]))
	{
		// NOTE: The data type is actualy a 64 bit number, not 32.
		return (UInt32) *((UInt32*)[data bytes]);
	} else {
		if(deviceProperties && (data = [deviceProperties objectForKey:@"vendor-id"]))
		{
			return (UInt32) *((UInt32*)[data bytes]);
		}
		else
		{
			return 0;
		}
	}

}

- (BOOL) driverAvailable
{
	return 0;
}

- (void) printProperties
{

	ExtendedLog(@"USB properties: %@", deviceProperties);
}


@end
