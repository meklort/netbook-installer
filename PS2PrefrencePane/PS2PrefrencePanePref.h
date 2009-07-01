//
//  PS2PrefrencePanePref.h
//  PS2PrefrencePane
//
//  Created by Evan Lojewski on 3/26/09.
//  Copyright (c) 2009 UCCS. All rights reserved.
//

#import <PreferencePanes/PreferencePanes.h>

#define APP_ID				"com.meklort.ps2.prefrences"

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

	

@interface PS2PrefrencePanePref : NSPreferencePane 
{
	IBOutlet NSSlider* _trackingSpeedSlider;
	IBOutlet NSSlider* _trackpadSensitivitySlider;
	IBOutlet NSSlider* _accelerationRateSlider;
	
	IBOutlet NSSlider* _scrollSpeedSlider;
	IBOutlet NSSlider* _scrollAreaSlider;

	
	IBOutlet NSButton* _tapToClickCheckbox;
	IBOutlet NSButton* _draggingCheckbox;
	IBOutlet NSButton* _dragLockCheckbox;
	
	IBOutlet NSButton* _edgescrollChecbox;
	IBOutlet NSButton* _horizontalScrolling;
	
	
	IBOutlet NSTextField* _scrollSpeedText;
	IBOutlet NSTextField* _scrollAreaText;
}

//- (id)initWithBundle:(NSBundle *)bundle;
//- (void) mainViewDidLoad;

- (void) awakeFromNib;



- (bool) setPrefrences;

- (IBAction) setTapToClick: (id) sender;
- (IBAction) setDragable: (id) sender;
- (IBAction) setDragLock: (id) sender;
- (IBAction) setSrolling: (id) sender;
- (IBAction) setHorizScrolling: (id) sender;
- (IBAction) setTrackpadSpeed: (id) sender;
- (IBAction) setScrollSpeed: (id) sender;
- (IBAction) setScrollArea: (id) sender;
- (IBAction) setSensitivity: (id) sender;
- (IBAction) setAcceleration: (id) sender;


@end
