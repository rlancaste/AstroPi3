#!/bin/bash

#	AstroPi3 Manjaro SBC KStars/INDI Configuration Script
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
    echo -en "\033]0;AstroPi3-SetupManjaroSBC-$*\a"
}

display "Welcome to the AstroPi3 Manjaro SBC KStars/INDI Configuration Script."

display "This will update, install and configure your Manjaro System to work with INDI and KStars to be a hub for Astrophotography. Be sure to read the script first to see what it does and to customize it."

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
PS1='AstroPi3-SetupManjaroSBC~$ '

#########################################################
#############  Updates


# Updates the computer to the latest packages.
display "Updating installed packages"
sudo pacman -Syu --noconfirm

# Making sure yay is installed for the use of the AUR Packages
sudo pacman -S --noconfirm --needed yay

# Updates the AUR Packages and their Dependencies
sudo -H -u $SUDO_USER yay -Syu --noconfirm

# Installs some packages yay will need
sudo pacman -S --noconfirm --needed patch cmake make gcc pkg-config fakeroot

#########################################################
#############  Configuration for Ease of Use/Access

# This makes sure there is a config folder owned by the user, since many things depend on it.
mkdir -p $USERHOME/.config
sudo chown $SUDO_USER:users $USERHOME/.config

# This will set up the SBC so that double clicking on desktop icons brings up the program right away
# The default behavior is to ask what you want to do with the executable file.
display "Setting desktop icons to open programs when you click them."
if [ -f $USERHOME/.config/pcmanfm-qt/lxqt/settings.conf ]
then
	sed -i "s/QuickExec=false/QuickExec=true/g" $USERHOME/.config/pcmanfm-qt/lxqt/settings.conf
fi
if [ -f $USERHOME/.config/pcmanfm-qt/default/settings.conf ]
then
	sed -i "s/QuickExec=false/QuickExec=true/g" $USERHOME/.config/pcmanfm-qt/default/settings.conf
fi
if [ -f $USERHOME/.config/libfm/libfm.conf ]
then
	if [ -z "$(grep 'quick_exec' $USERHOME/.config/libfm/libfm.conf)" ]
	then
		sed -i "/\[config\]/ a quick_exec=1" $USERHOME/.config/libfm/libfm.conf
	else
		sed -i "s/quick_exec=0/quick_exec=1/g" $USERHOME/.config/libfm/libfm.conf
	fi
fi
if [ -f /etc/xdg/libfm/libfm.conf ]
then
	if [ -z "$(grep 'quick_exec' /etc/xdg/libfm/libfm.conf)" ]
	then
		sed -i "/\[config\]/ a quick_exec=1" /etc/xdg/libfm/libfm.conf
	else
		sed -i "s/quick_exec=0/quick_exec=1/g" /etc/xdg/libfm/libfm.conf
	fi
fi

# In the Raspberry Pi scripts, I set the HDMI options in the /boot/config.txt file.  Manjaro doesn't have that
# You should try to come up with some way to set the resolution when headless

# This will set your account to autologin.  If you don't want this. then put a # on each line to comment it out.
display "Setting account: "$SUDO_USER" to auto login."
if [ -n "$(grep '/usr/s\?bin/sddm' '/etc/systemd/system/display-manager.service')" ] && [ -f /etc/sddm.conf ]
then
	if [ -z "$(grep User=$SUDO_USER '/etc/sddm.conf')" ]
	then
		sed -i "s/^User=.*/User=$SUDO_USER/1" /etc/sddm.conf
	fi
	
	sed -i "s/Relogin=false/Relogin=true/1" /etc/sddm.conf
	
	if [ -z "$(grep 'Session=lxqt.desktopt' '/etc/sddm.conf')" ]
	then
		sed -i "s/^Session=.*/Session=lxqt.desktop/1" /etc/sddm.conf
	fi
fi

# This will prevent the SBC from turning on the lock-screen / powersave function which can be problematic when using VNC
if [ -f $USERHOME/.config/lxqt/lxqt-powermanagement.conf ]
then
	sed -i "s/enableBatteryWatcher=true/enableBatteryWatcher=false/g" $USERHOME/.config/lxqt/lxqt-powermanagement.conf
	sed -i "s/enableExtMonLidClosedActions=true/enableExtMonLidClosedActions=false/g" $USERHOME/.config/lxqt/lxqt-powermanagement.conf
	sed -i "s/enableIdlenessWatcher=true/enableIdlenessWatcher=false/g" $USERHOME/.config/lxqt/lxqt-powermanagement.conf
	sed -i "s/enableLidWatcher=true/enableLidWatcher=false/g" $USERHOME/.config/lxqt/lxqt-powermanagement.conf
fi

# This will enable SSH which is apparently disabled on some SBCs by default.
display "Enabling SSH"
sudo pacman -S --noconfirm --needed openssh
sudo systemctl enable sshd
sudo systemctl start sshd

# This adds avahi to local hostnaming is enabled.
display "Enabling Avahi for local hostnames"
sudo pacman -S --noconfirm --needed nss-mdns 
sudo systemctl enable avahi-daemon

# This will install and configure network manager and remove dhcpcd5 if installed because it has some issues
# Also the commands below that setup networking depend upon network manager.
display "Installing network manager"
sudo pacman -S --noconfirm --needed networkmanager nm-connection-editor network-manager-applet
sudo systemctl enable NetworkManager.service

display "Making sure dhcpcd5 is not installed"
if [ -n "$(pacman -Qi | awk '/^Name/' | grep dhcpcd5)" ]
then
	sudo systemctl disable dhcpcd.service
	sudo apt purge -y openresolv dhcpcd5
	# This should remove the old manager panel from the taskbar
	if [ -n "$(grep 'type=dhcpcdui' $USERHOME/.config/lxpanel/LXDE-$SUDO_USER/panels/panel)" ]
	then
		sed -i "s/type=dhcpcdui/type=space/g" $USERHOME/.config/lxpanel/LXDE-$SUDO_USER/panels/panel
	fi
	if [ -n "$(grep 'type=dhcpcdui' /etc/xdg/lxpanel/LXDE-$SUDO_USER/panels/panel)" ]
	then
		sed -i "s/type=dhcpcdui/type=space/g" /etc/xdg/lxpanel/LXDE-$SUDO_USER/panels/panel
	fi
	if [ -n "$(grep 'type=dhcpcdui' /etc/xdg/lxpanel/LXDE/panels/panel)" ]
	then
		sed -i "s/type=dhcpcdui/type=space/g" /etc/xdg/lxpanel/LXDE/panels/panel
	fi
else
	echo "dhcpcd5 is not installed"
fi

# This will set up your Pi to have access to internet with wifi, ethernet with DHCP, and ethernet with direct connection
display "Setting up Ethernet for both link-local and DHCP"
if [ -z "$(ls /etc/NetworkManager/system-connections/ | grep Link\ Local\ Ethernet)" ]
then
	read -p "Do you want to give your pi a static ip address so that you can connect to it in the observing field with no router or wifi and just an ethernet cable (y/n)? " useStaticIP
	if [ "$useStaticIP" == "y" ]
	then
		read -p "Please enter the IP address you would prefer.  Please make sure that the first two numbers match your client computer's self assigned IP.  For Example mine is: 169.254.0.5 ? " IP
		if [[ "$IP" =~ ^(([1-9]?[0-9]|1[0-9][0-9]|2([0-4][0-9]|5[0-5]))\.){3}([1-9]?[0-9]|1[0-9][0-9]|2([0-4][0-9]|5[0-5]))$ ]] # Note that this formula came from Jon in the thread: https://stackoverflow.com/questions/13777387/check-for-ip-validity
		then
			echo "IP Address is in correct format, proceeding"
			
			# This will make sure that network manager can manage whether the ethernet connection is on or off and then you can change the connection in network maanager.
			if [ -n "$(grep 'managed=false' /etc/NetworkManager/NetworkManager.conf)" ]
			then
				sed -i "s/managed=false/managed=true/g" /etc/NetworkManager/NetworkManager.conf
			fi
	
			# This section should add two connections, one for connecting to ethernet with a router and the other for connecting directly to a computer in the observing field with a Link Local IP
			nmcli connection add type ethernet ifname eth0 con-name "Wired DHCP Ethernet" autoconnect yes
			nmcli connection modify "Wired DHCP Ethernet" connection.autoconnect-priority 2 	# Higher Priority because then it tries DHCP first and then switches to Link Local as a backup
			nmcli connection modify "Wired DHCP Ethernet" ipv4.dhcp-timeout 5 					# This sets the timeout for DHCP to a much shorter time so you don't have to wait forever for Link Local
			nmcli connection modify "Wired DHCP Ethernet" ipv4.may-fail no 						# I'm not sure why this is needed, but without it, it doesn't seem to want to switch to link local
			nmcli connection modify "Wired DHCP Ethernet" connection.autoconnect-retries 2		# These last two might not be necessary, but they might be needed if the global settings are to infinitely retry
			nmcli connection modify "Wired DHCP Ethernet" connection.auth-retries 2
	
			nmcli connection add type ethernet ifname eth0 con-name "Link Local Ethernet" autoconnect yes ip4 $IP/24
			nmcli connection modify "Link Local Ethernet" connection.autoconnect-priority 1		# Lower priority because this is the backup for when in the observing field
	
# This will make sure /etc/network/interfaces does not interfere
##################
sudo --preserve-env bash -c 'cat > /etc/network/interfaces' <<- EOF
# interfaces(5) file used by ifup(8) and ifdown(8)
# Include files from /etc/network/interfaces.d:
source-directory /etc/network/interfaces.d

# The loopback network interface
auto lo
iface lo inet loopback
EOF
##################

		else
			echo "IP Address invalid, the static IP will not be set up.  Please configure Network Manager later or run the script again."
		fi
	else
		display "Leaving your IP address to be assigned only by dhcp.  Note that you will always need either a router or wifi network to connect to your pi."
	fi
else
	display "This computer already has been assigned a static ip address.  If you need to edit that, please edit the Link Local and Wired DHCP connections in Network Manager or delete them and run the script again."
fi

# This will promt you to install (1) x11vnc, (2) x2go, or (3) no remote access tool
display "Setting up a VNC Server"
if [ -z "$(pacman -Qi | awk '/^Name/' | grep x11vnc)" ] && [ -z "$(pacman -Qi | awk '/^Name/' | grep x2go)" ]
then
	read -p "Do you want to install (1) x11vnc, (2) x2go, or (3) no remote access tool? input (1/2/3)? " remoteAccessTool
	if [ "$remoteAccessTool" == "1" ]
	then
		# Note: RealVNC does not work on non-Raspberry Pi ARM systems as far as I can tell.
		# This will install x11vnc instead
		sudo pacman -S --noconfirm --needed x11vnc
		# This will get the password for VNC
		x11vnc -storepasswd /etc/x11vnc.pass
		# This will store the service file.
######################
sudo --preserve-env bash -c 'cat > /lib/systemd/system/x11vnc.service' << EOF
[Unit]
Description=Start x11vnc at startup.
After=multi-user.target
[Service]
Type=simple
ExecStart=/usr/bin/x11vnc -auth $USERHOME/.Xauthority -forever -loop -noxdamage -repeat -rfbauth /etc/x11vnc.pass -rfbport 5900 -shared
Restart=on-failure
RestartSec=2
[Install]
WantedBy=multi-user.target
EOF
######################
		# This enables the Service so it runs at startup
		sudo systemctl enable x11vnc.service
		sudo systemctl daemon-reload
		sudo systemctl start x11vnc.service
	elif [ "$remoteAccessTool" == "2" ]
	then
		# This will install x2go for Manjaro
		sudo pacman -S --noconfirm --needed x2goserver
		sudo systemctl enable x2goserver.service
		sudo systemctl daemon-reload
		sudo systemctl start x2goserver.service
	else
		echo "No remote access tool will be installed!"
	fi
else
	echo "VNC is already installed"
fi

display "Making Utilities Folder with script shortcuts for the Desktop"
# This will make a folder on the desktop with the right permissions for the launchers
if [ ! -d "$USERHOME/Desktop/utilities" ]
then
	sudo --preserve-env -H -u $SUDO_USER bash -c 'mkdir -p $USERHOME/Desktop/utilities'
fi

# This will create a shortcut on the desktop in the utilities folder for creating udev rules for Serial Devices.
##################
sudo --preserve-env bash -c 'cat > $USERHOME/Desktop/utilities/SerialDevices.desktop' <<- EOF
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
sudo chown $SUDO_USER:users $USERHOME/Desktop/utilities/SerialDevices.desktop

# This will create a shortcut on the desktop in the utilities folder for Installing Astrometry Index Files.
##################
sudo --preserve-env bash -c 'cat > $USERHOME/Desktop/utilities/InstallAstrometryIndexFiles.desktop' <<- EOF
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
sudo chown $SUDO_USER:users $USERHOME/Desktop/utilities/InstallAstrometryIndexFiles.desktop

# This will create a shortcut on the desktop in the utilities folder for Updating the System.
##################
#sudo --preserve-env bash -c 'cat > $USERHOME/Desktop/utilities/systemUpdater.desktop' <<- EOF
##!/usr/bin/env xdg-open
#[Desktop Entry]
#Version=1.0
#Type=Application
#Terminal=true
#Icon[en_US]=system-software-update
#Exec=sudo $(echo $DIR)/systemUpdater.sh
#Name[en_US]=Software Update
#Name=Software Update
#Icon=$(echo $DIR)/icons/system-software-update.svg
#EOF
###################
#sudo chmod +x $USERHOME/Desktop/utilities/systemUpdater.desktop
#sudo chown $SUDO_USER:users $USERHOME/Desktop/utilities/systemUpdater.desktop

# This will create a shortcut on the desktop in the utilities folder for Backing Up and Restoring the KStars/INDI Files.
##################
sudo --preserve-env bash -c 'cat > $USERHOME/Desktop/utilities/backupOrRestore.desktop' <<- EOF
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
sudo chown $SUDO_USER:users $USERHOME/Desktop/utilities/backupOrRestore.desktop

#########################################################
#############  Configuration for Hotspot Wifi for Connecting on the Observing Field

# This will fix a problem where AdHoc and Hotspot Networks Shut down very shortly after starting them
# Apparently it was due to power management of the wifi network by Network Manager.
# If Network Manager did not detect internet, it shut down the connections to save energy. 
# If you want to leave wifi power management enabled, put #'s in front of this section
display "Preventing Wifi Power Management from shutting down AdHoc and Hotspot Networks"
##################
sudo --preserve-env bash -c 'cat > /etc/NetworkManager/conf.d/default-wifi-powersave-on.conf' <<- EOF
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

# This section will set the new field wifi networks to autoconnect if the other networks don't connect.
display "Configuring Field wifi to autoconnect after wifi fails"
if [ -f /etc/NetworkManager/conf.d/wifi-enable-autohotspot.conf ]
then
	echo "Field Wifi autoconnection is already configured, if you want to change it, edit network manager and /etc/NetworkManager/conf.d/wifi-enable-autohotspot.conf"
else
	read -p "Do you wish to configure the field wifi hotspot to automatically come up after a certain time if there is no wifi network (y/n)? " autoWifi

	if [ "$autoWifi" == "y" ]
	then
		read -p "What do you want the timeout to be?  Mine is 30 seconds: " wifiTimeout
		if ! [ "$wifiTimeout" -eq "$wifiTimeout" ] 2> /dev/null
		then
   			echo "The timeout must be an integer number of seconds.  Making it 30 instead.  You can edit /etc/NetworkManager/conf.d/wifi-enable-autohotspot.conf to change it."
   			wifiTimeout=30
		fi
		# This sets both wifi networks to autoconnect with a priority to connect on 5G if available
		nmcli connection modify $(hostname -s)_FieldWifi connection.autoconnect yes
		nmcli connection modify $(hostname -s)_FieldWifi_5G connection.autoconnect yes
		nmcli connection modify $(hostname -s)_FieldWifi connection.autoconnect-priority -10
		nmcli connection modify $(hostname -s)_FieldWifi_5G connection.autoconnect-priority -5
	
		# This configuration file will ensure that the wifi networks come up successfully in a reasonable time if the regular wifi fails.
##################
sudo --preserve-env bash -c ' cat > /etc/NetworkManager/conf.d/wifi-enable-autohotspot.conf' <<- EOF
[connection-wifi]
match-device=interface-name:wlan0
ipv4.dhcp-timeout=$wifiTimeout
ipv4.may-fail=no
connection.auth-retries=2
connection.autoconnect-retries=2
EOF
##################
	fi
fi

# This will make a link to start the hotspot wifi on the Desktop
##################
sudo --preserve-env bash -c 'cat > $USERHOME/Desktop/utilities/StartFieldWifi.desktop' <<- EOF
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
sudo chown $SUDO_USER:users $USERHOME/Desktop/utilities/StartFieldWifi.desktop
##################
sudo --preserve-env bash -c 'cat > $USERHOME/Desktop/utilities/StartFieldWifi_5G.desktop' <<- EOF
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
sudo chown $SUDO_USER:users $USERHOME/Desktop/utilities/StartFieldWifi_5G.desktop

# This will make a link to restart Network Manager Service if there is a problem or to go back to regular wifi after using the adhoc connection
##################
sudo --preserve-env bash -c 'cat > $USERHOME/Desktop/utilities/StartNmService.desktop' <<- EOF
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Icon[en_US]=preferences-system-network
Name[en_US]=Restart Network Manager Service
Exec=pkexec systemctl restart NetworkManager.service
Name=Restart Network Manager Service
Icon=$(echo $DIR)/icons/preferences-system-network.svg
EOF
##################
sudo chmod +x $USERHOME/Desktop/utilities/StartNmService.desktop
sudo chown $SUDO_USER:users $USERHOME/Desktop/utilities/StartNmService.desktop

# This will make a link to restart nm-applet which sometimes crashes
##################
sudo --preserve-env bash -c 'cat > $USERHOME/Desktop/utilities/StartNmApplet.desktop' <<- EOF
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
sudo chown $SUDO_USER:users $USERHOME/Desktop/utilities/StartNmApplet.desktop

# This will support the functions of the next two shortcuts.
display "Setting up Night Vision tools"
sudo -H -u $SUDO_USER yay -S --noconfirm --needed --norebuild xcalib

# This will create a link that will turn the screen red to preserve night vision
##################
sudo --preserve-env bash -c 'cat > $USERHOME/Desktop/utilities/NightVisionMode.desktop' <<- EOF
[Desktop Entry]
Version=1.0
Type=Application
Terminal=true
Icon[en_US]=redeyes
Exec=xcalib -red 1 0 100 -green .1 0 1 -blue .1 0 1 -alter
Name[en_US]=Night Vision Mode
Name=Night Vision Mode
Icon=$(echo $DIR)/icons/redeyes.svg
EOF
##################
sudo chmod +x $USERHOME/Desktop/utilities/NightVisionMode.desktop
sudo chown $SUDO_USER:users $USERHOME/Desktop/utilities/NightVisionMode.desktop

# This will create a link that will turn the screen back to normal
##################
sudo --preserve-env bash -c 'cat > $USERHOME/Desktop/utilities/NormalVisionMode.desktop' <<- EOF
[Desktop Entry]
Version=1.0
Type=Application
Terminal=true
Icon[en_US]=redeyes
Exec=xcalib -clear
Name[en_US]=Normal Vision Mode
Name=Normal Vision Mode
Icon=$(echo $DIR)/icons/blackeyes.svg
EOF
##################
sudo chmod +x $USERHOME/Desktop/utilities/NormalVisionMode.desktop
sudo chown $SUDO_USER:users $USERHOME/Desktop/utilities/NormalVisionMode.desktop

#########################################################
#############  File Sharing Configuration

display "Setting up File Sharing"

# Installs samba so that you can share files to your other computer(s).
sudo pacman -S --noconfirm --needed samba

if [ ! -f /etc/samba/smb.conf ]
then
##################
sudo --preserve-env bash -c 'cat > /etc/samba/smb.conf' <<- EOF
[global]
   workgroup = ASTROGROUP
   server string = Samba Server
   server role = standalone server
   log file = /var/log/samba/log.%m
   max log size = 50
   dns proxy = no
[homes]
   comment = Home Directories
   browseable = no
   read only = no
   writable = yes
   valid users = $SUDO_USER
EOF
##################
fi

# Adds yourself to the user group of who can use samba, but checks first if you are already in the list
if [ -z "$(sudo pdbedit -L | grep $SUDO_USER)" ]
then
	# creates a samba password for you
	sudo smbpasswd -a $SUDO_USER
	# Enables the Samba services
	sudo systemctl enable smb nmb
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
# if you are using a DSLR on a system with 1GB of RAM, it definitely is needed.  If you don't want this, comment it out.
display "Installing zRAM for increased RAM capacity"
if [ ! -f /usr/bin/zram.sh ]
then
	sudo pacman -S --noconfirm --needed systemd-swap
	sudo wget -O /usr/bin/zram.sh https://raw.githubusercontent.com/novaspirit/rpi_zram/master/zram.sh
	sudo chmod +x /usr/bin/zram.sh
##################
sudo --preserve-env bash -c 'cat > /lib/systemd/system/zram.service' << EOF
[Unit]
Description=Start zram at startup.
After=multi-user.target
[Service]
Type=simple
ExecStart=/usr/bin/zram.sh
[Install]
WantedBy=multi-user.target
EOF
##################
	sudo systemctl enable systemd-swap
	sudo systemctl start systemd-swap
	sudo systemctl enable zram
	sudo systemctl daemon-reload
	sudo systemctl start zram
else
	echo "zRAM already set up"
fi

# This should fix an issue where modemmanager could interfere with serial connections
display "Removing Modemmanger, which can interfere with serial connections."
sudo pacman -R --noconfirm modemmanager

# This should fix an issue where you might not be able to use a serial mount connection because you are not in the "dialout" group
display "Enabling Serial Communication"
sudo usermod -a -G dialout $SUDO_USER


#########################################################
#############  ASTRONOMY SOFTWARE

# Creates a config file for kde themes and icons which is missing on the Raspberry pi.
# Note:  This is required for KStars to have the breeze icons.
display "Creating KDE config file so KStars can have breeze icons."
##################
sudo --preserve-env bash -c 'cat > $USERHOME/.config/kdeglobals' <<- EOF
[Icons]
Theme=breeze
EOF
##################
sudo chown $SUDO_USER:users $USERHOME/.config/kdeglobals

# This installs INDI and KStars Dependencies that will be needed
display "Installing INDI and KStars Dependencies"
sudo pacman -S --noconfirm --needed cfitsio fftw gsl libjpeg-turbo libnova libtheora libusb boost cmake qt5-base libevdev
sudo pacman -S --noconfirm --needed breeze-icons arduino binutils libraw wxgtk2 gpsd libdc1394 libftdi1 libgphoto2

# Note that INDI is available in Manjaro Packages and INDI 3rd Party is available in AUR.
# But there are issues in installing on ARM 64 bit, so for now this is disabled.
# When it is ready to be re-enabled, be sure uncomment this and to delete the build code.
#sudo pacman -S --noconfirm --needed  libindi
#display "Building and Installing INDI 3rd Party"
#sudo -H -u $SUDO_USER yay -S --noconfirm --needed --norebuild libindi_3rdparty

sudo -H -u $SUDO_USER mkdir -p $USERHOME/AstroRoot

read -p "Do you want to pull for indi & indi-3rdparty (1) latest master, (2) 1.8.4, (3) 1.8.3, or (4) latest release? input (1/2/3/4)? " gitTagINDI
if [ "$gitTagINDI" == "1" ]
then
	# Note: The master branch is broken in indi-3rdparty 
	# This will install check out latest branch instead
	Releases_Tag="master"
elif [ "$gitTagINDI" == "2" ]
then
	# This will install x2go for Manjaro
	Releases_Tag="v1.8.4"
elif [ "$gitTagINDI" == "3" ]
then
	# This will install x2go for Manjaro
	Releases_Tag="v1.8.3"
elif [ "$gitTagINDI" == "4" ]
then
	# This will install x2go for Manjaro
	Releases_Tag="latest"
else
	echo "Indi & Indi-3rdparty latest releases will be installed!"
	Releases_Tag="latest"
fi

#This removes the old build folders from the outdated version of this script before the repo was split
if [ -d $USERHOME/AstroRoot/indi-build/libindi ]
then
	display "Removing old build folders from before the Repo was split."
	sudo rm -r $USERHOME/AstroRoot/indi-build/libindi
fi
if [ -d $USERHOME/AstroRoot/indi-build/3rdpartyLibraries ]
then
	sudo rm -r $USERHOME/AstroRoot/indi-build/3rdpartyLibraries
fi
if [ -d $USERHOME/AstroRoot/indi-build/3rdpartyDrivers ]
then
	sudo rm -r $USERHOME/AstroRoot/indi-build/3rdpartyDrivers
fi

# This builds and installs INDI.  Note that this should not be the standard way on Manjaro, the commands above should be used
# But this will build and install the Latest INDI.
display "Building and Installing INDI"

# This builds and installs INDI
display "Building and Installing INDI"

if [ ! -d $USERHOME/AstroRoot/indi ]
then
	cd $USERHOME/AstroRoot/
	sudo -H -u $SUDO_USER git clone https://github.com/indilib/indi.git 
	sudo -H -u $SUDO_USER mkdir -p $USERHOME/AstroRoot/indi-build
	cd $USERHOME/AstroRoot/indi
else
	cd $USERHOME/AstroRoot/indi
	sudo -H -u $SUDO_USER git pull
fi
# list all repo tags
tags=$(eval "git tag")
IFS=$'\n' lines=($tags)

if [ "$Releases_Tag" == "master" ]
then
	# This will pull currnet branch
	echo "pull latest master"
	git pull

elif [ "$Releases_Tag" == "latest" ]
then
	# This will install latest release
	echo "Indi & Indi-3rdparty latest release ${lines[-1]} will be installed!"
	git checkout ${lines[-1]}
else
	# This will install selected release
	echo "Indi & Indi-3rdparty release ${Releases_Tag} will be installed!"
	git checkout ${Releases_Tag}
fi

display "Building and Installing Core LibINDI"
sudo -H -u $SUDO_USER mkdir -p $USERHOME/AstroRoot/indi-build/indi-core
cd $USERHOME/AstroRoot/indi-build/indi-core
sudo -H -u $SUDO_USER cmake -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=Debug $USERHOME/AstroRoot/indi
sudo -H -u $SUDO_USER make -j $(expr $(nproc) + 2)
sudo make install

# This builds and installs INDI 3rd Party
display "Building and Installing INDI 3rd Party"

if [ ! -d $USERHOME/AstroRoot/indi-3rdparty ]
then
	cd $USERHOME/AstroRoot/
	sudo -H -u $SUDO_USER git clone https://github.com/indilib/indi-3rdparty.git
	sudo -H -u $SUDO_USER mkdir -p $USERHOME/AstroRoot/indi-build
	cd $USERHOME/AstroRoot/indi-3rdparty
else
	cd $USERHOME/AstroRoot/indi-3rdparty
	sudo -H -u $SUDO_USER git pull
fi

# list all repo tags
tags=$(eval "git tag")
IFS=$'\n' lines=($tags)

if [ "$Releases_Tag" == "master" ]
then
	# This will pull currnet branch
	echo "pull latest master"
	git pull

elif [ "$Releases_Tag" == "latest" ]
then
	# This will install latest release
	echo "Indi & Indi-3rdparty latest release ${lines[-1]} will be installed!"
	git checkout ${lines[-1]}
else
	# This will install selected release
	echo "Indi & Indi-3rdparty release ${Releases_Tag} will be installed!"
	git checkout ${Releases_Tag}
fi
# This step should not be required.  For some reason, some libraries are installing in /usr/lib64, but then it looks for them in /usr/lib
# This should be solved another way.
sudo cp -r /usr/lib64/* /usr/lib/

display "Building and Installing the INDI 3rd Party Libraries"
sudo -H -u $SUDO_USER mkdir -p $USERHOME/AstroRoot/indi-build/3rdparty-Libraries
cd $USERHOME/AstroRoot/indi-build/3rdparty-Libraries
sudo -H -u $SUDO_USER cmake -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=Debug -DBUILD_LIBS=1 $USERHOME/AstroRoot/indi-3rdparty
sudo -H -u $SUDO_USER make -j $(expr $(nproc) + 2)
sudo make install

display "Building and Installing the INDI 3rd Party Drivers"
sudo -H -u $SUDO_USER mkdir -p $USERHOME/AstroRoot/indi-build/3rdparty-Drivers
cd $USERHOME/AstroRoot/indi-build/3rdparty-Drivers
sudo -H -u $SUDO_USER cmake -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=Debug -DWITH_FXLOAD=1 $USERHOME/AstroRoot/indi-3rdparty
sudo -H -u $SUDO_USER make -j $(expr $(nproc) + 2)
sudo make install

# This should prevent a well documented error
# If a camera is mounted in the file system, it will not connect in INDI
display "Disabling automounting of Volumes so that cameras do not mount themselves."
echo "Deleting key files if they exist."
sudo rm /usr/share/dbus-1/services/org.gtk.vfs.GPhoto2VolumeMonitor.service
sudo rm /usr/share/dbus-1/services/org.gtk.Private.GPhoto2VolumeMonitor.service
sudo rm /usr/share/gvfs/mounts/gphoto2.mount
sudo rm /usr/share/gvfs/remote-volume-monitors/gphoto2.monitor
sudo rm /usr/lib/gvfs/gvfs-gphoto2-volume-monitor

# Installs the Astrometry.net package for supporting offline plate solves.  If you just want the online solver, comment this out with a #.
display "Installing Astrometry.net"
sudo -H -u $SUDO_USER yay -S --noconfirm --needed --norebuild wcslib62
sudo -H -u $SUDO_USER yay -S --noconfirm --needed --norebuild astrometry.net

# Installs the optional xplanet package for simulating the solar system.  If you don't want it, comment this out with a #.
display "Installing XPlanet"
sudo -H -u $SUDO_USER yay -S --noconfirm --needed --norebuild xplanet

#This builds and installs KStars
display "Installing KStars"
sudo pacman -S --noconfirm --needed kstars --assume-installed libindi=1.8.0

# Installs the General Star Catalog if you plan on using the simulators to test (If not, you can comment this line out with a #)
display "Building and Installing GSC"
if [ ! -d /usr/share/GSC ]
then
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
else
	echo "GSC is already installed"
fi

# Installs PHD2 if you want it.  If not, comment each line out with a #.
# display "Installing PHD2"
#sudo -H -u $SUDO_USER yay -S --noconfirm --needed --norebuild open-phd-guiding-git

# This builds and installs PHD2.  It is required for now because libindi is manually installed and you cant set that option in yay
sudo pacman -S --noconfirm --needed wxgtk3
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
sudo -H -u $SUDO_USER cmake $USERHOME/AstroRoot/phd2
sudo -H -u $SUDO_USER make -j $(expr $(nproc) + 2)
sudo make install

# This will copy the desktop shortcuts into place.  If you don't want  Desktop Shortcuts, of course you can comment this out.
display "Putting shortcuts on Desktop"

sudo cp /usr/share/applications/org.kde.kstars.desktop  $USERHOME/Desktop/
sudo chmod +x $USERHOME/Desktop/org.kde.kstars.desktop
sudo chown $SUDO_USER:users $USERHOME/Desktop/org.kde.kstars.desktop

sudo cp /usr/share/applications/phd2.desktop  $USERHOME/Desktop/
sudo chmod +x $USERHOME/Desktop/phd2.desktop
sudo chown $SUDO_USER:users $USERHOME/Desktop/phd2.desktop

#########################################################
#############  INDI WEB MANAGER App

display "Installing INDI Web Manager App, indiweb, and python3"

# This will install pip3 and python along with their headers for the next steps
sudo pacman -S --noconfirm --needed python-pip

# Wheel might not be installed on some systems
sudo -H -u $SUDO_USER pip3 install --user wheel

# This will install indiweb as the user
sudo -H -u $SUDO_USER pip3 install --user indiweb

# Dependencies for INDIWebManagerApp
sudo pacman -S --noconfirm --needed extra-cmake-modules kdoctools

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
sudo -H -u $SUDO_USER make -j $(expr $(nproc) + 2)
sudo make install

# This will make a link to start INDIWebManagerApp on the desktop
##################
sudo --preserve-env bash -c 'cat > $USERHOME/Desktop/INDIWebManagerApp.desktop' <<- EOF
[Desktop Entry]
Encoding=UTF-8
Name=INDI Web Manager App
Type=Application
Exec=INDIWebManagerApp %U
Icon=$(sudo -H -u $SUDO_USER python3 -m site --user-site)/indiweb/views/img/indi_logo.png
Comment=Program to start and configure INDI WebManager
EOF
##################
sudo chmod +x $USERHOME/Desktop/INDIWebManagerApp.desktop
sudo chown $SUDO_USER:users $USERHOME/Desktop/INDIWebManagerApp.desktop
##################

#########################################################
#############  Configuration for System Monitoring

# This will set you up with conky so that you can see how your system is doing at a moment's glance
# A big thank you to novaspirit who set up this theme https://github.com/novaspirit/rpi_conky
sudo pacman -S --noconfirm --needed conky
cp "$DIR/conkyrc" $USERHOME/.conkyrc
sudo chown $SUDO_USER:users $USERHOME/.conkyrc

#This should dynamically add lines to the conkyrc file based on the number of CPUs found
NUMEROFCPUS=$(grep -c ^processor /proc/cpuinfo)
for (( c=1; c<=$NUMEROFCPUS; c++ ))
do  
   CPULINE="CPU$c  \${cpu cpu$c}% \${cpubar cpu$c}"
   echo $CPULINE
   sed -i "/\${cpugraph DimGray DarkSlateGray} \$color/i $CPULINE" $USERHOME/.conkyrc
done

# This will put a link into the autostart folder so it starts at login
# Also this sets the resolution of the screen to something a bit larger than the default.
# You should change this to match the screen resolution you want
##################
mkdir -p $USERHOME/.config/autostart
sudo --preserve-env bash -c 'cat > $USERHOME/.config/autostart/startConky.desktop' <<- EOF
[Desktop Entry]
Name=StartConky
Exec=conky -db -p 20
Terminal=false
Type=Application
EOF
##################
# Note that in order to work, this link needs to stay owned by root and not be executable

# This will run a script that should trust the desktop icons in Gnome
su - $SUDO_USER -c "$DIR/trustIconsGnome.sh"

#########################################################


# This will make the utility scripts in the folder executable in case the user wants to use them.
chmod +x "$DIR/udevRuleScript.sh"
chmod +x "$DIR/astrometryIndexInstaller.sh"
#chmod +x "$DIR/systemUpdater.sh"
chmod +x "$DIR/backupOrRestore.sh"

display "Script Execution Complete.  Your Manjaro System should now be ready to use for Astrophotography.  You should restart your computer."