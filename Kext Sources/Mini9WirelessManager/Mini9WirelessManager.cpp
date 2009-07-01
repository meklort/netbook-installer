/* add your code here */

#include <IOKit/assert.h>
#include <IOKit/IOService.h>
#include <IOKit/acpi/IOACPIPlatformDevice.h>
#include "Mini9WirelessManager.h"

// =============================================================================
// ApplePS2SynapticsTouchPad Class Implementation
//

#define super IOService
OSDefineMetaClassAndStructors(Mini9WirelessManager, IOService);


// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
bool Mini9WirelessManager::init(OSDictionary *dict)
{

    bool res = super::init(dict);
    return res;
}

void Mini9WirelessManager::free(void)
{
    IOLog("Freeing\n");
    super::free();
}

IOService* Mini9WirelessManager::probe(IOService *provider, SInt32 *score)
{
    IOService *res = super::probe(provider, score);
    IOLog("Probing\n");
    return res;
}

bool Mini9WirelessManager::start(IOService *provider)
{
	fProvider = OSDynamicCast(IOACPIPlatformDevice, provider);

    bool res = super::start(provider);
    IOLog("Startions\n");
	IOLog("WirelessManager: start\n");
	IOLog("WirelessManager: getting stat\n");
	//i386_iopl(kWMCommandPort);
	//i386_iopl(kWMStatusPort);
	getStatus();
	IOLog("WirelessManager: done\n");
    return res;
}

void Mini9WirelessManager::stop(IOService *provider)
{
    IOLog("Stopping\n");
    super::stop(provider);
}




void Mini9WirelessManager::portInit () {
		
	//while((inb(kWMCommandPort) & kWMOK) != 0);
	while((fProvider->ioRead8(kWMCommandPort) & kInputBusy) != 0);
	fProvider->ioWrite8(kWMCommandPort, 0xb0);
	
	while((fProvider->ioRead8(kWMCommandPort) & kInputBusy) != 0);
	fProvider->ioWrite8(kWMStatusPort, 0xbb);
	
	while((fProvider->ioRead8(kWMCommandPort) & kOutputReady) != 0);
	_status = fProvider->ioRead8(kWMStatusPort);
}

void Mini9WirelessManager::getStatus () {
	portInit();
	
	if(_status & WIRELESS_BITMAP) // Wifi is on
		IOLog("Mini9WirelessManager: Wireless is on.\n");
	else	// wifi is off
		IOLog("Mini9WirelessManager: Wireless is off.\n");
	
	if(_status & BLUETOOTH_BITMAP) // Bluetooth is on
		IOLog("Mini9WirelessManager: Bluetooth is on.\n");
	else
		IOLog("Mini9WirelessManager: Bluetooth is off.\n");
	
	
	while((fProvider->ioRead8(kWMCommandPort) & kInputBusy) != 0);
	fProvider->ioWrite8(kWMCommandPort, 0xff);
}


IOReturn Mini9WirelessManager::setParamProperties( OSDictionary * dict )
{
	return true;
}


bool Mini9WirelessManager::powerControl (UInt8 bitmap) {
	UInt8 newStatus = _status;
	portInit();

	while((fProvider->ioRead8(kWMCommandPort) & kInputBusy) != 0);
	fProvider->ioWrite8(kWMCommandPort, 0xff);
	
	while((fProvider->ioRead8(kWMCommandPort) & kWMOK) != 0);
	while((fProvider->ioRead8(kWMCommandPort) & kInputBusy) != 0);
	fProvider->ioWrite8(kWMCommandPort, 0xb1);
	
	while((fProvider->ioRead8(kWMCommandPort) & kInputBusy) != 0);
	
	fProvider->ioWrite8(kWMStatusPort, 0xbb);
	
	if((_status & WIRELESS_BITMAP) && !(bitmap & WIRELESS_BITMAP))
		newStatus &= 0xfe; // Turn off wireless	(unset bit 1_
	else if(!(_status & WIRELESS_BITMAP) && (bitmap & WIRELESS_BITMAP)) // Wifi is on
		newStatus |= WIRELESS_BITMAP;
	
	
	if((_status & BLUETOOTH_BITMAP) && !(bitmap & WIRELESS_BITMAP)) // Bluetooth is on
		newStatus &= 0xfd;
	else if(!(_status & BLUETOOTH_BITMAP) && (bitmap & WIRELESS_BITMAP)) // Bluetooth is on
		newStatus |= BLUETOOTH_BITMAP;
	
	

	
	while((fProvider->ioRead8(kWMCommandPort) & kInputBusy) != 0);
	fProvider->ioWrite8(kWMStatusPort, newStatus);
	while((fProvider->ioRead8(kWMCommandPort) & kInputBusy) != 0);
	fProvider->ioWrite8(kWMCommandPort, 0xff);
	return true;
}
	

//
	

/*#include <stdio.h>
#include <stdlib.h>
#include <string.h>



unsigned int eq(unsigned int a, unsigned int b) {
	return a == b;
}

unsigned int ne(unsigned int a, unsigned int b) {
	return a != b;
}

void waitfor(i386_ioport_t port, unsigned char datum, unsigned int (*comp)(unsigned int, unsigned int)) {
	while (1) {
		unsigned char status = inb(port);
		if (comp((status & datum), 0))
			break;
	}
}


void powerControl(unsigned char radio) {
	unsigned char x, wstatus, new_wstatus;
	
	wstatus = port_setup();
	
	if (radio == 1) {
		if (wstatus & 1 << 0) {
			printf("Wifi on");
			x = 1;
		} else {
			printf("Wifi off");
			x = 3;
		}
	}
	
	if (radio == 2) {
		if (wstatus & 1 << 1) {
			printf("BT on");
			x = 2;
		} else {
			printf("BT off");
			x = 4;
		}
	}
	
	if (radio == 3)
		x = 1;
	if (radio == 4)
		x = 2;
	if (radio == 5)
		x = 3;
	if (radio == 6)
		x = 4;
	
	waitfor(0x6c, 0x02, &eq);
	outb(0x6c, 0xff);
	
	waitfor(0x6c, 0x80, &eq);
	waitfor(0x6c, 0x02, &eq);
	outb(0x6c, 0xb1);
	
	waitfor(0x6c, 0x02, &eq);
	outb(0x68, 0xbb);
	
	new_wstatus = wstatus;
	if (x == 1)
		new_wstatus = new_wstatus & 0xfe; // turn off wireless
	if (x == 2)
		new_wstatus = new_wstatus & 0xfd; // turn off bluetooth
	if (x == 3)
		new_wstatus = new_wstatus | 0x01; // turn on wireless
	if (x == 4)
		new_wstatus = new_wstatus | 0x02; // turn on bluetooth
	
	waitfor(0x6c, 0x02, &eq);
	outb(0x68, new_wstatus);
	
	waitfor(0x6c, 0x02, &eq);
	outb(0x6c, 0xff);
}

*/