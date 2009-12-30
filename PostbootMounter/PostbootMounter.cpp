#include "PostbootMounter.h"

#include "sysproto.h"
#include <bsd/sys/stat.h>


#include <IOKit/IOBSD.h>
#include <IOKit/IOLib.h>
#include <IOKit/IOService.h>
#include <IOKit/IODeviceTreeSupport.h>
#include <IOKit/IOKitKeys.h>
#include <IOKit/IOPlatformExpert.h>

#undef KERNEL
#include <hfs/hfs_mount.h>

#define	ROUND_PTR(type, addr)	\
	(type *)( ( (uintptr_t)(addr) + 16 - 1) \
	& ~(16 - 1) )

extern "C"
{
	/* hook called after root is mounted XXX temporary hack */
	extern void (*mountroot_post_hook)(void);
		//	extern task_t bsd_init_task;
		//extern void mac_cred_label_associate_user(kauth_cred_t cred);
		//extern void mac_task_label_update_internal(struct label *pl, struct task *t);
		//#define mac_task_label_update_cred(cred, task)				\
		//	mac_task_label_update_internal(((cred)->cr_label), task)


		//void (*unmountroot_pre_hook)(void);
	
};

void (*old_mountroot_post_hook)(void);



void run_mount(void);

int exec_file(const char* path);
int mount_dev(const char* devpath, const char* mountpath, const char* fstype, int mntflags);


#define super IOService

OSDefineMetaClassAndStructors(PostbootMounter, IOService);

volatile bool run;

	// our service start function, this is where we setup all the goodies
bool PostbootMounter::start(IOService *provider)
{
	IORegistryEntry *	regEntry;
	OSData *			data;
	if((regEntry = IORegistryEntry::fromPath( "/chosen/memory-map", gIODTPlane ))) {	/* Find the map node */
		data = (OSData *)regEntry->getProperty("RAMDisk");	/* Find the ram disk, if there */
		if(!data) {		
			/* No Ramdisk... */
			IOLog("PostbootMounter: No ramdisk specified, exiting.\n");
			return false;
		}
	}
	else
	{
		
		run = false;
		//printf("PostbootMounter: Saving mountroot_post_hook\n");
		
		old_mountroot_post_hook = mountroot_post_hook;
		//printf("PostbootMounter: mountroot_post_hook backed up.\n");
		
		mountroot_post_hook = &run_mount;
		//printf("PostbootMounter: mountroot_post_hook modified\n");
		
		while ( !run )
		{
			// Keep watching the post root hook, ensure that we own it.
			if (mountroot_post_hook != &run_mount)
			{
				// FIXME: This is only needed because another kext modifies mountroot_post_hook
				// In the future, we should *wait* for that kext to do it's stuff, then overwrite the hook
				// That way, there is no need for this while loop.
				if(!old_mountroot_post_hook) old_mountroot_post_hook = mountroot_post_hook;
				// TODO: wailt for BootCache.kext to use this, then modify it
				//printf("PostbootMounter: mountroot_post_hook modified\n");
				mountroot_post_hook = &run_mount;
			}
			IOSleep(50);	// Wait a bit
		}
		
		return true;	// False would causes the kext to unload after it mountroot_post_hook is run (hence while (!run))
		
	}
	
	return false;
}

int mount_dev(const char* devpath, const char* mountpath, const char* fstype, int mntflags)
{
	struct hfs_mount_args args;
	struct mount_args uap;
	int /*mntflags,*/ mountStatus;
	
	(void)memset(&args, 0, sizeof(struct hfs_mount_args));
	(void)memset(&uap, 0, sizeof(struct mount_args));
	
	args.flags = 0;
	args.hfs_uid = 0;
	args.hfs_gid = 0;
	args.hfs_mask = 0777 & (S_IRWXU | S_IRWXG | S_IRWXO);
	args.hfs_encoding = 0;
	args.fspec = (char*)devpath;

	uap.flags = mntflags;
	uap.data = CAST_USER_ADDR_T(&args);
	uap.type = CAST_USER_ADDR_T(fstype);
	uap.path = CAST_USER_ADDR_T(mountpath);
	
	mountStatus = mount(current_proc(), &uap, 0);
	switch (mountStatus) {
		case 0:
			printf("PostbootMounter: Mount of %s to %s Suceeded\n", devpath, mountpath);
		case ENOENT:
			break;
			printf("PostbootMounter: No such file or directory\n");
			break;
		case ENOTDIR:
			printf("PostbootMounter: Not a directory\n");
			break;
			
		default:
			printf("PostbootMounter: Mount: unknown error code %d\n", mountStatus);
			break;
	}
	
	
	return mountStatus;
	
}



// Currently not used
int exec_file(const char* path)
{
	/// NOTE: We *should* be using posix_spawn. The only reason we are mounting over the WindowSeriver is to ensure that we run before it does.	
	
	vm_offset_t	init_addr;
	proc_t p = current_proc();
		//thread_t thread = bsd_init_task;
	struct execve_args	init_exec_args;
	int		argc = 0;
	uint32_t argv[3];
	int32_t retval;
	int error;
	
	//process_name("NetbookBootMaker", p);

	
	//	mac_cred_label_associate_user(p->p_ucred);
	//	mac_task_label_update_cred (p->p_ucred, (struct task *) p->task);
	
	
	/*
	 * Copy out program name.
	 */
		// Not sure if this is needed, but bsd_exec (load_init_prog) does it. This code is copied directly from there.
	init_addr = VM_MIN_ADDRESS;
	(void) vm_allocate(current_map(), &init_addr, PAGE_SIZE,
					   VM_FLAGS_ANYWHERE);
	if (init_addr == 0)
		init_addr++;
	
	(void) copyout((caddr_t) path, CAST_USER_ADDR_T(init_addr),
				   (unsigned) sizeof(path)+1);
	
	argv[argc++] = (uint32_t)init_addr;			// set program name as the first argument to the executable
	init_addr += sizeof(path);
	init_addr = (vm_offset_t)ROUND_PTR(char, init_addr);
	
	
	
	argv[argc] = 0;

	(void) copyout((caddr_t) argv, CAST_USER_ADDR_T(init_addr),
				   (unsigned) sizeof(argv));

	
	init_exec_args.fname = CAST_USER_ADDR_T(argv[0]);				// program name
	init_exec_args.argp = CAST_USER_ADDR_T((char **)init_addr);		// arguments
	init_exec_args.envp = CAST_USER_ADDR_T(0);						// env variables
	
	printf("set_security_token: %d\n", set_security_token(p));

	error = execve(p,&init_exec_args,&retval);
	
	switch (error)
	{
		case 0:
			error = retval;
			printf("PostbootMounter: Execution of %s Suceeded\n", path);
			break;
		case EINVAL:
			printf("PostbootMounter: Invalid argument (EINVAL)\n");
			break;
		case ENOTSUP:
			printf("PostbootMounter: Invalid argument (ENOTSUP)\n");
			break;
		case EACCES:
			printf("PostbootMounter: Permission denied\n");
			break;
		case EINTR:
			printf("PostbootMounter: Interrupted function\n");
			break;
		case ENOMEM:
			printf("PostbootMounter: Not enough space\n");
			break;
		case EFAULT:
			printf("PostbootMounter: Bad addressn\n");
			break;
		case ENAMETOOLONG:
			printf("PostbootMounter: Filename too long\n");
			break;
		case ENOEXEC:
			printf("PostbootMounter: Executable file format error\n");
			break;
		case ETXTBSY:
			printf("PostbootMounter: Text file busy [misuse of error code]\n");
			break;
		default:
			printf("PostbootMounter: execve: unknown error code %d\n", retval);
	}
	
	
	return error;	
}

void run_mount()
{
	// TODO: Make this configurable.
	run = true;
	//printf("PostbootMounter: Mounting /dev/md0\n");
	
	// we mount the ramdisk to /System/Library/Frameworks/ApplicationServices.framework/Frameworks/CoreGraphics.framework/Resources/ so that we can overwrite the WindowServer command.
	// TODO: make this configurable in a plist
	mount_dev("/dev/md0", "/System/Library/Frameworks/ApplicationServices.framework/Frameworks/CoreGraphics.framework/Resources/", "hfs", MNT_UNION | MNT_SYNCHRONOUS);

	if(old_mountroot_post_hook != NULL) 
	{
		// I believe BootCache uses mountroot_post_hook to retrive a notification from the kernel to do it's stuff, we overwrite that.
		// Since we overwrote it, lets call it ourself.
		//printf("PostbootMounter: Running old mountroot_post_hook\n");
		(*old_mountroot_post_hook)();
	}
}


