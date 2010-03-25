//
//  main_bootmaker.m
//  NetbookInstaller
//
//  Created by Evan Lojewski on 6/20/09.
//  Copyright 2009. All rights reserved.
//

#import <Cocoa/Cocoa.h>

int main(int argc, const char *argv[])
{
#ifndef __APPLE__
	// Initialize the Objectiv-C runtime for Windows
	//NSInitializeProcess(argc,argv);
#endif

	// TODO: make sure everything is realeased properly... (It's not)
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	return NSApplicationMain(argc,  (const char **) argv);
	[pool release];
}
