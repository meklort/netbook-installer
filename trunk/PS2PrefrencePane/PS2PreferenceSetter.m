#import <Foundation/Foundation.h>
#include <IOKit/IOKitLib.h>


#define APP_ID				"com.meklort.ps2.preferences"

#define	kTPEdgeScrolling 	"kTPEdgeScrolling"
#define kTPScrollArea 		"kTPScrollArea"
#define kTPHorizScroll		"kTPHorizScroll"
#define kTPScrollSpeed		"kTPScrollSpeed"
#define kTPTrackSpeed 		"kTPTrackSpeed"
#define	kTPSensitivity		"kTPSensitivity"
#define kTPAccelRate 		"kTPAccelRate"
#define kTPTapToClick 		"kTPTapToClick"
#define kTPDraggin			"kTPDraggin"
#define kTPDragLock 		"kTPDragLock"

#define kKBSwapKeys 		"kKBSwapKeys"
#define kKeyScroll			"kKBKeyScroll"




int main (int argc, const char * argv[]) {
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	io_iterator_t			iter;
    io_service_t			service;
    kern_return_t			kr;
	CFDictionaryRef	dictRef;
		
		
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
	
		
	dictRef = CFPreferencesCopyMultiple(NULL ,CFSTR(APP_ID), kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
	
	
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
		
	[pool drain];
	return 0;
}
