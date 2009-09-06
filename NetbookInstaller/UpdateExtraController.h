//
//  UpdateExtraController.h
//  NetbookInstaller
//
//  Created by Evan Lojewski on 6/23/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SystemInformation.h"
#import "Installer.h"

@interface UpdateExtraController : NSObject {
	IBOutlet NSProgressIndicator*	progressBar;
}

- (IBAction) performInstall: (id) sender;

@end
