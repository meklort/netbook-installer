/*
 *  checksum.h
 *  NetbookInstaller
 *
 *  Created by Evan Lojewski on 5/15/09.
 *  Copyright 2009. All rights reserved.
 *
 */

// NUM Bootloaders = 2 because PC EFI v10 has problems on the mini 
// TODO: read these from a plist instead
//#define NUM_SUPPORTED_BOOTLOADERS		2
#define NUM_KERNELS						8


const UInt64 kernelVersionMD5[NUM_KERNELS][2] = 
{
	0xc4cdde3890b79ca3, 0xbe765612b3cfbf94,		// Mac OS X 10.5.0
	0xdf04dbf2369806c3, 0x0f6d76dcd2d0f70a,		// Mac OS X 10.5.1
	0x128803a7ea87afbd, 0xbae3c613ca58fc30,		// Mac OS X 10.5.2
	0x48b5a7124ecc2a8b, 0xa9a07e86c07802cc,		// Mac OS X 10.5.3
	0xecfed0eab109e1d6, 0x276e3aed721bf3c3,		// Mac OS X 10.5.4
	0x07872dbbe6aee7e6, 0xbfe0fcfde9b8f681,		// Mac OS X 10.5.5
	0x45b608d8d62fa464, 0xd3d5055b5e9a09a0,		// Mac OS X 10.5.6
	0x4a6f680888c61098, 0x1c727b3af89e04f9		// Mac OS X 10.5.7
	
};




