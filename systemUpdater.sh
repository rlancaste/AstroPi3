#!/bin/bash
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
if [ "$(whoami)" != "root" ]; then
	echo "Please run this script with sudo due to the fact that it must do a number of sudo tasks.  Exiting now."
	exit 1
fi
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo "Welcome to the AstroPi3 KStars/INDI System Updater"
echo "This script will update your SBC to all the latest software and the AstroPi3 Scripts to the latest version"

read -p "Do you wish to run this script? (y/n)" runscript
if [ "$runscript" != "y" ]
then
	echo "Quitting the script as you requested."
	exit
fi 

# Updates the computer to the latest packages.
echo "Updating installed packages"
sudo apt-get update
sudo apt-get -y upgrade
sudo apt-get -y dist-upgrade

# Updates the AstroPi3 Script to the latest version.
echo "Updating AstroPi3 Scripts"
cd $DIR
rm "$DIR/setupAstro64.sh"
rm "$DIR/setupAstroPi3.sh"
rm "$DIR/setupAstro64with32bitKStars.sh"
rm "$DIR/udevRuleScript.sh"
rm "$DIR/astrometryIndexInstaller.sh"
rm "$DIR/systemUpdater.sh"
git reset --hard
chmod +x "$DIR/setupAstro64.sh"
chmod +x "$DIR/setupAstroPi3.sh"
chmod +x "$DIR/setupAstro64with32bitKStars.sh"
chmod +x "$DIR/udevRuleScript.sh"
chmod +x "$DIR/astrometryIndexInstaller.sh"
chmod +x "$DIR/systemUpdater.sh"
sudo chown $SUDO_USER *

echo "Your requested updates are complete."

read -p "Hit [Enter] to end the script" closing

