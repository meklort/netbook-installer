//
//  main.m
//  netbookInstallerHelper
//
//  Created by Evan Lojewski on 8/26/09.
//  Copyright __MyCompanyName__ 2009. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>
#import "../../NetbookInstaller/SystemInformation.h"

#define APP_ID "com.meklort.netbookinstaller.helper"
void catcher(int sig);

int main(int argc, char *argv[])
{
	signal(SIGTERM, catcher);
	signal(SIGHUP, catcher);
	signal(SIGINT, catcher);


	while(1)
	{
		sleep(100);
	}
	return 0;

}

void catcher(int sig) {
//	if(sig != SIGTERM) return;
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSFileManager *fileManger = [NSFileManager defaultManager];
	NSDictionary* dict;
	NSMutableDictionary* currentState = [[NSMutableDictionary alloc] init];
	NSError* error;
	
	// Determine current machine state
	SystemInformation* sysInfo = [[SystemInformation alloc] init];
	[sysInfo determineInstallState];
	
	// Currently, all we care about is the OS version, and the extension timestamp. We *will* check /Extra/ later on
	[currentState setObject:[NSNumber numberWithInt:[sysInfo targetOS]] forKey:@"Kernel Version"];
	[currentState setObject:[[fileManger attributesOfItemAtPath:@"/System/Library/Extensions/" error:&error] objectForKey:@"NSFileModificationDate"] forKey:@"System Extensions timestamp"];
	
	
	
	
	// Retrive last known machine state
	dict = (NSDictionary*)CFPreferencesCopyMultiple(NULL ,CFSTR(APP_ID), kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
	
	// Save current state for future use
	CFPreferencesSetMultiple((CFDictionaryRef) currentState, NULL, CFSTR(APP_ID), kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
	if(!CFPreferencesSynchronize(CFSTR("com.meklort.netbookinstaller.helper"), kCFPreferencesCurrentUser, kCFPreferencesAnyHost)) 
		NSLog(@"%s: Failed to save preferences\n", APP_ID);
	
	
	
	if([dict isEqualToDictionary:currentState] || ![dict count]) NSLog(@"No system state changes");	// If we cont know the prevois state, assume no change
	else
	{
		NSLog(@"System state changed, regenerating system caches");
		// TODO: use somethign other than system() for reboot... check to see if there is some api to use
		// Run NetbookInstallerCLI and reboot
		// TODO: verify that file exists, if it doesnt possibly download it / report ot user that it is missing
		system("/Applications/NetbookInstaller.app/Contents/MacOS/NetbookInstallerCLI");
		
		// WARNING: this must be run as root
		//system("reboot");	// no need, we run this at shutdown anyways
	}
	
	
	
	
	
	
	[currentState release];
	[pool release];
	
	exit(0);
}
