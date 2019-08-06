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

sudo apt-get -y install git
sudo apt-get -y install dkms
sudo apt-get install raspberrypi-kernel-headers
git clone https://github.com/drwilco/RTL8822BU.git
cd RTL8822BU
sudo make dkms-install
make
sudo make install
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo "Script Execution Complete.  You may need to restart for the wifi dongle to work well."