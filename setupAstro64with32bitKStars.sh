#!/bin/bash

#	AstroPi3 Ubuntu-Mate 64 Bit Configuration Script with 32 bit KStars (for SBIG)
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
}

display "Welcome to the AstroPi3 Ubuntu-Mate 64 Bit Configuration Script with 32 bit KStars (for SBIG)."

display "This will update, install and configure your 64 bit Ubuntu-Mate system to work with 32 bit INDI and KStars to be a hub for Astrophotography.  The 32 bit KStars is because SBIG doesn't work in 64 bit right now.   If you do not plan to use an SBIG, please use the other 64 bit installer. Be sure to read the script first to see what it does and to customize it."

if [ "$(whoami)" != "root" ]; then
	display "Please run this script with sudo due to the fact that it must do a number of sudo tasks.  Exiting now."
	exit 1
fi

read -p "Are you ready to proceed (y/n)? " proceed

if [ "$proceed" != "y" ]
then
	exit
fi

#########################################################
#############  Updates

## check if DPKG database is locked
dpkg -i /dev/zero 2>/dev/null
if [ "$?" -eq 2 ]
then
    echo "dpkg is currently locked, meaning another program is either checking for updates or is currently updating the system."
    echo "Please wait for a few minutes or quit the other process and run this script again.  Exiting now."
    exit
fi

# Updates the computer to the latest packages.
display "Updating installed packages"
sudo apt-get update
sudo apt-get -y upgrade
sudo apt-get -y dist-upgrade

#########################################################
#############  Configuration for Ease of Use/Access

# This will set your account to autologin.  If you don't want this. then put a # on each line to comment it out.
display "Setting account: "$SUDO_USER" to auto login."
##################
sudo bash -c 'cat > /usr/share/lightdm/lightdm.conf.d/60-lightdm-gtk-greeter.conf' <<- EOF
[SeatDefaults]
greeter-session=lightdm-gtk-greeter
autologin-user=$SUDO_USER
EOF
##################

# Installs Synaptic Package Manager for easy software install/removal
display "Installing Synaptic"
sudo apt-get -y install synaptic

# This will enable SSH which is apparently disabled on Raspberry Pi by default.  It might be true of your system.  If so, enable this.
#display "Enabling SSH"
#sudo apt-get -y purge openssh-server
#sudo apt-get -y install openssh-server

# This will give the SBC a static IP address so that you can connect to it over an ethernet cable
# in the observing field if no router is available.
# You may need to edit this ip address to make sure the first 2 numbers match your computer's self assigned ip address
# If there is already a static IP defined, it leaves it alone.
if [ -z "$(grep 'eth0' '/etc/rc.local')" ]
then
	read -p "Do you want to give your SBC a static ip address so that you can connect to it in the observing field with no router or wifi and just an ethernet cable (y/n)? " useStaticIP
	if [ "$useStaticIP" == "y" ]
	then
		read -p "Please enter the IP address you would prefer.  Please make sure that the first two numbers match your client computer's self assigned IP.  For Example mine is: 169.254.0.5 ? " IP
		display "Setting Static IP to $IP.  Note, you can change this later by editing the file /etc/rc.local"
		sed -i "/# By default this script does nothing./ a ifconfig eth0 $IP up" /etc/rc.local
		echo "New contents of /etc/rc.local:"
		echo "$(cat /etc/rc.local)"
		echo "~~~~~~~~~~~~~~~~~~~~~~~"
		
# This will make sure that the SBC will still work over Ethernet connected directly to a router if you have assigned a static ip address as requested.
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
		display "Leaving your IP address to be assigned only by dhcp.  Note that you will always need either a router or wifi network to connect to your SBC."
	fi
else
	display "This computer already has been assigned a static ip address.  If you need to edit that, please edit the file /etc/rc.local"
fi

# Note: RealVNC does not work on the 64 bit aarch64 system so far, as far as I can tell.
# This will install x11vnc
sudo apt-get -y install x11vnc
# This will get the password for VNC
x11vnc -storepasswd /etc/x11vnc.pass
# This will store the service file.
######################
bash -c 'cat > /lib/systemd/system/x11vnc.service' << EOF
[Unit]
Description=Start x11vnc at startup.
After=multi-user.target
[Service]
Type=simple
ExecStart=/usr/bin/x11vnc -auth guess -forever -loop -noxdamage -repeat -rfbauth /etc/x11vnc.pass -rfbport 5900 -shared
[Install]
WantedBy=multi-user.target
EOF
######################
# This enables the Service so it runs at startup
sudo systemctl enable x11vnc.service
sudo systemctl daemon-reload

# This will make a folder on the desktop with the right permissions for the launchers
sudo -H -u $SUDO_USER bash -c 'mkdir -p ~/Desktop/utilities'

# This will create a shortcut on the desktop in the utilities folder for creating udev rules for Serial Devices
##################
sudo bash -c 'cat > ~/Desktop/utilities/SerialDevices.desktop' <<- EOF
#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=true
Icon[en_US]=mate-panel-launcher
Exec=sudo $(echo $DIR)/udevRuleScript.sh
Name[en_US]=Create Rule for Serial Device
Name=Create Rule for Serial Device
Icon=mate-panel-launcher
EOF
##################
sudo chmod +x ~/Desktop/utilities/SerialDevices.desktop
sudo chown $SUDO_USER ~/Desktop/utilities/SerialDevices.desktop

# This will create a shortcut on the desktop in the utilities folder for Installing Astrometry Index Files.
##################
sudo bash -c 'cat > ~/Desktop/utilities/InstallAstrometryIndexFiles.desktop' <<- EOF
#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=true
Icon[en_US]=mate-panel-launcher
Exec=sudo $(echo $DIR)/astrometryIndexInstaller.sh
Name[en_US]=Install Astrometry Index Files
Name=Install Astrometry Index Files
Icon=mate-panel-launcher
EOF
##################
sudo chmod +x ~/Desktop/utilities/InstallAstrometryIndexFiles.desktop
sudo chown $SUDO_USER ~/Desktop/utilities/InstallAstrometryIndexFiles.desktop

# This will create a shortcut on the desktop in the utilities folder for Updating the System.
##################
sudo bash -c 'cat > ~/Desktop/utilities/systemUpdater.desktop' <<- EOF
#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=true
Icon[en_US]=mate-panel-launcher
Exec=sudo $(echo $DIR)/systemUpdater.sh
Name[en_US]=Software Update
Name=Software Update
Icon=mate-panel-launcher
EOF
##################
sudo chmod +x ~/Desktop/utilities/systemUpdater.desktop
sudo chown $SUDO_USER ~/Desktop/utilities/systemUpdater.desktop

# This will create a shortcut on the desktop in the utilities folder for Backing Up and Restoring the KStars/INDI Files.
##################
sudo bash -c 'cat > ~/Desktop/utilities/backupOrRestore.desktop' <<- EOF
#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=true
Icon[en_US]=system-upgrade
Exec=$(echo $DIR)/backupOrRestore.sh
Name[en_US]=Backup or Restore
Name=Backup or Restore
Icon=system-upgrade
EOF
##################
sudo chmod +x ~/Desktop/utilities/backupOrRestore.desktop
sudo chown $SUDO_USER ~/Desktop/utilities/backupOrRestore.desktop

#########################################################
#############  Configuration for Hotspot Wifi for Connecting on the Observing Field

# This will fix a problem where AdHoc and Hotspot Networks Shut down very shortly after starting them
# Apparently it was due to power management of the wifi network by Network Manager.
# If Network Manager did not detect internet, it shut down the connections to save energy. 
# If you want to leave wifi power management enabled, put #'s in front of this section
display "Preventing Wifi Power Management from shutting down AdHoc and Hotspot Networks"
##################
sudo bash -c 'cat > /etc/NetworkManager/conf.d/default-wifi-powersave-on.conf' <<- EOF
[connection]
wifi.powersave = 2
EOF
##################

# This will create a NetworkManager Wifi Hotspot File.  
# You can edit this file to match your settings now or after the script runs in Network Manager.
# If you prefer to set this up yourself, you can comment out this section with #'s.
# If you want the hotspot to start up by default you should set autoconnect to true.
display "Creating $(hostname -s)_FieldWifi, Hotspot Wifi for the observing field"
nmcli connection add type wifi ifname '*' con-name $(hostname -s)_FieldWifi autoconnect no ssid $(hostname -s)_FieldWifi
nmcli connection modify $(hostname -s)_FieldWifi 802-11-wireless.mode ap 802-11-wireless.band bg ipv4.method shared
nmcli connection modify $(hostname -s)_FieldWifi 802-11-wireless-security.key-mgmt wpa-psk 802-11-wireless-security.psk $(hostname -s)_password

nmcli connection add type wifi ifname '*' con-name $(hostname -s)_FieldWifi_5G autoconnect no ssid $(hostname -s)_FieldWifi_5G
nmcli connection modify $(hostname -s)_FieldWifi_5G 802-11-wireless.mode ap 802-11-wireless.band a ipv4.method shared
nmcli connection modify $(hostname -s)_FieldWifi_5G 802-11-wireless-security.key-mgmt wpa-psk 802-11-wireless-security.psk $(hostname -s)_password

# This will make a link to start the hotspot wifi on the Desktop
##################
sudo bash -c 'cat > ~/Desktop/utilities/StartFieldWifi.desktop' <<- EOF
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Icon[en_US]=mate-panel-launcher
Name[en_US]=Start $(hostname -s) Field Wifi
Exec=nmcli con up $(hostname -s)_FieldWifi
Name=Start $(hostname -s)_FieldWifi 
Icon=mate-panel-launcher
EOF
##################
sudo chmod +x ~/Desktop/utilities/StartFieldWifi.desktop
sudo chown $SUDO_USER ~/Desktop/utilities/StartFieldWifi.desktop
##################
sudo bash -c 'cat > ~/Desktop/utilities/StartFieldWifi_5G.desktop' <<- EOF
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Icon[en_US]=mate-panel-launcher
Name[en_US]=Start $(hostname -s) Field Wifi 5G
Exec=nmcli con up $(hostname -s)_FieldWifi_5G
Name=Start $(hostname -s)_FieldWifi_5G
Icon=mate-panel-launcher
EOF
##################
sudo chmod +x ~/Desktop/utilities/StartFieldWifi_5G.desktop
sudo chown $SUDO_USER ~/Desktop/utilities/StartFieldWifi_5G.desktop

# This will make a link to restart Network Manager Service if there is a problem
##################
sudo bash -c 'cat > ~/Desktop/utilities/StartNmService.desktop' <<- EOF
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Icon[en_US]=mate-panel-launcher
Name[en_US]=Restart Network Manager Service
Exec=gksu systemctl restart NetworkManager.service
Name=Restart Network Manager Service
Icon=mate-panel-launcher
EOF
##################
sudo chmod +x ~/Desktop/utilities/StartNmService.desktop
sudo chown $SUDO_USER ~/Desktop/utilities/StartNmService.desktop

# This will make a link to restart nm-applet which sometimes crashes
##################
sudo bash -c 'cat > ~/Desktop/utilities/StartNmApplet.desktop' <<- EOF
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Icon[en_US]=mate-panel-launcher
Name[en_US]=Restart Network Manager Applet
Exec=nm-applet
Name=Restart Network Manager
Icon=mate-panel-launcher
EOF
##################
sudo chmod +x ~/Desktop/utilities/StartNmApplet.desktop
sudo chown $SUDO_USER ~/Desktop/utilities/StartNmApplet.desktop

#########################################################
#############  File Sharing Configuration

display "Setting up File Sharing"

# Installs samba so that you can share files to your other computer(s).
sudo apt-get -y install samba

# Installs caja-share so that you can easily share the folders you want.
sudo apt-get -y install caja-share

# Adds yourself to the user group of who can use samba.
sudo smbpasswd -a $SUDO_USER

# This makes sure that you actually get added to the right group
sudo adduser $SUDO_USER sambashare

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
# if you are using a DSLR on a system with 1GB of RAM, it definitely is needed.  If you don't want this, comment it out.
display "Installing zRAM for increased RAM capacity"
sudo apt-get -y install zram-config

# This should fix an issue where you might not be able to use a serial mount connection because you are not in the "dialout" group
display "Enabling Serial Communication"
sudo usermod -a -G dialout $SUDO_USER


#########################################################
#############  ASTRONOMY SOFTWARE

# Installs INDI, Kstars, and Ekos bleeding edge and debugging
display "Installing INDI and KStars"
sudo apt-add-repository ppa:mutlaqja/ppa -y
sudo apt-get update
sudo apt-get -fy install
sudo apt-get -y install unity-gtk2-module:armhf
sudo apt-get -y install gtk2-engines-murrine:armhf
sudo apt-get -y install topmenu-gtk2:armhf
sudo apt-get -y install topmenu-gtk3:armhf
sudo apt-get -y install libcanberra-gtk-module:armhf
sudo apt-get -y install libatk-adaptor:armhf
sudo apt-get -y install indi-full:armhf
sudo apt-get -y install libkf5auth5:armhf
sudo apt-get -y install libkf5configgui5:armhf
sudo apt-get -y install libkf5configwidgets5:armhf
sudo apt-get -y install libkf5crash5:armhf
sudo apt-get -y install libkf5kiocore5:armhf
sudo apt-get -y install libkf5kiowidgets5:armhf
sudo apt-get -y install libkf5newstuff5:armhf
sudo apt-get -y install libkf5notifications5:armhf
sudo apt-get -y install libkf5notifyconfig5:armhf
sudo apt-get -y install libkf5plotting5:armhf
sudo apt-get -y install libkf5widgetsaddons5:armhf
sudo apt-get -y install libkf5xmlgui5:armhf
sudo apt-get -y install libqt5gui5:armhf
sudo apt-get -y install libqt5printsupport5:armhf
sudo apt-get -y install libqt5quick5:armhf
sudo apt-get -y install libqt5svg5:armhf
sudo apt-get -y install libqt5widgets5:armhf
sudo apt-get -y install kstars-bleeding-data:all
sudo apt-get -y install kded5:armhf
sudo apt-get -y install kinit:armhf
sudo apt-get -y install qml-module-qtquick-controls:armhf
cd ~/Downloads
mkdir kstars32bit
cd kstars32bit
apt-get download kstars-bleeding:armhf
apt-get download kstars-bleeding-dbg
sudo dpkg --force-all -i *.deb

# Creates a config file for kde themes and icons which is missing on the Raspberry pi.
# Note:  This is required for KStars to have the breeze icons.
display "Creating KDE config file so KStars can have breeze icons."
##################
sudo bash -c 'cat > ~/.config/kdeglobals' <<- EOF
[Icons]
Theme=breeze
EOF
##################

# Installs the General Star Catalog if you plan on using the simulators to test (If not, you can comment this line out with a #)
display "Installing GSC"
sudo apt-get -y install gsc

# Installs the Astrometry.net package for supporting offline plate solves.  If you just want the online solver, comment this out with a #.
display "Installing Astrometry.net"
sudo apt-get -y install astrometry.net

# Installs PHD2 if you want it.  If not, comment each line out with a #.
display "Installing PHD2"
sudo apt-add-repository ppa:pch/phd2 -y
sudo apt-get update
sudo apt-get -y install phd2

# This will copy the desktop shortcuts into place.  If you don't want  Desktop Shortcuts, of course you can comment this out.
display "Putting shortcuts on Desktop"

sudo cp /usr/share/applications/org.kde.kstars.desktop  ~/Desktop/
sudo chmod +x ~/Desktop/org.kde.kstars.desktop
sudo chown $SUDO_USER ~/Desktop/org.kde.kstars.desktop

sudo cp /usr/share/applications/phd2.desktop  ~/Desktop/
sudo chmod +x ~/Desktop/phd2.desktop
sudo chown $SUDO_USER ~/Desktop/phd2.desktop

#########################################################
#############  INDI WEB MANAGER

display "Installing and Configuring INDI Web Manager"

# This will install pip and the headers so you can use it in the next step
sudo apt-get -y install python-pip
sudo apt-get -y install python-dev

# Setuptools may bee needed in order to install indiweb on some 64 bit systems
sudo apt-get -y install python-setuptools
sudo -H pip install setuptools --upgrade

# Wheel might not be installed on some 64 bit systems
sudo -H pip install wheel

# This will install INDI Web Manager
sudo -H pip install indiweb

# This will prepare the indiwebmanager.service file
##################
sudo bash -c 'cat > /etc/systemd/system/indiwebmanager.service' <<- EOF
[Unit]
Description=INDI Web Manager
After=multi-user.target

[Service]
Type=idle
User=$SUDO_USER
ExecStart=/usr/local/bin/indi-web -v
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
##################

# This will change the indiwebmanager.service file permissions and enable it.
sudo chmod 644 /etc/systemd/system/indiwebmanager.service
sudo systemctl daemon-reload
sudo systemctl enable indiwebmanager.service

# This will make a link to the Web Manager on the Desktop
##################
sudo bash -c 'cat > ~/Desktop/INDIWebManager.desktop' <<- EOF
[Desktop Entry]
Encoding=UTF-8
Name=INDI Web Manager
Type=Link
URL=http://localhost:8624
Icon=/usr/local/lib/python2.7/dist-packages/indiweb/views/img/indi_logo.png
EOF
##################
sudo chmod +x ~/Desktop/INDIWebManager.desktop
sudo chown $SUDO_USER ~/Desktop/INDIWebManager.desktop
#########################################################
#############  Configuration for System Monitoring

# This will set you up with conky so that you can see how your system is doing at a moment's glance
# A big thank you to novaspirit who set up this theme https://github.com/novaspirit/rpi_conky
sudo apt-get -y install conky-all
cp "$DIR/conkyrc" ~/.conkyrc
sudo chown $SUDO_USER ~/.conkyrc

# This will put a link into the autostart folder so it starts at login
##################
sudo bash -c 'cat > /usr/share/mate/autostart/startConky.desktop' <<- EOF
[Desktop Entry]
Name=StartConky
Exec=conky -b
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

display "Script Execution Complete.  Your Ubuntu Mate System should now be ready to use for Astrophotography.  You should restart your computer."