#!/bin/bash

function display
{
    echo ""
    echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    echo "~ $*"
    echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    echo ""
}

display "Welcome to the INDI and KStars Raspberry Pi 3 Configuration Script."

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

#########################################################
#############  Updates

# This would update the Raspberry Pi kernel.  For now it is disabled because there is debate about whether to do it or not.  To enable it, take away the # sign.
#display "Updating Kernel"
#sudo rpi-update 

# Updates the Raspberry Pi to the latest packages.
display "Updating installed packages"
sudo apt-get update
sudo apt-get -y upgrade
sudo apt-get -y dist-upgrade

#########################################################
#############  Configuration for Ease of Use/Access

# This will set your account to autologin.  If you don't want this. then put a # on each line to comment it out.
display "Setting account: "$SUDO_USER" to auto login."
sudo cat > /usr/share/lightdm/lightdm.conf.d/60-lightdm-gtk-greeter.conf <<- EOF
[SeatDefaults]
greeter-session=lightdm-gtk-greeter
autologin-user=$SUDO_USER
EOF

# Installs Synaptic Package Manager for easy software install/removal
display "Installing Synaptic"
sudo apt-get -y install synaptic

# This will enable SSH which is apparently disabled on Raspberry Pi by default.
display "Enabling SSH"
sudo apt-get purge openssh-server
sudo apt-get -y install openssh-server

# To view the Raspberry Pi Remotely, this installs RealVNC Servier and enables it to run by default.
display "Installing RealVNC Server"
wget https://www.realvnc.com/download/binary/latest/debian/arm/ -O VNC.deb
sudo dpkg -i VNC.deb
sudo systemctl enable vncserver-x11-serviced.service
rm VNC.deb

#########################################################
#############  File Sharing Configuration

display "Setting up File Sharing"

# Installs samba so that you can share files to your other computer(s).
sudo apt-get -y install samba

# Installs caja-share so that you can easily share the folders you want.
sudo apt-get -y install caja-share

# Adds yourself to the user group of who can use samba.
sudo smbpasswd -a $SUDO_USER


#########################################################
#############  Very Important Configuration Items

# This will create a swap file for an increased 2 GB of artificial RAM.  This is not needed on all systems, since different cameras download different size images, but if you are using a DSLR, it definitely is.
display "Creating SWAP Memory"
wget https://raw.githubusercontent.com/Cretezy/Swap/master/swap.sh -O swap
sh swap 2G
rm swap

# This should fix an issue where you might not be able to use a serial mount connection because you are not in the "dialout" group
display "Enabling Serial Communication"
sudo usermod -a -G dialout $SUDO_USER


#########################################################
#############  ASTRONOMY SOFTWARE

# Installs INDI, Kstars, and Ekos bleeding edge and debugging
display "Installing INDI and KStars"
sudo apt-add-repository ppa:mutlaqja/ppa -y
sudo apt-get update
sudo apt-get -y install indi-full
sudo apt-get -y install indi-full kstars-bleeding
sudo apt-get -y install kstars-bleeding-dbg indi-dbg

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

# This will install INDI Web Manager
sudo pip install indiweb

# This will prepare the indiwebmanager.service file
sudo cat > /etc/systemd/system/indiwebmanager.service <<- EOF
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

# This will change the indiwebmanager.service file permissions and enable it.
sudo chmod 644 /etc/systemd/system/indiwebmanager.service
sudo systemctl daemon-reload
sudo systemctl enable indiwebmanager.service

# This will make a link to the Web Manager on the Desktop
sudo cat > ~/Desktop/INDIWebManager.desktop <<- EOF
[Desktop Entry]
Encoding=UTF-8
Name=INDIWebManager
Type=Link
URL=http://localhost:8624
Icon=text-html
EOF

sudo chmod +x ~/Desktop/INDIWebManager.desktop
sudo chown $SUDO_USER ~/Desktop/INDIWebManager.desktop

#########################################################

display "Script Execution Complete.  Your Raspberry Pi 3 should now be ready to use for Astrophotography."