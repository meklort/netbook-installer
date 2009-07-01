//
//  DSDTPatcher.h
//  NetbookInstaller
//
//  Created by Evan Lojewski on 5/18/09.
//  Copyright 2009. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SystemInformation.h"



@interface DSDTPatcher : NSObject {
	NSString* originalDSDT;
	NSMutableString* patchedDSDT;
	
	NSMutableData* compiledPatchedDSDT;
	NSData* compiledOriginalDSDT;
	
	enum machine machineType;
}

- (BOOL) applyPatchFiles;
- (BOOL) applyHPETPatch;
- (BOOL) applyRTCPatch;
- (BOOL) applyVersionPatch;
- (BOOL) applyMiscPatch;

//- (BOOL) checkIfPatched;

- (NSData*) getDSDT;
- (NSString*) decompileDSDT: (NSData*) data;;
- (NSData*) compileDSDT: (NSString*) data;

@end
