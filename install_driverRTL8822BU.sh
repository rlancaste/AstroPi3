#!/bin/bash

#	AstroPi3 Realtek drivers for Wifi Dongle using chipset RTL8822BU Install Script
#﻿  Copyright (C) 2018 Robert Lancaster <rlancaste@gmail.com>
#	This script is free software; you can redistribute it and/or
#	modify it under the terms of the GNU General Public
#	License as published by the Free Software Foundation; either
#	version 2 of the License, or (at your option) any later version.

if [ "$(whoami)" != "root" ]; then
	echo "Please run this script with sudo due to the fact that it must do a number of sudo tasks.  Exiting now."
	exit 1
fi

echo "~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo "Attempting to Install Realtek drivers for Wifi Dongle using chipset RTL8822BU.  This script is intended for an SBC running Ubuntu or Raspbian"
read -p "Are you ready to proceed (y/n)? " proceed

if [ "$proceed" != "y" ]
then
	exit
fi

export USERHOME=$(sudo -u $SUDO_USER -H bash -c 'echo $HOME')

cd $USERHOME

sudo apt -y install git
# For Raspberry pi
sudo apt -y install raspberrypi-kernel-headers
# For Ubuntu MATE
sudo apt -y install linux-headers-$(uname -r)
sudo -H -u $SUDO_USER git clone https://github.com/FomalhautWeisszwerg/rtl8822bu.git
# This link needs to be made for it to find the headers on ubuntu mate raspberry pi 3.
sudo ln -s /usr/src/linux-headers-$(uname -r)/arch/arm/ /usr/src/linux-headers-$(uname -r)/arch/armv7l
cd rtl8822bu
if [ -z "$(grep 'Wno-incompatible-pointer-types' Makefile)" ]
then
	sed -i "/EXTRA_CFLAGS += -Wall/ a EXTRA_CFLAGS += -Wno-incompatible-pointer-types" Makefile
fi
sudo -H -u $SUDO_USER make
sudo make install
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo "Script Execution Complete.  You may need to restart for the wifi dongle to work well."