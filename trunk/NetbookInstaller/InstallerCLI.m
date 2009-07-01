//
//  InstallerCLI.m
//  NetbookInstaller
//
//  Created by Evan Lojewski on 6/18/09.
//  Copyright 2009. All rights reserved.
//

#import "InstallerCLI.h"


@implementation InstallerCLI: Installer

// TODO: The copy and move commands should also be over ridden to use NSFileManager since this will be run as root
- (BOOL) runCMD: (char*) command withArgs: (NSArray*) nsargs
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
		
		[run appendString:escapedString];
		
		i++;
	}
	
	system([run cStringUsingEncoding:NSASCIIStringEncoding]);	
	return YES;
}



@end
