//
//  DSDTPatcher.m
//  NetbookInstaller
//
//  Created by Evan Lojewski on 5/18/09.
//  Copyright 2009. All rights reserved.
//

#import "DSDTPatcher.h"

@implementation DSDTPatcher
- (BOOL) applyPatchFiles
{
	NSArray* configFile;
	NSString* patchDir;
	
	
	
	switch(machineType) {
		case MINI9:
			patchDir = [[[NSBundle mainBundle] resourcePath] stringByAppendingString: @"/SupportFiles/DSDTPatches/Mini 9 Patches"];
			break;
		case MINI10V:
			patchDir = [[[NSBundle mainBundle] resourcePath] stringByAppendingString: @"/SupportFiles/DSDTPatches/Mini 10v Patches"];
			break;
		case LENOVO_S10:
			patchDir = [[[NSBundle mainBundle] resourcePath] stringByAppendingString: @"/SupportFiles/DSDTPatches/Lenovo S10 Patches"];
			break;
		default:
			// No patching for hardware we don't recognize
			return YES;
			break;
	}
	configFile = [[NSArray alloc] initWithContentsOfFile:[patchDir stringByAppendingString:@"/config.txt"]];
	
	if(configFile = nil) return NO;
	
	// Loop thourgh the patch file
	for(int i = 0; i < [configFile count]; i++)
	{
		NSString* string = [configFile objectAtIndex:i];
		NSString* patch;
		NSString* fileNameString;
		NSRange search;
		NSRange fileName;
		search.location = 0;
		search.length = 2;
		if([string compare: @"//" options: 0 range: search] == 0) continue;		// Line has been commented out
		
		search = [string rangeOfString:@":"];	// Start of file name is fileNameStarte.location + length
		fileName.location = search.location + search.length;
		search.length = [string length] - search.location;
		search = [string rangeOfString:@":" options:0 range:search];
		
		fileName.length = search.location -  fileName.location;
		
		fileNameString = [string substringWithRange:fileName];
		
		
		// TODO Read file
		patch = [[NSString alloc] initWithContentsOfFile:[[[patchDir stringByAppendingString:@"/"] stringByAppendingString:fileNameString] stringByAppendingString:@".txt"]];
	
//		NSString 
		
		
	}
	
	

	
	//[patchedDSDT rangeOfString
	
	return YES;
	
}

- (BOOL) applyHPETPatch
{
	return NO;
}

- (BOOL) applyRTCPatch
{
	return NO;
}

- (BOOL) applyVersionPatch
{
	return NO;
}


- (BOOL) applyMiscPatch
{
	return NO;
}

//- (BOOL) checkIfPatched;

- (NSData*) getDSDT
{
	return nil;
}

- (NSString*) decompileDSDT: (NSData*) data
{
	return nil;
}

- (NSData*) compileDSDT: (NSString*) data
{
	return nil;
}



#if 0
- (BOOL) applyPatchFiles
{
	printf("\nPatching...\n\n");
	while(!feof(configFile)) {
		// Read the next line
		if(fgets(buffer, BUFFER_SIZE, configFile)) {
			
			// TODO: verify last chars are the CRLF / remove them
			if(buffer[0] == '/') continue;	// If line begins with /, consider it a comment
			
			// Vars used in while loop
			char* token;
			int index = 0;
			int loop = 0;
			char name[200];
			char searchString[200]; // = "Device (BAT1";
			//char* patchString;
			
			
			token = strtok(buffer, ":"); // If there are none, NULL will bre returned and the line will be ignored
			while (token != NULL)
			{
				switch(index) {
					case 0:		// Save the name
						for(loop=0; loop <= strlen(token); loop++)	name[loop] = token[loop]; // copy the string, we could use sprintf too..
						break;
					case 1:
						for(loop=0; loop <= strlen(token); loop++)	searchString[loop] = token[loop];	// -1 to remove the \r\n
						//printf("Patching %s with patches/%s.txt; searching for: %s\n", origDSDTPath, name, searchString);// patch function\n");	
						
						//if ((origDSDT = fopen("./patched_dsdt.dsl", "r"))== NULL) {
							if((origDSDT = fopen(origDSDTPath, "r")) == NULL ) {
								printf("\tCould not open file ./patched_dsd.dsl or %s\n\n", origDSDTPath);
								return 0;
							}
						}							// Open Files
						if ((patchedDSDT=fopen("./latest_dsdt.dsl","w"))==NULL) {
							printf("\tCould not create file ./latest_dsdt.dsl\n\n");
							return 0;
						}					// Open Files
						
						openBrackets = 0;				// count of open {
						int patching = 1;
						currLine=0;
						
						
						UInt32 num= [dsdt count];
						UInt32 index = 0;
						while(index < num){
							index++
							if (foundDevice(dsdt, searchString) ) {

									
									while(patching) {			// Read untill teh end of the device / method / block of code
										
										fgets(buffer, BUFFER_SIZE, origDSDT);	// Get a new Line
										if (cmpStr(buffer, "{")) openBrackets++;		// If its a { we increment open
										if (cmpStr(buffer, "}")) openBrackets--;	// If its a } we decrement open
										if(openBrackets == 0) {				// If there are no more open { we reached the Device RTC end -> break
											printf("\tReplacing...\n");
											
											char fileString[200];
											sprintf(fileString, "patches/%s.txt", name);
											FILE *patchFile = fopen(fileString, "r");
											if(patchFile == NULL) {
												printf("\tUnable to read patch file %s\n", fileString);
												return 1;
											}
											// Read in the file and write it to the patched file
											while(!feof(patchFile)) {
												if(fgets(buffer, BUFFER_SIZE, patchFile))
													fprintf(patchedDSDT, buffer);
											}
											printf("\tPatched.\n\n");
											fclose(patchFile);
											patching = 0;
											
											
											// Read the next line so that the next fprintf doesn't write something twice
											fgets(buffer, BUFFER_SIZE, origDSDT);	// Get a new Line
										}
									}
									
								} 
								fprintf(patchedDSDT, buffer);			// Write the rest as it is to the patched DSDT
							}
						}
						fclose(origDSDT);
						fclose(patchedDSDT);
						if(patching == 1) {
							printf("\tAn error occured while patching.\n\n");
						} else {
							system("cp latest_dsdt.dsl patched_dsdt.dsl");
							system("rm latest_dsdt.dsl");
						}
						
						// TODO: move the latest_dsdt to a new fiel to be patched
						//closeFiles();
						
						
						break;
					default:
						break;
						//printf("An error occured while reading the config file\n");
						//return 1;
				}
				index++;
				//printf ("%s\n",token);
				token = strtok(NULL, ":");
			}
			// Split it
			
			
			//printf("Read line: %s", s);
		}
	}
	fclose(configFile);
}
- (BOOL) applyHPETPatch
{
	if ((origDSDT=fopen("./patched_dsdt.dsl","r"))==NULL) {
		printf("Could not open file ./patched_dsdt.dsl\n\n");
		return 0;
	}				// Open Files
	if ((patchedDSDT=fopen("./latest_dsdt.dsl","w"))==NULL) {
		printf("Could not create file ./latest_dsdt.dsl\n\n");
		return 0;
	}
	openBrackets = 0;				// count of open {
	int start = 0;
	
	printf("\nPatching HPET...\n\n");
	
	if (writeFixedHPET) {
		if(!HPETDeviceFound) {												// If there is no HPET Device in your DSDT already
			printf("HPET Device will be overwritten...\n");
			
			openBrackets=0;						// count of open {
			int written=0;				// stores if the HPET is already written
			HPETDeviceFound=0;
			while(!feof(origDSDT)) {
				if(fgets(buffer, BUFFER_SIZE, origDSDT)) {
					foundHPETDevice(buffer);
				}
			}
			if(!HPETDeviceFound) goto nextone;
			fseek(origDSDT, 0, SEEK_SET);
			// We will search for the RTC device and add a HPET device after that
			while(!feof(origDSDT)) {
				if(fgets(buffer, BUFFER_SIZE, origDSDT)) {
					if(foundHPETDevice(buffer)) {				// RTC Device found
						while(1) {
							fgets(buffer, BUFFER_SIZE, origDSDT);
							if (cmpStr(buffer, "{")) openBrackets++;
							if (cmpStr(buffer, "}")) openBrackets--;
							if (!openBrackets) break;
							printf("%i: %s\n",openBrackets, buffer);
						}
						if(!written) {						// we reached the end of rtc device, write the hpet here
							fprintf(patchedDSDT,fixedHPET);
							printf("New HPET written\n\n");
							written=1;
							fgets(buffer, BUFFER_SIZE, origDSDT);		// get next line
						}
					}
					fprintf(patchedDSDT, buffer);		// write that line
				}
			}
			closeFiles();					// close the files
			return 1;
		}
	}
	
	
	// Patching the HPET -> adding IRQ's
	while(!feof(origDSDT)) {
		if(fgets(buffer, BUFFER_SIZE, origDSDT)) {
			
			// Write as is until we reach the HPET
			if (foundHPETDevice(buffer)) {
				// We reached to HPET Device, search for "ResourceTemplate ()" now
				fprintf(patchedDSDT, buffer);		// Write the Device line
				
				start++;
				
				while(start) {			// While we didnt reach the end of the HPET Device
					fgets(buffer, BUFFER_SIZE, origDSDT);	// Get a new Line
					if (cmpStr(buffer,"{")) openBrackets++;		// If its a { we increment open
					else if (cmpStr(buffer,"}")) openBrackets--;	// If its a } we decrement open
					if(!openBrackets) break;				// If there are no more open { we reached the Device HPET end -> break
					if (cmpStr(buffer, RESOURCETEMP)) {			// Search for "ResourceTemplate ()"
						fprintf(patchedDSDT, buffer);						// Write the "ResourceTemplate ()"
						fgets(buffer, BUFFER_SIZE, origDSDT);						// Get the {
						fprintf(patchedDSDT, buffer);						// Write the {
						fprintf(patchedDSDT, HPETIRQ);				// Write the IRQ's to HPET Device
						fgets(buffer, BUFFER_SIZE, origDSDT);						// We get the next line
						while(cmpStr(buffer, IRQ)) {						// If there were already IRQ's skip that ones
							fgets(buffer, BUFFER_SIZE, origDSDT); fgets(buffer, BUFFER_SIZE, origDSDT);
						}
						fprintf(patchedDSDT, buffer);
						printf("IRQ's written to HPET\n");
						printf("HPET patched\n");
						openBrackets=0;												// We are done here and say there are no more open {
					}
					
					if(openBrackets!=0) fprintf(patchedDSDT, buffer);	// While we havent reached the Device HPET end we write the lines to the patched dsdt
					
				}
				
			}
			fprintf(patchedDSDT, buffer);			// Write the rest to the patched DSDT
		}
		
	}
nextone:
	closeFiles();
	
	if(!HPETDeviceFound) {												// If there is no HPET Device in your DSDT already
		printf("No HPET Device found, adding one\n");
		
		if ((origDSDT=fopen("./patched_dsdt.dsl","r"))==NULL) {
			printf("Could not open file ./patched_dsdt.dsl\n\n");
			return 0;
		}		// Open File
		if ((patchedDSDT=fopen("./latest_dsdt.dsl","w"))==NULL) {
			printf("Could not create file ./latest_dsdt.dsl\n\n");
			return 0;
		}		// Open File
		
		openBrackets=0;						// count of open {
		int written=0;				// stores if the HPET is already written
		RTCDeviceFound=0;
		
		// We will search for the RTC device and add a HPET device after that
		while(!feof(origDSDT)) {
			if(fgets(buffer, BUFFER_SIZE, origDSDT)) {
				if(foundRTCDevice(buffer)) {				// RTC Device found
					fprintf(patchedDSDT, buffer);			// wrtie the Device (RTC
					while(1) {
						fgets(buffer, BUFFER_SIZE, origDSDT);
						if (cmpStr(buffer, "{")) openBrackets++;
						if(cmpStr(buffer, "}")) openBrackets--;
						fprintf(patchedDSDT, buffer);
						if (!openBrackets) break;
						
					}
					if(!written) {						// we reached the end of rtc device, write the hpet here
						fprintf(patchedDSDT, fixedHPET);
						printf("New HPET written\n\n");
						written=1;
						fgets(buffer, BUFFER_SIZE, origDSDT);		// get next line
					}
				}
				fprintf(patchedDSDT, buffer);		// write that line
			}
		}
		closeFiles();					// close the files
	}
	return 1;
}

- (BOOL) applyRTCPatch 
{
	if ((origDSDT=fopen("./patched_dsdt.dsl","r"))==NULL) {
		printf("Could not open file %s\n\n",origDSDTPath);
		return 0;
	}							// Open Files
	if ((patchedDSDT=fopen("./latest_dsdt.dsl","w"))==NULL) {
		printf("Could not create file ./latest_dsdt.dsl\n\n");
		return 0;
	}					// Open Files
	
	openBrackets = 0;				// count of open {
	int start = 0;
	
	printf("Patching RTC...\n\n");
	currLine=0;
	
	// Patching the RTC -> removing IRQ
	while(!feof(origDSDT)) {
		if(fgets(buffer, BUFFER_SIZE, origDSDT)) {
			currLine++;	
			// Write as is until we reach the RTC Device
			if (foundRTCDevice(buffer)) {
				// We reached to RTC Device, search for IRQ now
				fprintf(patchedDSDT, buffer);		// Write the Device line
				
				start++;
				
				while(start) {			// While we didnt reach the end of the RTC Device
					fgets(buffer, BUFFER_SIZE, origDSDT);	// Get a new Line
					if (cmpStr(buffer,"{")) openBrackets++;		// If its a { we increment open
					if (cmpStr(buffer,"}")) openBrackets--;	// If its a } we decrement open
					if(!openBrackets) {				// If there are no more open { we reached the Device RTC end -> break
						printf("No IRQ found in RTC Device, should be fine\n");
						break;
					}
					if (cmpStr(buffer,IRQ)) {			// Search for IRQ
						printf("Found IRQ in RTC Device, removing it\n");	// We found one
						printf("%s",buffer);
						fgets(buffer, BUFFER_SIZE, origDSDT); fgets(buffer, BUFFER_SIZE, origDSDT);		// Skip the IRQ
						printf("RTC patched\n\n");
						break;
						openBrackets=0;												// We are done here and say there are no more open {
					}
					if(openBrackets!=0) fprintf(patchedDSDT, buffer);	// While we havent reached the Device RTC end we write the lines to the patched dsdt
				}
			}
			fprintf(patchedDSDT, buffer);			// Write the rest as it is to the patched DSDT
		}
	}
	closeFiles();
	
	return 1;
}

- (BOOL) applyVersionPatch
{
	int v = 0;
	char *inbuf, *outbuf;
	FILE *f;
	char *replfrom, *replto, *inptr,*outptr;
	int flen;
	printf ("Which OS to emulate? [0=Darwin,1=WinXP, 2=WinVista]\n");
	printf ("\tAssuming Darwin\n");
	//scanf ("%d", &v);
	switch (v)
    {
		case 1:
			replfrom="_OSI (\"Windows 2001\")";
			replto="LOr (_OSI (\"Darwin\"), _OSI (\"Windows 2001\"))";
			break;
		case 2:
			replfrom="_OSI (\"Windows 2006\")";
			replto="LOr (_OSI (\"Darwin\"), _OSI (\"Windows 2006\"))";
			break;
		default:
			return;
    }
	f=fopen ("./patched_dsdt.dsl", "rb");
	fseek (f, 0, SEEK_END);
	flen=ftell (f);
	fseek (f, 0, SEEK_SET);
	inbuf=malloc (flen);
	fread (inbuf, flen,1, f);
	fclose (f);
	outbuf=malloc (2*flen);
	for (inptr=inbuf,outptr=outbuf;inptr<inbuf+flen-strlen (replfrom);)
    {
		if (memcmp (inptr,replfrom,strlen (replfrom)))
		{
			*outptr=*inptr;
			outptr++;
			inptr++;
			continue;
		}
		memcpy (outptr, replto, strlen (replto));
		outptr+=strlen (replto);
		inptr+=strlen (replfrom);
    }
	memcpy (outptr, inptr, flen-(inptr-inbuf));
	outptr+=flen-(inptr-inbuf);
	f=fopen ("./latest_dsdt.dsl", "wb");
	fwrite (outbuf, outptr-outbuf,1,f);
	fclose (f);
	
}
- (BOOL) applyMiscPatch
{
	char *ALIAS;
	char *ALIAS2;
	char *buff;
	
	int firstfreet=0; // First unused prefix of form T%d_
	char freetprefix[40];
	
starthere:
	
	if ((origDSDT=fopen("./patched_dsdt.dsl","r"))==NULL) {
		printf("Could not open file ./patched_dsdt.dsl\n\n");
		return 0;
	}			// open files
	if ((patchedDSDT=fopen("./latest_dsdt.dsl","w"))==NULL) {
		printf("Could not create file ./latest_dsdt.dsl\n\n");
		return 0;
	}
	
	printf("Fixing various Issues...\n\n");
	
	/*Finding first unused prefix of form T%d_. Ugly, inefficient but gets job done*/
	for (firstfreet=0;;firstfreet++)
	{
		int isfree=1;
		sprintf(freetprefix,"T%d_",firstfreet);
		while(!feof(origDSDT))
			if(fgets(buffer, BUFFER_SIZE, origDSDT) && cmpStr(buffer, freetprefix))
			{
				isfree=0;
				break;
			}
		fseek(origDSDT,0,SEEK_SET);
		if (isfree)
			break;
	}
	
	while(!feof(origDSDT)) {
		if(fgets(buffer, BUFFER_SIZE, origDSDT)) {
			
			if(cmpStr(buffer, issue1)) {				// Found an issue, saw this until yet just for dell dsdt, we skip the * in device name
				printf("Found an issue\n\n");
				int i=0;
				char buff[100];
				int add=0;
				
				for(;i<strlen(buffer);i++) {
					if(buffer[i]=='*') {
						printf("Found");
						add=1;
					}
					strcpy(&buff[i],&buffer[i+add]); //buff[i]=s[i+add];
				}
				printf("%s", buffer);
				printf("Fixed %s\n\n",buff);
				fprintf(patchedDSDT,buff);		// write the modified line
				goto dontwrite;			
			}					// Device Name fix
			
			
			if(cmpStr(buffer, PROCESSOR)) {				// Here is the CPU Aliases fix, we just skip the alias lines
				fprintf(patchedDSDT, buffer);
				if(fgets(buffer, BUFFER_SIZE, origDSDT)) {
					if(cmpStr(buffer, issue2)) {
						printf("Found an issue\n");
						printf("Found   %s", buffer);
						printf("Skipped %s\n", buffer);
						int i=0;
						int b=0;
						
						ALIAS=malloc(strlen(buffer)+2);
						ALIAS2=malloc(strlen(buffer)+2);
						buff=malloc(strlen(buffer)+2);
						
						strcpy(buff,buffer);
						
						for(;i<=strlen(buffer);i++) {
							if(buffer[i]=='(') {
								i++;
								for(;i<=strlen(buffer);i++) {
									if(buffer[i]!=',') {
										ALIAS[b] = buffer[i];
										b++;
									} else goto next;
								}
							}
						}
					next:
						ALIAS[b+1]='\0';
						i+=2;
						b=0;
						for(;i<=strlen(buffer);i++) {
							if(buffer[i]!=')') {
								ALIAS2[b] = buffer[i];
								b++;
							} else break;
						}
					next2:
						ALIAS2[b+1]='\0';
						
						while(!feof(origDSDT)) {
							if(fgets(buffer, BUFFER_SIZE, origDSDT)) {
								if(cmpStr(buffer, ALIAS2)) {
									buff=malloc(strlen(buffer)+2);
									strcpy(buff,buffer);
									i=0;
									while(!cmpStr2(buffer,ALIAS2,i)) i++;
									printf("Found    %s", buff);
									replaceAlias(buffer, ALIAS, i);
									printf("Replaced %s",buffer);
								}
								fprintf(patchedDSDT, buffer);
							}
						}
						closeFiles();
						system("cp ./latest_dsdl.dsl ./latest2_dsdt.dsl");
						origDSDT=fopen("./latest_dsdt.dsl","r");
						patchedDSDT=fopen("./latest2_dsdt.dsl","w");
					}
				}
			}				// CPU Aliases Fix
			
			if(cmpStr(buffer, issue3)) {						// "Method local variable is not initialized (Local0)" fix
				fprintf(patchedDSDT,fix3);
				printf("Found an issue\n");
				printf("Found   %s", buffer);
				printf("Fixed   %s\n", fix3);	
				goto dontwrite;
			}
			if(cmpStr(buffer, issue4)) {						// "_T_" fix
				char *tmp, *tmpptr;
				int i;
				printf("Found an issue\n");
				printf("Found   %s", buffer);
				tmpptr=tmp=malloc(strlen(buffer)*5+10);
				for (i = 0 ; i <= strlen(buffer); )
				{
					if ( strncmp(buffer+i, issue4, strlen(issue4) ) == 0 )
					{
						strcpy(tmpptr,freetprefix);
						tmpptr+=strlen(freetprefix);
						i+=strlen(issue4);
					}
					else 
					{
						*tmpptr=buffer[i];
						tmpptr++;
						i++;
					}
					
				}
				*tmpptr=0;
				fprintf(patchedDSDT,tmp);
				printf("Fixed   %s\n\n", tmp);
				free(tmp);
				goto dontwrite;
			}
			
			if(cmpStrWild(buffer, issue5) && !cmpStr(buffer, fix5)) {						// "Mute fix
				fprintf(patchedDSDT,fix5);
				printf("Found an issue\n");
				printf("Found   %s", buffer);
				printf("Fixed   %s\n", fix5);	
				goto dontwrite;
			}
			
			fprintf(patchedDSDT, buffer);				// Write the line
		dontwrite:
			printf("");
			//printf("%s", buffer);
		}
	}
	closeFiles();						// Close files
	
	printf("Done\n\n");
	system("cp latest2_dsdt.dsl latest_dsdt.dsl ");
	system("rm latest2_dsdt.dsl");
	
	return 1;
}

//- (BOOL) checkIfPatched;

- (NSData*) getDSDT;
- (NSString*) decompileDSDT: NSData* data;;
- (NSData*) compileDSDT: NSString* data;
#endif
@end
#if 0


#include <stdio.h>
#include <string.h>
#include <stdlib.h>


#define VERSION			"1.0.2a"
#define BUFFER_SIZE		2048

void patchVersion ();

// Variables
int debug=0, forceBuild=0, currLine=0, openBrackets=0, otherDSDTFileGiven=0, writeFixedHPET=0, fixmini9=0;

char buffer[BUFFER_SIZE]; // Line Buffer


// Paths to files
char origDSDTPath[50] = "./dsdt.dsl", patchedDSDTPath[] ="./dsdt_fixed.txt"; 

// THis is the HPET device we write if no HPET device is found
char fixedHPET[]	= "		Device (HPET)\n                {\n                    Name (_HID, EisaId (\"PNP0103\"))\n                    Name (ATT3, ResourceTemplate ()\n                    {\n                        IRQNoFlags ()\n                            {0}\n                        IRQNoFlags ()\n                            {8}\n                        Memory32Fixed (ReadWrite,\n                            0xFED00000,         // Address Base\n                            0x00000400,         // Address Length\n                            )\n                    })\n                    Name (ATT4, ResourceTemplate ()\n                    {\n                    })\n                    Method (_STA, 0, NotSerialized)\n                    {\n                        Return (0x0F)\n                    }\n                    Method (_CRS, 0, NotSerialized)\n                    {\n                        Return (ATT3)\n                    }\n                }\n";


// These are the IRQ's that are required in HPET
char HPETIRQ[]		= "                        IRQNoFlags ()\n                            {0}\n                        IRQNoFlags ()\n                            {8}\n";
// File pointers
FILE *origDSDT, *patchedDSDT;

// Findigs
int HPETDeviceFound=0;
int RTCDeviceFound=0;
int RTCIRQFound=0;
int BATDeviceFound=0;
int fn8DeviceFound=0;

// Device Strings
char RTCDevice[] = "Device (RTC";				// RTC device
char RTCDevice2[] = "PNP0B00";					// RTC device
char HPETDevice[] = "Device (HPET";				// HPET device
char HPETDevice2[] = "PNP0103";					// HPET device
//char BAT1Device[] = "Device (BAT1";				// Battery device
//char FN8Device[] = "Method (_Q1C";				// Method tha thandels the FN-8 button press

char IRQ[] = "IRQNoFlags ()";					// needed for RTC fix
char RESOURCETEMP[] = "ResourceTemplate ()";	// search for this entry when we dont find "human" device name like HPET but PNP0103
char PROCESSOR[] = "Processor (";				// processor string, we need this for searching for cpu aliases

// various issues
char issue1[] = ", \"*";						// devices must not begin with *   saw it on some dell
char issue2[] = "Alias (";						// CPU aliases
char issue3[] = "Store (Local0, Local0)"; char fix3[] = "Store (\"Local0\", Local0)";		// Local0 issue
char issue4[] = "_T_";
char issue5[] = "Acquire (MUTE, 0x????)";
char fix5[] = "Acquire (MUTE, 0xFFFF)\n";

void flagCheck(int argc, const char *argv[]) {
	// Todo chang eto a while / switch loop
	if (argc>1) {
		int i=1;	// Skip the first one
		for (i;i<argc;i++) {
			if (!strcmp(argv[i], "-d")) debug=1;			// checks for debug flag
			else if (!strcmp(argv[i], "-f")) forceBuild=1;	// checks for force build flag
			else if (!strcmp(argv[i], "-newHPET")) writeFixedHPET=1;
			else if (!strcmp(argv[i], "-notmini9")) fixmini9=1;
			else {											// checks for an other dsdt.dsl to patch
				sprintf(origDSDTPath, "%s", argv[i]);
				otherDSDTFileGiven=1;
			}
		}
	}
}	// checks for flags given to the tool

void cwd(const char *argv[]) {	// change to dir
	char dir[strlen(argv[0])];
	int i=strlen(argv[0]);
	sprintf(dir, "%s", argv[0]);
	
	for (i=strlen(dir);i>=0;i--) { 
		if (dir[i] == '/') {
			dir[i] = '\0';
			break;
		}
	}
	chdir(dir);
}		// change the current working directory


int foundDevice (char *haystack, char *needle) {
	if (cmpStr(haystack, needle)) {								
		printf("\tDevice found : %s",haystack);
		return 1;
	}
	return 0;
}

int main(int argc, const char *argv[]) {
	printf("DSDT Patcher version %s\n", VERSION);
	printf("Repoart any bugs to meklort@gmail.com\n");
	printf("\tPlease include Debug/USER.tar\n\n");
	
	
	//printf("Press any key to continue");
	//system("read");		// We could use something else here, TODO: change me
	
	flagCheck(argc, argv);		// TODO: maybe change to pass by refrence
	if (!otherDSDTFileGiven) {								// if no other file is set in the args, get the dsdt.dsl with getdsdt tool and decompile it
		printf("\n\nGetting the DSDT through ioreg...\n");
		system("./Tools/getDSDT.sh");
		printf("\n\n\nDecompiling the DSDT...\n");
		system("./Tools/iasl -d ./dsdt.dat");
		system("clear");
	}
	sprintf( buffer, "cp %s patched_dsdt.dsl", origDSDTPath);
	system(buffer);
	printf("Preparing to patch %s...\n", origDSDTPath);
	printf("\tReading config file...\n");
	
	
	
	FILE *configFile;
	if ((configFile=fopen("config","r"))==NULL) {
		printf("Unable to open the config file\n\n");
		return 0;
	}
	

	
	
	if(!patchRTC()) {
		printf("An error occured while patching the RTC.\n");
		return 1;
	}
	system("cp latest_dsdt.dsl patched_dsdt.dsl");
	system("rm latest_dsdt.dsl");
	
	if(!patchHPET()) {
		printf("An error occured while patching the HPET.\n");
		return 1;
	}
	
	system("cp latest_dsdt.dsl patched_dsdt.dsl");
	system("rm latest_dsdt.dsl");
	
	
	patchVersion();
	system("cp latest_dsdt.dsl patched_dsdt.dsl");
	system("rm latest_dsdt.dsl");
	
	// Patching various issues
	if(!patchVarious()) {
		printf("An error occured while patching the misc errors.\n");
		return 1;
	}
	system("cp latest_dsdt.dsl patched_dsdt.dsl");
	system("rm latest_dsdt.dsl");
	
	
	printf("\n\n\nPatching complete, compiling..\n\n");
	
	if(forceBuild)										// when -f flag is set we force the build
		system("./Tools/iasl -ta -f ./patched_dsdt.dsl");
	else												// otherwise we compile it without forcing
		system("./Tools/iasl -ta ./patched_dsdt.dsl");
	
	printf("\n\n\nCompiling done, if it worked, you have now a patched DSDT in dsdt.aml\nIf the compiling went wrong, you could force to build it with ./DSDT\\ Patcher -f (try this DSDT at your own risk)\n\n\n");
	
	// Clean up & make a tar for debug
	system("rm patched_dsdt.hex && rm dsdt.dat");			
	system("mkdir ./Debug");
	system("mv ./patched_dsdt.dsl ./Debug");
	system("tar -czf ./Debug/$USER.tar ./Debug/*");
	
	
	return 0;
	
}



int cmpStr(char *haystack, char *needle) {
	//return 0;
	
	long i;
	for (i = 0 ; i <= strlen(haystack); ++i )
	{
		if ( strncmp( &haystack[ i ], needle, strlen(needle) ) == 0 ) return 1;
	}
	return 0;
}		// compares 2 strings



int cmpStrWild(char *searchString, char *searchTerm) {
	int i, j;
	for (i = 0 ; i +strlen(searchTerm) < strlen(searchString); ++i )
	{
		for (j = 0; j<strlen(searchTerm);j++)
			if (searchString[i+j]!=searchTerm[j] && searchTerm[j]!='?')
				break;
		if ( j==strlen(searchTerm) ) return 1;
	}
	return 0;
}		// compares 2 strings

int cmpStr2(char *searchString, char *searchTerm, int i) {
	int x=0;
	for (x ; x < strlen(searchTerm); ++x )
	{
		if (searchString[i+x]!=searchTerm[x]) return 0;
	}
	return 1;
}
void replaceAlias(char *string, char *string2, int i) {
	int x=0;
	for(;x<strlen(string2);x++) {
		string[i+x]=string2[x];
	}
}

int foundRTCDevice (char *s) {
	if (cmpStr(s, RTCDevice)) {								// compare to "Device (RTC"
		RTCDeviceFound=1;
		printf("RTC Device found : %s",s);
		return 1;
	} else if (cmpStr(s, RTCDevice2) && !RTCDeviceFound) {	// compare to "PNP0B00"
		RTCDeviceFound=1;
		printf("RTC Device found : %s",s);
		openBrackets++;								// if we found this it means there is already an open { so we need to increment it, otherwise the routine wouldnt find the HPET device end
		return 1;
	}
	return 0;
}							// found an RTC device?


int foundHPETDevice (char *s) {
	if (cmpStr(s, HPETDevice)) {							// compare to "Device (HPET"
		HPETDeviceFound=1;
		printf("HPET Device found : %s",s);
		return 1;
	} else if (cmpStr(s, HPETDevice2) && !HPETDeviceFound) {	// compare to "PNP0103"
		HPETDeviceFound=1;
		printf("HPET Device found : %s",s);
		openBrackets++;								// if we found this it means there is already an open { so we need to increment it, otherwise the routine wouldnt find the RTC device end
		return 1;
	}
	return 0;
}							// found an HPET device?
										// Patch the RTC here


#endif
