//
//  kext.m
//  NetbookInstaller
//
//  Created by Evan Lojewski on 12/25/09.
//  Copyright 2009. All rights reserved.
//

#import "kext.h"


@implementation kext


//- (kext*) initWithKext: (NSString*)
//{
//	return self;
//}

/*- (UInt8)kextFlags
{
	return kextFlags;
}
*/
- (BOOL) is32bitCapable
{
	return kextFlags & kext32bit;
}

- (BOOL) is64bitCapable
{
	return kextFlags & kext64bit;
}


@end
