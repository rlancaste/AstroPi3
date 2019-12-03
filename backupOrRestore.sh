#!/bin/bash

#	AstroPi3 KStars/INDI Backup and Restore Script
#﻿  Copyright (C) 2018 Robert Lancaster <rlancaste@gmail.com>
#	This script is free software; you can redistribute it and/or
#	modify it under the terms of the GNU General Public
#	License as published by the Free Software Foundation; either
#	version 2 of the License, or (at your option) any later version.

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

if [ "$(whoami)" == "root" ]; then
	echo "Please run this script without sudo due to the fact that it saves and backs up lots of files owned by the user.  Exiting now."
	exit 1
fi
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo "Welcome to the AstroPi3 KStars/INDI Backup and Restore Script"
echo "This script can backup and restore your KStars and INDI files from your Ubuntu-Mate System."
echo "Please note, make sure the folder or drive you want to save the files to or retrieve them from is ready to go."

read -p "Do you wish to run this script? (y/n)" runscript
if [ "$runscript" != "y" ]
then
	echo "Quitting the script as you requested."
	exit
fi 

read -p "Do you want to backup or restore your files? Please type the full word, backup or restore: " option
if [ "$option" != "backup" ] && [ "$option" != "restore" ]
then
	echo "You must either type backup or restore.  Please run this script again."
	read -p "Hit [Enter] to end the script" closing
	exit
fi 

if [ "$option" == "backup" ]
then
	read -p "Please either drag a folder to this window or type the folder path in which you want the backup to be saved:" saveLocation
	saveLocation="$(echo $saveLocation | sed 's/'\''//g')"
	if [ -d "$saveLocation" ]
	then
		backupFolderName="$saveLocation/astroPi3Backup-$(date '+%d-%m-%Y_%H-%M-%S')"
		mkdir -p "$backupFolderName"
		cp ~/.config/kstarsrc "$backupFolderName/kstarsrc"
		cp -r ~/.local/share/kstars "$backupFolderName/kstarsData"
		cp -r ~/.indi "$backupFolderName/INDIConfig"
		echo "Your KStars/INDI backup is complete."
		read -p "Hit [Enter] to end the script" closing
		exit
	else
		echo "The specified folder does not seem to exist.  Please run this script again."
		read -p "Hit [Enter] to end the script" closing
		exit
	fi
fi 

read -p "Are you sure you want to restore the files.  If they already exist on this system, they will be overwritten? (y/n)" sure
if [ "$sure" != "y" ]
then
	echo "Quitting the script as you requested."
	exit
fi 

if [ "$option" == "restore" ]
then
	read -p "Please either drag the astroPi3 Backup folder you wish to restore from to this window or type the folder path:" savedLocation
	savedLocation="$(echo $savedLocation | sed 's/'\''//g')"
	if [ -d "$savedLocation" ]
	then
		cp -f "$savedLocation/kstarsrc" ~/.config/kstarsrc
		rm -rf ~/.local/share/kstars
		cp -rf "$savedLocation/kstarsData" ~/.local/share/kstars
		rm -rf ~/.indi
		cp -rf "$savedLocation/INDIConfig" ~/.indi
		echo "Your KStars/INDI restore is complete."
		read -p "Hit [Enter] to end the script" closing
		exit
	else
		echo "The specified folder does not seem to exist.  Please run this script again."
		read -p "Hit [Enter] to end the script" closing
		exit
	fi
fi 