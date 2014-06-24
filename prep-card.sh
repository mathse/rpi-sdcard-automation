#!/bin/bash
echo "checking noobs version ..."
mkdir -p ./images/unpack
mkdir -p /tmp/rpi-sdcard-automation
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
	curl -4 -# -o ./images/$latestFile $url
else
	echo "latest version already downloaded"
fi
echo -n "unpacking ... "
if [ ! -f ./images/unpack/$(echo $latestFile | sed 's/zip/img/g') ]
then
	unzip ./images/$latestFile -d ./images/unpack
fi
echo "done"

echo
echo "looking for block devices ..."
dmesg | grep -i "blocks:" | cut -c 28- | sort | uniq
lastDev=$(dmesg | grep -i "blocks:" | cut -c 28- | cut -c 2-4 | tail -n1)

echo
echo -n "device to use [$lastDev] "
read dev
if [ "$dev" == "" ]
then
	dev=$lastDev
fi

echo "using /dev/$dev"
size=$(ls -l ./images/unpack/$(echo $latestFile | sed 's/zip/img/g') | awk '{ print $5 }')
#dd if=./images/unpack/$(echo $latestFile | sed 's/zip/img/g') | bar -s $size > /dev/$dev

partprobe /dev/$dev
mkdir /tmp/rpi-sdcard-automation/root
mkdir /tmp/rpi-sdcard-automation/boot
mount /dev/${dev}1 /tmp/rpi-sdcard-automation/boot
mount /dev/${dev}2 /tmp/rpi-sdcard-automation/root

cp -r ./skel/root/* /tmp/rpi-sdcard-automation/root
cp -r ./skel/boot/* /tmp/rpi-sdcard-automation/boot
