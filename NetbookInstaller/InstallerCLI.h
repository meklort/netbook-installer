//
//  InstallerCLI.h
//  NetbookInstaller
//
//  Created by Evan Lojewski on 6/18/09.
//  Copyright 2009. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Installer.h"

@interface InstallerCLI : Installer {

}

- (BOOL) runCMD: (char*) command withArgs: (NSArray*) nsargs;


@end
