#!/bin/bash

#	AstroPi3 Xorg Video Dummy installer
#﻿  Copyright (C) 2018 Robert Lancaster <rlancaste@gmail.com>
#	This script is free software; you can redistribute it and/or
#	modify it under the terms of the GNU General Public
#	License as published by the Free Software Foundation; either
#	version 2 of the License, or (at your option) any later version.

if [ "$(whoami)" != "root" ]; then
	echo "Please run this script with sudo due to the fact that it must do a number of sudo tasks.  Exiting now."
	exit 1
fi
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo "Welcome to the AstroPi3 Xorg Video Dummy installer"
echo "This script is for devices that need the XOrg Video Dummy Driver to show up properly in VNC."
echo "Note that if you install the dummy driver, VNC will then work, but HDMI will no longer work since it is using the dummy driver instead"
echo "If the script has already run, instead of setting it up, it will uninstall the dummy driver and remove the conf file."

read -p "Do you wish to run this script? (y/n)" runscript
if [ "$runscript" != "y" ]
then
	echo "Quitting the script as you requested."
	exit
fi

if [ -e "/etc/X11/xorg.conf.d/10-videodummy.conf" ]
then
		read -p "The script was already run.  Do you wish to uninstall? (y/n)" uninstall
		if [ "$uninstall" == "y" ]
		then
			echo "Removing the dummy driver and the conf file as you requested."
			sudo apt-get -y remove xserver-xorg-video-dummy
			sudo rm /etc/X11/xorg.conf.d/10-videodummy.conf
		fi
		echo "Script Execution Complete.  The Video Dummy Driver is removed.  You should restart your computer."
		exit
fi


# This will install the Video Dummy Driver
sudo apt-get -y install xserver-xorg-video-dummy

# This will create the configuration file needed to support the dummy driver.
# Note:  Thanks to https://ubuntuforums.org/showthread.php?t=1297815&page=3 for all the modes.
##################
sudo bash -c 'cat > /etc/X11/xorg.conf.d/10-videodummy.conf' <<- EOF
Section "Monitor"
	Identifier "Monitor0"
    HorizSync 22 - 83
    VertRefresh 50 - 76
     #1024x768 @ 60.00 Hz (GTF) hsync: 47.70 kHz; pclk: 64.11 MHz
    Modeline "1024x768" 64.11 1024 1080 1184 1344 768 769 772 795 -HSync +Vsync
     #1152x864 @ 60.00 Hz (GTF) hsync: 53.70 kHz; pclk: 81.62 MHz
    Modeline "1152x864" 81.62 1152 1216 1336 1520 864 865 868 895 -HSync +Vsync
     #1280x800 @ 60.00 Hz (GTF) hsync: 49.68 kHz; pclk: 83.46 MHz
    Modeline "1280x800" 83.46 1280 1344 1480 1680 800 801 804 828 -HSync +Vsync
     #1280x1024 @ 60.00 Hz (GTF) hsync: 63.60 kHz; pclk: 108.88 MHz
    Modeline "1280x1024" 108.88 1280 1360 1496 1712 1024 1025 1028 1060 -HSync +Vsync
     #1360x1024 @ 60.00 Hz (GTF) hsync: 63.60 kHz; pclk: 116.01 MHz
    Modeline "1360x1024" 116.01 1360 1448 1592 1824 1024 1025 1028 1060 -HSync +Vsync
     #1440x900 @ 60.00 Hz (GTF) hsync: 55.92 kHz; pclk: 106.47 MHz
    Modeline "1440x900" 106.47 1440 1520 1672 1904 900 901 904 932 -HSync +Vsync
     #1600x1200 @ 60.00 Hz (GTF) hsync: 74.52 kHz; pclk: 160.96 MHz
    Modeline "1600x1200" 160.96 1600 1704 1880 2160 1200 1201 1204 1242 -HSync +Vsync
     #1680x1050 @ 60.00 Hz (GTF) hsync: 65.22 kHz; pclk: 147.14 MHz
    Modeline "1680x1050" 147.14 1680 1784 1968 2256 1050 1051 1054 1087 -HSync +Vsync
     #1920x1080 @ 60.00 Hz (GTF) hsync: 67.08 kHz; pclk: 172.80 MHz
    Modeline "1920x1080" 172.80 1920 2040 2248 2576 1080 1081 1084 1118 -HSync +Vsync
     #1920x1200 @ 60.00 Hz (GTF) hsync: 74.52 kHz; pclk: 193.16 MHz
    Modeline "1920x1200" 193.16 1920 2048 2256 2592 1200 1201 1204 1242 -HSync +Vsync
EndSection

Section "Device"
	Identifier "Card0"
	Option "NoDDC" "true"
	Option "IgnoreEDID" "true"
	Driver "dummy"
	VideoRam	16384
EndSection

Section "Screen"
	DefaultDepth 24
	Identifier "Screen0"
	Device "Card0"
	Monitor "Monitor0"
    SubSection "Display"
    	Depth 24
    	Modes "1024x768" "1152x864" "1280x800" "1280x1024" "1360x1024" "1440x900" "1600x1200" "1680x1050" "1920x1080" "1920x1200"
    EndSubSection
EndSection
EOF
##################

echo "Script Execution Complete.  The Video Dummy Driver is set up.  You should restart your computer and log in via VNC."




	