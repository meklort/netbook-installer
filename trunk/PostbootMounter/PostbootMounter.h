
#include <IOKit/IOService.h>
#include <IOKit/IOLib.h>

	//extern class IOService;

	// class definition
class PostbootMounter : public IOService
{
	OSDeclareDefaultStructors(PostbootMounter)
	
public:
	
	virtual bool	start(IOService *provider);
		//	virtual int		mount_dev(const char* devpath, const char* mountpath, const char* fstype, int mntflags);
		//	virtual int		exec_file(const char* path);

};