//
//  HexEditor.h
//  NetbookInstaller
//
//  Created by Evan Lojewski on 6/1/09.
//  Copyright 2009. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface HexEditor : NSObject {
	NSMutableData*	data;
}
- (NSMutableData*) data;
- (id) initWithData: (NSData*) initialData;
- (BOOL) find: (NSData*) needle andReplace: (NSData*) replace;
@end
