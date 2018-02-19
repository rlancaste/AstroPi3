#!/bin/bash

#	AstroPi3 Linux UDEV Rule Script
#﻿  Copyright (C) 2018 Robert Lancaster <rlancaste@gmail.com>
#	This script is free software; you can redistribute it and/or
#	modify it under the terms of the GNU General Public
#	License as published by the Free Software Foundation; either
#	version 2 of the License, or (at your option) any later version.

if [ "$(whoami)" != "root" ]; then
	display "Please run this script with sudo due to the fact that it must do a number of sudo tasks.  Exiting now."
	exit 1
fi
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo "Welcome to the AstroPi3 Linux Udev Script"
echo "This will create udev rules that will allow multiple devices based on serial/tty communications to have consistent names when they are connected."
echo "This script will place a rule in /lib/udev/rules.d/99-<device name>.rules so that when you connect this device to this computer, it can be accessed via a symlink name like /dev/moonlite instead of having to use /dev/ttyusb0"
read -p "Do you wish to run this script? (y/n)" runscript
if [ "$runscript" != "y" ]
	then
		echo "Quitting the script as you requested."
		read -p "Hit [Enter] to end the script now." closing
		exit
	fi

echo "Please Plug in only the device for which you want to make a udev rule."
read -p "Hit [Enter] when you are ready" ready

if [ -e "/dev/ttyUSB0" ]
then
	echo "Device Found at /dev/ttyUSB0"
	devicePath=/dev/ttyUSB0
elif [ -e "/dev/ttyACM0" ]
then
	echo "Device Found at /dev/ttyACM0"
	devicePath=/dev/ttyACM0
else
	echo "Serial Device not found.  Are you sure it is plugged in and turned on?  Please connect it and run the script again."
	read -p "Hit [Enter] to end the script" closing
	exit
fi

#This will ask the user for a long name for the device
echo "Please type a descriptive name for this device.  For Example:  MoonLite Focuser "
read -p "Descriptive name: " longName
#This will ask the user for the symlink name for the device
echo "Please type a unique short name for this device that will be used to make the symlink as well as for the name of the udev rule file. It should have no spaces or special characters.  For example: focuser or moonlite.  But you might want to check that you don't have any other udev rules with the same name in /lib/udev/rules.d/ unless you want to overwrite an old one."
read -p "symlink name: " symlink

if [ -e "/lib/udev/rules.d/99-$symlink.rules" ]
then
	read -p "A File already exists with that name, do you wish to overwrite it? (y/n)" overwrite

	if [ "$overwrite" != "y" ]
	then
		"Exiting Script.  Symlink not created. Run again with a different name if you like."
		read -p "Hit [Enter] to end the script" closing
		exit
	fi

fi

#This will get the vendor id of the device
vendor=$(udevadm info -a -n $devicePath | grep '{idVendor}' | head -n1)

#This will get the product identifier of the device
product=$(udevadm info -a -n $devicePath | grep '{idProduct}' | head -n1)

#This will get the serial number of the device
serial=$(udevadm info -a -n $devicePath | grep '{serial}' | head -n1)

echo "Here is the information that was collected for your $longName."
echo $vendor
echo $product
echo $serial
echo "Please note that sometimes the rule works well with all three pieces of information, but sometimes that is too strict of a requirement and the rule doesn't work.  But on the other hand if you have two devices where two of the pieces of information is identical, you will need the third.  The most common one that needs to be left out is the serial ID."

read -p "Do you want to leave it out? (y/n)" removeSerial

read -p "Do you wish to symlink the device with this information as /dev/$symlink? (y/n)" save

if [ "$save" != "y" ]
then
	"Exiting Script.  Symlink not created."
	read -p "Hit [Enter] to end the script" closing
	exit
fi

if [ "$removeSerial" == "y" ]
then

# This will create the udev rule file without the serial id
sudo cat > /lib/udev/rules.d/99-$symlink.rules <<- EOF
# $longName udev rule                                                                                                                                                                                                                     
SUBSYSTEMS=="usb", $vendor, $product, MODE="0666", SYMLINK+="$symlink"
EOF

else

# This will create the udev rule file including the serial id
sudo cat > /lib/udev/rules.d/99-$symlink.rules <<- EOF
# $longName udev rule                                                                                                                                                                                                                     
SUBSYSTEMS=="usb", $vendor, $product, $serial, MODE="0666", SYMLINK+="$symlink"
EOF

fi


echo "Script finished.  You should now have a udev rule file located at /lib/udev/rules.d/99-$symlink.rules.  And you should now have a symlink called /dev/$symlink that will identify your device.  Please see the rules list below to see your new rule included."
ls /lib/udev/rules.d/99-*

echo "If you unplug your device and plug it back in, this script can detect if the rule worked."
read -p "Please hit [Enter] once you have done so." testing

if [ -e "/dev/$symlink" ]
then
	echo "Your rule appears to work well."
else
	echo "Serial Device not detected.  Most likely the cause is one of these: you did not unplug it and plug it back in, or your device is not working, or your rule is too strict.  You might try changing the rule: /lib/udev/rules.d/99-$symlink.rules"
fi

read -p "Hit [Enter] to end the script" closing