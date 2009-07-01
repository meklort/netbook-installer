/* add your code here */

#ifndef _APPLEPS2SYNAPTICSTOUCHPAD_H
#define _APPLEPS2SYNAPTICSTOUCHPAD_H

#define kWMBluetooth	"BluetoothEnabled"
#define kWMWireless		"WirelessEnabled"

#define kWMCommandPort	0x6c
#define kWMStatusPort	0x68

#define kOutputReady            0x01    // output (from keybd) buffer full
#define kInputBusy              0x02    // input (to keybd) buffer full

// These are guesses...
#define	kWMOK			0x80

//#define KWMSetStatus	0xbb
//#define kWMUnknown	0xb1
//#define kWMRest		0xff

#define WIRELESS_BITMAP		0x01
#define BLUETOOTH_BITMAP	0x02


class Mini9WirelessManager : public IOService 
{
	OSDeclareDefaultStructors( Mini9WirelessManager );

	private:
		
		virtual void   free();
		//virtual void   setDevicePowerState(UInt32 whatToDo);
		virtual void   portInit();
		virtual void   getStatus();


		virtual bool   powerControl (UInt8 bitmap);
	
		UInt8		   _portStatus;
		UInt8		   _status;
		IOACPIPlatformDevice   *fProvider;

	
	//virtual bool   portSetup ();


		
	public:
		virtual bool init( OSDictionary * properties );
	
	
		virtual IOService *probe(IOService *provider, SInt32 *score);

	
		virtual bool start( IOService * provider );
		virtual void stop ( IOService * provider );
	
	
		virtual IOReturn setParamProperties( OSDictionary * dict );
};

#endif /* _APPLEPS2SYNAPTICSTOUCHPAD_H */
