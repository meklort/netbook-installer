//
//  kext.h
//  NetbookInstaller
//
//  Created by Evan Lojewski on 12/25/09.
//  Copyright 2009. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define kext32bit		0x01
#define kext64bit		0x02


@interface Kext : NSObject {
	NSDictionary*	kextDictionary;
	UInt8			kextFlags;
}

//- (kext*) initWithKext: (NSString*);

//- (UInt8)kextFlags;
- (BOOL) is32bitCapable;
- (BOOL) is64bitCapable;


@end
