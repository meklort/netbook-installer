//
//  main.m
//  NetbookInstaller
//
//  Created by Evan Lojewski on 5/15/09.
//  Copyright 2009. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "PCI.h"

int main(int argc, char *argv[])
{
	// TODO: make sure everything is realeased properly... (It's not)
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	
	PCIDevice* tempDevice;
	
	PCIDevice*	pciRootdevice = [[PCIDevice alloc] initFromRoot];
	//[pciRootdevice printProperties];
	
	while((tempDevice = [pciRootdevice nextChild]) != 0)
	{
	
		//[tempDevice printProperties];
		ExtendedLog(@"Found vendorID: 0x%X deviceID: 0x%X ClassID: 0x%X SubClassID: 0x%X", [tempDevice vendorID], [tempDevice deviceID], [tempDevice PCIClass], [tempDevice PCISubClass]);
	

		[tempDevice release];
	}

	return NSApplicationMain(argc,  (const char **) argv);
	[pool release];
}
