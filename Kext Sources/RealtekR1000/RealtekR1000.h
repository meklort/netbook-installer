/* This driver based on R1000 Linux Driver for Realtek controllers.
 * It's not supported by Realtek company, so use it for your own risk.
 * 2006 (c) Dmitri Arekhta (DaemonES@gmail.com)
 * 
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 *
 *****************************************************************
 *
 * MODIFIED by PSYSTAR, 2008 -- (Rudy Pedraza)
 * -- all changes released under GPL as required
 * -- changes made to code are copyright PSYSTAR Corporation, 2008
 **** Enhancement Log
 * - added sleep/wake DHCP fix for
 * - changed tx/rx interrupt handling, 2x speedup
 * - added support for multiple NIC's, driver didnt play nice before
 * - fixed com.apple.kernel & com.apple.kpi dependencies, you cant use both (warning now, future error)
 * - cleaned up Info.plist, fixed matching
 */

#ifndef _REALTEKR1000_H_
#define _REALTEKR1000_H_

#include <IOKit/IOLib.h>
#include <IOKit/IOTimerEventSource.h>
#include <IOKit/IOBufferMemoryDescriptor.h>
#include <IOKit/network/IOEthernetController.h>
#include <IOKit/network/IOEthernetInterface.h>
#include <IOKit/network/IOGatedOutputQueue.h>
#include <IOKit/network/IOMbufMemoryCursor.h>
#include <IOKit/pci/IOPCIDevice.h>
#include <IOKit/IOFilterInterruptEventSource.h>

extern "C"
{
	#include <sys/kpi_mbuf.h>
	#include <architecture/i386/pio.h>>
}

#include "R1000Regs.h"
#include "mii.h"

#ifdef DEBUG
#define DLog(args...)
//#define DLog(args...) IOLog("REALTEK: "args)
#else 
#define DLog(args...)
#endif

#define RealtekR1000 com_psystar_RealtekR1000

enum
{
	MEDIUM_INDEX_10HD	= 0,
	MEDIUM_INDEX_10FD	= 1,
	MEDIUM_INDEX_100HD	= 2,
	MEDIUM_INDEX_100FD	= 3,
	MEDIUM_INDEX_1000HD = 4,
	MEDIUM_INDEX_1000FD = 5,
	MEDIUM_INDEX_AUTO	= 6,
	MEDIUM_INDEX_COUNT	= 7
};


enum 
{
    kActivationLevelNone = 0,  /* adapter shut off */
    kActivationLevelKDP,       /* adapter partially up to support KDP */
    kActivationLevelBSD        /* adapter fully up to support KDP and BSD */
};

class RealtekR1000 : public IOEthernetController
{
	OSDeclareDefaultStructors(RealtekR1000)
public:
	virtual bool			init(OSDictionary *properties);
	virtual void			free();
	virtual bool			start(IOService *provider);
	virtual void			stop(IOService *provider);
	
	virtual IOReturn		enable(IONetworkInterface *netif);
    virtual IOReturn		disable(IONetworkInterface *netif);
	
    virtual UInt32			outputPacket(mbuf_t m, void *param);
    virtual void			getPacketBufferConstraints(IOPacketBufferConstraints *constraints) const;
    virtual IOOutputQueue	*createOutputQueue();
    virtual const OSString	*newVendorString() const;
    virtual const OSString	*newModelString() const;
    virtual IOReturn		selectMedium(const IONetworkMedium *medium);
    virtual bool			configureInterface(IONetworkInterface *netif);
    virtual bool			createWorkLoop();
    virtual IOWorkLoop		*getWorkLoop() const;
    virtual IOReturn		getHardwareAddress(IOEthernetAddress *addr);

    virtual IOReturn		setPromiscuousMode(bool enabled);
    virtual IOReturn		setMulticastMode(bool enabled);
    virtual IOReturn		setMulticastList(IOEthernetAddress *addrs, UInt32 count);

    virtual void			sendPacket(void *pkt, UInt32 pkt_len);
    virtual void			receivePacket(void * pkt, UInt32 *pkt_len, UInt32 timeout);

    virtual IOReturn		registerWithPolicyMaker(IOService *policyMaker);
    virtual IOReturn		setPowerState(unsigned long powerStateOrdinal, IOService *policyMaker);

private:
	IOPCIDevice						*pciDev;
	IOWorkLoop						*workLoop;
	IOInterruptEventSource			*intSource;
    IOTimerEventSource				*timerSource;
    IONetworkStats					*netStats;
    IOEthernetStats					*etherStats;
	IOOutputQueue					*transmitQueue;
    IOEthernetInterface				*netif;
	OSDictionary					*mediumDict;
	const IONetworkMedium			*mediumTable[MEDIUM_INDEX_COUNT];

	UInt16							pioBase;
	IOMemoryMap						*mmioBase;
	bool							forcedPio;
	
	
	// this added because of compatibility problems with new
	// init routine, OS X, on some cards, takes a crap
	// because the card recieves interrupts but isnt ready
	bool isInitialized;
	
	bool enabled;
	ushort vendorId, deviceId;
	bool linked;
	
	UInt32							activationLevel;
	bool							enabledForBSD;
	bool							enabledForKDP;

	int mcfg;
	int pcfg;
	int chipset;
	ulong expire_time;
	
	ulong mc_filter0, mc_filter1;
	
	unsigned long phy_link_down_cnt;
	unsigned long cur_rx;                   /* Index into the Rx descriptor buffer of next Rx pkt. */
	unsigned long cur_tx;                   /* Index into the Tx descriptor buffer of next Rx pkt. */
	unsigned long dirty_tx;

	uchar   drvinit_fail;

	struct	__mbuf				*Tx_skbuff[NUM_TX_DESC];	
	uchar						*Tx_dbuff[NUM_TX_DESC];
	IOBufferMemoryDescriptor	*Tx_skbuff_Md[NUM_TX_DESC];
	IOPhysicalAddress			Tx_skbuff_Dma[NUM_TX_DESC];
	
	uchar						*Rx_dbuff[NUM_RX_DESC];
	IOBufferMemoryDescriptor	*Rx_skbuff_Md[NUM_RX_DESC];
	IOPhysicalAddress			Rx_skbuff_Dma[NUM_RX_DESC];
	
	void *txdesc_space;
	struct	TxDesc	*TxDescArray;           /* Index of 256-alignment Tx Descriptor buffer */
	IOBufferMemoryDescriptor *tx_descMd;
	IOPhysicalAddress txdesc_phy_dma_addr;
	int sizeof_txdesc_space;

	void *rxdesc_space;
	struct	RxDesc	*RxDescArray;           /* Index of 256-alignment Rx Descriptor buffer */
	IOBufferMemoryDescriptor *rx_descMd;
	IOPhysicalAddress rxdesc_phy_dma_addr;
	int sizeof_rxdesc_space;
	
	int curr_mtu_size;
	int tx_pkt_len;
	int rx_pkt_len;

	int hw_rx_pkt_len;

	u16	speed;
	u8	duplex;
	u8	autoneg;
	
	static int max_interrupt_work;
	static int multicast_filter_limit;
	static const unsigned int ethernet_polynomial;

	inline void WriteMMIO8(ushort offset, uchar value)	 { (forcedPio) ? outb(pioBase + offset, value) : pciDev->ioWrite8(offset, value, mmioBase); }
	inline void WriteMMIO16(ushort offset, ushort value) { (forcedPio) ? outw(pioBase + offset, value) : pciDev->ioWrite16(offset, value, mmioBase); }
	inline void WriteMMIO32(ushort offset, ulong value)  { (forcedPio) ? outl(pioBase + offset, value) : pciDev->ioWrite32(offset, value, mmioBase); }
	
	inline uchar ReadMMIO8(ushort offset)   { return ((forcedPio) ? inb(pioBase + offset) : pciDev->ioRead8(offset, mmioBase)); }
	inline ushort ReadMMIO16(ushort offset) { return ((forcedPio) ? inw(pioBase + offset) : pciDev->ioRead16(offset, mmioBase)); }
	inline ulong ReadMMIO32(ushort offset)  { return ((forcedPio) ? inl(pioBase + offset) : pciDev->ioRead32(offset, mmioBase)); }
	
	void WriteGMII32(int RegAddr, int value );
	int ReadGMII32(int RegAddr);
	
	bool R1000InitBoard();
	bool R1000ProbeAndStartBoard();
	bool R1000StopBoard();
	
	bool R1000SetSpeedDuplex(ulong anar, ulong gbcr, ulong bmcr);
	bool R1000SetMedium(ushort speed, uchar duplex, uchar autoneg);
	
	bool increaseActivationLevel(UInt32 level);
	bool decreaseActivationLevel(UInt32 level);
	bool setActivationLevel(UInt32 level);
	
	void R1000HwPhyReset();
	void R1000HwPhyConfig();
	void R1000HwStart();
		
	ulong ether_crc(int length, unsigned char *data);
	
	bool AllocateDescriptorsMemory();
	void FreeDescriptorsMemory();
	
	bool R1000InitEventSources(IOService *provide);
	bool R1000OpenAdapter();
	void R1000CloseAdapter();
	void R1000TxClear();
	
    void R1000Interrupt(OSObject * client, IOInterruptEventSource * src, int count);
	void R1000RxInterrupt();
	void R1000TxInterrupt();
	void R1000TxTimeout(OSObject *owner, IOTimerEventSource * timer);
	
	bool OSAddNetworkMedium(ulong type, UInt32 bps, ulong index);
};

#endif