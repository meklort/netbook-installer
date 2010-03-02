#!/bin/bash
# setActive.sh
PARTITION=$2
DISK=$1
SCHEME=`diskutil info /dev/disk$DISK | grep Partition`
SCHEME=${SCHEME:29:21}


if [[ "x$SCHEME" != "xGUID_partition_scheme" ]]
then
	exit
fi

"${0%/*}/gdisk" /dev/disk$DISK << EOF
r
h
1 2 3 4
n

n

n

n

n
w
y
q

EOF

fdisk -e /dev/disk$DISK << EOF
f $PARTITION
w
y
q
EOF