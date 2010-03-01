#!/bin/bash

cd /Volumes/ramdisk
/usr/bin/xar -xf "$1/System/Installation/Packages/BSD.pkg"

gzcat /Volumes/ramdisk/Payload | cpio -i /usr/bin/xxd

while [ ! -f /Volumes/ramdisk/usr/bin/xxd ]; do
	sleep 1
done

rm  /Volumes/ramdisk/Payload


