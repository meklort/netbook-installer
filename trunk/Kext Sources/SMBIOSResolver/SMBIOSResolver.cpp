/* --- SMBIOS Resolver kext --- SMBIOSResolver.cpp
 The main purpose is to fill in information that is missing or erronoeus in a common x86 PC
 */

/* (C) 2008 Superhai
 Thanks to Kabyl for some foundation and fsb calculation routine */

/* Changelog
 1.01b1 - 02JUN08
 - Initial
 1.01b2 - 03JUN08
 - Parse boot arg "SMBIOS" to make this verbose
 - /rom/version
 - /manufacturer
 - /compatible
 - /model
 - /product-name
 - /version
 - /serial-number
 - /board-id
 1.01b3 - 04JUN08
 - /efi/platform/FSBFrequency & maxCPUfreq -> SetBusClockRateMHz
 1.01b7 - 06JUN08
 - Memory info
 /memory/dimm-manufacturer
 /memory/dimm-part-number
 /memory/dimm-serial-number
 /memory/dimm-speeds
 /memory/dimm-types
 /memory/reg
 /memory/slot-names
 1.01b9 - 08JUN08
 Fixed panic from OSDynamicCast
 1.01 - 08JUN08
 - /options/dvd-fix
 1.02 - 22JUN08
 - Memory info bugfixes
 - Updated FSB calc routine from kabyl
 1.03 - 24JUN08
 - UUID fixups
 1.04 - 02AUG08
 - Small bugfixes (thanks iNDi)
 1.05 - 10AUG08
 - Added memory speed override
 1.06 - 18AUG08
 - Choose SMBIOS or EFI bus speed
 1.07 - 27OCT08
 - Cleanup
  
  
*/

/* To do and bugs

 
 
 */

#include <IOKit/IOPlatformExpert.h>
#include <IOKit/IODeviceTreeSupport.h>
#include <IOKit/IOKitKeys.h>
#include <i386/cpuid.h>
#include <i386/proc_reg.h>
#include <sys/sysctl.h>
#include "SMBIOSResolver.h"

#define super IOService
OSDefineMetaClassAndStructors(SMBIOSResolver, IOService)

IOService * SMBIOSResolver::probe(IOService * provider, SInt32 * score)
{
	IOService * ret = super::probe(provider, score);
	if (ret != this) return 0;
	return ret;
}

bool SMBIOSResolver::start(IOService * provider)
{
	if( super::start(provider) != true ) return false;	// Oh no	
	if( IOService::getResourceService()->getProperty("SMBIOS-Resolver") ) return false;	// We should exist only once	
	if( !IOService::getResourceService()->getProperty("SMBIOS") ) return false;	// AppleSMBIOS.kext didn´t start we bail out
	
	IOService * iosRoot = getServiceRoot();
	if( !iosRoot ) return false;	// Unable to get IOServiceRoot
	
	int doVerbose = 0;
	// PE_parse_boot_arg("smbios", &doVerbose);	// bootarg SMBIOS=1 will give a verbose output to log (when I find something verbose worth outputting)
	
	// Dictionary from plist
	OSDictionary * hwDict = OSDynamicCast( OSDictionary, getProperty("Override"));
	
	//	/rom/version
	IORegistryEntry * dtROMNode = fromPath("/rom", gIODTPlane);
	if( dtROMNode )
	{
		OSString * romVersion = OSDynamicCast( OSString, hwDict->getObject("rom-version"));
		if(romVersion->getLength() > 0) dtROMNode->setProperty("version", OSData::withBytes(romVersion->getCStringNoCopy(), romVersion->getLength() + 1) );
		dtROMNode->release();
	}
	else
	{
		return false;	// No /rom node in IODeviceTree plane
	}
	
	// root entries
	OSObject * dictString = 0;
	
	dictString = hwDict->getObject("manufacturer");
	if(dictString)
	{
		OSString * rootManufacturer = OSDynamicCast( OSString, dictString);
		if(rootManufacturer->getLength() > 1) iosRoot->setProperty("manufacturer", OSData::withBytes(rootManufacturer->getCStringNoCopy(), rootManufacturer->getLength() + 1) );
	}
	
	dictString = hwDict->getObject("compatible");
	if(dictString) 
	{
		OSString * rootCompatible = OSDynamicCast( OSString, dictString);
		if(rootCompatible->getLength() > 1) iosRoot->setProperty("compatible", OSData::withBytes(rootCompatible->getCStringNoCopy(), rootCompatible->getLength() + 1) );
	}
	
	dictString = hwDict->getObject("product-name");
	if(dictString) 
	{
		OSString * rootProductName = OSDynamicCast( OSString, dictString);
		if(rootProductName->getLength() > 1) iosRoot->setProperty("product-name", OSData::withBytes(rootProductName->getCStringNoCopy(), rootProductName->getLength() + 1) );
	}
	
	dictString = hwDict->getObject("model");
	if(dictString) 
	{
		OSString * rootModel = OSDynamicCast( OSString, dictString);
		if(rootModel->getLength() > 1)
		{
			iosRoot->setProperty("model", OSData::withBytes(rootModel->getCStringNoCopy(), rootModel->getLength() + 1) );
			iosRoot->setName(rootModel->getCStringNoCopy());
		}
	}
	
	dictString = hwDict->getObject("version");
	if(dictString) 
	{
		OSString * rootVersion = OSDynamicCast( OSString, dictString);
		if(rootVersion->getLength() > 1) iosRoot->setProperty("version", OSData::withBytes(rootVersion->getCStringNoCopy(), rootVersion->getLength() + 1) );
	}
	
	dictString = hwDict->getObject("board-id");
	if(dictString) 
	{
		OSString * rootBoardId = OSDynamicCast( OSString, dictString);
		if(rootBoardId->getLength() > 1) iosRoot->setProperty("board-id", OSData::withBytes(rootBoardId->getCStringNoCopy(), rootBoardId->getLength() + 1) );
	}
	
	dictString = hwDict->getObject("serial-number");
	if(dictString) 
	{
		OSString * rootSerial = OSDynamicCast( OSString, dictString);
		if(rootSerial->getLength() > 1)
		{
			UInt8 length = rootSerial->getLength();
			const char *serialNumberString = rootSerial->getCStringNoCopy();
			
			// The serial-number property in the IORegistry is a 43-byte data object.
			// Bytes 0 through 2 are the last three bytes of the serial number string.
			// Bytes 11 through 20, inclusive, are the serial number string itself.
			// All other bytes are '\0'.
			OSData * data = OSData::withCapacity(43);
			if (data)
			{
				data->appendBytes(serialNumberString + (length - 3), 3);
				data->appendBytes(NULL, 10);
				data->appendBytes(serialNumberString, length);
				data->appendBytes(NULL, 43 - length - 10 - 3);
				iosRoot->setProperty("serial-number", data);
				data->release();
			}
			
			iosRoot->setProperty(kIOPlatformSerialNumberKey, rootSerial);
		}
	}
	
	dictString = hwDict->getObject("UUID-key");
	if(dictString) 
	{
		OSString * rootUUIDKey = OSDynamicCast( OSString, hwDict->getObject("UUID-key"));
		iosRoot->setProperty(kIOPlatformUUIDKey, rootUUIDKey);
		publishResource(kIOPlatformUUIDKey, rootUUIDKey);
	}
	
	bool useEfiBus = false;
	UInt64 fsbFrequency = 0;
	UInt64 msr;
	dictString = hwDict->getObject("use-efi-bus");
	if (dictString) useEfiBus = (OSDynamicCast(OSBoolean, dictString))->getValue(); 
	IORegistryEntry * efiPlatform = fromPath("/efi/platform", gIODTPlane);
	if (efiPlatform && useEfiBus)
	{
		OSData * efiFSBFreq = OSDynamicCast(OSData, efiPlatform->getProperty("FSBFrequency"));
		bcopy(efiFSBFreq->getBytesNoCopy(), &fsbFrequency, efiFSBFreq->getLength());
		efiPlatform->release();
	}
	else
	{	// No /efi/platform found
		fsbFrequency = gPEClockFrequencyInfo.bus_frequency_hz;	// Value previously set by AppleSMBIOS 
		if (!strncmp(cpuid_info()->cpuid_vendor, CPUID_VID_INTEL, sizeof(CPUID_VID_INTEL)) && (cpuid_info()->cpuid_features & CPUID_FEATURE_SSE2)) fsbFrequency /= 4;
	}

	dictString = hwDict->getObject("hardcode-bus");
	if(dictString) 
	{
		fsbFrequency = (OSDynamicCast(OSNumber, dictString))->unsigned64BitValue();
		if (fsbFrequency)
		{
			if (fsbFrequency <= 10000) fsbFrequency *= 1000000;
		}
		else
		{
			if (!strncmp(cpuid_info()->cpuid_vendor, CPUID_VID_INTEL, sizeof(CPUID_VID_INTEL)))
			{
				if ((cpuid_info()->cpuid_family == 0x0f) && (cpuid_info()->cpuid_model >= 2))
				{
					msr = rdmsr64(0x0000002C);
					switch ((msr >> 16) & 0x7) {
						case 0:
							if (cpuid_info()->cpuid_model == 2) fsbFrequency = 100 * 1000000;
							else 
							{
								fsbFrequency = (800 * 1000000) / 3;	// 266
								fsbFrequency++;
							}
							break;
						case 1:
							fsbFrequency = (400 * 1000000) / 3;	//	133
							break;
						case 2:
							fsbFrequency = (600 * 1000000) / 3;	// 200
							break;
						case 3:
							fsbFrequency = (500 * 1000000) / 3;	//	166
							fsbFrequency++;
							break;
						case 4:
							fsbFrequency = (1000 * 1000000) / 3;	//	333
							break;
						default:
							break;
					}
				}
				else
				{
					fsbFrequency = 100 * 1000000;
				}
				
				if (cpuid_info()->cpuid_family == 0x06)
				{
					msr = rdmsr64(0x000000CD);
					switch (msr & 0x7) {
						case 0:
							fsbFrequency = (800 * 1000000) / 3;	//	266
							fsbFrequency++;
							break;
						case 1:
							fsbFrequency = (400 * 1000000) / 3;	//	133
							break;
						case 2:
							fsbFrequency = (600 * 1000000) / 3;	//	200
							break;
						case 3:
							fsbFrequency = (500 * 1000000) / 3;	//	166
							fsbFrequency++;
							break;
						case 4:
							fsbFrequency = (1000 * 1000000) / 3;//	333
							break;
						case 5:
							fsbFrequency = (300 * 1000000) / 3;	//	100
							break;
						case 6:
							fsbFrequency = (1200 * 1000000) / 3;//	400
							break;
						case 7:		// should check
							fsbFrequency = (1400 * 1000000) / 3;//	466
							fsbFrequency++;
							break;
						default:
							break;
					}
				}
				 
			}
		}
		
	}
	
	UInt64 cpuFrequency = calcCPU(fsbFrequency);
		
    if (fsbFrequency > 0) {
		// convert from FSB to quad-pumped bus speed
        if (!strncmp(cpuid_info()->cpuid_vendor, CPUID_VID_INTEL, sizeof(CPUID_VID_INTEL)) && (cpuid_info()->cpuid_features & CPUID_FEATURE_SSE2)) fsbFrequency *= 4;
				
		if (gPEClockFrequencyInfo.bus_frequency_hz == gPEClockFrequencyInfo.bus_frequency_min_hz) gPEClockFrequencyInfo.bus_frequency_min_hz = fsbFrequency;
		if (gPEClockFrequencyInfo.bus_frequency_hz == gPEClockFrequencyInfo.bus_frequency_max_hz) gPEClockFrequencyInfo.bus_frequency_max_hz = fsbFrequency;
		gPEClockFrequencyInfo.bus_clock_rate_hz = fsbFrequency;
		gPEClockFrequencyInfo.bus_frequency_hz = fsbFrequency;
		gPEClockFrequencyInfo.cpu_clock_rate_hz = cpuFrequency;
		if (gPEClockFrequencyInfo.cpu_frequency_hz == gPEClockFrequencyInfo.cpu_frequency_min_hz) gPEClockFrequencyInfo.cpu_frequency_min_hz = cpuFrequency;
		if (gPEClockFrequencyInfo.cpu_frequency_hz == gPEClockFrequencyInfo.cpu_frequency_max_hz) gPEClockFrequencyInfo.cpu_frequency_max_hz = cpuFrequency;
		gPEClockFrequencyInfo.cpu_frequency_hz = cpuFrequency;
		PE_call_timebase_callback();
    }
	
	if (doVerbose)
	{
		IOLog("%s: ----------------------------------------------------- \n", this->getName());
		IOLog("%s: CPU Data \n", this->getName());
		IOLog("%s: ----------------------------------------------------- \n", this->getName());
		IOLog("%s: Bus clock rate %d hz \n", this->getName(), gPEClockFrequencyInfo.bus_clock_rate_hz);
		IOLog("%s: CPU clock rate %d hz \n", this->getName(), gPEClockFrequencyInfo.cpu_clock_rate_hz);
		IOLog("%s: Dec clock rate %d hz \n", this->getName(), gPEClockFrequencyInfo.dec_clock_rate_hz);
		IOLog("%s: Bus clock rate number %d \n", this->getName(), gPEClockFrequencyInfo.bus_clock_rate_num);
		IOLog("%s: Bus clock rate den %d \n", this->getName(), gPEClockFrequencyInfo.bus_clock_rate_den);
		IOLog("%s: Bus to CPU rate number %d \n", this->getName(), gPEClockFrequencyInfo.bus_to_cpu_rate_num);
		IOLog("%s: Bus to CPU rate den %d \n", this->getName(), gPEClockFrequencyInfo.bus_to_cpu_rate_den);
		IOLog("%s: Bus to dec rate number %d \n", this->getName(), gPEClockFrequencyInfo.bus_to_dec_rate_num);
		IOLog("%s: Bus to dec rate den %d \n", this->getName(), gPEClockFrequencyInfo.bus_to_dec_rate_den);
		IOLog("%s: Timebase frequency %d hz \n", this->getName(), gPEClockFrequencyInfo.timebase_frequency_hz);
		IOLog("%s: Timebase frequency number %d \n", this->getName(), gPEClockFrequencyInfo.timebase_frequency_num);
		IOLog("%s: Timebase frequency den %d \n", this->getName(), gPEClockFrequencyInfo.timebase_frequency_den);
		IOLog("%s: Bus frequency %d hz \n", this->getName(), gPEClockFrequencyInfo.bus_frequency_hz);
		IOLog("%s: Bus frequency minimum %d hz \n", this->getName(), gPEClockFrequencyInfo.bus_frequency_min_hz);
		IOLog("%s: Bus frequency maximum %d hz \n", this->getName(), gPEClockFrequencyInfo.bus_frequency_max_hz);
		IOLog("%s: CPU frequency %d hz \n", this->getName(), gPEClockFrequencyInfo.cpu_frequency_hz);
		IOLog("%s: CPU frequency minimum %d hz \n", this->getName(), gPEClockFrequencyInfo.cpu_frequency_min_hz);
		IOLog("%s: CPU frequency maximum %d hz \n", this->getName(), gPEClockFrequencyInfo.cpu_frequency_max_hz);
		IOLog("%s: Prf frequency %d hz \n", this->getName(), gPEClockFrequencyInfo.prf_frequency_hz);
		IOLog("%s: Prf frequency minimum %d hz \n", this->getName(), gPEClockFrequencyInfo.prf_frequency_min_hz);
		IOLog("%s: Prf frequency maximum %d hz \n", this->getName(), gPEClockFrequencyInfo.prf_frequency_max_hz);
		IOLog("%s: Memory frequency %d hz \n", this->getName(), gPEClockFrequencyInfo.mem_frequency_hz);
		IOLog("%s: Memory frequency minimum %d hz \n", this->getName(), gPEClockFrequencyInfo.mem_frequency_min_hz);
		IOLog("%s: Memory frequency maximum %d hz \n", this->getName(), gPEClockFrequencyInfo.mem_frequency_max_hz);
		IOLog("%s: Fix frequency %d hz \n", this->getName(), gPEClockFrequencyInfo.fix_frequency_hz);
	}	
	
	// Memory node
	IORegistryEntry * dtMemoryNode = fromPath("/memory", gIODTPlane);
	if(dtMemoryNode)
	{
		UInt8 dimmCount = 0;
		UInt8 dimmLength;
		UInt8 dimmData = 0;
		bool dimmZero = true;
		
		OSData * dimmManufacturer = OSDynamicCast(OSData, dtMemoryNode->getProperty("dimm-manufacturer"));
		memManufData	= OSData::withCapacity(kMemDataSize);
		
		dimmLength = dimmManufacturer->getLength();	
		for(UInt8 i = 0; i < dimmLength; i++)
		{
			bcopy(dimmManufacturer->getBytesNoCopy(i,1), &dimmData, 1);
			if (!dimmData)
			{
				if (dimmZero) memManufData->appendBytes("Unknown\0", 8);
				else
				{
					memManufData->appendBytes("\0", 1);
					dimmZero = true;
				}
				dimmCount++;
			}
			else
			{
				if (dimmData == 0x20) memManufData->appendBytes("\0", 1);
				else memManufData->appendByte( dimmData, 1);
				dimmZero = false;
			}
		}
		dtMemoryNode->setProperty("dimm-manufacturer", memManufData);
		memManufData->release();
				
		memSerialData	= OSData::withCapacity(kMemDataSize);
		OSData * dimmSerialNumber = OSDynamicCast(OSData, dtMemoryNode->getProperty("dimm-serial-number"));
		
		dimmZero = true;
		dimmLength = dimmSerialNumber->getLength();	
		for(UInt8 i = 0; i < dimmLength; i++)
		{
			bcopy(dimmSerialNumber->getBytesNoCopy(i,1), &dimmData, 1);
			if (!dimmData)
			{
				if (dimmZero) memSerialData->appendBytes("Unknown\0", 8);
				else
				{
					memSerialData->appendBytes("\0", 1);
					dimmZero = true;
				}
			}
			else
			{
				if (dimmData == 0x20) memSerialData->appendBytes("\0", 1);
				else memSerialData->appendByte( dimmData, 1);
				dimmZero = false;
			}
		}
		dtMemoryNode->setProperty("dimm-serial-number", memSerialData);
		memSerialData->release();

		memPartData		= OSData::withCapacity(kMemDataSize);
		OSData * dimmPartNumber = OSDynamicCast(OSData, dtMemoryNode->getProperty("dimm-part-number"));
		
		dimmZero = true;
		dimmLength = dimmPartNumber->getLength();	
		for(UInt8 i = 0; i < dimmLength; i++)
		{
			bcopy(dimmPartNumber->getBytesNoCopy(i,1), &dimmData, 1);
			if (!dimmData)
			{
				if (dimmZero) memPartData->appendBytes("Unknown\0", 8);
				else
				{
					memPartData->appendBytes("\0", 1);
					dimmZero = true;
				}
			}
			else
			{
				if (dimmData == 0x20) memPartData->appendBytes("\0", 1);
				else memPartData->appendByte( dimmData, 1);
				dimmZero = false;
			}
		}
		dtMemoryNode->setProperty("dimm-part-number", memPartData);
		memPartData->release();
		
		dictString = hwDict->getObject("dimm-speed");
		if (dictString)
		{
			OSString * dimmDictData = OSDynamicCast( OSString, dictString);
			if (dimmDictData->getLength() > 1)
			{
				memSpeedData	= OSData::withCapacity(kMemDataSize);
				OSData * dimmSpeedNumber = OSDynamicCast(OSData, dtMemoryNode->getProperty("dimm-speeds"));
				dimmLength = dimmSpeedNumber->getLength();
				for(UInt8 i = 0; i < dimmLength;i ++)
				{
					bcopy(dimmSpeedNumber->getBytesNoCopy(i,1), &dimmData, 1);
					if (!dimmData) memSpeedData->appendBytes(dimmDictData->getCStringNoCopy(), dimmDictData->getLength() + 1);
				}
				dtMemoryNode->setProperty("dimm-speeds", memSpeedData);
				memSpeedData->release();
			}			
		}
		
		
	}
	else
	{
		return false;	// No /memory node in IODeviceTree plane
	}
	
	// /options/ node fix (aka dvd-fix)
	IOService * optionNode = new IOService;
	if (optionNode)
	{
		if (optionNode->init())
		{
			optionNode->setName("options");
			optionNode->setProperty("resolver", "\0\0");
			optionNode->attachToParent(iosRoot, gIODTPlane);
			optionNode->release();
		}
		else
		{
			optionNode->release();
			optionNode = 0;
			return false;	// Error in creating options node
		}
	}
	
	publishResource("SMBIOS-Resolver");
	return true; // OK we are done
}

UInt64 SMBIOSResolver::calcCPU(UInt64 fsb_frequency_hz)
{
	UInt64				cpu_frequency_hz;
	UInt64				msr;
	int					coef;
	UInt16				N_2 = 0; // Non-Integer Bus Ratio
	
	if (!strncmp(cpuid_info()->cpuid_vendor, CPUID_VID_INTEL, sizeof(CPUID_VID_INTEL)))
	{
		if(((cpuid_info()->cpuid_family == 0x06) && ((cpuid_info()->cpuid_model > 0x0d)) ||
			((cpuid_info()->cpuid_family == 0x0f) && (cpuid_info()->cpuid_model > 0x02))))
		{
			msr = rdmsr64(MSR_IA32_PERF_STS);
			N_2 = ((msr >> 46) & 1) * 2;
			coef = (msr >> 40) & 0x1f;
		}
	}
	
	else if((!strncmp(cpuid_info()->cpuid_vendor, CPUID_VID_AMD, sizeof(CPUID_VID_AMD))) && (cpuid_info()->cpuid_family == 0x0f))
	{
		if(cpuid_info()->cpuid_extfamily == 0x00 /* K8 */)
			coef = (rdmsr64(K8_FIDVID_STATUS) & 0x3f) / 2 + 4;
		else if(cpuid_info()->cpuid_extfamily == 0x01 /* K10 */)
		{
			msr = rdmsr64(K10_COFVID_STATUS);
			coef = (msr & 0x3f) + 0x10;
			N_2 = (2 << ((msr >> 6) & 0x07));
		}
	}
	
	if(N_2) cpu_frequency_hz = (fsb_frequency_hz * ((coef * N_2) + 1)) / N_2;
	else cpu_frequency_hz = fsb_frequency_hz * coef;
	
	gPEClockFrequencyInfo.bus_to_cpu_rate_num = coef;
	
	return cpu_frequency_hz;
}

void SMBIOSResolver::stop(IOService * provider)
{
	super::stop(provider);
}

void SMBIOSResolver::free( void )
{
	super::free();	// Ok so we will leave...
}

