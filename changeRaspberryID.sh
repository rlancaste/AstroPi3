#!/bin/bash

#	AstroPi3 Raspberry Pi 3 Ubuntu-Mate KStars/INDI Configuration Script
#﻿  Copyright (C) 2023 Robert Lancaster <rlancaste@gmail.com>
#	This script is free software; you can redistribute it and/or
#	modify it under the terms of the GNU General Public
#	License as published by the Free Software Foundation; either
#	version 2 of the License, or (at your option) any later version.

if [ "$(whoami)" != "root" ]; then
	display "Please run this script with sudo due to the fact that it must do a number of sudo tasks.  Exiting now."
	exit 1
fi

read -p "This script will change the name of a newly copied Raspberry Pi and make changes to make it independent of the old one.  Do you want to do this? (y/n)? " proceed

if [ "$proceed" != "y" ]
then
	exit
fi

oldhostname=$(cat /etc/hostname)
echo "Your old host name is: " $oldhostname
read -p "What do you want your new hostname to be? "newhostname

# Write the new host name to the appropriate files
sudo $newhostname > /etc/hostname
sed -i "s/$oldhostname/$newhostname/g" /etc/hosts

# Regenerate the SSH keys (https://raspberrypi.stackexchange.com/questions/84281/using-a-cloned-raspberry-pi-as-its-own-system#112717)
sudo rm /etc/ssh/ssh_host*
sudo dpkg-reconfigure openssh-server
sudo systemctl restart sshd.service

# Get a new id for realvnc (https://raspberrypi.stackexchange.com/questions/84281/using-a-cloned-raspberry-pi-as-its-own-system#112717)
sudo systemctl stop vncserver-x11-serviced
sudo rm -rf /root/.vnc
sudo systemctl start vncserver-x11-serviced

# Reboot the system as the new host name
sudo reboot