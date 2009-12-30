//
//  AboutWindowController.m
//  NetbookInstaller
//
//  Created by Evan Lojewski on 6/3/09.
//  Copyright 2009. All rights reserved.
//

#import "AboutWindowController.h"


@implementation AboutWindowController


- (void) awakeFromNib {
	// This is run whenever the about.nib file is loaded.
}

/***
 ** closeAboutWindow
 **		This funciton closes the key window and probably should be renamed as such
 **		It does not specifical close the about window because when you press the
 **		close button, it will always be the key window (theoreticaly...)
 **
 ***/


- (IBAction) closeAboutWindow: (id) sender {
	//	NSWindow* aboutWindow;
	//	aboutWindow = NULL;

	[[NSApp keyWindow] close];
}

@end
