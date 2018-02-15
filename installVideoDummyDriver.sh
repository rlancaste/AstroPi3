#!/bin/bash
if [ "$(whoami)" != "root" ]; then
	echo "Please run this script with sudo due to the fact that it must do a number of sudo tasks.  Exiting now."
	exit 1
fi
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo "Welcome to the KStars/INDI Xorg Video Dummy installer"
echo "This script is for devices that need the XOrg Video Dummy Driver to show up properly in VNC."
echo "Note that if you use this script, VNC will then work, but HDMI will no longer work since it is using the dummy driver instead"

read -p "Do you wish to run this script? (y/n)" runscript
if [ "$runscript" != "y" ]
	then
		echo "Quitting the script as you requested."
		read -p "Hit [Enter] to end the script now." closing
		exit
fi

# This will install the Video Dummy Driver
sudo apt-get install xserver-xorg-video-dummy

# This will create the configuration file needed to support the dummy driver.
##################
sudo bash -c 'cat > /etc/X11/xorg.conf.d/10-videodummy.conf' <<- EOF
Section "Monitor"
	Identifier "Monitor0"
	HorizSync 28.0-80.0
	VertRefresh 48.0-75.0
	Modeline "1224x685" 67.72 1224 1280 1408 1592 685 686 689 709 -HSync +Vsync
EndSection

Section "Device"
	Identifier "Card0"
	Option "NoDDC" "true"
	Option "IgnoreEDID" "true"
	Driver "dummy"
EndSection

Section "Screen"
	DefaultDepth 24
	Identifier "Screen0"
	Device "Card0"
	Monitor "Monitor0"
    SubSection "Display"
    	Depth 24
    	Modes "1224x685"    
    EndSubSection
EndSection
EOF
##################

display "Script Execution Complete.  The Video Dummy Driver is set up.  You should restart your computer and log in via VNC."




	