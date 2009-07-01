/* --- Clamshell Display Driver --- ClamshellDisplay.h
*/

/* (C) 2008 Superhai
*/

#define IOFRAMEBUFFER_PRIVATE
#include "IODisplay.h"

class ClamshellDisplay : public IODisplay
{
	OSDeclareDefaultStructors(ClamshellDisplay)
	public:
		void initPowerManagement( IOService * provider );
		void stop( IOService * provider );
};

