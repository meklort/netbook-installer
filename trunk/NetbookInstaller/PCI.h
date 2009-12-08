//
//  PCI.h
//  NetbookInstaller
//
//  Created by Evan Lojewski on 11/7/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <IOKit/IOKitLib.h>

#define PCI_CLASS_UNDEFINED			0x00
#define PCI_CLASS_MASS_STORAGE		0x01
#define PCI_CLASS_NETWORK			0x02
#define PCI_CLASS_DISPLAY			0x03
#define PCI_CLASS_MULTIMEDIA		0x04
#define PCI_CLASS_MEMORY			0x05
#define PCI_CLASS_BRIDGE			0x06
#define PCI_CLASS_COMM				0x07
#define PCI_CLASS_GENERIC			0x08
#define PCI_CLASS_INPUT				0x09
#define PCI_CLASS_DOCK				0x0A
#define PCI_CLASS_PROCESSOR			0x0B
#define PCI_CLASS_SERIAL			0x0C
#define PCI_CLASS_WIRELESS			0x0D
#define PCI_CLASS_INTELLIGENT		0x0E
#define PCI_CLASS_SATALITE			0x0F
#define PCI_CLASS_ENCRYPTION		0x10
#define PCI_CLASS_SIGNAL_PROC		0x11
#define PCI_CLASS_MISC				0xFF

/**** Class Code 0: Undefined ****/
#define PRE_20_ALL					0x00
#define PRE_20_VGA					0x01


/**** Class Code 1: Mass Storage ****/
#define SCSI_CONTROLLER				0x00
#define IDE_CONTROLLER				0x01
#define FLOPPY_CONTROLLER			0x02
#define IPI_CONTROLLER				0x03
#define RAID_CONTROLLER				0x04
#define OTHER_MSD_CONTROLLER		0x80

/**** Class Code 2: Network ****/
#define ETHERNET_CONTROLLER			0x00
#define TOKEN_RING					0x01
#define FDDI_CONTROLLER				0x02
#define ATM_CONTROLLER				0x03
#define OTHER_NET_CONTROLLER		0x80

/**** Class Code 3: Display ****/
#define VGA_CONTROLLER				0x00
#define IBM8514_CONTROLLER			0x00
#define	XGA_CONTROLLER				0x01
#define OTHER_DISPLAY_CONTROLLER	0x80

/**** Class Code 4: Multimedia ****/
#define VIDEO_DEVICE				0x00
#define AUDIO_DEVICE				0x01
#define OTHER_MULTIMEDIA_DEVICE		0x80

/**** Class Code 5: Memory ****/
#define RAM_CONTROLLER				0x00
#define FLASH_CONTROLLER			0x01
#define OTHER_MEM_CONTROLLER		0x80

/**** Class Code 6: Bridge ****/
#define HOST_PCI_BRIDGE				0x00
#define PCI_ISA_BRIDGE				0x01
#define PCI_EISA_BRIDGE				0x02
#define PCI_MICRO_BRIDGE			0x03
#define PCI_PCI_BRIDGE				0x04
#define PCI_PCMCIA_BRIDGE			0x05
#define PCI_NUBUS_BRIDGE			0x06
#define PCI_CARDBUS_BRIDGE			0x07
#define OTHER_PCI_BRIDGE			0x80

/**** Class Code 7: Communications ****/
#define SERIAL_PORT					0x00
#define PARALLEL_PORT				0x01
#define OTHER_COMM_PORT				0x80

/**** Class Code 8: Generic System Peripherals ****/
#define GENERIC_PIC					0x00
#define DMA_CONTROLLER				0x01
#define SYSTEM_TIMER				0x02
#define RTC_CONTROLLER				0x03
#define OTHER_SYSTEM_PERIP			0x80

/**** Class Code 9: Input Devices ****/
#define KEYBOARD_CONTROLLER			0x00
#define DIGITIZER_CONTROLLER		0x01
#define MOUSE_CONTROLLER			0x02
#define OTHER_INPUT_DEVICE			0x80

/**** Class Code A: Docking Stations ****/
#define GENERIC_DOCK				0x00
#define OTHER_DOCK_DEVICE			0x80

/**** Class Code B: Processors ****/
#define PROC_386					0x00
#define PROC_486					0x01
#define PROC_PENTIUM				0x02
#define PROC_ALPHA					0x10
#define PROC_PPC					0x20
#define PROC_COPROC					0x40

/**** Class Code C: Serial Bus ****/
#define FIREWIRE_BUS				0x00
#define ACCESS_BUS					0x01
#define SSA_BUS						0x02
#define USB_BUS						0x03


@interface PCIDevice : NSObject {
	io_service_t		selfEntry;
	io_iterator_t		iterator;
	mach_port_t			masterPort;
	UInt32				pciIndex;
	NSDictionary*		deviceProperties;

}
- (PCIDevice*)	initFromRoot;
- (PCIDevice*)	initWithEntry: (io_service_t) entry;

- (NSDictionary*) getDeviceProperties;

- (PCIDevice*)	nextChild;
- (UInt32)		deviceID;
- (UInt32)		vendorID;
- (UInt32)		PCIClass;		// read from "class-code"
- (UInt32)		PCISubClass;	// read from "class code"

- (BOOL)		driverAvailable;

- (void) printProperties;

@end
