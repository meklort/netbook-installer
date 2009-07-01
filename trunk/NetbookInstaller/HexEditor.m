//
//  HexEditor.m
//  NetbookInstaller
//
//  Created by Evan Lojewski on 6/1/09.
//  Copyright 2009. All rights reserved.
//

#import "HexEditor.h"


@implementation HexEditor

- (id) initWithData: (NSData*) initialData
{
	data = [[NSMutableData alloc] initWithData: initialData];
	return self;
}

- (NSUInteger) find: (NSData*) needle andReplace: (NSData*) replace
{
	NSUInteger index = 0;
	NSRange	range;
	NSData* compare;
	void* bytes = malloc([needle length] * 8);
	
	range.length = [needle length];
		
	while(index < [data length] - [needle length])
	{
		range.location = index;
		[data getBytes: bytes range: range];
		//NSLog(@"%d", index);

		compare = [[NSData alloc] initWithBytes: bytes length: range.length];
		if([compare isEqualToData:needle])
		{
			//NSLog(@"Found byte sequence, replacing\n");
			[data replaceBytesInRange:range withBytes:[replace bytes] length:[replace length]];
		}
		index++;
	}
	free(bytes);
	
	return YES;
}

- (NSMutableData*) data
{
	return data;
}

@end
