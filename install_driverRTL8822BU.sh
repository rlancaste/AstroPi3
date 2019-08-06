#!/bin/bash

#	AstroPi3 Realtek drivers for Wifi Dongle using chipset RTL8822BU Install Script
#﻿  Copyright (C) 2018 Robert Lancaster <rlancaste@gmail.com>
#	This script is free software; you can redistribute it and/or
#	modify it under the terms of the GNU General Public
#	License as published by the Free Software Foundation; either
#	version 2 of the License, or (at your option) any later version.

if [ "$(whoami)" != "root" ]; then
	display "Please run this script with sudo due to the fact that it must do a number of sudo tasks.  Exiting now."
	exit 1
fi

echo "~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo "Attempting to Install Realtek drivers for Wifi Dongle using chipset RTL8822BU.  This script is intended for a Raspberry Pi3 running Ubuntu-Mate"
read -p "Are you ready to proceed (y/n)? " proceed

if [ "$proceed" != "y" ]
then
	exit
fi

export USERHOME=$(sudo -u $SUDO_USER -H bash -c 'echo $HOME')

cd $USERHOME

sudo apt -y install git
sudo apt -y install dkms
# For Raspberry pi
sudo apt install raspberrypi-kernel-headers
# For Ubuntu MATE
sudo apt install linux-headers-$(uname -r)
sudo -H -u $SUDO_USER git clone https://github.com/drwilco/RTL8822BU.git
cd RTL8822BU
sudo -H -u $SUDO_USER make dkms-install
sudo -H -u $SUDO_USER make
sudo make install
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo "Script Execution Complete.  You may need to restart for the wifi dongle to work well."