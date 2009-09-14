//
//  NetbookInstallerController.m
//  NetbookInstaller
//
//  Created by Evan Lojewski on 5/15/09.
//  Copyright 2009. All rights reserved.
//

#import "NetbookInstallerController.h"

@implementation NetbookInstallerController

/***
 ** awakeFromNib
 **		This function handles intializing the window before it is displayed. 
 **		It obtains the system info and sets the checkboxes and labels
 **
 ***/
- (void) awakeFromNib {	
	// This is run whenever ANY nib file is loaded
	if(!initialized) [self initializeApplication];
}
- (IBAction) volumeChanged: (id) sender
{
//	NSLog(@"Selected target: %@", [@"/Volumes/" stringByAppendingString:[[sender selectedItem] title]]);
	[systemInfo determinePartitionFromPath:[@"/Volumes/" stringByAppendingString:[[sender selectedItem] title]]];
 
	// TODO: enable this
	[self updateBootloaderMenu];
	[self updateCheckboxes];
}
- (void) updateBootloaderMenu
{
	NSMutableArray* bootOptions = [[NSMutableArray alloc] init];
	NSArray* bootloaders = [systemInfo supportedBootloaders];
//	NSLog(@"bootloaders: %@", bootloaders);

	NSEnumerator* enumerator = [bootloaders objectEnumerator];
	NSDictionary* bootloader;
	// TODO: read these from the plist
	while(bootloader = [enumerator nextObject]) {
		[bootOptions addObject:[bootloader objectForKey:@"Visible Name"]];

	}
//	NSLog(@"bootOptions: %@", bootOptions);
	[bootloaderVersion removeAllItems];
	[bootloaderVersion addItemsWithTitles:bootOptions];
	
	// TODO: select default bootloader
		
	/*if([systemInfo installedBootloader] != nil)
		// TODO: follow upgrade path and determine if we need to upgrade to a new bootloader
		[bootloaderVersion selectItemWithTitle:[[systemInfo installedBootloader] objectForKey:@"Support Files"]];

	else
	{
		// No bootloader is installed, default to the latest version available
		[bootloaderVersion selectItemWithTitle:[[systemInfo bootloaderDict] objectForKey:@"Default Bootloader"]];
		[bootloaderVersion setState:true];
	}*/
}

- (void) initializeApplication
{
	NSDictionary* infoDict;
	systemInfo = [[SystemInformation alloc] init];
	appBundle = [NSBundle mainBundle];
	infoDict = [appBundle infoDictionary];
	NSNotificationCenter *notificationCenter = [[NSWorkspace sharedWorkspace] notificationCenter];
	
	[notificationCenter addObserver:self selector:@selector(mountChange:) name:NSWorkspaceDidMountNotification object:nil];
	[notificationCenter addObserver:self selector:@selector(mountChange:) name:NSWorkspaceDidUnmountNotification object:nil];
	
	[systemInfo determineInstallState];
	
	[self updateVolumeMenu];
	[self enableOptions];
	[self updateCheckboxes];

	
	
	// Set the version lable and window title (does not fully rebrand, but it's good enough)
	[mainWindow	  setTitle:		  [infoDict objectForKey:@"CFBundleExecutable"]];	// Bundle Name would work as well
	[versionLabel setStringValue: [infoDict objectForKey:@"CFBundleVersion"]];
	
	// Initialize botloader dropdown
	[self updateBootloaderMenu];
	
	
	
	// Initialize warning label
	// TODO: machine specific labels
	[warningLabel setStringValue:NSLocalizedString(@"Warning Label", nil)];
	/*switch([systemInfo machineType]) {
		case MINI9: [warningLabel setStringValue:NSLocalizedString(@"Mini 9 Warning", nil)];
			break;
		case MINI10V: [warningLabel setStringValue:NSLocalizedString(@"Mini 10v Warning", nil)];
			break;
		case VOSTRO_A90: [warningLabel setStringValue:NSLocalizedString(@"Vostro A90 Warning", nil)];
			break;
		case LENOVO_S10: [warningLabel setStringValue:NSLocalizedString(@"S10 Warning", nil)];
			break;
		case EEE_1000H: [warningLabel setStringValue:NSLocalizedString(@"EEE 1000H Warning", nil)];
		case UNKNOWN:
		default: [warningLabel setStringValue:NSLocalizedString(@"Unknown Warning", nil)];
			break;
	}*/
	
	[self updateCheckboxes];

	[targetVolume setStringValue:[systemInfo bootPartition]];
}

- (void) updateCheckboxes
{
	
	if([systemInfo installedBootloader] != nil) {
		[bootloaderCheckbox setState: false];
		[bootloaderVersion setEnabled:false];
	} 
	else
	{
		[bootloaderCheckbox setState: true];
		[bootloaderVersion setEnabled:true];

		
	}
	
	// Initialize checkboxes (TODO: commented checkboxes need to be initialized
	//extensionsCheckbox;
	//oldGMACheckbox;
	
	if([systemInfo efiHidden])
	{
		[showhideFilesCheckbox setState:false];
		[showhideFilesCheckbox setTitle:[[@"Show " stringByAppendingString:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleExecutable"]] stringByAppendingString:@" Files"]];
	} 
	else
	{
		[showhideFilesCheckbox setState:true];
		[showhideFilesCheckbox setTitle:[[@"Hide " stringByAppendingString:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleExecutable"]] stringByAppendingString:@" Files"]];
		
	}
	[extensionsCheckbox setTitle:[[@"Install " stringByAppendingString:[systemInfo getMachineString]] stringByAppendingString:@" Extensions"]];
	 
	[dsdtCheckbox setState:![systemInfo dsdtInstalled]];
	if([systemInfo remoteCDEnabled])
	{
		[remoteCDCheckbox setState:false];
		[remoteCDCheckbox setTitle:NSLocalizedString(@"Disable Remote CD", nil)];
	} 
	else
	{
		[remoteCDCheckbox setState:true];
		[remoteCDCheckbox setTitle:NSLocalizedString(@"Enable Remote CD", nil)];
		
	}
	
	if([systemInfo hibernationDissabled])
	{
		[hibernateChecbox setState:false];
		[hibernateChecbox setTitle:NSLocalizedString(@"Enable hibernation", nil)];
	} 
	else
	{
		[hibernateChecbox setState:true];
		[hibernateChecbox setTitle:NSLocalizedString(@"Disable hibernation", nil)];
		
	}
	
	if([systemInfo quietBoot])
	{
		[quietBootCheckbox setState:false];
		[quietBootCheckbox setTitle:NSLocalizedString(@"Disable Quiet Boot", nil)];
	} 
	else
	{
		[quietBootCheckbox setState:false];
		[quietBootCheckbox setTitle:NSLocalizedString(@"Enable Quiet Boot", nil)];
		
	}
	[bluetoothCheckbox setState:![systemInfo bluetoothPatched]];

}

/***
 ** isMachineSupported
 **		This function checks the system info class's machineType varaible 
 **		and insures that not only is it supported, but that the nessicary
 **		extensions exist.
 **
 ***/
- (BOOL) isMachineSupported {
	if([[systemInfo getMachineString] isEqualToString:@"General"]) return NO;
	else return YES;
	
	// TODO: verify the machine's directory exists. If it doesnt, then the machine isn't supported
	/*BOOL			supported, isDir = YES;
	NSFileManager* fileManager;
	NSString		*path, *fullPath;
	
	fileManager = [NSFileManager defaultManager];
	path = [appBundle resourcePath];
	
	switch([systemInfo machineType]) {
		case MINI9:
		case VOSTRO_A90:
			
			fullPath = [NSString stringWithFormat:@"%@/SupportFiles/Extensions/Mini 9 Extensions/",path];
			supported = [fileManager fileExistsAtPath: fullPath isDirectory: &isDir];
			if(!isDir) supported = NO;
			break;
		
		case MINI10V:
			fullPath = [NSString stringWithFormat:@"%@/SupportFiles/Extensions/Mini 10v Extensions/",path];
			supported = [fileManager fileExistsAtPath: fullPath isDirectory: &isDir];
			if(!isDir) supported = NO;
			break;
			
		case LENOVO_S10:
			fullPath = [NSString stringWithFormat:@"%@/SupportFiles/Extensions/S10 Extensions/",path];
			supported = [fileManager fileExistsAtPath: fullPath isDirectory: &isDir];
			if(!isDir) supported = NO;			break;
		case EEE_1000H:
			fullPath = [NSString stringWithFormat:@"%@/SupportFiles/Extensions/EEE 1000H Extensions/",path];
			supported = [fileManager fileExistsAtPath: fullPath isDirectory: &isDir];
			if(!isDir) supported = NO;			break;
		case UNKNOWN:
		default:
			//NSLog(@"Unknown");
			supported = NO;
			break;
	}
	
	if(!supported) [systemInfo machineType: UNKNOWN];
	return supported;*/
}

/***
 ** applicationDidFinishLoading
 **		This function creates an alert if we are on an unsupported machine
 **		This is NOT in awake from nib because the alert cannot attach to the window
 **		when it isn't done being created / visible
 **
 ***/
- (void) applicationDidFinishLaunching:(id)application
{
	
	initialized = YES;
	if(![self isMachineSupported]) {
		// Look into NSRunAlertPanel
		NSAlert *alert = [[[NSAlert alloc] init] autorelease];
		[alert addButtonWithTitle:NSLocalizedString(@"Continue", nil)];
		[alert addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
		[alert setMessageText:NSLocalizedString(@"Unsupported Device", nil)];
		[alert setInformativeText:NSLocalizedString(@"You are running this applicaiton on an unsupported device. Are you sure you want to continue?", nil)];
		[alert setAlertStyle:NSWarningAlertStyle];
		[alert beginSheetModalForWindow:mainWindow modalDelegate:self didEndSelector:@selector(unknownMachineAlert:returnCode:contextInfo:) contextInfo:nil];
	}
}

/***
 ** applicationShouldTerminateAfterLastWindowClosed
 **		This funciton tells Mac OS X to terminate the program when the windows close
 **
 ***/
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication {
	return YES;
}


- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
	if(installing) return NSTerminateCancel;
	else return NSTerminateNow;
}

/***
 ** unknownMachineAlert
 **		This function handles the alert and exit's if the user selects cancle
 **
 ***/
- (void) unknownMachineAlert:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	if(returnCode == NSAlertSecondButtonReturn)
	{
		exit(-1);
	}
}

/***
 ** performInstall
 **		This function is called when the install button is pressed.
 **		It creates an installer and passes it needed information.
 **
 ***/
- (IBAction) performInstall:  (id) sender {
	if(![targetVolume selectedItem])
	{
		// do something, the install failed
		// TODO: Alert the user that the install failed
		NSAlert *alert = [[[NSAlert alloc] init] autorelease];
		[alert addButtonWithTitle:NSLocalizedString(@"Continue", nil)];
		[alert setMessageText:NSLocalizedString(@"Select a Target", nil)];
		[alert setInformativeText:NSLocalizedString(@"Please select a target volume to continue", nil)];
		[alert setAlertStyle:NSWarningAlertStyle];
		[alert beginSheetModalForWindow:mainWindow modalDelegate:nil didEndSelector:nil contextInfo:nil];
		return;
	}
	
	
	installing = YES;	// Dissable applicaiton closing while it's doing stuff
	[installButton setEnabled:false];
	[progressBar setHidden:false];
	[progressBar startAnimation: sender];
	
	[NSThread detachNewThreadSelector:@selector(performThreadedInstall) toTarget: self withObject: nil];
		
		
	
	// TODO:  Force a restart if needed
	
	//[progressBar setHidden:true];
	//[progressBar stopAnimation: sender];
		
}

/***
 ** openAboutWindows
 **		This opens the about window by loading the about nib.
 **		The check is very simple and could (should) be much better / fixed
 **
 ***/
- (IBAction) openAboutWindow: (id) sender
{
	NSArray* windows;
	// TODO: Fix the check to ensure it really is not open
	
	// Check to make sure only one (the main window) exists.
	// Since there are only two possible windows (main + about), this is acceptable
	//if([[NSApp windows] count] < 2) [NSBundle loadNibNamed:@"about" owner:self];
	
	
	// Use
	
	int i = 0;
	windows = [NSApp windows];
	while(i < [windows count])
	{
		if([windows objectAtIndex:i]  && [[[windows objectAtIndex:i] title] isEqualToString:@"About"]) return;
		i++;
	}
	[NSBundle loadNibNamed:@"about" owner:self];
}

/***
 ** installationMethodModified
 **		This is called when the installation method checkbox is chaned, enables
 **		or disabled all of the checkboxes
 **		
 ***/
- (void) enableOptions
{

	bool state = true;
	//bool state = true;
	// Dissable / enable all checkboxes
	[bootloaderCheckbox			setEnabled: state];
	//if(state) 	[oldGMACheckbox setEnabled: [oldGMACheckbox state]];
	//else		[oldGMACheckbox setEnabled: false];
	
	[extensionsCheckbox			setEnabled: state];
	[oldGMACheckbox				setEnabled: state && [extensionsCheckbox state]];

	[showhideFilesCheckbox		setEnabled: state];
	[dsdtCheckbox				setEnabled: state];
	[remoteCDCheckbox			setEnabled: state];
	[hibernateChecbox			setEnabled: state];
	[quietBootCheckbox			setEnabled: state];
	[bluetoothCheckbox			setEnabled: state];
	[bootloaderVersion			setEnabled: state && [bootloaderCheckbox state]];

}


- (IBAction) bootloaderModified: (id) sender
{
	// Dissable / enable target option
	[bootloaderVersion setEnabled: [sender state]];
//	[targetDiskBlah
}


- (IBAction) extensionsModified: (id) sender
{
	[oldGMACheckbox setEnabled: [sender state]];
	// Dissable / enable GMA checbox
}

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
	[systemInfo release];
}


- (void) setProgress: (double) progress
{
	[progressBar setDoubleValue:progress];
}

////////////////

- (BOOL) enableQuietBoot
{
	if(![quietBootCheckbox state]) return [systemInfo quietBoot];
	else return (![systemInfo quietBoot]);
}

- (BOOL) dissableHibernation
{
	if(![hibernateChecbox state]) return [systemInfo hibernationDissabled];
	else return (![systemInfo hibernationDissabled]);
}

- (BOOL) enableRemoteCD
{
	if(![remoteCDCheckbox state]) return [systemInfo remoteCDEnabled];
	else return (![systemInfo remoteCDEnabled]);
}


- (BOOL) installExtensions
{
	return [extensionsCheckbox state];
}

- (NSDictionary*) bootloaderType
{
	NSDictionary* returnDict = nil;
	if(![bootloaderVersion titleOfSelectedItem]) return nil;
	if([bootloaderCheckbox state] == NO) return nil;
	//NSLog(@"verifying bootlaoder");

	NSEnumerator* bootloaders = [[[systemInfo bootloaderDict] objectForKey:@"Bootloaders"] keyEnumerator];
	NSDictionary* bootloader;
	while(bootloader = [bootloaders nextObject])
	{
		NSLog(@"Testing against %@", bootloader);
		if([[bootloaderVersion titleOfSelectedItem] isEqualToString:[[[[systemInfo bootloaderDict] objectForKey:@"Bootloaders"] objectForKey:bootloader] objectForKey:@"Visible Name"]]) {
//			NSLog(@"Found %@", [[[systemInfo bootloaderDict] objectForKey:@"Bootloaders"] objectForKey:bootloader]);
			returnDict = [[NSDictionary alloc] initWithDictionary: [[[systemInfo bootloaderDict] objectForKey:@"Bootloaders"] objectForKey:bootloader] copyItems:YES];
			break;
		}
	}
	
	return returnDict;
}

- (BOOL) fixBluetooth
{
	return [bluetoothCheckbox state];
}

- (BOOL) mirrorFriendlyGMA
{
	return [oldGMACheckbox state];
}

- (BOOL) regenerateDSDT
{
	return [dsdtCheckbox state];
}
- (BOOL) toggleVisibility
{
	return [showhideFilesCheckbox state];
}


- (BOOL) updatePorgressBar: (NSNumber*) percent
{
	// This is often called from a secondary thread, if so, we need to call it on the main thread
	if(![[NSThread currentThread] isMainThread])
	{
		[self performSelectorOnMainThread:@selector(updatePorgressBar:) withObject: percent waitUntilDone:NO];
		
	}
	else {
		[progressBar incrementBy: [percent intValue]];
	}
	return YES;
}
- (BOOL) updateStatus: (NSString*) status
{
	// This is often called from a secondary thread, if so, we need to call it on the main thread
	if(![[NSThread currentThread] isMainThread])
	{
		[self performSelectorOnMainThread:@selector(updateStatus:) withObject: status waitUntilDone:NO];

	}
	else {
		NSLog(@"%@", status);
		[statusLabel setStringValue:status];		
	}
	return YES;
}	

- (BOOL) hideFiles
{
	return [showhideFilesCheckbox state];
}


- (void) updateVolumeMenu
{
	NSArray* options = [systemInfo installableVolumes: KERNEL_VERSION(10, 5, 6)];
	//	NSMutableArray* newOptions;
	
	NSMenuItem* current = [targetVolume selectedItem];
	
	
	[targetVolume removeAllItems];
	[targetVolume addItemsWithTitles:options];
	[targetVolume selectItemWithTitle:[current title]];	
	
}

- (BOOL) installFinished
{
	[installButton setEnabled:true];
	[progressBar setHidden:true];
	[progressBar startAnimation: self];
	[self setProgress:0];	
	installing = NO;
	
	NSAlert *alert = [[[NSAlert alloc] init] autorelease];
	[alert addButtonWithTitle:NSLocalizedString(@"Continue", nil)];
	[alert setMessageText:NSLocalizedString(@"Installation Complete", nil)];
	[alert setInformativeText:NSLocalizedString(@"The installation Completed successfully.", nil)];
	[alert setAlertStyle:NSWarningAlertStyle];
	[alert beginSheetModalForWindow:mainWindow modalDelegate:nil didEndSelector:nil contextInfo:nil];
	

	return YES;
	
}

- (BOOL) installFailed
{
	[installButton setEnabled:true];
	[progressBar setHidden:true];
	[progressBar startAnimation: self];
	[self setProgress:0];	

	
	NSAlert *alert = [[[NSAlert alloc] init] autorelease];
	[alert addButtonWithTitle:NSLocalizedString(@"Continue", nil)];
	[alert setMessageText:NSLocalizedString(@"Installation Failed", nil)];
	[alert setInformativeText:NSLocalizedString(@"The installation failed. Please look at consol.app for more information about the failure.", nil)];
	[alert setAlertStyle:NSWarningAlertStyle];
	[alert beginSheetModalForWindow:mainWindow modalDelegate:nil didEndSelector:nil contextInfo:nil];

	installing = NO;
	
	return YES;
	
}

- (void) mountChange:(NSNotification *)notification 
{
	[self updateVolumeMenu];
	// TOOD: update the volume list.
	//NSString *devicePath = [[notification userInfo] objectForKey:@"NSDevicePath"];
	
	
//	NSLog(@"Device did mount: %@", devicePath);
}


- (BOOL) performThreadedInstall
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	Installer* installer = [[Installer alloc] init];
	[installer systemInfo: systemInfo];
	//systemInfo = sysInfo;
	
	if(![installer getAuthRef]) 
	{
		[self performSelectorOnMainThread:@selector(installFailed) withObject: nil waitUntilDone:NO];
		return NO;
	}
	
	
	[self updateStatus:NSLocalizedString(@"Remounting target", nil)];
	[installer remountTargetWithPermissions];
	[self updatePorgressBar: [NSNumber numberWithInt: 0]];
	
	
	[self updateStatus:NSLocalizedString(@"Creating ramdisk", nil)];
	[installer mountRamDisk];
	[self updatePorgressBar: [NSNumber numberWithInt: 7]];
		
	//[self copyFrom:[[[[NSBundle mainBundle] resourcePath] stringByAppendingString: @"/SupportFiles/machine/General/ExtraFiles//UpdateExtra.app"] toDir:[[systemInfo installPath] stringByAppendingString: @"/Extra/"]];
	
	[self updatePorgressBar: [NSNumber numberWithInt: 0]];
	[self updateStatus:NSLocalizedString(@"Creating /Extra", nil)];
	if([self installExtensions]) 
	{
		[installer removePrevExtra];
	} else
	{
		[installer installExtraFiles];
	}
	[self updatePorgressBar: [NSNumber numberWithInt: 3]];
	
	
	[self updateStatus:NSLocalizedString(@"Installing Display Profiles", nil)];
	[installer installDisplayProfile];
	[self updatePorgressBar: [NSNumber numberWithInt: 1]];
	
	[self updateStatus:NSLocalizedString(@"Installing Preference Panes", nil)];
	[installer installPrefPanes];
	[installer installLaunchAgents];
	[self updatePorgressBar: [NSNumber numberWithInt: 1]];
	
	
	[self updateStatus:NSLocalizedString(@"Instaling Power Managment bundle", nil)];
	[installer installSystemConfiguration];
	[self updatePorgressBar: [NSNumber numberWithInt: 1]];
	
	if([self regenerateDSDT]) [installer installDSDT]; // modifed version of chameleon ensures origional dsdt is available.
	

	
	
	if([self installExtensions]){
		//[self makeDir:@"/Volumes/ramdisk/Extensions"];
		[self updateStatus:NSLocalizedString(@"Copying Dependencies", nil)];
		[installer copyDependencies];
		[self updatePorgressBar: [NSNumber numberWithInt: 5]];
		
		[self updateStatus:NSLocalizedString(@"Installing Extensions", nil)];
		[installer installExtensions];
		[installer installLocalExtensions];
		[self updatePorgressBar: [NSNumber numberWithInt: 14]];
		
		if([self mirrorFriendlyGMA]) 
		{
			[installer installMirrorFriendlyGraphics];
		}
		else 
		{
			[self updateStatus:NSLocalizedString(@"Patching GMA950 Extension", nil)];
			[installer patchGMAkext];
			[self updatePorgressBar: [NSNumber numberWithInt: 5]];
			
			[self updateStatus:NSLocalizedString(@"Patching Framebuffer Extension", nil)];
			[installer patchFramebufferKext];
			[self updatePorgressBar: [NSNumber numberWithInt: 5]];
		}
		
		[self updateStatus:NSLocalizedString(@"Patching Wireless Extension", nil)];
		[installer patchIO80211kext];
		[self updatePorgressBar: [NSNumber numberWithInt: 5]];
		
		[self updateStatus:NSLocalizedString(@"Patching Bluetooth", nil)];
		[installer patchBluetooth];
		[self updatePorgressBar: [NSNumber numberWithInt: 5]];
		
		[self updateStatus:NSLocalizedString(@"Patching USB", nil)];

		[installer patchAppleUSBEHCI];
		
		[self updateStatus:NSLocalizedString(@"Generating Extension Caches", nil)];
		[installer generateExtensionsCache];
		[installer useSystemKernel];
		
	}
	
	[self updateStatus:NSLocalizedString(@"Verifying Quiet Boot state", nil)];
	[installer setQuietBoot:			[self enableQuietBoot]];
	
	
	[self updateStatus:NSLocalizedString(@"Verifying Hibernation state", nil)];
	[installer dissableHibernation:	[self dissableHibernation]];
	
	[self updateStatus:NSLocalizedString(@"Verifying RemoteCD State", nil)];
	[installer setRemoteCD:			[self enableRemoteCD]];
	[self updatePorgressBar: [NSNumber numberWithInt: 5]];
	
	[self updateStatus:NSLocalizedString(@"Verifying Bootloader", nil)];
	NSLog(@"Installing bootloader %@", [self bootloaderType]);
	if([self bootloaderType]) [installer installBootloader: [[NSDictionary alloc] initWithDictionary:[self bootloaderType] copyItems:YES]];
	[self updatePorgressBar: [NSNumber numberWithInt: 10]];
	
	
	if([self hideFiles]) {
		if([systemInfo efiHidden])		[installer showFiles];
		else							[installer hideFiles];
	} else if([systemInfo efiHidden])	[installer hideFiles];	// rehide files if previously hidden
	
	if([self fixBluetooth]) [installer fixBluetooth];
	[self updatePorgressBar: [NSNumber numberWithInt: 30]];
	
	[self updateStatus:NSLocalizedString(@"Done", nil)];
	
	[installer unmountRamDisk];
	
	[self performSelectorOnMainThread:@selector(installFinished) withObject: nil waitUntilDone:NO];
	
	
	
	
	
	[installer release];
	[pool release];
	
	return YES;
}


@end
