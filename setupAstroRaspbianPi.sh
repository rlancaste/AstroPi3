#!/bin/bash

#	AstroRaspbianPi Raspberry Pi 3/4 Raspbian KStars/INDI Configuration Script
#﻿  Copyright (C) 2018 Robert Lancaster <rlancaste@gmail.com>
#	This script is free software; you can redistribute it and/or
#	modify it under the terms of the GNU General Public
#	License as published by the Free Software Foundation; either
#	version 2 of the License, or (at your option) any later version.

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

function display
{
    echo ""
    echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    echo "~ $*"
    echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    echo ""
    
    # This will display the message in the title bar (Note that the PS1 variable needs to be changed too--see below)
    echo -en "\033]0;AstroPi3-SetupAstroRaspbianPi-$*\a"
}

display "Welcome to the AstroPi3 Raspberry Pi 3 Raspbian KStars/INDI Configuration Script."

display "This will update, install and configure your Raspberry Pi 3 to work with INDI and KStars to be a hub for Astrophotography. Be sure to read the script first to see what it does and to customize it."

if [ "$(whoami)" != "root" ]; then
	display "Please run this script with sudo due to the fact that it must do a number of sudo tasks.  Exiting now."
	exit 1
fi

read -p "Are you ready to proceed (y/n)? " proceed

if [ "$proceed" != "y" ]
then
	exit
fi

export USERHOME=$(sudo -u $SUDO_USER -H bash -c 'echo $HOME')

# This changes the UserPrompt for the Setup Script (Necessary to make the messages display in the title bar)
PS1='AstroPi3-SetupAstroRaspbianPi~$ '

#########################################################
#############  Updates

# This would update the Raspberry Pi kernel.  For now it is disabled because there is debate about whether to do it or not.  To enable it, take away the # sign.
#display "Updating Kernel"
#sudo rpi-update 

# Updates the Raspberry Pi to the latest packages.
display "Updating installed packages"
sudo apt update
sudo apt -y upgrade
sudo apt -y dist-upgrade

#########################################################
#############  Configuration for Ease of Use/Access

# This will set your account to autologin.  If you don't want this. then put a # on each line to comment it out.
display "Setting account: "$SUDO_USER" to auto login."
if [ -n "$(grep '#autologin-user' '/etc/lightdm/lightdm.conf')" ]
then
	sed -i "s/#autologin-user=/autologin-user=$SUDO_USER/g" /etc/lightdm/lightdm.conf
	sed -i "s/#autologin-user-timeout=0/autologin-user-timeout=0/g" /etc/lightdm/lightdm.conf
fi

display "Setting HDMI settings in /boot/config.txt."

# This pretends an HDMI display is connected at all times, otherwise, the pi might shut off HDMI
# So that when you go to plug in an HDMI connector to diagnose a problem, it doesn't work
# This makes the HDMI output always available
if [ -n "$(grep '#hdmi_force_hotplug=1' '/boot/config.txt')" ]
then
	sed -i "s/#hdmi_force_hotplug=1/hdmi_force_hotplug=1/g" /boot/config.txt
fi

# This sets the group for the HDMI mode.  Please see the config file for details about all the different modes
# There are many options.  I selected group 1 mode 46 because that matches my laptop's resolution.
# You might want a different mode and group if you want a certain resolution in VNC
if [ -n "$(grep '#hdmi_group=1' '/boot/config.txt')" ]
then
	sed -i "s/#hdmi_group=1/hdmi_group=2/g" /boot/config.txt
fi

# This sets the HDMI mode.  Please see the config file for details about all the different modes
# There are many options.  I selected group 1 mode 46 because that matches my laptop's resolution.
# You might want a different mode and group if you want a certain resolution in VNC
if [ -n "$(grep '#hdmi_mode=1' '/boot/config.txt')" ]
then
	sed -i "s/#hdmi_mode=1/hdmi_mode=46/g" /boot/config.txt
fi

# This comments out a line in Raspbian's config file that seems to prevent the desired screen resolution in VNC
# The logic here is that if the line does exist, and if the line is not commented out, comment it out.
if [ -n "$(grep 'dtoverlay=vc4-kms-v3d' '/boot/config.txt')" ]
then
	if [ -z "$(grep '#dtoverlay=vc4-kms-v3d' '/boot/config.txt')" ]
	then
		sed -i "s/dtoverlay=vc4-kms-v3d/#dtoverlay=vc4-kms-v3d/g" /boot/config.txt
	fi
fi

# This will prevent the raspberry pi from turning on the lock-screen / screensaver which can be problematic when using VNC
if [ -z "$(grep 'xserver-command=X -s 0 dpms' '/etc/lightdm/lightdm.conf')" ]
then
	sed -i "/\[Seat:\*\]/ a xserver-command=X -s 0 dpms" /etc/lightdm/lightdm.conf
fi

# Installs Synaptic Package Manager for easy software install/removal
display "Installing Synaptic"
sudo apt -y install synaptic

# This will enable SSH which is apparently disabled on Raspberry Pi by default.
display "Enabling SSH"
sudo apt -y install openssh-server
sudo systemctl enable ssh
sudo systemctl start ssh

# This will install and configure network manager and remove dhcpcd5 because it has some issues
# Also the commands below that setup networking depend upon network manager.
sudo apt -y install network-manager network-manager-gnome
sudo apt purge -y openresolv dhcpcd5

# This will give the Raspberry Pi a static IP address so that you can connect to it over an ethernet cable
# in the observing field if no router is available.
# You may need to edit this ip address to make sure the first 2 numbers match your computer's self assigned ip address
# If there is already a static IP defined, it leaves it alone.
if [ -z "$(grep 'ip=' '/boot/cmdline.txt')" ]
then
	read -p "Do you want to give your pi a static ip address so that you can connect to it in the observing field with no router or wifi and just an ethernet cable (y/n)? " useStaticIP
	if [ "$useStaticIP" == "y" ]
	then
		read -p "Please enter the IP address you would prefer.  Please make sure that the first two numbers match your client computer's self assigned IP.  For Example mine is: 169.254.0.5 ? " IP
		display "Setting Static IP to $IP.  Note, you can change this later by editing the file /boot/cmdline.txt"
		echo "New contents of /boot/cmdline.txt:"
		echo -n $(cat /boot/cmdline.txt) "ip=$IP" | sudo tee /boot/cmdline.txt
		echo ""
		
# This will make sure that the pi will still work over Ethernet connected directly to a router if you have assigned a static ip address as requested.
##################
sudo cat > /etc/network/interfaces <<- EOF
# interfaces(5) file used by ifup(8) and ifdown(8)
# Include files from /etc/network/interfaces.d:
source-directory /etc/network/interfaces.d

# The loopback network interface
auto lo
iface lo inet loopback

# These two lines allow the pi to respond to a router's dhcp even though you have a static ip defined.
allow-hotplug eth0
iface eth0 inet dhcp
EOF
##################
	else
		display "Leaving your IP address to be assigned only by dhcp.  Note that you will always need either a router or wifi network to connect to your pi."
	fi
else
	display "This computer already has been assigned a static ip address.  If you need to edit that, please edit the file /boot/cmdline.txt"
fi

# To view the Raspberry Pi Remotely, this installs RealVNC Servier and enables it to run by default.
display "Installing RealVNC Server"
sudo apt install realvnc-vnc-server
sudo systemctl enable vncserver-x11-serviced.service
sudo systemctl start vncserver-x11-serviced.service

# This will make a folder on the desktop for the launchers if it doesn't exist already
if [ ! -d "$USERHOME/Desktop/utilities" ]
then
	mkdir -p $USERHOME/Desktop/utilities
	sudo chown $SUDO_USER $USERHOME/Desktop/utilities
fi

# This will create a shortcut on the desktop in the utilities folder for creating udev rules for Serial Devices.
##################
sudo cat > $USERHOME/Desktop/utilities/SerialDevices.desktop <<- EOF
#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=true
Icon[en_US]=plip
Exec=sudo $(echo $DIR)/udevRuleScript.sh
Name[en_US]=Create Rule for Serial Device
Name=Create Rule for Serial Device
Icon=$(echo $DIR)/icons/plip.png
EOF
##################
sudo chmod +x $USERHOME/Desktop/utilities/SerialDevices.desktop
sudo chown $SUDO_USER $USERHOME/Desktop/utilities/SerialDevices.desktop

# This will create a shortcut on the desktop in the utilities folder for Installing Astrometry Index Files.
##################
sudo cat > $USERHOME/Desktop/utilities/InstallAstrometryIndexFiles.desktop <<- EOF
#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=true
Icon[en_US]=mate-preferences-desktop-display
Exec=sudo $(echo $DIR)/astrometryIndexInstaller.sh
Name[en_US]=Install Astrometry Index Files
Name=Install Astrometry Index Files
Icon=$(echo $DIR)/icons/mate-preferences-desktop-display.svg
EOF
##################
sudo chmod +x $USERHOME/Desktop/utilities/InstallAstrometryIndexFiles.desktop
sudo chown $SUDO_USER $USERHOME/Desktop/utilities/InstallAstrometryIndexFiles.desktop

# This will create a shortcut on the desktop in the utilities folder for Updating the System.
##################
sudo cat > $USERHOME/Desktop/utilities/systemUpdater.desktop <<- EOF
#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=true
Icon[en_US]=system-software-update
Exec=sudo $(echo $DIR)/systemUpdater.sh
Name[en_US]=Software Update
Name=Software Update
Icon=$(echo $DIR)/icons/system-software-update.svg
EOF
##################
sudo chmod +x $USERHOME/Desktop/utilities/systemUpdater.desktop
sudo chown $SUDO_USER $USERHOME/Desktop/utilities/systemUpdater.desktop

# This will create a shortcut on the desktop in the utilities folder for Backing Up and Restoring the KStars/INDI Files.
##################
sudo cat > $USERHOME/Desktop/utilities/backupOrRestore.desktop <<- EOF
#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Icon[en_US]=system-upgrade
Exec=mate-terminal -e '$(echo $DIR)/backupOrRestore.sh'
Name[en_US]=Backup or Restore
Name=Backup or Restore
Icon=$(echo $DIR)/icons/system-upgrade.svg
EOF
##################
sudo chmod +x $USERHOME/Desktop/utilities/backupOrRestore.desktop
sudo chown $SUDO_USER $USERHOME/Desktop/utilities/backupOrRestore.desktop

#########################################################
#############  Configuration for Hotspot Wifi for Connecting on the Observing Field

# This will fix a problem where AdHoc and Hotspot Networks Shut down very shortly after starting them
# Apparently it was due to power management of the wifi network by Network Manager.
# If Network Manager did not detect internet, it shut down the connections to save energy. 
# If you want to leave wifi power management enabled, put #'s in front of this section
display "Preventing Wifi Power Management from shutting down AdHoc and Hotspot Networks"
##################
sudo cat > /etc/NetworkManager/conf.d/default-wifi-powersave-on.conf <<- EOF
[connection]
wifi.powersave = 2
EOF
##################

# This will create a NetworkManager Wifi Hotspot File.  
# You can edit this file to match your settings now or after the script runs in Network Manager.
# If you prefer to set this up yourself, you can comment out this section with #'s.
# If you want the hotspot to start up by default you should set autoconnect to true.
display "Creating $(hostname -s)_FieldWifi, Hotspot Wifi for the observing field"
if [ -z "$(ls /etc/NetworkManager/system-connections/ | grep $(hostname -s)_FieldWifi)" ]
then

	nmcli connection add type wifi ifname '*' con-name $(hostname -s)_FieldWifi autoconnect no ssid $(hostname -s)_FieldWifi
	nmcli connection modify $(hostname -s)_FieldWifi 802-11-wireless.mode ap 802-11-wireless.band bg ipv4.method shared
	nmcli connection modify $(hostname -s)_FieldWifi 802-11-wireless-security.key-mgmt wpa-psk 802-11-wireless-security.psk $(hostname -s)_password

	nmcli connection add type wifi ifname '*' con-name $(hostname -s)_FieldWifi_5G autoconnect no ssid $(hostname -s)_FieldWifi_5G
	nmcli connection modify $(hostname -s)_FieldWifi_5G 802-11-wireless.mode ap 802-11-wireless.band a ipv4.method shared
	nmcli connection modify $(hostname -s)_FieldWifi_5G 802-11-wireless-security.key-mgmt wpa-psk 802-11-wireless-security.psk $(hostname -s)_password
else
	echo "$(hostname -s)_FieldWifi is already setup."
fi

# This will make a link to start the hotspot wifi on the Desktop
##################
sudo cat > $USERHOME/Desktop/utilities/StartFieldWifi.desktop <<- EOF
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Icon[en_US]=irda
Name[en_US]=Start $(hostname -s) Field Wifi
Exec=nmcli con up $(hostname -s)_FieldWifi
Name=Start $(hostname -s)_FieldWifi 
Icon=$(echo $DIR)/icons/irda.png
EOF
##################
sudo chmod +x $USERHOME/Desktop/utilities/StartFieldWifi.desktop
sudo chown $SUDO_USER $USERHOME/Desktop/utilities/StartFieldWifi.desktop
##################
sudo cat > $USERHOME/Desktop/utilities/StartFieldWifi_5G.desktop <<- EOF
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Icon[en_US]=irda
Name[en_US]=Start $(hostname -s) Field Wifi 5G
Exec=nmcli con up $(hostname -s)_FieldWifi_5G
Name=Start $(hostname -s)_FieldWifi_5G
Icon=$(echo $DIR)/icons/irda.png
EOF
##################
sudo chmod +x $USERHOME/Desktop/utilities/StartFieldWifi_5G.desktop
sudo chown $SUDO_USER $USERHOME/Desktop/utilities/StartFieldWifi_5G.desktop

# This will make a link to restart Network Manager Service if there is a problem or to go back to regular wifi after using the adhoc connection
##################
sudo cat > $USERHOME/Desktop/utilities/StartNmService.desktop <<- EOF
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Icon[en_US]=preferences-system-network
Name[en_US]=Restart Network Manager Service
Exec=gksu systemctl restart NetworkManager.service
Name=Restart Network Manager Service
Icon=$(echo $DIR)/icons/preferences-system-network.svg
EOF
##################
sudo chmod +x $USERHOME/Desktop/utilities/StartNmService.desktop
sudo chown $SUDO_USER $USERHOME/Desktop/utilities/StartNmService.desktop

# This will make a link to restart nm-applet which sometimes crashes
##################
sudo cat > $USERHOME/Desktop/utilities/StartNmApplet.desktop <<- EOF
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Icon[en_US]=preferences-system-network
Name[en_US]=Restart Network Manager Applet
Exec=nm-applet
Name=Restart Network Manager
Icon=$(echo $DIR)/icons/preferences-system-network.svg
EOF
##################
sudo chmod +x $USERHOME/Desktop/utilities/StartNmApplet.desktop
sudo chown $SUDO_USER $USERHOME/Desktop/utilities/StartNmApplet.desktop

#########################################################
#############  File Sharing Configuration

display "Setting up File Sharing"

# Installs samba so that you can share files to your other computer(s).
sudo apt -y install samba

# Installs caja-share so that you can easily share the folders you want.
sudo apt -y install caja-share

# Adds yourself to the user group of who can use samba, but checks first if you are already in the list
if [ -z "$(sudo pdbedit -L | grep $SUDO_USER)" ]
then
	sudo smbpasswd -a $SUDO_USER
	sudo adduser $SUDO_USER sambashare
fi

#########################################################
#############  Very Important Configuration Items

# This will create a swap file for an increased 2 GB of artificial RAM.  This is not needed on all systems, since different cameras download different size images, but if you are using a DSLR, it definitely is.
# This method is disabled in favor of the zram method below. If you prefer this method, you can re-enable it by taking out the #'s
#display "Creating SWAP Memory"
#wget https://raw.githubusercontent.com/Cretezy/Swap/master/swap.sh -O swap
#sh swap 2G
#rm swap

# This will create zram, basically a swap file saved in RAM. It will not read or write to the SD card, but instead, writes to compressed RAM.  
# This is not needed on all systems, since different cameras download different size images, and different SBC's have different RAM capacities but 
# if you are using a DSLR on a Raspberry Pi with 1GB of RAM, it definitely is needed. If you don't want this, comment it out.
display "Installing zRAM for increased RAM capacity"
sudo wget -O /usr/bin/zram.sh https://raw.githubusercontent.com/novaspirit/rpi_zram/master/zram.sh
sudo chmod +x /usr/bin/zram.sh

if [ -z "$(grep '/usr/bin/zram.sh' '/etc/rc.local')" ]
then
   sed -i "/^exit 0/i /usr/bin/zram.sh &" /etc/rc.local
fi

# This should fix an issue where you might not be able to use a serial mount connection because you are not in the "dialout" group
display "Enabling Serial Communication"
sudo usermod -a -G dialout $SUDO_USER


#########################################################
#############  ASTRONOMY SOFTWARE


# Creates a config file for kde themes and icons which is missing on the Raspberry pi.
# Note:  This is required for KStars to have the breeze icons.
sudo apt -y install breeze-icon-theme
display "Creating KDE config file so KStars can have breeze icons."
##################
sudo cat > $USERHOME/.config/kdeglobals <<- EOF
[Icons]
Theme=breeze
EOF
##################

# Installs Pre Requirements for INDI
sudo apt -y install libnova-dev libcfitsio-dev libusb-1.0-0-dev libusb-dev zlib1g-dev libgsl-dev build-essential cmake git libjpeg-dev libcurl4-gnutls-dev libtiff-dev
sudo apt -y install libftdi-dev libgps-dev libraw-dev libdc1394-22-dev libgphoto2-dev libboost-dev libboost-regex-dev librtlsdr-dev liblimesuite-dev libftdi1-dev

#sudo apt install cdbs fxload libkrb5-dev dkms Are these needed too???

sudo -H -u $SUDO_USER mkdir -p $USERHOME/AstroRoot

# This builds and installs INDI
display "Building and Installing INDI"

if [ ! -d $USERHOME/AstroRoot/indi ]
then
	cd $USERHOME/AstroRoot/
	sudo -H -u $SUDO_USER git clone https://github.com/indilib/indi.git 
	sudo -H -u $SUDO_USER mkdir -p $USERHOME/AstroRoot/indi-build
else
	cd $USERHOME/AstroRoot/indi
	sudo -H -u $SUDO_USER git pull
fi

display "Building and Installing core LibINDI"
sudo -H -u $SUDO_USER mkdir -p $USERHOME/AstroRoot/indi-build/libindi
cd $USERHOME/AstroRoot/indi-build/libindi
sudo -H -u $SUDO_USER cmake -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=Debug $USERHOME/AstroRoot/indi/libindi
sudo -H -u $SUDO_USER make
sudo make install

display "Building and Installing the INDI 3rd Party Libraries"
sudo -H -u $SUDO_USER mkdir -p $USERHOME/AstroRoot/indi-build/3rdpartyLibraries
sudo -H -u $SUDO_USER cd $USERHOME/AstroRoot/indi-build/3rdpartyLibraries
sudo -H -u $SUDO_USER cmake -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=Debug -DBUILD_LIBS=1 $USERHOME/AstroRoot/indi/3rdparty
sudo -H -u $SUDO_USER make
sudo make install

display "Building and Installing the INDI 3rd Party Drivers"
sudo -H -u $SUDO_USER mkdir -p $USERHOME/AstroRoot/indi-build/3rdpartyDrivers
cd $USERHOME/AstroRoot/indi-build/3rdpartyDrivers
sudo -H -u $SUDO_USER cmake -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=Debug $USERHOME/AstroRoot/indi/3rdparty
sudo -H -u $SUDO_USER make
sudo make install

# Installs the Astrometry.net package for supporting offline plate solves.  If you just want the online solver, comment this out with a #.
display "Installing Astrometry.net"
sudo apt -y install astrometry.net

# Installs the optional xplanet package for simulating the solar system.  If you don't want it, comment this out with a #.
display "Installing XPlanet"
sudo apt -y install xplanet

# Installs Pre Requirements for KStars
sudo apt -y install build-essential cmake git libeigen3-dev libcfitsio-dev zlib1g-dev libindi-dev extra-cmake-modules libkf5plotting-dev libqt5svg5-dev libkf5iconthemes-dev wcslib-dev
sudo apt -y install libkf5xmlgui-dev kio-dev kinit-dev libkf5newstuff-dev kdoctools-dev libkf5notifications-dev libqt5websockets5-dev qtdeclarative5-dev libkf5crash-dev gettext qml-module-qtquick-controls qml-module-qtquick-layouts

#This builds and installs KStars
display "Building and Installing KStars"

if [ ! -d $USERHOME/AstroRoot/kstars ]
then
	cd $USERHOME/AstroRoot/
	sudo -H -u $SUDO_USER git clone git://anongit.kde.org/kstars
	sudo -H -u $SUDO_USER mkdir -p $USERHOME/AstroRoot/kstars-build
else
	cd $USERHOME/AstroRoot/kstars
	sudo -H -u $SUDO_USER git pull
fi

cd $USERHOME/AstroRoot/kstars-build
sudo -H -u $SUDO_USER cmake -DCMAKE_INSTALL_PREFIX=/usr $USERHOME/AstroRoot/kstars/
sudo -H -u $SUDO_USER make
sudo make install

# Installs the General Star Catalog if you plan on using the simulators to test (If not, you can comment this line out with a #)
display "Building and Installing GSC"
sudo -H -u $SUDO_USER mkdir -p $USERHOME/AstroRoot/gsc
cd $USERHOME/AstroRoot/gsc
if [ ! -f $USERHOME/AstroRoot/gsc/bincats_GSC_1.2.tar.gz ]
then
	sudo -H -u $SUDO_USER wget -O bincats_GSC_1.2.tar.gz http://cdsarc.u-strasbg.fr/viz-bin/nph-Cat/tar.gz?bincats/GSC_1.2
fi
sudo -H -u $SUDO_USER tar -xvzf bincats_GSC_1.2.tar.gz
cd $USERHOME/AstroRoot/gsc/src
sudo -H -u $SUDO_USER make
sudo -H -u $SUDO_USER mv gsc.exe gsc
sudo cp gsc /usr/bin/
cp -r $USERHOME/AstroRoot/gsc /usr/share/
sudo mv /usr/share/gsc /usr/share/GSC
sudo rm -r /usr/share/GSC/bin-dos
sudo rm -r /usr/share/GSC/src
sudo rm /usr/share/GSC/bincats_GSC_1.2.tar.gz
sudo rm /usr/share/GSC/bin/gsc.exe
sudo rm /usr/share/GSC/bin/decode.exe

if [ -z "$(grep 'export GSCDAT' /etc/profile)" ]
then
	cp /etc/profile /etc/profile.copy
	echo "export GSCDAT=/usr/share/GSC" >> /etc/profile
fi

# Installs PHD2 if you want it.  If not, comment each line out with a #.
sudo apt -y install libwxgtk3.0-dev
display "Building and Installing PHD2"

if [ ! -d $USERHOME/AstroRoot/phd2 ]
then
	cd $USERHOME/AstroRoot/
	sudo -H -u $SUDO_USER git clone https://github.com/OpenPHDGuiding/phd2.git
	sudo -H -u $SUDO_USER mkdir -p $USERHOME/AstroRoot/phd2-build
else
	cd $USERHOME/AstroRoot/phd2
	sudo -H -u $SUDO_USER git pull
fi

cd $USERHOME/AstroRoot/phd2-build
sudo -H -u $SUDO_USER cmake -DOPENSOURCE_ONLY=1 $USERHOME/AstroRoot/phd2
sudo -H -u $SUDO_USER make
sudo make install

# This will copy the desktop shortcuts into place.  If you don't want  Desktop Shortcuts, of course you can comment this out.
display "Putting shortcuts on Desktop"

sudo cp /usr/share/applications/org.kde.kstars.desktop  $USERHOME/Desktop/
sudo chmod +x $USERHOME/Desktop/org.kde.kstars.desktop
sudo chown $SUDO_USER $USERHOME/Desktop/org.kde.kstars.desktop

sudo cp /usr/share/applications/phd2.desktop  $USERHOME/Desktop/
sudo chmod +x $USERHOME/Desktop/phd2.desktop
sudo chown $SUDO_USER $USERHOME/Desktop/phd2.desktop

#########################################################
#############  INDI WEB MANAGER APP

display "Building and Installing INDI Web Manager App, indiweb, and python3"

# This will install pip3
sudo apt -y install python3-pip

# This will install indiweb as the user
sudo -H -u $SUDO_USER pip3 install indiweb

# This will clone or update the repo
if [ ! -d $USERHOME/AstroRoot/INDIWebManagerApp ]
then
	cd $USERHOME/AstroRoot/
	sudo -H -u $SUDO_USER git clone https://github.com/rlancaste/INDIWebManagerApp.git
	sudo -H -u $SUDO_USER mkdir -p $USERHOME/AstroRoot/INDIWebManagerApp-build
else
	cd $USERHOME/AstroRoot/INDIWebManagerApp
	sudo -H -u $SUDO_USER git pull
fi

# This will make and install the program
cd $USERHOME/AstroRoot/INDIWebManagerApp-build
sudo -H -u $SUDO_USER cmake -DCMAKE_INSTALL_PREFIX=/usr $USERHOME/AstroRoot/INDIWebManagerApp/
sudo -H -u $SUDO_USER make
sudo make install

# This will make a link to start INDIWebManagerApp on the desktop
##################
sudo cat > $USERHOME/Desktop/INDIWebManagerApp.desktop <<- EOF
[Desktop Entry]
Encoding=UTF-8
Name=INDI Web Manager App
Type=Application
Exec=INDIWebManagerApp %U
Icon=$(python3 -m site --user-site)/indiweb/views/img/indi_logo.png
Comment=Program to start and configure INDI WebManager
EOF
##################
sudo chmod +x $USERHOME/Desktop/INDIWebManagerApp.desktop
sudo chown $SUDO_USER $USERHOME/Desktop/INDIWebManagerApp.desktop
##################

#########################################################
#############  Configuration for System Monitoring

# This will set you up with conky so that you can see how your system is doing at a moment's glance
# A big thank you to novaspirit who set up this theme https://github.com/novaspirit/rpi_conky
sudo apt -y install conky-all
cp "$DIR/conkyrc" $USERHOME/.conkyrc
sudo chown $SUDO_USER $USERHOME/.conkyrc

# This will put a link into the autostart folder so it starts at login
##################
mkdir -p $USERHOME/.config/autostart
sudo cat > $USERHOME/.config/autostart/startConky.desktop <<- EOF
[Desktop Entry]
Name=StartConky
Exec=conky -d
Terminal=false
Type=Application
EOF
##################
# Note that in order to work, this link needs to stay owned by root and not be executable


#########################################################


# This will make the utility scripts in the folder executable in case the user wants to use them.
chmod +x "$DIR/udevRuleScript.sh"
chmod +x "$DIR/astrometryIndexInstaller.sh"
chmod +x "$DIR/systemUpdater.sh"
chmod +x "$DIR/backupOrRestore.sh"

display "Script Execution Complete.  Your Raspberry Pi 3 should now be ready to use for Astrophotography.  You should restart your Pi."