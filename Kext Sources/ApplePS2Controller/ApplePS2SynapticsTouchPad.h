/*
 * Copyright (c) 2002 Apple Computer, Inc. All rights reserved.
 *
 * @APPLE_LICENSE_HEADER_START@
 * 
 * The contents of this file constitute Original Code as defined in and
 * are subject to the Apple Public Source License Version 1.2 (the
 * "License").  You may not use this file except in compliance with the
 * License.  Please obtain a copy of the License at
 * http://www.apple.com/publicsource and read it before using this file.
 * 
 * This Original Code and all software distributed under the License are
 * distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, EITHER
 * EXPRESS OR IMPLIED, AND APPLE HEREBY DISCLAIMS ALL SUCH WARRANTIES,
 * INCLUDING WITHOUT LIMITATION, ANY WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE OR NON-INFRINGEMENT.  Please see the
 * License for the specific language governing rights and limitations
 * under the License.
 * 
 * @APPLE_LICENSE_HEADER_END@
 */

#ifndef _APPLEPS2SYNAPTICSTOUCHPAD_H
#define _APPLEPS2SYNAPTICSTOUCHPAD_H

#include "ApplePS2MouseDevice.h"
#include <IOKit/hidsystem/IOHIPointing.h>

//  a better way might be to make a sub class that alllows access to teh variables
#define private public					
#define protected public

#include <IOKit/hidsystem/IOHIKeyboard.h>
#include "IOHIDFamily/IOHIDFamily/IOHIDEvent.h"
#include "IOHIDFamily/IOHIDFamily/IOHIDEventData.h"



#undef private
#undef protected

#include "IOHIDFamily/IOHIDSystem/IOKit/hidsystem/IOHIDSystem.h"


// 10 to 500ms = a tap
// MIN isn't really used since 12500 is the time between packets (aprox, according to spec)
#define TAP_LENGTH_MIN			10000

#define TAPPING					(((_streamdt < _prefClickDelay)  && (_streamdt > TAP_LENGTH_MIN)) && (ABS(_streamdx) <= 50) && (ABS(_streamdy) <= 50))
#define LEFT_CLICK				0x01;
#define RIGHT_CLICK				0x02;


#define RELATIVE_PACKET_SIZE	3
#define ABSOLUTE_PACKET_SIZE	6

// These values are coppied from the spec sheet, however they can change per device
#define ABSOLUTE_X_MIN			1632
#define ABSOLUTE_X_MAX			5312
#define ABSOLUTE_Y_MIN			1568
#define ABSOLUTE_Y_MAX			4288

// _touchPadModeByte bitmap
#define ABSOLUTE_MODE_BIT			0x80
#define RATE_MODE_BIT				0x40
// bit 5 undefined					0x20
// bit 4 undefined					0x10
#define SLEEP_MODE_BIT				0x08
#define GESTURES_MODE_BIT			0x04
//	#define PACKET_SIZE				0x02		// Only used for serial touchpads, not ps2
#define W_MODE_BIT					0x01

// The following is for reading _touchPadModeByte bitmap
#define ABSOLUTE_MODE			((_touchPadModeByte & ABSOLUTE_MODE_BIT) >> 7)
#define RELATIVE_MODE		    !(ABSOLUTE_MODE)
#define RATE_80_PPS				((_touchPadModeByte & RATE_MODE_BIT) >> 6)
#define SLEEPING				((_touchPadModeByte & SLEEP_MODE_BIT) >> 3)
#define GESTURES				((_touchPadModeByte & GESTURES_MODE_BIT) >> 2)
#define W_MODE					(_touchPadModeByte & W_MODE_BIT)

// Read the _capabilties (16 bit number) (These are ONLY true if W_MODE is also true)
#define CAP_PALM_DETECT				(_capabilties & 0x0001)
#define CAP_MULTIFINGER				(_capabilties & 0x0002)
#define CAP_BALLISTICS				(_capabilties & 0x0004)
#define CAP_FOUR_BUTTONS			(_capabilties & 0x0008)
#define CAP_SLEEP					(_capabilties & 0x0010)
// #define CAP_RESERVER_CAP1		(_capabilties & 0x0020)
// #define CAP_RESERVER_CAP2		(_capabilties & 0x0040)
// #define CAP_RESERVER_CAP3		(_capabilties & 0x0080)

// #define CAP_RESERVER_CAP11		(_capabilties & 0x0100)
// #define CAP_RESERVER_CAP12		(_capabilties & 0x0200)

#define CAP_MIDDLE_BUTTON			(_capabilties & 0x0400)
// #define CAP_RESERVER_CAP14		(_capabilties & 0x0800) 
#define CAP_N_EXTENDED_QUERY	   ((_capabilties & 0x7000) >> 12)
#define CAP_W_MODE					(_capabilties & 0x8000)

// EXTended Model ID query information, supported if nQueriesExtended > 1
#define EXT_LIGHT_CONTROL			(_extendedCapabilitied & 0x400000) 
#define EXT_PEAK_DETECT				(_extendedCapabilitied & 0x200000) 
#define EXT_GLASS_PASS				(_extendedCapabilitied & 0x100000)
#define EXT_VERTICAL_WHEEL			(_extendedCapabilitied & 0x080000)
#define EXT_W_MODE					(_extendedCapabilitied & 0x040000)
#define EXT_HORIZONTAL_SCROLL		(_extendedCapabilitied & 0x020000)
#define EXT_VERTICAL_SCROLL			(_extendedCapabilitied & 0x010000)
#define EXT_N_BUTTONS			   ((_extendedCapabilitied & 0x00F000) >> 12)
#define EXT_INFO_SENSOR			   ((_extendedCapabilitied & 0x000C00) >> 10)
#define EXT_PROD_ID					(_extendedCapabilitied & 0x0000FF)





// The folowing are available W Modes values
// Rquires CAP_MULTIFINGER (values 0 to 1)
#define W_TWOFINGERS				0
#define W_THREEPLUS					1
// Requires INFO_PEN (values 2)
#define W_PEN						2
// Unused, should never be set
#define W_RESERVED					3
// Requires CAP_PALM_DETECT (values 4 to 15)
#define W_FINGER_MIN				4
#define W_FINGER_MAX				7
#define W_FAT_FINGER_MIN			8
#define W_FAT_FINGER_MAX			14
#define W_MAX_CONTACT				15

// The flowing are available Z values (if we want to use them, W should be sufficient)
#define Z_NO_FINGER					0
#define Z_FINGER_NEAR				10
#define Z_LIGHT_FINGER				30
#define Z_NORMAL_FINGER				80
#define Z_HEAVY_FINGER				110
#define Z_FULL_FINGER				200
#define Z_MAX						255


// ModelID (info about hardware)
#define INFO_SENSOR					((_modelId & 0x3F0000) >> 16)
#define INFO_180					((_modelId & 0x800000) >> 23)
#define INFO_PORTRAIT				((_modelId & 0x400000) >> 22)
#define INFO_HARDWARE				((_modelId & 0x00FE00) >> 9)
#define INFO_NEWABS					((_modelId & 0x000080) >> 7)
#define INFO_SIMPLECMD				((_modelId & 0x000010) >> 5)
#define INTO_PEN					((_modelId & 0x000020) >> 6)

// Boundaries for sidescrolling (curently undefined
//#define HORIZ_SCROLLING_BOUNDARY
//#define VERT_SCROLLING_BOUNDARY


// Possible touchpad events
#define DEFAULT_EVENT				0
#define DRAGGING				1 << 0
#define SCROLLING				1 << 1
#define HORIZONTAL_SCROLLING	1 << 2
#define VERTICAL_SCROLLING		1 << 3
#define ZOOMING					1 << 4			// Pinch in / out
#define MOVEMENT				1 << 5
#define SWIPE					1 << 6			// Three finger swipe;



// kST_** = Synaptics Commands (Information queries)
#define kST_IdentifyTouchpad		0x00
#define kST_getTouchpadModeByte		0x01
#define kST_getCapabilities			0x02
#define kST_getModelID				0x03
#define kST_unknown1				0x04
#define kST_unknown2				0x05
#define kST_getSerialNumberPrefix	0x06
#define kST_getSerialNumberSuffix	0x07
#define kST_getResolution			0x08
#define kST_getExtendedModelID		0x09




static char *model_names [] = {	// 16 models currenlty in this list
	"Unknown",
	"Standard TouchPad (TM41xx134)",
	"Mini Module (TM41xx156)",
	"Super Module (TM41xx180)",	
	"Romulan Module",					// Specification does not list (reserved)
	"Apple Module",						// Specification does not list (reserved)
	"Single Chip",						// Specification does not list (reserved)
	"Flexible pad (discontinued)",
	"Ultra-thin Module (TM41xx220)",
	"Wide pad Module (TW41xx230)",
	"Twin Pad module",					// Specification does not list (reserved)
	"Stamp Pad Module (TM41xx240)",
	"SubMini Module (TM41xx140)",
	"MultiSwitch module (TBD)",
	"Standard Thin",					// Specification does not list (reserved)
	"Advanced Technology Pad (TM41xx301)",
	"Ultra-thin Module, connector reversed (TM41xx221)"
};


// Sensor reslutions (yes, I COULD use a struct, but I dont feal like it
#define UNKNOWN_RESOLUTION_X	85
#define UNKNOWN_RESOLUTION_Y	94	

#define UNKNOWN_DIMENSIONS_X	47.1
#define UNKNOWN_DIMENSIONS_Y	32.3


// Resolutions of the sensor (in X x Y) to convert to dpi multiply by 25.4
static UInt32 model_resolution [][2] = {
	{UNKNOWN_RESOLUTION_X, UNKNOWN_RESOLUTION_Y},
	{85, 94},
	{91, 124},
	{57, 58},
	{UNKNOWN_RESOLUTION_X, UNKNOWN_RESOLUTION_Y},
	{UNKNOWN_RESOLUTION_X, UNKNOWN_RESOLUTION_Y},
	{UNKNOWN_RESOLUTION_X, UNKNOWN_RESOLUTION_Y},
	{UNKNOWN_RESOLUTION_X, UNKNOWN_RESOLUTION_Y},
	{85, 94},
	{73, 96},
	{UNKNOWN_RESOLUTION_X, UNKNOWN_RESOLUTION_Y},
	{187, 170},
	{122, 167},
	{UNKNOWN_RESOLUTION_X, UNKNOWN_RESOLUTION_Y},
	{UNKNOWN_RESOLUTION_X, UNKNOWN_RESOLUTION_Y},
	{UNKNOWN_RESOLUTION_X, UNKNOWN_RESOLUTION_Y},
	{UNKNOWN_RESOLUTION_X, UNKNOWN_RESOLUTION_Y}
};

static float model_dimensions [][2] = {
	{UNKNOWN_DIMENSIONS_X, UNKNOWN_DIMENSIONS_Y},
	{47.1, 32.3},
	{44.0, 24.5},
	{70.2, 52.4},
	{UNKNOWN_DIMENSIONS_X, UNKNOWN_DIMENSIONS_Y},
	{UNKNOWN_DIMENSIONS_X, UNKNOWN_DIMENSIONS_Y},
	{UNKNOWN_DIMENSIONS_X, UNKNOWN_DIMENSIONS_Y},
	{UNKNOWN_DIMENSIONS_X, UNKNOWN_DIMENSIONS_Y},
	{47.1, 32.3},
	{54.8, 31.7},
	{UNKNOWN_DIMENSIONS_X, UNKNOWN_DIMENSIONS_Y},
	{21.4, 17.9},
	{32.8, 18.2},
	{UNKNOWN_DIMENSIONS_X, UNKNOWN_DIMENSIONS_Y},
	{UNKNOWN_DIMENSIONS_X, UNKNOWN_DIMENSIONS_Y},
	{UNKNOWN_DIMENSIONS_X, UNKNOWN_DIMENSIONS_Y},
	{UNKNOWN_DIMENSIONS_X, UNKNOWN_DIMENSIONS_Y},
};

#define	kTPScrollMode				"kTPScrollMode"
#define kTPScrollArea				"kTPScrollArea"
#define kTPGestureMode				"kTPGestureMode"
#define kTPHorizScroll				"kTPHorizScroll"
#define kTPScrollSpeed				"kTPScrollSpeed"

#define	kTPOneFingerThreshold		"kTPOneFingerThreshold"
#define	kTPTwoFingerThreshold		"kTPTwoFingerThreshold"
#define	kTPThreeFingerThreshold		"kTPThreeFingerThreshold"


#define kTPTrackSpeed				"kTPTrackSpeed"
#define kTPAccelRate				"kTPAccelRate"
#define kTPTapToClick				"kTPTapToClick"
#define kTPDraggin					"kTPDraggin"
#define kTPDragLock					"kTPDragLock"
#define kTPSecondaryClick			"kTPSecondaryClick"
#define kTPSwapButtons				"kTPSwapButtons"


#define kTPClickDelay				"kTPClickDelay"
#define kTPReleaseDelay				"kTPReleaseDelay"

#define kKBSwapKeys					"kKBSwapKeys"
#define kKBKeyScroll				"kKBKeyScroll"

#define SCROLL_MODE_NONE			0
#define SCROLL_MODE_TWO_FINGER		1
#define SCROLL_MODE_EDGE			2

#define GESTURE_MODE_NONE			0
#define GESTURE_MODE_SCROLL			1
#define GESTURE_MODE_ENABLED		2


#define ACCELERATION_TABLE_SIZE	1867
static int accelerationTable[1867] = 
{
0, 	0, 	1, 	1, 	1, 	2, 	2, 	3, 	3, 	3, 	4, 	4, 	4, 	5, 	5, 	6, 	6, 	6, 	7, 	7, 
7, 	8, 	8, 	9, 	9, 	9, 	10, 	10, 	10, 	11, 	11, 	11, 	12, 	12, 	13, 	13, 	13, 	14, 	14, 	14, 
15, 	15, 	16, 	16, 	16, 	17, 	17, 	17, 	18, 	18, 	19, 	19, 	19, 	20, 	20, 	20, 	21, 	21, 	22, 	22, 
22, 	23, 	23, 	23, 	24, 	24, 	25, 	25, 	25, 	26, 	26, 	26, 	27, 	27, 	28, 	28, 	28, 	29, 	29, 	30, 
30, 	30, 	31, 	31, 	31, 	32, 	32, 	33, 	33, 	33, 	34, 	34, 	34, 	35, 	35, 	36, 	36, 	36, 	37, 	37, 
38, 	38, 	38, 	39, 	39, 	39, 	40, 	40, 	41, 	41, 	41, 	42, 	42, 	42, 	43, 	43, 	44, 	44, 	44, 	45, 
45, 	46, 	46, 	46, 	47, 	47, 	48, 	48, 	48, 	49, 	49, 	49, 	50, 	50, 	51, 	51, 	51, 	52, 	52, 	53, 
53, 	53, 	54, 	54, 	55, 	55, 	55, 	56, 	56, 	57, 	57, 	57, 	58, 	58, 	59, 	59, 	59, 	60, 	60, 	60, 
61, 	61, 	62, 	62, 	62, 	63, 	63, 	64, 	64, 	64, 	65, 	65, 	66, 	66, 	66, 	67, 	67, 	68, 	68, 	69, 
69, 	69, 	70, 	70, 	71, 	71, 	71, 	72, 	72, 	73, 	73, 	73, 	74, 	74, 	75, 	75, 	75, 	76, 	76, 	77, 
77, 	78, 	78, 	78, 	79, 	79, 	80, 	80, 	80, 	81, 	81, 	82, 	82, 	83, 	83, 	83, 	84, 	84, 	85, 	85, 
85, 	86, 	86, 	87, 	87, 	88, 	88, 	88, 	89, 	89, 	90, 	90, 	91, 	91, 	91, 	92, 	92, 	93, 	93, 	94, 
94, 	95, 	95, 	95, 	96, 	96, 	97, 	97, 	98, 	98, 	98, 	99, 	99, 	100, 	100, 	101, 	101, 	102, 	102, 	102, 
103, 	103, 	104, 	104, 	105, 	105, 	106, 	106, 	107, 	107, 	107, 	108, 	108, 	109, 	109, 	110, 	110, 	111, 	111, 	112, 
112, 	112, 	113, 	113, 	114, 	114, 	115, 	115, 	116, 	116, 	117, 	117, 	118, 	118, 	119, 	119, 	120, 	120, 	121, 	121, 
121, 	122, 	122, 	123, 	123, 	124, 	124, 	125, 	125, 	126, 	126, 	127, 	127, 	128, 	128, 	129, 	129, 	130, 	130, 	131, 
131, 	132, 	132, 	133, 	133, 	134, 	134, 	135, 	135, 	136, 	136, 	137, 	137, 	138, 	138, 	139, 	140, 	140, 	141, 	141, 
142, 	142, 	143, 	143, 	144, 	144, 	145, 	145, 	146, 	146, 	147, 	148, 	148, 	149, 	149, 	150, 	150, 	151, 	151, 	152, 
152, 	153, 	154, 	154, 	155, 	155, 	156, 	156, 	157, 	157, 	158, 	159, 	159, 	160, 	160, 	161, 	161, 	162, 	163, 	163, 
164, 	164, 	165, 	166, 	166, 	167, 	167, 	168, 	169, 	169, 	170, 	170, 	171, 	172, 	172, 	173, 	173, 	174, 	175, 	175, 
176, 	176, 	177, 	178, 	178, 	179, 	180, 	180, 	181, 	181, 	182, 	183, 	183, 	184, 	185, 	185, 	186, 	187, 	187, 	188, 
189, 	189, 	190, 	190, 	191, 	192, 	192, 	193, 	194, 	195, 	195, 	196, 	197, 	197, 	198, 	199, 	199, 	200, 	201, 	201, 
202, 	203, 	203, 	204, 	205, 	206, 	206, 	207, 	208, 	208, 	209, 	210, 	211, 	211, 	212, 	213, 	213, 	214, 	215, 	216, 
216, 	217, 	218, 	219, 	219, 	220, 	221, 	222, 	222, 	223, 	224, 	225, 	226, 	226, 	227, 	228, 	229, 	229, 	230, 	231, 
232, 	233, 	233, 	234, 	235, 	236, 	237, 	237, 	238, 	239, 	240, 	241, 	242, 	242, 	243, 	244, 	245, 	246, 	247, 	247, 
248, 	249, 	250, 	251, 	252, 	252, 	253, 	254, 	255, 	256, 	257, 	258, 	259, 	259, 	260, 	261, 	262, 	263, 	264, 	265, 
266, 	267, 	268, 	268, 	269, 	270, 	271, 	272, 	273, 	274, 	275, 	276, 	277, 	278, 	279, 	280, 	281, 	281, 	282, 	283, 
284, 	285, 	286, 	287, 	288, 	289, 	290, 	291, 	292, 	293, 	294, 	295, 	296, 	297, 	298, 	299, 	300, 	301, 	302, 	303, 
304, 	305, 	306, 	307, 	308, 	309, 	310, 	311, 	313, 	314, 	315, 	316, 	317, 	318, 	319, 	320, 	321, 	322, 	323, 	324, 
325, 	326, 	328, 	329, 	330, 	331, 	332, 	333, 	334, 	335, 	336, 	337, 	339, 	340, 	341, 	342, 	343, 	344, 	345, 	347, 
348, 	349, 	350, 	351, 	352, 	354, 	355, 	356, 	357, 	358, 	359, 	361, 	362, 	363, 	364, 	365, 	367, 	368, 	369, 	370, 
371, 	373, 	374, 	375, 	376, 	377, 	379, 	380, 	381, 	382, 	384, 	385, 	386, 	387, 	389, 	390, 	391, 	392, 	394, 	395, 
396, 	397, 	399, 	400, 	401, 	403, 	404, 	405, 	406, 	408, 	409, 	410, 	412, 	413, 	414, 	416, 	417, 	418, 	420, 	421, 
422, 	423, 	425, 	426, 	427, 	429, 	430, 	432, 	433, 	434, 	436, 	437, 	438, 	440, 	441, 	442, 	444, 	445, 	446, 	448, 
449, 	451, 	452, 	453, 	455, 	456, 	458, 	459, 	460, 	462, 	463, 	465, 	466, 	467, 	469, 	470, 	472, 	473, 	474, 	476, 
477, 	479, 	480, 	482, 	483, 	484, 	486, 	487, 	489, 	490, 	492, 	493, 	495, 	496, 	497, 	499, 	500, 	502, 	503, 	505, 
506, 	508, 	509, 	511, 	512, 	513, 	515, 	516, 	518, 	519, 	521, 	522, 	524, 	525, 	527, 	528, 	530, 	531, 	533, 	534, 
536, 	537, 	539, 	540, 	542, 	543, 	545, 	546, 	548, 	549, 	551, 	552, 	554, 	555, 	557, 	558, 	560, 	561, 	563, 	564, 
566, 	567, 	569, 	570, 	572, 	574, 	575, 	577, 	578, 	580, 	581, 	583, 	584, 	586, 	587, 	589, 	590, 	592, 	593, 	595, 
596, 	598, 	600, 	601, 	603, 	604, 	606, 	607, 	609, 	610, 	612, 	613, 	615, 	616, 	618, 	620, 	621, 	623, 	624, 	626, 
627, 	629, 	630, 	632, 	633, 	635, 	637, 	638, 	640, 	641, 	643, 	644, 	646, 	647, 	649, 	650, 	652, 	654, 	655, 	657, 
658, 	660, 	661, 	663, 	664, 	666, 	668, 	669, 	671, 	672, 	674, 	675, 	677, 	678, 	680, 	681, 	683, 	684, 	686, 	688, 
689, 	691, 	692, 	694, 	695, 	697, 	698, 	700, 	701, 	703, 	705, 	706, 	708, 	709, 	711, 	712, 	714, 	715, 	717, 	718, 
720, 	721, 	723, 	724, 	726, 	728, 	729, 	731, 	732, 	734, 	735, 	737, 	738, 	740, 	741, 	743, 	744, 	746, 	747, 	749, 
750, 	752, 	753, 	755, 	756, 	758, 	759, 	761, 	762, 	764, 	765, 	767, 	769, 	770, 	772, 	773, 	775, 	776, 	778, 	779, 
781, 	782, 	784, 	785, 	787, 	788, 	789, 	791, 	792, 	794, 	795, 	797, 	798, 	800, 	801, 	803, 	804, 	806, 	807, 	809, 
810, 	812, 	813, 	815, 	816, 	818, 	819, 	821, 	822, 	823, 	825, 	826, 	828, 	829, 	831, 	832, 	834, 	835, 	837, 	838, 
840, 	841, 	842, 	844, 	845, 	847, 	848, 	850, 	851, 	853, 	854, 	855, 	857, 	858, 	860, 	861, 	863, 	864, 	865, 	867, 
868, 	870, 	871, 	873, 	874, 	875, 	877, 	878, 	880, 	881, 	882, 	884, 	885, 	887, 	888, 	889, 	891, 	892, 	894, 	895, 
896, 	898, 	899, 	901, 	902, 	903, 	905, 	906, 	908, 	909, 	910, 	912, 	913, 	915, 	916, 	917, 	919, 	920, 	921, 	923, 
924, 	926, 	927, 	928, 	930, 	931, 	932, 	934, 	935, 	936, 	938, 	939, 	940, 	942, 	943, 	945, 	946, 	947, 	949, 	950, 
951, 	953, 	954, 	955, 	957, 	958, 	959, 	961, 	962, 	963, 	965, 	966, 	967, 	969, 	970, 	971, 	973, 	974, 	975, 	977, 
978, 	979, 	980, 	982, 	983, 	984, 	986, 	987, 	988, 	990, 	991, 	992, 	994, 	995, 	996, 	997, 	999, 	1000, 	1001, 	1003, 
1004, 	1005, 	1006, 	1008, 	1009, 	1010, 	1012, 	1013, 	1014, 	1015, 	1017, 	1018, 	1019, 	1021, 	1022, 	1023, 	1024, 	1026, 	1027, 	1028, 
1029, 	1031, 	1032, 	1033, 	1035, 	1036, 	1037, 	1038, 	1040, 	1041, 	1042, 	1043, 	1045, 	1046, 	1047, 	1048, 	1050, 	1051, 	1052, 	1053, 
1055, 	1056, 	1057, 	1058, 	1059, 	1061, 	1062, 	1063, 	1064, 	1066, 	1067, 	1068, 	1069, 	1071, 	1072, 	1073, 	1074, 	1075, 	1077, 	1078, 
1079, 	1080, 	1082, 	1083, 	1084, 	1085, 	1086, 	1088, 	1089, 	1090, 	1091, 	1093, 	1094, 	1095, 	1096, 	1097, 	1099, 	1100, 	1101, 	1102, 
1103, 	1105, 	1106, 	1107, 	1108, 	1109, 	1111, 	1112, 	1113, 	1114, 	1115, 	1116, 	1118, 	1119, 	1120, 	1121, 	1122, 	1124, 	1125, 	1126, 
1127, 	1128, 	1130, 	1131, 	1132, 	1133, 	1134, 	1135, 	1137, 	1138, 	1139, 	1140, 	1141, 	1142, 	1144, 	1145, 	1146, 	1147, 	1148, 	1149, 
1151, 	1152, 	1153, 	1154, 	1155, 	1156, 	1158, 	1159, 	1160, 	1161, 	1162, 	1163, 	1164, 	1166, 	1167, 	1168, 	1169, 	1170, 	1171, 	1173, 
1174, 	1175, 	1176, 	1177, 	1178, 	1179, 	1181, 	1182, 	1183, 	1184, 	1185, 	1186, 	1187, 	1189, 	1190, 	1191, 	1192, 	1193, 	1194, 	1195, 
1196, 	1198, 	1199, 	1200, 	1201, 	1202, 	1203, 	1204, 	1206, 	1207, 	1208, 	1209, 	1210, 	1211, 	1212, 	1213, 	1215, 	1216, 	1217, 	1218, 
1219, 	1220, 	1221, 	1222, 	1223, 	1225, 	1226, 	1227, 	1228, 	1229, 	1230, 	1231, 	1232, 	1234, 	1235, 	1236, 	1237, 	1238, 	1239, 	1240, 
1241, 	1242, 	1243, 	1245, 	1246, 	1247, 	1248, 	1249, 	1250, 	1251, 	1252, 	1253, 	1255, 	1256, 	1257, 	1258, 	1259, 	1260, 	1261, 	1262, 
1263, 	1264, 	1265, 	1267, 	1268, 	1269, 	1270, 	1271, 	1272, 	1273, 	1274, 	1275, 	1276, 	1278, 	1279, 	1280, 	1281, 	1282, 	1283, 	1284, 
1285, 	1286, 	1287, 	1288, 	1289, 	1291, 	1292, 	1293, 	1294, 	1295, 	1296, 	1297, 	1298, 	1299, 	1300, 	1301, 	1302, 	1304, 	1305, 	1306, 
1307, 	1308, 	1309, 	1310, 	1311, 	1312, 	1313, 	1314, 	1315, 	1316, 	1317, 	1319, 	1320, 	1321, 	1322, 	1323, 	1324, 	1325, 	1326, 	1327, 
1328, 	1329, 	1330, 	1331, 	1332, 	1334, 	1335, 	1336, 	1337, 	1338, 	1339, 	1340, 	1341, 	1342, 	1343, 	1344, 	1345, 	1346, 	1347, 	1348, 
1350, 	1351, 	1352, 	1353, 	1354, 	1355, 	1356, 	1357, 	1358, 	1359, 	1360, 	1361, 	1362, 	1363, 	1364, 	1365, 	1366, 	1367, 	1369, 	1370, 
1371, 	1372, 	1373, 	1374, 	1375, 	1376, 	1377, 	1378, 	1379, 	1380, 	1381, 	1382, 	1383, 	1384, 	1385, 	1386, 	1388, 	1389, 	1390, 	1391, 
1392, 	1393, 	1394, 	1395, 	1396, 	1397, 	1398, 	1399, 	1400, 	1401, 	1402, 	1403, 	1404, 	1405, 	1406, 	1407, 	1408, 	1409, 	1411, 	1412, 
1413, 	1414, 	1415, 	1416, 	1417, 	1418, 	1419, 	1420, 	1421, 	1422, 	1423, 	1424, 	1425, 	1426, 	1427, 	1428, 	1429, 	1430, 	1431, 	1432, 
1433, 	1434, 	1436, 	1437, 	1438, 	1439, 	1440, 	1441, 	1442, 	1443, 	1444, 	1445, 	1446, 	1447, 	1448, 	1449, 	1450, 	1451, 	1452, 	1453, 
1454, 	1455, 	1456, 	1457, 	1458, 	1459, 	1460, 	1461, 	1462, 	1463, 	1465, 	1466, 	1467, 	1468, 	1469, 	1470, 	1471, 	1472, 	1473, 	1474, 
1475, 	1476, 	1477, 	1478, 	1479, 	1480, 	1481, 	1482, 	1483, 	1484, 	1485, 	1486, 	1487, 	1488, 	1489, 	1490, 	1491, 	1492, 	1493, 	1494, 
1495, 	1496, 	1497, 	1498, 	1500, 	1501, 	1502, 	1503, 	1504, 	1505, 	1506, 	1507, 	1508, 	1509, 	1510, 	1511, 	1512, 	1513, 	1514, 	1515, 
1516, 	1517, 	1518, 	1519, 	1520, 	1521, 	1522, 	1523, 	1524, 	1525, 	1526, 	1527, 	1528, 	1529, 	1530, 	1531, 	1532, 	1533, 	1534, 	1535, 
1536, 	1537, 	1538, 	1539, 	1540, 	1541, 	1543, 	1544, 	1545, 	1546, 	1547, 	1548, 	1549, 	1550, 	1551, 	1552, 	1553, 	1554, 	1555, 	1556, 
1557, 	1558, 	1559, 	1560, 	1561, 	1562, 	1563, 	1564, 	1565, 	1566, 	1567, 	1568, 	1569, 	1570, 	1571, 	1572, 	1573, 	1574, 	1575, 	1576, 
1577, 	1578, 	1579, 	1580, 	1581, 	1582, 	1583, 	1584, 	1585, 	1586, 	1587, 	1588, 	1589, 	1590, 	1591, 	1592, 	1593, 	1594, 	1595, 	1596, 
1597, 	1598, 	1600, 	1601, 	1602, 	1603, 	1604, 	1605, 	1606, 	1607, 	1608, 	1609, 	1610, 	1611, 	1612, 	1613, 	1614, 	1615, 	1616, 	1617, 
1618, 	1619, 	1620, 	1621, 	1622, 	1623, 	1624, 	1625, 	1626, 	1627, 	1628, 	1629, 	1630, 	1631, 	1632, 	1633, 	1634, 	1635, 	1636, 	1637, 
1638, 	1639, 	1640, 	1641, 	1642, 	1643, 	1644, 	1645, 	1646, 	1647, 	1648, 	1649, 	1650, 	1651, 	1652, 	1653, 	1654, 	1655, 	1656, 	1657, 
1658, 	1659, 	1660, 	1661, 	1662, 	1663, 	1664, 	1665, 	1666, 	1667, 	1668, 	1669, 	1670, 	1671, 	1672, 	1673, 	1674, 	1675, 	1676, 	1677, 
1678, 	1679, 	1680, 	1681, 	1682, 	1683, 	1685, 	1686, 	1687, 	1688, 	1689, 	1690, 	1691, 	1692, 	1693, 	1694, 	1695, 	1696, 	1697, 	1698, 
1699, 	1700, 	1701, 	1702, 	1703, 	1704, 	1705, 	1706, 	1707, 	1708, 	1709, 	1710, 	1711, 	1712, 	1713, 	1714, 	1715, 	1716, 	1717, 	1718, 
1719, 	1720, 	1721, 	1722, 	1723, 	1724, 	1725, 	1726, 	1727, 	1728, 	1729, 	1730, 	1731, 	1732, 	1733, 	1734, 	1735, 	1736, 	1737, 	1738, 
1739, 	1740, 	1741, 	1742, 	1743, 	1744, 	1745, 	1746, 	1747, 	1748, 	1749, 	1750, 	1751, 	1752, 	1753, 	1754, 	1755, 	1756, 	1757, 	1758, 
1759, 	1760, 	1761, 	1762, 	1763, 	1764, 	1765, 	1766, 	1767, 	1768, 	1769, 	1770, 	1771, 	1772, 	1773, 	1774, 	1775, 	1776, 	1777, 	1778, 
1779, 	1780, 	1781, 	1782, 	1783, 	1784, 	1785, 	1786, 	1787, 	1788, 	1789, 	1790, 	1791, 	1792, 	1793, 	1794, 	1795, 	1796, 	1797, 	1798, 
1799, 	1800, 	1801, 	1802, 	1803, 	1804, 	1805, 	1806, 	1807, 	1808, 	1809, 	1810, 	1811, 	1812, 	1813, 	1814, 	1815, 	1816, 	1817, 	1818, 
1819, 	1820, 	1821, 	1822, 	1823, 	1824, 	1825, 	1826, 	1827, 	1828, 	1829, 	1830, 	1831, 	1832, 	1833, 	1834, 	1835, 	1836, 	1837, 	1838, 
1839, 	1840, 	1841, 	1842, 	1843, 	1844, 	1845, 	1846, 	1847, 	1848, 	1849, 	1850, 	1851, 	1852, 	1853, 	1854, 	1855, 	1856, 	1857, 	1858, 
1859, 	1860, 	1861, 	1862, 	1863, 	1864, 	1866, };




// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// ApplePS2SynapticsTouchPad Class Declaration
//

class ApplePS2SynapticsTouchPad : public IOHIPointing 
{
	OSDeclareDefaultStructors( ApplePS2SynapticsTouchPad );

private:
    ApplePS2MouseDevice * _device;
	IOHIKeyboard		* _keyboard;
	
	
    UInt32                _interruptHandlerInstalled:1;
    UInt32                _powerControlHandlerInstalled:1;
    UInt8                 _packetBuffer[ABSOLUTE_PACKET_SIZE];
    UInt8				  _packetByteCount;
	
    IOFixed               _resolution;
    UInt16                _touchPadVersion;
    UInt8                 _touchPadModeByte;
	UInt32				  _touchpadIntormation;
	UInt16				  _capabilties;
	UInt32				  _extendedCapabilitied;
	UInt32				  _modelId;
	UInt8				  _event;
	long long			  _serialNumber;
	double				  _scaleFactor;
	
	bool				  _tapped;
	bool				  _dragging;
	bool				  _dragLocked;
	SInt32				  _streamdx;
	SInt32				  _streamdy;
	
	IOTimerEventSource*	  _dragTimeout;
	
	UInt32				  _prevX;
	UInt32				  _prevY;
	UInt8				  _prevButtons;
	UInt8				  _prevNumFingers;
	
	uint32_t			  _prevPacketTime;
	uint32_t			  _prevPacketSecond;
	uint64_t			  _streamdt;
	uint32_t			  _settleTime;
	
	
	
	// Prefrences from the pref pane...
	UInt32				  _prefClickDelay;
	UInt32				  _prefReleaseDelay;
	UInt8				  _prefScrollMode;
	UInt8				  _prefGestureMode;
	double				  _prefHysteresis;
	bool				  _prefHorizScroll;
	bool				  _prefClicking;
	bool				  _prefDragging;
	bool				  _prefDragLock;
	bool				  _prefSecondaryClick;
	bool				  _prefSwapButtons;
	bool				  _prefIgnoreAccidental;

	double				  _prefOneFingerThreshold;
	double				  _prefTwoFingerThreshold;
	double				  _prefThreeFingerThreshold;

	double				  _prefScrollArea;
	double				  _prefScrollSpeed;
	double				  _prefTrackSpeed;

	// dispatchRelativePointerEvent reall is dispatch relative packet, while the absolute one is the absolute packet
	virtual void   dispatchRelativePointerEventWithRelativePacket( UInt8 * packet, UInt32  packetSize, AbsoluteTime now );
	virtual void   dispatchRelativePointerEventWithAbsolutePacket( UInt8 * packet, UInt32  packetSize, AbsoluteTime now );
	virtual void   dispatchSwipeEvent ( IOHIDSwipeMask swipeType, AbsoluteTime now);
									   
	virtual void   setCommandByte( UInt8 setBits, UInt8 clearBits );

	
	// Synaptic specific stuff... (added by meklort)
	virtual bool   setRelativeMode();
	virtual bool   setAbsoluteMode();
	virtual bool   setStreamMode( bool enable );

	virtual bool   getCapabilities();
	virtual bool   getExtendedCapabilities();
	virtual bool   getModelID();
	virtual bool   identifyTouchpad();
	virtual bool   getTouchpadModes();
	virtual bool   getSerialNumber();
	virtual bool   getResolutions();

	

	
    virtual void   setTouchPadEnable( bool enable );
    virtual UInt32 getTouchPadData( UInt8 dataSelector );
    virtual bool   setTouchPadModeByte( UInt8 modeByteValue,
                                        bool  enableStreamMode = false );

	virtual void   free();
	virtual void   interruptOccurred( UInt8 data );
    virtual void   setDevicePowerState(UInt32 whatToDo);

protected:
	virtual IOItemCount buttonCount();
	virtual IOFixed     resolution();
	virtual IOFixed		scrollResolution();


public:
    virtual bool init( OSDictionary * properties );
    virtual ApplePS2SynapticsTouchPad * probe( IOService * provider,
                                               SInt32 *    score );
    
    virtual bool start( IOService * provider );
    virtual void stop ( IOService * provider );
    
    virtual UInt32 deviceType();
    virtual UInt32 interfaceID();

	virtual IOReturn setParamProperties( OSDictionary * dict );
	
	virtual bool  draggingTimeout();


};

#endif /* _APPLEPS2SYNAPTICSTOUCHPAD_H */
