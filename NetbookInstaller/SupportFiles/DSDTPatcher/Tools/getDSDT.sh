#!/bin/sh
ioreg -lw0 | grep DSDT > /Volumes/ramdisk/dsdt/ioreg.txt
ioregdump=$(cat /Volumes/ramdisk/dsdt/ioreg.txt)
modified1=${ioregdump#*'DSDT'}
modified2=${modified1#*'<'}
modified3=${modified2%%'>'*}
echo $modified3 > /Volumes/ramdisk/dsdt/dsdt.txt
/usr/bin/xxd -r -p /Volumes/ramdisk/dsdt/dsdt.txt > /Volumes/ramdisk/dsdt/dsdt.dat
rm /Volumes/ramdisk/dsdt/dsdt.txt
rm /Volumes/ramdisk/dsdt/ioreg.txt
