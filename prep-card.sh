#!/bin/bash
mkdir -p ./images/unpack
mkdir -p /tmp/rpi-sdcard-automation

if [ $1 ]
then
	echo "using $1"
	latestFile=$(basename $1)
else
	echo "checking noobs version ..."
	curl -4 -s -o /tmp/rpi-sdcard-automation/wp-slice-raspbian http://downloads.raspberrypi.org/wp-slice-raspbian
	latestFile=$(cat /tmp/rpi-sdcard-automation/wp-slice-raspbian | sed 's|</b>|-|g' | sed 's|<[^>]*>||g' | grep zip | head -n1)
	releaseDate=$(cat /tmp/rpi-sdcard-automation/wp-slice-raspbian | sed 's|</b>|-|g' | sed 's|<[^>]*>||g' | grep -A1 Release | tail -n1)
	if [ ! -f ./images/$latestFile ]
	then
		echo "latest version not downloaded"
		echo "downloading $latestFile ..."
		curl -4 -# -o /tmp/rpi-sdcard-automation/raspbian_latest http://downloads.raspberrypi.org/raspbian_latest
		url=$(cat /tmp/rpi-sdcard-automation/raspbian_latest | grep moved | cut -f2 -d'"' | sed 's/downloads/director\.downloads/g')
		echo "using url: $url"
		curl -L -4 -# -o ./images/$latestFile $url
	else
		echo "latest version already downloaded"
	fi
	echo -n "unpacking ... "
	if [ ! -f ./images/unpack/$(echo $latestFile | sed 's/zip/img/g') ]
	then
		unzip ./images/$latestFile -d ./images/unpack
	fi
	echo "done"
fi


echo
echo "looking for block devices ..."
dmesg | grep -i "blocks:" | cut -c 28- | sort | uniq
lastDev=$(fdisk -l 2> /dev/null | grep Disk | grep sd | cut -f1 -d: | cut -f3 -d/ | tail -n1)

echo
echo -n "device to use [$lastDev] "
read dev
if [ "$dev" == "" ]
then
	dev=$lastDev
fi

echo "using /dev/$dev"
umount -f /dev/$dev?
size=$(ls -l ./images/unpack/$(echo $latestFile | sed 's/zip/img/g') | awk '{ print $5 }')
if [ "$1" != "--skipdd" ]
then
	dd if=./images/unpack/$(echo $latestFile | sed 's/zip/img/g') | bar -s $size > /dev/$dev
	sleep 5
fi

partprobe /dev/$dev
mkdir /tmp/rpi-sdcard-automation/root 2> /dev/null
mkdir /tmp/rpi-sdcard-automation/boot 2> /dev/null
sleep 5
mount /dev/${dev}1 /tmp/rpi-sdcard-automation/boot
mount /dev/${dev}2 /tmp/rpi-sdcard-automation/root

if [ "$2" == "" ]
then
	echo "available profiles"
	ls -1 ./profiles
	echo
	echo "which one to use?"
	read profile
else
	profile=$2
fi
cp -r ./profiles/$profile/root/* /tmp/rpi-sdcard-automation/root
cp -r ./profiles/$profile/boot/* /tmp/rpi-sdcard-automation/boot

sleep 5
umount /dev/${dev}1
umount /dev/${dev}2

