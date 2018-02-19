#!/bin/bash

#	AstroPi3 Astrometry Index File Installer
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
echo "Welcome to the AstroPi3 Astrometry Index Installer Script"
echo "This script will ask you which Index files you want to download and then will install them to /usr/share/astrometry"
echo "Note that you need to install at least the index files that cover 10% to 100% of your FOV."
echo "Please make sure you know your FOV before Proceeeding."
read -p "Do you wish to run this script? (y/n)" runscript
if [ "$runscript" != "y" ]
	then
		echo "Quitting the script as you requested."
		read -p "Hit [Enter] to end the script now." closing
		exit
	fi
	
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo "To download and install the correct files, you need to decide which packages you want."
echo "Note that for large file sizes, the index files are in a big set."
echo "If you type the word 'large', you will get index files 4208-4219 which covers 30 arcmin to 2000 arcmin."
echo "For smaller fields, the file sizes become much bigger, so they are in separate packages."
echo "You just need to type the file number to download and install that package"
echo "You can select more than one packages by typing each number after the other separated by spaces or commas"
echo "Here is a list of all the available index file sets and their FOV's in Arc minutes"
echo "File  FOV"
echo "4207  22 - 30"
echo "4206  16 - 22"
echo "4205  11 - 16"
echo "4204  8 - 11"
echo "4203  5.6 - 8.0"
echo "4202  4.0 - 5.6"
echo "4201  2.8 - 4.0"
echo "4200  2.0 - 2.8"

read -p "Which file set would you like to download? Remember, type either 'large' or the file number(s) above: " indexFile

if [[ $indexFile = *"large"* ]]
then
	wget http://data.astrometry.net/debian/astrometry-data-4208-4219_0.45_all.deb
fi

if [[ $indexFile = *"4207"* ]]
then
	wget http://data.astrometry.net/debian/astrometry-data-4207_0.45_all.deb
fi

if [[ $indexFile = *"4206"* ]]
then
	wget http://data.astrometry.net/debian/astrometry-data-4206_0.45_all.deb
fi

if [[ $indexFile = *"4205"* ]]
then
	wget http://data.astrometry.net/debian/astrometry-data-4205_0.45_all.deb
fi

if [[ $indexFile = *"4204"* ]]
then
	wget http://data.astrometry.net/debian/astrometry-data-4204_0.45_all.deb
fi

if [[ $indexFile = *"4203"* ]]
then
	wget http://data.astrometry.net/debian/astrometry-data-4203_0.45_all.deb
fi

if [[ $indexFile = *"4202"* ]]
then
	wget http://data.astrometry.net/debian/astrometry-data-4202_0.45_all.deb
fi

if [[ $indexFile = *"4201"* ]]
then
	wget http://data.astrometry.net/debian/astrometry-data-4201-1_0.45_all.deb
	wget http://data.astrometry.net/debian/astrometry-data-4201-2_0.45_all.deb
	wget http://data.astrometry.net/debian/astrometry-data-4201-3_0.45_all.deb
	wget http://data.astrometry.net/debian/astrometry-data-4201-4_0.45_all.deb
fi

if [[ $indexFile = *"4200"* ]]
then
	wget http://data.astrometry.net/debian/astrometry-data-4200-1_0.45_all.deb
	wget http://data.astrometry.net/debian/astrometry-data-4200-2_0.45_all.deb
	wget http://data.astrometry.net/debian/astrometry-data-4200-3_0.45_all.deb
	wget http://data.astrometry.net/debian/astrometry-data-4200-4_0.45_all.deb
fi

sudo dpkg -i astrometry-data-*.deb
sudo rm *.deb

echo "Your requested installations are complete."

read -p "Hit [Enter] to end the script" closing