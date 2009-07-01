/* --- Clamshell Display Driver --- ClamshellDisplay.cpp
*/

/* (C) 2008 Superhai
*/

/* Changelog
1.0.1 - 18JUN08
- Initial

*/

/* To do and bugs 

*/

#include "ClamshellDisplay.h"

#define super IODisplay
OSDefineMetaClassAndStructors(ClamshellDisplay, IODisplay)

void ClamshellDisplay::initPowerManagement( IOService * provider )
{
    super::initPowerManagement( provider );

    IOFramebuffer::clamshellEnable( +1 );
}

void ClamshellDisplay::stop( IOService * provider )
{
    IOFramebuffer::clamshellEnable( -1 );

    super::stop( provider );
}
