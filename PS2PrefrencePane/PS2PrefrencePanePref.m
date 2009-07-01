//
//  PS2PrefrencePanePref.m
//  PS2PrefrencePane
//
//  Created by Evan Lojewski on 3/26/09.
//  Copyright (c) 2009 UCCS. All rights reserved.
//

#import "PS2PrefrencePanePref.h"
#include <IOKit/IOKitLib.h>


@implementation PS2PrefrencePanePref


//- (void) mainViewDidLoad  For some reason, the checkboxes have not loaded yet, changed to awakeFromNib
- (void) awakeFromNib
{
	NSDictionary *dict;	
	dict = (NSDictionary*)CFPreferencesCopyMultiple(NULL ,CFSTR(APP_ID), kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
	
	
	// There probably is an easier way to do this, but oh well (for now)

    if ([dict objectForKey:@kTPEdgeScrolling])
			[_edgescrollChecbox setState:[(NSNumber*)[dict objectForKey:@kTPEdgeScrolling]  boolValue]];
	else	[_edgescrollChecbox setState:NSOffState];
		
	if ([dict objectForKey:@kTPHorizScroll])
			[_horizontalScrolling setState:[(NSNumber*)[dict objectForKey:@kTPHorizScroll]  boolValue]];
	else	[_horizontalScrolling setState:NSOffState];
	
	if ([dict objectForKey:@kTPTapToClick])
			[_tapToClickCheckbox setState:[(NSNumber*)[dict objectForKey:@kTPTapToClick]  boolValue]];
	else	[_tapToClickCheckbox setState:NSOffState];
	
	if ([dict objectForKey:@kTPDraggin])
			[_draggingCheckbox setState:[(NSNumber*)[dict objectForKey:@kTPDraggin]  boolValue]];
	else	[_draggingCheckbox setState:NSOffState];
	
	if ([dict objectForKey:@kTPDragLock])
			[_dragLockCheckbox setState:[(NSNumber*)[dict objectForKey:@kTPDragLock]  boolValue]];
	else	[_dragLockCheckbox setState:NSOffState];

	if ([dict objectForKey:@kTPScrollArea])
			[_scrollAreaSlider setFloatValue:[(NSNumber*)[dict objectForKey:@kTPScrollArea] floatValue]];
	else	[_scrollAreaSlider setFloatValue:3];

	if ([dict objectForKey:@kTPScrollSpeed])
			[_scrollSpeedSlider setFloatValue:[(NSNumber*)[dict objectForKey:@kTPScrollSpeed] floatValue]];
	else	[_scrollSpeedSlider setFloatValue:3];
	
	if ([dict objectForKey:@kTPTrackSpeed])
			[_trackingSpeedSlider setFloatValue:[(NSNumber*)[dict objectForKey:@kTPTrackSpeed] floatValue]];
	else	[_trackingSpeedSlider setFloatValue:3];
	
	if ([dict objectForKey:@kTPSensitivity])
			[_trackpadSensitivitySlider setFloatValue:[(NSNumber*)[dict objectForKey:@kTPSensitivity] floatValue]];
	else	[_trackpadSensitivitySlider setFloatValue:3];
	
	if ([dict objectForKey:@kTPAccelRate])
			[_accelerationRateSlider setFloatValue:[(NSNumber*)[dict objectForKey:@kTPAccelRate] floatValue]];
	else	[_accelerationRateSlider setFloatValue:3];
}

- (bool) setPrefrences
{
	CFMutableDictionaryRef	dictRef;
	io_iterator_t			iter;
    io_service_t			service;
    kern_return_t			kr;
	
    
    // The bulk of this code locates all instances of our driver running on the system.
	
	// First find all children of our driver. As opposed to nubs, drivers are often not registered
	// via the registerServices call because nothing is expected to match to them. Unregistered
	// objects in the I/O Registry are not returned by IOServiceGetMatchingServices.
	
	// ApplePS2MouseDevice is our parent in the I/O Registry
	dictRef = IOServiceMatching("ApplePS2MouseDevice"); 
    if (!dictRef) {
		NSLog(@"IOServiceMatching returned NULL.\n");
        return false;
    } 

    
    // Create an iterator over all matching IOService nubs.
    // This consumes a reference on dictRef.
    kr = IOServiceGetMatchingServices(kIOMasterPortDefault, dictRef, &iter);
    if (KERN_SUCCESS != kr) {
		NSLog(@"IOServiceGetMatchingServices returned 0x%08x.\n", kr);
        return false;
    }
	
    // Create a dictionary to pass to our driver. This dictionary has the key "MyProperty"
	// and the value an integer 1. 
	
	
	
    dictRef = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, 
                                        &kCFTypeDictionaryKeyCallBacks,
                                        &kCFTypeDictionaryValueCallBacks);
	
    [(NSMutableDictionary*) dictRef setValue:[[NSNumber alloc] initWithBool:[_edgescrollChecbox state]]						forKey:[[NSString alloc] initWithCString:kTPEdgeScrolling]];
    [(NSMutableDictionary*) dictRef setValue:[[NSNumber alloc] initWithBool:[_horizontalScrolling state]]					forKey:[[NSString alloc] initWithCString:kTPHorizScroll]];
    [(NSMutableDictionary*) dictRef setValue:[[NSNumber alloc] initWithBool:[_tapToClickCheckbox state]]					forKey:[[NSString alloc] initWithCString:kTPTapToClick]];
    [(NSMutableDictionary*) dictRef setValue:[[NSNumber alloc] initWithBool:[_draggingCheckbox state]]						forKey:[[NSString alloc] initWithCString:kTPDraggin]];
    [(NSMutableDictionary*) dictRef setValue:[[NSNumber alloc] initWithBool:[_dragLockCheckbox state]]						forKey:[[NSString alloc] initWithCString:kTPDragLock]];
	[(NSMutableDictionary*) dictRef setValue:[[NSNumber alloc] initWithDouble:([_trackpadSensitivitySlider doubleValue])]	forKey:[[NSString alloc] initWithCString:kTPSensitivity]];
	[(NSMutableDictionary*) dictRef setValue:[[NSNumber alloc] initWithDouble:([_scrollAreaSlider doubleValue])]			forKey:[[NSString alloc] initWithCString:kTPScrollArea]];
	[(NSMutableDictionary*) dictRef setValue:[[NSNumber alloc] initWithDouble:([_scrollSpeedSlider doubleValue])]			forKey:[[NSString alloc] initWithCString:kTPScrollSpeed]];
	[(NSMutableDictionary*) dictRef setValue:[[NSNumber alloc] initWithDouble:([_trackingSpeedSlider doubleValue])]			forKey:[[NSString alloc] initWithCString:kTPTrackSpeed]];
	[(NSMutableDictionary*) dictRef setValue:[[NSNumber alloc] initWithDouble:([_scrollAreaSlider doubleValue])]			forKey:[[NSString alloc] initWithCString:kTPAccelRate]];

	
	// Store the prefrences so that they are available on reboot
	CFPreferencesSetMultiple(dictRef, NULL, CFSTR(APP_ID), kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
	if(!CFPreferencesSynchronize(CFSTR(APP_ID), kCFPreferencesCurrentUser, kCFPreferencesAnyHost)) 
		NSLog(@"%s: Failed to save preferences\n", APP_ID);

	// Following doesn thave an object to read from...
    //[(NSMutableDictionary*) dictRef setValue:[[NSNumber alloc] initWithDouble:([ doubleValue])] forKey:[[NSString alloc] initWithCString:kTPTrackSpeed]];
    //[(NSMutableDictionary*) dictRef setValue:[[NSNumber alloc] initWithDouble:([ doubleValue])] forKey:[[NSString alloc] initWithCString:kTPAccelRate]];

	
    // Iterate across all instances of IOBlockStorageServices.
	while ((service = IOIteratorNext(iter))) {
		//NSLog([[NSString alloc] initWithCString:"Iterating...\n" encoding:NSASCIIStringEncoding]);

        io_registry_entry_t child;
        
        // Now that our parent has been found we can traverse the I/O Registry to find our driver.
		kr = IORegistryEntryGetChildEntry(service, kIOServicePlane, &child);
        if (KERN_SUCCESS != kr) {
			NSLog(@"IORegistryEntryGetParentEntry returned 0x%08x.\n", kr);
        } else {
            // We're only interested in the parent object if it's our driver class.
			if (IOObjectConformsTo(child, "ApplePS2SynapticsTouchPad")) {
                // This is the function that results in ::setProperties() being called in our
                // kernel driver. The dictionary we created is passed to the driver here.
				
				
                kr = IORegistryEntrySetCFProperties(child, dictRef);
				//NSLog([[NSString alloc] initWithCString:"Sent message to kext" encoding:NSASCIIStringEncoding]);
                if (KERN_SUCCESS != kr) {
					NSLog(@"IORegistryEntrySetCFProperties returned an error.\n", kr);
                }
            } else {
				NSLog(@"%s: Unable to locate Touchpad kext.\n", APP_ID);
//				IOObjectRelease(parent);
//				IOObjectRelease(service);

//				return false
			}
            
            // Done with the parent object.
			IOObjectRelease(child);
        }
        
        // Done with the object returned by the iterator.
		IOObjectRelease(service);
    }
	
    if (iter != IO_OBJECT_NULL) {
        IOObjectRelease(iter);
        iter = IO_OBJECT_NULL;
    }
	
    if (dictRef) {
        CFRelease(dictRef);
        dictRef = NULL;
    } 

	return true;
}

- (IBAction) setTapToClick: (id) sender
{
	//_tapToClick = tapToClick;
	if([sender state] == NSOnState) {
		[_draggingCheckbox setEnabled:true];
		[_dragLockCheckbox setEnabled:true];

	} else {
		[_draggingCheckbox setEnabled:false];
		[_dragLockCheckbox setEnabled:false];
	}
	[self setPrefrences];
} //(bool) tapToClick;

- (IBAction) setDragable: (id) sender
{
	if([sender state] == NSOnState) {
		[_dragLockCheckbox setEnabled:true];
	} else {
		[_dragLockCheckbox setEnabled:false];
	}
	[self setPrefrences];

}

- (IBAction) setDragLock: (id) sender
{
	[self setPrefrences];

}

- (IBAction) setSrolling: (id) sender
{
	if([sender state] == NSOnState) {
		[_horizontalScrolling setEnabled:true];
		[_scrollSpeedSlider setEnabled:true];
		[_scrollAreaSlider setEnabled:true];
		[_tapToClickCheckbox setState:false];

	} else {
		[_horizontalScrolling setEnabled:false];
		[_scrollSpeedSlider setEnabled:false];
		[_scrollAreaSlider setEnabled:false];
	}
	[self setPrefrences];

}

- (IBAction) setHorizScrolling: (id) sender
{
	[self setPrefrences];
}

- (IBAction) setTrackpadSpeed: (id) sender
{
	[self setPrefrences];

}

- (IBAction) setScrollSpeed: (id) sender
{
	[self setPrefrences];

}

- (IBAction) setScrollArea: (id) sender
{
	[self setPrefrences];
	
}

- (IBAction) setSensitivity: (id) sender
{
	[self setPrefrences];
	
}

- (IBAction) setAcceleration: (id) sender
{
	[self setPrefrences];

}

- (void)dealloc
{
	// TODO: add the rest of em
	[_horizontalScrolling release];
	[_scrollSpeedSlider release];
	[_scrollAreaSlider release];
	[_tapToClickCheckbox release];
	[_draggingCheckbox release];
	[_dragLockCheckbox release];
	[_horizontalScrolling release];
	[super dealloc];
}


@end
