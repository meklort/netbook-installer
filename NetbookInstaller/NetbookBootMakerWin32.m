//
//  NetbookBootMakerWin32.m
//  NetbookInstaller
//
//  Created by Evan Lojewski on 12/29/09.
//  Copyright 2009. All rights reserved.
//
//	Code taken from https://launchpad.net/win32-image-writer/+download
//

#import "NetbookBootMakerWin32.h"
#include "disk.h"

//	GetLogicalDrives();

#if 0
@implementation NetbookBootMakerWin32

- (void) awakeFromNib {	
	[volumeList removeAllItems];
	
	
	unsigned long availabledrives = GetLogicalDrives();
	
	char drivename[] = "\\\\.\\A:\\";

	while (availabledrives != 0)
	{
		
		if ((availabledrives & 0x1) == 0x1)	// Check last bit
		{
			//if (DRIVE_REMOVABLE == GetDriveType(drivename))
			//{
				[volumeList addItemWithTitle:[NSString stringWithFormat:@"[%c]", drivename[4]]];
				
				//cboxDevice->addItem(QString("[d1]").arg(drivename[4]), QVariant(getPhysicalDeviceID(i)));
			//}
		}
		availabledrives >>= 1;
		drivename[4] ++;
	}
	
	[volumeList addItemWithTitle:@"Refresh List"];


}

- (IBAction) performInstall: (id) sender
{
	[self writeImage:@"BootMakerSupport/NetbookBootLoader.img" toDrive: [volumeList indexOfSelectedItem]];
}

- (void) writeImage: (NSString*) imageFile toDrive: (int) drive
{
	char* fileLocation; // [imageFile cString]
	// if([NSFileManager fileExistsAtPath: imageFile])	// spsuedocode
	{
	//if (!leFile->text().isEmpty())
	//{
		// if file is readable, and file > 0
		{
		//QFileInfo fileinfo(leFile->text());
		//if (fileinfo.exists() && fileinfo.isFile() && fileinfo.isReadable() && fileinfo.size() > 0)
		//{
			if (leFile->text().at(0) == cboxDevice->currentText().at(1))
			{
				QMessageBox::critical(NULL, "Write Error", "Image file cannot be located on the requested device.");
				return;
			}
			if (QMessageBox::warning(NULL, "Confirm overwrite", "Writing to a physical device can corrupt the device.\nAre you sure you want to continue?", QMessageBox::Yes | QMessageBox::No, QMessageBox::No) == QMessageBox::No)
				return;
			//status = STATUS_WRITING;
			///bCancel->setEnabled(true);
			//bWrite->setEnabled(false);
			//bRead->setEnabled(false);
			//double mbpersec;
			UInt8 percent = 0;
			
			//unsigned long long i, lasti, availablesectors, numsectors;
			int volumeID = cboxDevice->currentText().at(1).toAscii() - 'A';
			int deviceID = cboxDevice->itemData(cboxDevice->currentIndex()).toInt();
			NSFileManager = new char[5 + leFile->text().length()];		// use malloc
			sprintf(filelocation, "\\\\.\\%s", leFile->text().toAscii().data());
			hVolume = getHandleOnVolume(volumeID, GENERIC_WRITE);
			if (hVolume == INVALID_HANDLE_VALUE)
			{
				if(fileLocation) free(filelocation);
				//status = STATUS_IDLE;
				fileLocation = NULL;
				//bCancel->setEnabled(false);
				//bWrite->setEnabled(true);
				//bRead->setEnabled(true);
				return;
			}
			if (!getLockOnVolume(hVolume))
			{
				if(fileLocation) free(fileLocation);
				CloseHandle(hVolume);
				//status = STATUS_IDLE;
				fileLocation = NULL;
				hVolume = INVALID_HANDLE_VALUE;
				//bCancel->setEnabled(false);
				//bWrite->setEnabled(true);
				//bRead->setEnabled(true);
				return;
			}
			if (!unmountVolume(hVolume))
			{
				if(fileLocation) free(fileLocation);
				removeLockOnVolume(hVolume);
				CloseHandle(hVolume);
				//status = STATUS_IDLE;
				fileLocation = NULL;
				hVolume = INVALID_HANDLE_VALUE;
				//bCancel->setEnabled(false);
				//bWrite->setEnabled(true);
				//bRead->setEnabled(true);
				return;
			}
			hFile = getHandleOnFile(fileLocation, GENERIC_READ);
			if (hFile == INVALID_HANDLE_VALUE)
			{
				if(fileLocation) free(fileLocation);
				removeLockOnVolume(hVolume);
				CloseHandle(hVolume);
				//status = STATUS_IDLE;
				fileLocation = NULL;
				hVolume = INVALID_HANDLE_VALUE;
				//bCancel->setEnabled(false);
				//bWrite->setEnabled(true);
				//bRead->setEnabled(true);
				return;
			}
			hRawDisk = getHandleOnDevice(deviceID, GENERIC_WRITE);
			if (hRawDisk == INVALID_HANDLE_VALUE)
			{
				if(fileLocation) free(fileLocation);
				removeLockOnVolume(hVolume);
				CloseHandle(hFile);
				CloseHandle(hVolume);
				status = STATUS_IDLE;
				fileLocation = NULL;
				hVolume = INVALID_HANDLE_VALUE;
				hFile = INVALID_HANDLE_VALUE;
				//bCancel->setEnabled(false);
				//bWrite->setEnabled(true);
				//bRead->setEnabled(true);
				return;
			}
			availablesectors = getNumberOfSectors(hRawDisk, &sectorsize);
			numsectors = getFileSizeInSectors(hFile, sectorsize);
			if (numsectors > availablesectors)
			{
				QMessageBox::critical(NULL, "Write Error", "Not enough space on disk.");
				if(fileLocation) free(fileLocation);
				removeLockOnVolume(hVolume);
				CloseHandle(hRawDisk);
				CloseHandle(hFile);
				CloseHandle(hVolume);
				status = STATUS_IDLE;
				fileLocation = NULL;
				hVolume = INVALID_HANDLE_VALUE;
				hFile = INVALID_HANDLE_VALUE;
				hRawDisk = INVALID_HANDLE_VALUE;
				//bCancel->setEnabled(false);
				//bWrite->setEnabled(true);
				//bRead->setEnabled(true);
				return;
			}
			if (numsectors == 0ull)
				progressbar->setRange(0, 100);
			else
				progressbar->setRange(0, (int)numsectors);
			
			lasti = 0ull;
			timer.start();
			for (i = 0ull; i < numsectors && status == STATUS_WRITING; i += 1024ull)
			{
				sectorData = readSectorDataFromHandle(hFile, i, (numsectors - i >= 1024ull) ? 1024ull:(numsectors - i), sectorsize);
				if (sectorData == NULL)
				{
					if(fileLocation) free(fileLocation);
					delete sectorData;
					removeLockOnVolume(hVolume);
					CloseHandle(hRawDisk);
					CloseHandle(hFile);
					CloseHandle(hVolume);
					status = STATUS_IDLE;
					fileLocation = NULL;
					sectorData = NULL;
					hRawDisk = INVALID_HANDLE_VALUE;
					hFile = INVALID_HANDLE_VALUE;
					hVolume = INVALID_HANDLE_VALUE;
					bCancel->setEnabled(false);
					bWrite->setEnabled(true);
					bRead->setEnabled(true);
					return;
				}
				if (!writeSectorDataToHandle(hRawDisk, sectorData, i, (numsectors - i >= 1024ull) ? 1024ull:(numsectors - i), sectorsize))
				{
					if(fileLocation) free(fileLocation);
					delete sectorData;
					removeLockOnVolume(hVolume);
					CloseHandle(hRawDisk);
					CloseHandle(hFile);
					CloseHandle(hVolume);
					status = STATUS_IDLE;
					fileLocation = NULL;
					sectorData = NULL;
					hRawDisk = INVALID_HANDLE_VALUE;
					hFile = INVALID_HANDLE_VALUE;
					hVolume = INVALID_HANDLE_VALUE;
					bCancel->setEnabled(false);
					bWrite->setEnabled(true);
					bRead->setEnabled(true);
					return;
				}
				delete sectorData;
				sectorData = NULL;
				QCoreApplication::processEvents();
				if (timer.elapsed() >= 1000)
				{
					mbpersec = (((double)sectorsize * (i - lasti)) * (1000.0 / timer.elapsed())) / 1024.0 / 1024.0;
					statusbar->showMessage(QString("%1Mb/s").arg(mbpersec));
					timer.start();
					lasti = i;
				}
				progressbar->setValue(i);
				QCoreApplication::processEvents();
			}
			if(fileLocation) free(fileLocation);
			removeLockOnVolume(hVolume);
			CloseHandle(hRawDisk);
			CloseHandle(hFile);
			CloseHandle(hVolume);
			fileLocation = NULL;
			sectorData = NULL;
			hRawDisk = INVALID_HANDLE_VALUE;
			hFile = INVALID_HANDLE_VALUE;
			hVolume = INVALID_HANDLE_VALUE;
		}
		else if (!fileinfo.exists() || !fileinfo.isFile())
			QMessageBox::critical(NULL, "File Error", "The selected file does not exist.");
		else if (!fileinfo.isReadable())
			QMessageBox::critical(NULL, "File Error", "You do not have permision to read the selected file.");
		else if (fileinfo.size() == 0)
			QMessageBox::critical(NULL, "File Error", "The specified file contains no data.");
		progressbar->reset();
		statusbar->showMessage("Done.");
		bCancel->setEnabled(false);
		bWrite->setEnabled(true);
		bRead->setEnabled(true);
	}
	else
		QMessageBox::critical(NULL, "File Error", "Please specify an image file to use.");
	if (status == STATUS_EXIT)
		close();
	status = STATUS_IDLE;

	
}

@end


/**********************************************************************
 *  This program is free software; you can redistribute it and/or     *
 *  modify it under the terms of the GNU General Public License       *
 *  as published by the Free Software Foundation; either version 2    *
 *  of the License, or (at your option) any later version.            *
 *                                                                    *
 *  This program is distributed in the hope that it will be useful,   *
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of    *
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the     *
 *  GNU General Public License for more details.                      *
 *                                                                    *
 *  You should have received a copy of the GNU General Public License *
 *  along with this program; if not, write to the Free Software       *
 *  Foundation, Inc., 51 Franklin Street, Fifth Floor,                *
 *  Boston, MA  02110-1301, USA.                                      *
 *                                                                    *
 *  ---                                                               *
 *  Copyright (C) 2009, Justin Davis <tuxdavis@gmail.com>             *
 **********************************************************************/

#ifndef WINVER
#define WINVER 0x0500
#endif


int getPhysicalDeviceID(int device)
{
	HANDLE hDevice;
	DWORD bytesreturned;
	BOOL bResult;
	DEVICE_NUMBER deviceInfo;
	char devicename[] = "\\\\.\\A:";
	devicename[4] += device;
	hDevice = CreateFile(devicename, 0, 0, NULL, OPEN_EXISTING, 0, NULL);
	if (hDevice == INVALID_HANDLE_VALUE)
	{
		char *errormessage=NULL;
		FormatMessage(FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_ALLOCATE_BUFFER, NULL, GetLastError(), 0, errormessage, 0, NULL);
		//QMessageBox::critical(NULL, "File Error", QString("An error occurred when attempting to get a handle on the device.\nThis usually means something is currently accessing the device; please close all applications and try again.\n\nError %1: %2").arg(GetLastError()).arg(errormessage));
		LocalFree(errormessage);
	}
	bResult = DeviceIoControl(hDevice, IOCTL_STORAGE_GET_DEVICE_NUMBER, NULL, 0, &deviceInfo, sizeof(deviceInfo), &bytesreturned, NULL);
	if (!bResult)
	{
		char *errormessage=NULL;
		FormatMessage(FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_ALLOCATE_BUFFER, NULL, GetLastError(), 0, errormessage, 0, NULL);
		//QMessageBox::critical(NULL, "File Error", QString("An error occurred when attempting to get a handle on the device.\nThis usually means something is currently accessing the device; please close all applications and try again.\n\nError %1: %2").arg(GetLastError()).arg(errormessage));
		LocalFree(errormessage);
		return -1;
	}
	CloseHandle(hDevice);
	return (int)deviceInfo.DeviceNumber;
}

HANDLE getHandleOnFile(char *filelocation, DWORD access)
{
	HANDLE hFile;
	char *location = malloc(5 + strlen(filelocation));
	sprintf(location, "\\\\.\\%s", filelocation);
	hFile = CreateFile(location, access, 0, NULL, (access == GENERIC_READ) ? OPEN_EXISTING:CREATE_ALWAYS, 0, NULL);
	if (hFile == INVALID_HANDLE_VALUE)
	{
		char *errormessage=NULL;
		FormatMessage(FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_ALLOCATE_BUFFER, NULL, GetLastError(), 0, errormessage, 0, NULL);
		//QMessageBox::critical(NULL, "File Error", QString("An error occurred when attempting to get a handle on the file.\nError %1: %2").arg(GetLastError()).arg(errormessage));
		LocalFree(errormessage);
	}
	free(location);
	return hFile;
}

HANDLE getHandleOnDevice(int device, DWORD access)
{
	HANDLE hDevice;
	
	char devicename[256];
	sprintf(devicename, "\\\\.\\PhysicalDrive%d", device);
	hDevice = CreateFile(devicename, access, FILE_SHARE_READ | FILE_SHARE_WRITE, NULL, OPEN_EXISTING, 0, NULL);
	if (hDevice == INVALID_HANDLE_VALUE)
	{
		printf("Device Error");
		//char *errormessage=NULL;
		//FormatMessage(FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_ALLOCATE_BUFFER, NULL, GetLastError(), 0, errormessage, 0, NULL);
		//QMessageBox::critical(NULL, "Device Error", QString("An error occurred when attempting to get a handle on the device.\nError %1: %2").arg(GetLastError()).arg(errormessage));
		//LocalFree(errormessage);
	}
	return hDevice;
}

HANDLE getHandleOnVolume(int volume, DWORD access)
{
	HANDLE hVolume;
	char volumename[] = "\\\\.\\A:";
	volumename[4] += volume;
	hVolume = CreateFile(volumename, access, FILE_SHARE_READ | FILE_SHARE_WRITE, NULL, OPEN_EXISTING, 0, NULL);
	if (hVolume == INVALID_HANDLE_VALUE)
	{
		char *errormessage=NULL;
		FormatMessage(FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_ALLOCATE_BUFFER, NULL, GetLastError(), 0, errormessage, 0, NULL);
		//QMessageBox::critical(NULL, "Volume Error", QString("An error occurred when attempting to get a handle on the volume.\nError %1: %2").arg(GetLastError()).arg(errormessage));
		LocalFree(errormessage);
	}
	return hVolume;
}

bool getLockOnVolume(HANDLE handle)
{
	DWORD bytesreturned;
	BOOL bResult;
	bResult = DeviceIoControl(handle, FSCTL_LOCK_VOLUME, NULL, 0, NULL, 0, &bytesreturned, NULL);
	if (!bResult)
	{
		char *errormessage=NULL;
		FormatMessage(FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_ALLOCATE_BUFFER, NULL, GetLastError(), 0, errormessage, 0, NULL);
		//QMessageBox::critical(NULL, "Lock Error", QString("An error occurred when attempting to lock the volume.\nError %1: %2").arg(GetLastError()).arg(errormessage));
		LocalFree(errormessage);
	}
	return (bResult == TRUE);
}

bool removeLockOnVolume(HANDLE handle)
{
	DWORD junk;
	BOOL bResult;
	bResult = DeviceIoControl(handle, FSCTL_UNLOCK_VOLUME, NULL, 0, NULL, 0, &junk, NULL);
	if (!bResult)
	{
		char *errormessage=NULL;
		FormatMessage(FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_ALLOCATE_BUFFER, NULL, GetLastError(), 0, errormessage, 0, NULL);
		//QMessageBox::critical(NULL, "Unlock Error", QString("An error occurred when attempting to unlock the volume.\nError %1: %2").arg(GetLastError()).arg(errormessage));
		LocalFree(errormessage);
	}
	return (bResult == TRUE);
}

bool unmountVolume(HANDLE handle)
{
	DWORD junk;
	BOOL bResult;
	bResult = DeviceIoControl(handle, FSCTL_DISMOUNT_VOLUME, NULL, 0, NULL, 0, &junk, NULL);
	if (!bResult)
	{
		char *errormessage=NULL;
		FormatMessage(FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_ALLOCATE_BUFFER, NULL, GetLastError(), 0, errormessage, 0, NULL);
		//QMessageBox::critical(NULL, "Dismount Error", QString("An error occurred when attempting to dismount the volume.\nError %1: %2").arg(GetLastError()).arg(errormessage));
		LocalFree(errormessage);
	}
	return (bResult == TRUE);
}

bool isVolumeUnmounted(HANDLE handle)
{
	DWORD junk;
	BOOL bResult;
	bResult = DeviceIoControl(handle, FSCTL_IS_VOLUME_MOUNTED, NULL, 0, NULL, 0, &junk, NULL);
	return (bResult == FALSE);
}

char *readSectorDataFromHandle(HANDLE handle, unsigned long long startsector, unsigned long long numsectors, unsigned long long sectorsize)
{
	unsigned long bytesread;
	char *data = malloc(sectorsize * numsectors);
	SetFilePointer(handle, startsector * sectorsize, NULL, FILE_BEGIN);
	if (!ReadFile(handle, data, sectorsize * numsectors, &bytesread, NULL))
	{
		char *errormessage=NULL;
		FormatMessage(FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_ALLOCATE_BUFFER, NULL, GetLastError(), 0, errormessage, 0, NULL);
		//QMessageBox::critical(NULL, "Read Error", QString("An error occurred when attempting to read data from handle.\nError %1: %2").arg(GetLastError()).arg(errormessage));
		LocalFree(errormessage);
		free(data);
		data = NULL;
	}
	return data;
}

bool writeSectorDataToHandle(HANDLE handle, char *data, unsigned long long startsector, unsigned long long numsectors, unsigned long long sectorsize)
{
	unsigned long byteswritten;
	BOOL bResult;
	SetFilePointer(handle, startsector * sectorsize, NULL, FILE_BEGIN);
	bResult = WriteFile(handle, data, sectorsize * numsectors, &byteswritten, NULL);
	if (!bResult)
	{
		char *errormessage=NULL;
		FormatMessage(FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_ALLOCATE_BUFFER, NULL, GetLastError(), 0, errormessage, 0, NULL);
		//QMessageBox::critical(NULL, "Write Error", QString("An error occurred when attempting to write data from handle.\nError %1: %2").arg(GetLastError()).arg(errormessage));
		LocalFree(errormessage);
	}
	return (bResult == TRUE);
}

unsigned long long getNumberOfSectors(HANDLE handle, unsigned long long *sectorsize)
{
	DWORD junk;
	DISK_GEOMETRY geometry;
	BOOL bResult;
	bResult = DeviceIoControl(handle, IOCTL_DISK_GET_DRIVE_GEOMETRY, NULL, 0, &geometry, sizeof(geometry), &junk, NULL);
	if (!bResult)
	{
		char *errormessage=NULL;
		FormatMessage(FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_ALLOCATE_BUFFER, NULL, GetLastError(), 0, errormessage, 0, NULL);
		//QMessageBox::critical(NULL, "Device Error", QString("An error occurred when attempting to get the device's geometry.\nError %1: %2").arg(GetLastError()).arg(errormessage));
		LocalFree(errormessage);
		return 0;
	}
	if (sectorsize != NULL)
		*sectorsize = (unsigned long long)geometry.BytesPerSector;
	return (unsigned long long)geometry.Cylinders.QuadPart * (unsigned long long)geometry.TracksPerCylinder * (unsigned long long)geometry.SectorsPerTrack;
}

unsigned long long getFileSizeInSectors(HANDLE handle, unsigned long long sectorsize)
{
	LARGE_INTEGER filesize;
	GetFileSizeEx(handle, &filesize);
	return (unsigned long long)filesize.QuadPart / sectorsize;
}

bool spaceAvailable(char *location, unsigned long long spaceneeded)
{
	ULARGE_INTEGER freespace;
	BOOL bResult;
	bResult = GetDiskFreeSpaceEx(location, NULL, NULL, &freespace);
	if (!bResult)
	{
		char *errormessage=NULL;
		FormatMessage(FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_ALLOCATE_BUFFER, NULL, GetLastError(), 0, errormessage, 0, NULL);
		//QMessageBox::critical(NULL, "Free Space Error", QString("Failed to get the free space on drive %1.\nError %2: %3\nChecking of free space will be skipped.").arg(location).arg(GetLastError()).arg(errormessage));
		return true;
	}
	return (spaceneeded <= freespace.QuadPart);
}
#endif