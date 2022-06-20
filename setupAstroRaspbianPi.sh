#!/bin/bash

#	AstroRaspbianPi Raspberry Pi 3 or 4 Raspbian KStars/INDI Configuration Script
#﻿  Copyright (C) 2018 Robert Lancaster <rlancaste@gmail.com>
#	This script is free software; you can redistribute it and/or
#	modify it under the terms of the GNU General Public
#	License as published by the Free Software Foundation; either
#	version 2 of the License, or (at your option) any later version.

if [ "$(whoami)" != "root" ]; then
	echo "Please run this script with sudo due to the fact that it must do a number of sudo tasks.  Exiting now."
	exit 1
elif [ -z "$BASH_VERSION" ]; then
	echo "Please run this script in a BASH shell because it is a script written using BASH commands.  Exiting now."
	exit 1
else
	echo "You are running BASH $BASH_VERSION as the root user."
fi

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

function checkForConnection
{
		testCommand=$(curl -Is $2 | head -n 1)
		if [[ "${testCommand}" == *"OK"* || "${testCommand}" == *"Moved"* || "${testCommand}" == *"HTTP/2 301"* || "${testCommand}" == *"HTTP/2 200"* ]]
  		then 
  			echo "$1 was found. The script can proceed."
  		else
  			echo "$1, ($2), a required connection, was not found, aborting script."
  			echo "If you would like the script to run anyway, please comment out the line that tests this connection in this script."
  			exit
		fi
}

display "Welcome to the AstroPi3 Raspberry Pi 3 or 4 Raspbian KStars/INDI Configuration Script."

display "This will update, install and configure your Raspberry Pi 3 or 4 to work with INDI and KStars to be a hub for Astrophotography. Be sure to read the script first to see what it does and to customize it."

read -p "Are you ready to proceed (y/n)? " proceed

if [ "$proceed" != "y" ]
then
	exit
fi

display "Testing connections to required web addresses for running the script.  If the pi cannot connect to the internet, you should correct this before running the script.  If a required resource is not available, you should find out if the resource has moved, or remove the requirement for this resource."
checkForConnection ZRam-script "https://raw.githubusercontent.com/novaspirit/rpi_zram/master/zram.sh"
checkForConnection INDI-Git-Repo "https://github.com/indilib/indi.git"
checkForConnection INDI-3rdparty-Repo "https://github.com/indilib/indi-3rdparty.git"
checkForConnection GSC-Source "http://cdsarc.u-strasbg.fr/viz-bin/nph-Cat/tar.gz?bincats/GSC_1.2"
checkForConnection StellarSolver-Repo "https://github.com/rlancaste/stellarsolver.git"
checkForConnection KStars-Repo "https://github.com/KDE/kstars"
checkForConnection PHD2-Repo "https://github.com/OpenPHDGuiding/phd2.git"
checkForConnection WX-FormBuilder-Repo "https://github.com/wxFormBuilder/wxFormBuilder.git"
checkForConnection PHD2-LogViewer-Repo "https://github.com/agalasso/phdlogview.git"
checkForConnection INDIWebManagerApp-Repo "https://github.com/rlancaste/INDIWebManagerApp.git"

export USERHOME=$(sudo -u $SUDO_USER -H bash -c 'echo $HOME')

# This changes the UserPrompt for the Setup Script (Necessary to make the messages display in the title bar)
PS1='AstroPi3-SetupAstroRaspbianPi~$ '

#########################################################
#############  Asking Questions for optional items later

display "Checking items that will require your input while running the script, so you don't get asked so many questions later.  Note that some installations later (VNC, samba in particular) may still require your input later on, this is out of my control."

staticIPExists=false
if [ -d "/etc/NetworkManager/system-connections/" ]
then
	if [ -z "$(ls /etc/NetworkManager/system-connections/ | grep Link\ Local\ Ethernet)" ]
	then
		staticIPExists=true
	fi
fi

if [ "$staticIPExists" == false ]
then
	read -p "Do you want to give your pi a static ip address so that you can connect to it in the observing field with no router or wifi and just an ethernet cable (y/n)? " useStaticIP
	if [ "$useStaticIP" == "y" ]
	then
		read -p "Please enter the IP address you would prefer.  Please make sure that the first two numbers match your client computer's self assigned IP.  For Example mine is: 169.254.0.5 ? " IP
		if [[ "$IP" =~ ^(([1-9]?[0-9]|1[0-9][0-9]|2([0-4][0-9]|5[0-5]))\.){3}([1-9]?[0-9]|1[0-9][0-9]|2([0-4][0-9]|5[0-5]))$ ]] # Note that this formula came from Jon in the thread: https://stackoverflow.com/questions/13777387/check-for-ip-validity
		then
			echo "IP Address is in correct format, proceeding"
		else
			echo "IP Address invalid, the static IP cannot be set up with this address.  Please configure Network Manager later or run the script again."
			read -p "Do you wish to abort and try to enter the IP address again (y/n)?" abortDueToIP
			if [ "$abortDueToIP" == "y" ]
			then
				exit
			fi
		fi
	else
		display "Leaving your IP address to be assigned only by dhcp.  Note that you will always need either a router or wifi network to connect to your pi."
	fi
else
	echo "A Static IP Address is already configured.  If you want to change that, you can delete the Link Local Ethernet System Connection in network manager."
fi

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
	fi
fi


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

# This makes sure there is a config folder owned by the user, since many things depend on it.
mkdir -p $USERHOME/.config
sudo chown $SUDO_USER:$SUDO_USER $USERHOME/.config

# This will set up the Pi so that double clicking on desktop icons brings up the program right away
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
# However it should be noted that this change may disable the 2nd HDMI output.
# If you want to use your PI in a headless mode and set your own resolution, you need to run this code on a PI 4.
# If you want to use two HDMI monitors with the PI 4, instead of going headless, you should not run this code.
if [ -n "$(grep '^dtoverlay=vc4-kms-v3d' '/boot/config.txt')" ]
then
	sed -i "s/dtoverlay=vc4-kms-v3d/#dtoverlay=vc4-kms-v3d/g" /boot/config.txt
fi
if [ -n "$(grep '^dtoverlay=vc4-fkms-v3d' '/boot/config.txt')" ]
then
	sed -i "s/dtoverlay=vc4-fkms-v3d/#dtoverlay=vc4-fkms-v3d/g" /boot/config.txt
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


# This will set up your Pi to have access to internet with wifi, ethernet with DHCP, and ethernet with direct connection
display "Setting up Ethernet for both link-local and DHCP"
if [ -z "$(ls /etc/NetworkManager/system-connections/ | grep Link\ Local\ Ethernet)" ]
then
	if [ "$useStaticIP" == "y" ]
	then
		if [[ "$IP" =~ ^(([1-9]?[0-9]|1[0-9][0-9]|2([0-4][0-9]|5[0-5]))\.){3}([1-9]?[0-9]|1[0-9][0-9]|2([0-4][0-9]|5[0-5]))$ ]] # Note that this formula came from Jon in the thread: https://stackoverflow.com/questions/13777387/check-for-ip-validity
		then
			echo "IP Address is in correct format, proceeding to set up the static IP"
			
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
sudo cat > /etc/network/interfaces <<- EOF
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

# To view the Raspberry Pi Remotely, this installs RealVNC Servier and enables it to run by default.
display "Installing RealVNC Server"
sudo apt install realvnc-vnc-server
sudo systemctl enable vncserver-x11-serviced.service
sudo systemctl daemon-reload
sudo systemctl start vncserver-x11-serviced.service

display "Making Utilities Folder with script shortcuts for the Desktop"

# This will make a folder on the desktop for the launchers if it doesn't exist already
if [ ! -d "$USERHOME/Desktop/utilities" ]
then
	mkdir -p $USERHOME/Desktop/utilities
	sudo chown $SUDO_USER:$SUDO_USER $USERHOME/Desktop/utilities
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
sudo chown $SUDO_USER:$SUDO_USER $USERHOME/Desktop/utilities/SerialDevices.desktop

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
sudo chown $SUDO_USER:$SUDO_USER $USERHOME/Desktop/utilities/InstallAstrometryIndexFiles.desktop

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
sudo chown $SUDO_USER:$SUDO_USER $USERHOME/Desktop/utilities/systemUpdater.desktop

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
sudo chown $SUDO_USER:$SUDO_USER $USERHOME/Desktop/utilities/backupOrRestore.desktop

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

# This section will set the new field wifi networks to autoconnect if the other networks don't connect.
display "Configuring Field wifi to autoconnect after wifi fails"
if [ -f /etc/NetworkManager/conf.d/wifi-enable-autohotspot.conf ]
then
	echo "Field Wifi autoconnection is already configured, if you want to change it, edit network manager and /etc/NetworkManager/conf.d/wifi-enable-autohotspot.conf"
else
	if [ "$autoWifi" == "y" ]
	then
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
sudo chown $SUDO_USER:$SUDO_USER $USERHOME/Desktop/utilities/StartFieldWifi.desktop
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
sudo chown $SUDO_USER:$SUDO_USER $USERHOME/Desktop/utilities/StartFieldWifi_5G.desktop

# This will make a link to restart Network Manager Service if there is a problem or to go back to regular wifi after using the adhoc connection
##################
sudo cat > $USERHOME/Desktop/utilities/StartNmService.desktop <<- EOF
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
sudo chown $SUDO_USER:$SUDO_USER $USERHOME/Desktop/utilities/StartNmService.desktop

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
sudo chown $SUDO_USER:$SUDO_USER $USERHOME/Desktop/utilities/StartNmApplet.desktop

#########################################################
#############  Checking Network connectivity before continuing, since the Network changes may have caused internet to drop out if on WIFI
display "Verifying that the Pi is still online and able to access all required online resources.  The network configuration may have been changed.  If the Pi no longer has internet connection, you should restart it and reconnect it to the internet."
checkForConnection ZRam-script "https://raw.githubusercontent.com/novaspirit/rpi_zram/master/zram.sh"
checkForConnection INDI-Git-Repo "https://github.com/indilib/indi.git"
checkForConnection INDI-3rdparty-Repo "https://github.com/indilib/indi-3rdparty.git"
checkForConnection GSC-Source "http://cdsarc.u-strasbg.fr/viz-bin/nph-Cat/tar.gz?bincats/GSC_1.2"
checkForConnection KStars-Repo "https://github.com/KDE/kstars"
checkForConnection PHD2-Repo "https://github.com/OpenPHDGuiding/phd2.git"
checkForConnection WX-FormBuilder-Repo "https://github.com/wxFormBuilder/wxFormBuilder.git"
checkForConnection PHD2-LogViewer-Repo "https://github.com/agalasso/phdlogview.git"
checkForConnection INDIWebManagerApp-Repo "https://github.com/rlancaste/INDIWebManagerApp.git"



# This will support the functions of the next two shortcuts.
display "Setting up Night Vision tools, note that they may not work if you aren't using a real display."
sudo apt -y install xcalib

# This will create a link that will turn the screen red to preserve night vision
##################
sudo cat > $USERHOME/Desktop/utilities/NightVisionMode.desktop <<- EOF
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
sudo chown $SUDO_USER:$SUDO_USER $USERHOME/Desktop/utilities/NightVisionMode.desktop

# This will create a link that will turn the screen back to normal
##################
sudo cat > $USERHOME/Desktop/utilities/NormalVisionMode.desktop <<- EOF
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
sudo chown $SUDO_USER:$SUDO_USER $USERHOME/Desktop/utilities/NormalVisionMode.desktop

#########################################################
#############  File Sharing Configuration

display "Setting up File Sharing"

# Installs samba so that you can share files to your other computer(s).
sudo apt -y install samba samba-common-bin
sudo touch /etc/libuser.conf

if [ ! -f /etc/samba/smb.conf ]
then
	sudo mkdir -p /etc/samba/
##################
sudo cat > /etc/samba/smb.conf <<- EOF
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

# This should fix an issue where modemmanager could interfere with serial connections
display "Removing Modemmanger, which can interfere with serial connections."
sudo apt -y remove modemmanager

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
sudo chown $SUDO_USER:$SUDO_USER $USERHOME/.config/kdeglobals

# Installs Pre Requirements for INDI
sudo apt -y install libnova-dev libcfitsio-dev libusb-1.0-0-dev libusb-dev zlib1g-dev libgsl-dev build-essential cmake git libjpeg-dev libcurl4-gnutls-dev libtiff-dev
sudo apt -y install libftdi-dev libgps-dev libraw-dev libdc1394-22-dev libgphoto2-dev libboost-dev libboost-regex-dev librtlsdr-dev liblimesuite-dev libftdi1-dev
sudo apt -y install ffmpeg libavcodec-dev libavdevice-dev libfftw3-dev libev-dev

#sudo apt install cdbs fxload libkrb5-dev dkms Are these needed too???

# This should prevent a well documented error
# If a camera is mounted in the file system, it will not connect in INDI
display "Disabling automounting of Volumes so that cameras do not mount themselves."
echo "Deleting key files if they exist."
sudo rm /usr/share/dbus-1/services/org.gtk.vfs.GPhoto2VolumeMonitor.service
sudo rm /usr/share/dbus-1/services/org.gtk.Private.GPhoto2VolumeMonitor.service
sudo rm /usr/share/gvfs/mounts/gphoto2.mount
sudo rm /usr/share/gvfs/remote-volume-monitors/gphoto2.monitor
sudo rm /usr/lib/gvfs/gvfs-gphoto2-volume-monitor

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

# This builds and installs INDI
display "Building and Installing INDI"

if [ ! -d $USERHOME/AstroRoot/indi ]
then
	cd $USERHOME/AstroRoot/
	sudo -H -u $SUDO_USER git clone --depth 1 https://github.com/indilib/indi.git 
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
sudo -H -u $SUDO_USER cmake -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=RelWithDebInfo $USERHOME/AstroRoot/indi
sudo -H -u $SUDO_USER make -j $(expr $(nproc) + 2)
sudo make install

# This builds and installs INDI 3rd Party
display "Building and Installing INDI 3rd Party"

if [ ! -d $USERHOME/AstroRoot/indi-3rdparty ]
then
	cd $USERHOME/AstroRoot/
	sudo -H -u $SUDO_USER git clone --depth 1 https://github.com/indilib/indi-3rdparty.git
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

display "Building and Installing the INDI 3rd Party Libraries"
sudo -H -u $SUDO_USER mkdir -p $USERHOME/AstroRoot/indi-build/3rdparty-Libraries
cd $USERHOME/AstroRoot/indi-build/3rdparty-Libraries
sudo -H -u $SUDO_USER cmake -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=RelWithDebInfo -DBUILD_LIBS=1 $USERHOME/AstroRoot/indi-3rdparty
sudo -H -u $SUDO_USER make -j $(expr $(nproc) + 2)
sudo make install

display "Building and Installing the INDI 3rd Party Drivers"
sudo -H -u $SUDO_USER mkdir -p $USERHOME/AstroRoot/indi-build/3rdparty-Drivers
cd $USERHOME/AstroRoot/indi-build/3rdparty-Drivers
sudo -H -u $SUDO_USER cmake -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=RelWithDebInfo -DWITH_FXLOAD=1 $USERHOME/AstroRoot/indi-3rdparty
sudo -H -u $SUDO_USER make -j $(expr $(nproc) + 2)
sudo make install

# Installs the Astrometry.net package for supporting offline plate solves.  If you just want the online solver, comment this out with a #.
display "Installing Astrometry.net"
sudo apt -y install astrometry.net

# Installs the optional xplanet package for simulating the solar system.  If you don't want it, comment this out with a #.
display "Installing XPlanet"
sudo apt -y install xplanet

# Installs Pre Requirements for KStars
sudo apt -y install build-essential cmake git libeigen3-dev libcfitsio-dev zlib1g-dev libindi-dev extra-cmake-modules libkf5plotting-dev libqt5svg5-dev libkf5iconthemes-dev wcslib-dev libqt5sql5-sqlite
sudo apt -y install libkf5xmlgui-dev kio-dev kinit-dev libkf5newstuff-dev kdoctools-dev libkf5notifications-dev libqt5websockets5-dev qtdeclarative5-dev libkf5crash-dev gettext qml-module-qtquick-controls qml-module-qtquick-layouts
sudo apt -y install libkf5notifyconfig-dev libqt5datavisualization5-dev qt5keychain-dev

# This builds and installs StellarSolver
display "Building and Installing StellarSolver"

if [ ! -d $USERHOME/AstroRoot/stellarsolver ]
then
	cd $USERHOME/AstroRoot/
	sudo -H -u $SUDO_USER git clone --depth 1 https://github.com/rlancaste/stellarsolver.git
	sudo -H -u $SUDO_USER mkdir -p $USERHOME/AstroRoot/stellar-build
else
	cd $USERHOME/AstroRoot/stellarsolver
	sudo -H -u $SUDO_USER git pull
fi

cd $USERHOME/AstroRoot/stellar-build
sudo -H -u $SUDO_USER cmake -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCMAKE_INSTALL_PREFIX=/usr $USERHOME/AstroRoot/stellarsolver/
sudo -H -u $SUDO_USER make -j $(expr $(nproc) + 2)
sudo make install

#This builds and installs KStars
display "Building and Installing KStars"

if [ ! -d $USERHOME/AstroRoot/kstars ]
then
	cd $USERHOME/AstroRoot/
	sudo -H -u $SUDO_USER git clone --depth 1 https://github.com/KDE/kstars
	sudo -H -u $SUDO_USER mkdir -p $USERHOME/AstroRoot/kstars-build
else
	cd $USERHOME/AstroRoot/kstars
	sudo -H -u $SUDO_USER git pull
fi

cd $USERHOME/AstroRoot/kstars-build
sudo -H -u $SUDO_USER cmake -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCMAKE_INSTALL_PREFIX=/usr $USERHOME/AstroRoot/kstars/
sudo -H -u $SUDO_USER make -j $(expr $(nproc) + 2)
sudo make install

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
	sudo -H -u $SUDO_USER make -j $(expr $(nproc) + 2)
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
sudo apt -y install libwxgtk3.0-dev
display "Building and Installing PHD2"

if [ ! -d $USERHOME/AstroRoot/phd2 ]
then
	cd $USERHOME/AstroRoot/
	sudo -H -u $SUDO_USER git clone --depth 1 https://github.com/OpenPHDGuiding/phd2.git
	sudo -H -u $SUDO_USER mkdir -p $USERHOME/AstroRoot/phd2-build
else
	cd $USERHOME/AstroRoot/phd2
	sudo -H -u $SUDO_USER git pull
fi

cd $USERHOME/AstroRoot/phd2-build
sudo -H -u $SUDO_USER cmake $USERHOME/AstroRoot/phd2
sudo -H -u $SUDO_USER make -j $(expr $(nproc) + 2)
sudo make install

display "Installing Dependencies for wxFormBuilder and PHD Log Viewer"
sudo apt -y install libwxgtk3.0-dev libwxgtk-media3.0-dev meson

# This code will build and install PHD Log Viewer.  If you don't want it, comment it out.
display "Building and Installing PHD Log Viewer"
if [ ! -d $USERHOME/AstroRoot/phdlogview ]
then
	cd $USERHOME/AstroRoot/
	sudo -H -u $SUDO_USER git clone --depth 1 https://github.com/agalasso/phdlogview.git
	sudo -H -u $SUDO_USER mkdir -p $USERHOME/AstroRoot/phdlogview/tmp
else
	cd $USERHOME/AstroRoot/phdlogview
	sudo -H -u $SUDO_USER git pull
fi

# Note that phdlogview.fbp needs to be updated to the latest version of wxFormBuilder.  This copy has been updated
# so that it won't cause an error in the build.  As soon as the repo gets updated to be compatible, this next line can be removed.
sudo -H -u $SUDO_USER cp -f $USERHOME/AstroPi3/phdlogview.fbp $USERHOME/AstroRoot/phdlogview/phdlogview.fbp

cd $USERHOME/AstroRoot/phdlogview/tmp
sudo -H -u $SUDO_USER cmake -DHAVE_WXFB=0 $USERHOME/AstroRoot/phdlogview
sudo -H -u $SUDO_USER make -j $(expr $(nproc) + 2)
cp $USERHOME/AstroRoot/phdlogview/tmp/phdlogview /usr/bin/

# This will make a shortcut to PHD Log Viewer.  If you aren't installing it, be sure to remove this too.
##################
sudo cat > $USERHOME/Desktop/utilities/PHDLogViewer.desktop <<- EOF
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Icon[en_US]=phd2
Name[en_US]=PHD Log Viewer
Exec=/usr/bin/phdlogview
Name=PHD Log Viewer
Icon=phd2
EOF
##################
sudo chmod +x $USERHOME/Desktop/utilities/PHDLogViewer.desktop
sudo chown $SUDO_USER:$SUDO_USER $USERHOME/Desktop/utilities/PHDLogViewer.desktop

# This will copy the desktop shortcuts into place.  If you don't want  Desktop Shortcuts, of course you can comment this out.
display "Putting shortcuts on Desktop"

sudo cp /usr/share/applications/org.kde.kstars.desktop  $USERHOME/Desktop/
sudo chmod +x $USERHOME/Desktop/org.kde.kstars.desktop
sudo chown $SUDO_USER:$SUDO_USER $USERHOME/Desktop/org.kde.kstars.desktop

sudo cp /usr/share/applications/phd2.desktop  $USERHOME/Desktop/
sudo chmod +x $USERHOME/Desktop/phd2.desktop
sudo chown $SUDO_USER:$SUDO_USER $USERHOME/Desktop/phd2.desktop

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
	sudo -H -u $SUDO_USER git clone --depth 1 https://github.com/rlancaste/INDIWebManagerApp.git
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
sudo cat > $USERHOME/Desktop/INDIWebManagerApp.desktop <<- EOF
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
sudo chown $SUDO_USER:$SUDO_USER $USERHOME/Desktop/INDIWebManagerApp.desktop
##################

#########################################################
#############  Configuration for System Monitoring

# This will set you up with conky so that you can see how your system is doing at a moment's glance
# A big thank you to novaspirit who set up this theme https://github.com/novaspirit/rpi_conky
sudo apt -y install conky-all
cp "$DIR/conkyrc" $USERHOME/.conkyrc
sudo chown $SUDO_USER:$SUDO_USER $USERHOME/.conkyrc

#This should dynamically add lines to the conkyrc file based on the number of CPUs found
NUMEROFCPUS=$(grep -c ^processor /proc/cpuinfo)
for (( c=1; c<=$NUMEROFCPUS; c++ ))
do  
   CPULINE="CPU$c  \${cpu cpu$c}% \${cpubar cpu$c}"
   echo $CPULINE
   sed -i "/\${cpugraph DimGray DarkSlateGray} \$color/i $CPULINE" $USERHOME/.conkyrc
done

# This will put a link into the autostart folder so it starts at login
##################
mkdir -p $USERHOME/.config/autostart
sudo cat > $USERHOME/.config/autostart/startConky.desktop <<- EOF
[Desktop Entry]
Name=StartConky
Exec=conky -db -p 20
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

display "Script Execution Complete.  Your Raspberry Pi 3 or 4 should now be ready to use for Astrophotography.  You should restart your Pi."

