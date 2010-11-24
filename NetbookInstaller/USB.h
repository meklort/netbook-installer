//
//  PCI.h
//  NetbookInstaller
//
//  Created by Evan Lojewski on 11/7/09.
//  Copyright 2009. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <IOKit/IOKitLib.h>


@interface USBDevice : NSObject {
	io_service_t		selfEntry;
	io_iterator_t		iterator;
	mach_port_t			masterPort;
	UInt32				pciIndex;
	NSDictionary*		deviceProperties;

}
- (USBDevice*)	initWithEntry: (io_service_t) entry;

- (NSDictionary*) getDevicePropertiesOnDevice: (io_service_t) device;

- (void) parseChildren;
- (UInt32)		deviceID;
- (UInt32)		vendorID;

- (BOOL)		driverAvailable;

- (void) printProperties;

@end
