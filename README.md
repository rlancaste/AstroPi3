# AstroPi3

This script is meant to automate the many setup steps involved with configuring a Raspberry Pi 3 or similar single board computer (SBC) running Ubuntu Mate,
so that it can be an Astrophotography hub using INDI, KStars, and Ekos.  I first developed the series of steps by research, trial, and error
in 2016.  Then several users on indilib.org, especially James Taylor ( u2pilotjt ), tested my steps and helped me revise them.
James Taylor wrote a beginners guide which can be accessed here:  http://www.indilib.org/support/tutorials/169-ekos-on-raspberry-pi-complete-guide.html
In Fall 2017,  I was configuring another PI, went back to my instructions and his guide and followed both.  I revised my steps and then
turned it into this script.  Hopefully this is much easier to use.

![Running KStars on Pi 3](/images/runningPi3.png "Running KStars on Pi 3")
![Running Ekos on Pi 3](/images/ekosRunning.png "Running Ekos on Pi 3")
![Running Ekos on 64 bit SBC](/images/64bitEkos.png "Running Ekos on 64 bit SBC")

Before running the script, please be sure to do some research and read up on all that it will do to your Raspberry Pi or other SBC.  You may want to 
use the script as is or add or remove certain lines before running it by adding or removing comment symbols from the front of the line (#).

When you are ready, you can follow these steps:

1.	Download latest version of Ubuntu mate https://ubuntu-mate.org/raspberry-pi/ (For Raspberry Pi)
2.  You will need to flash that img file to the SD card.  The easiest way to do this is to download the free program Etcher (https://etcher.io)
3.  Drag and drop the disk image you downloaded into etcher along with the mounted SD card.  Click to initialize the flash.
4.  Before you remove the SD Card, You should edit the config or ini files that are in the boot partition.  The primary goal of this is to make sure that 
	when an HDMI cable is not connected (a headless setup), the SBC doesn't shut down the GUI, so you can still access it over VNC.  The secondary goal is to ensure that 
	the screen resolution over VNC when headless is reasoable.   You can also edit other settings such as overclocking etc, but read up on this first.  For the Raspberry Pi, you should edit 
	the following file in the Pi-boot partition: 

		/boot/config.txt 
						
	to make sure that your PI will have a decent resolution even when an HDMI display is not connected. Use the following options:
	
		hdmi_force_hotplug=1
		
		hdmi_group=2
		
		hdmi_mode=46 (1440 x 900@60Hz)
		
		For the 3rd one, you can set your resolution to whatever you like.  I set it to option 46 (1440 x 900) since that is my laptop resolution.
		
		NOTE: On the Raspberry Pi 4 running Raspbian, you may also need to comment out the line: dtoverlay=vc4-kms-v3d

5.  Insert the SD Card into the SBC, connect a mouse, keyboard, and display.  Then turn it on.  Often the SBC will reboot the first time to resize the partition.
6.  You should get a setup window if you are using a Raspberry Pi.  Configure your SBC.  If you are on the Pi, be sure to choose your login name and computer name carefully.
    This is difficult to change later. Note that it may say your name is unavailable at first, but when you enter your login name that may change.
	After the configuration, your pi will restart.  You may need to restart it again to get your wifi network connection started.
7.  Copy the scripts in this GIT Repo to your SBC and Open a Terminal Window.  You could type the following commands into Terminal to accomplish this goal.

		sudo apt-get install git
	
		git clone https://github.com/rlancaste/AstroPi3.git
	
8.  Navigate to the Folder containing the script.  Assuming you typed the above commands, you can type the following to do this:

		cd AstroPi3
	
8.  Make sure the script file is executable using one of the following commands depending on your system.

		chmod +x setupAstroPi3.sh
	
		chmod +x setupUbuntuSBC.sh
		
		chmod +x setupAstroRasbianPi.sh
	
9.  Run one of the following scripts using sudo.  Choose the right one for your system.  The setupAstroPi3.sh is specifically for a Raspberry Pi 3b or 3b+
	running Ubuntu-Mate in the armhf architecture.  The setupUbuntuSBC.sh script is specifically for an SBC system running Ubuntu on any architecture such as a Rock64 or Odroid C2.  
	Be warned that right now the INDI SBIG driver does not compile in 64 bit.

		sudo ./setupAstroPi3.sh
	
		sudo ./setupUbuntuSBC.sh
		
		sudo ./setupAstroRasbianPi.sh
	
Here is a list of what the script does (If you want to disable or modify any of these, please edit before running the script):

- (DISABLED) Can hold Firefox back to an older version for installing on Ubuntu-Mate 16.04 (since updates break it)

- (DISABLED) Updates the Raspberry Pi Kernel if desired (Raspberry Pi script only)

- Uninstalls unattended-upgrades since they can slow down imaging and cause issues with updates.

- Updates/Upgrades the SBC

- Sets the user account to auto-login

- Disables the screen lock and screen saver to prevent them from causing issues when connecting via VNC

- Disables the CUPS modules for parallel printers since none are attached and it slows down boot (Raspberry Pi script only)

- Installs Synaptic Package Manager (makes it easier to uninstall what you don't want)

- Enables SSH which is disabled by default on Raspberry Pi. (Raspberry Pi script only, unless you enable it.)

- Optionally gives the SBC a static IP address by editing /boot/cmdline.txt so that in the field you can connect via a direct Ethernet cable if desired

- Optionally edits the /etc/network/interfaces file so that the static IP address does not interfere with DHCP

- Installs RealVNC Server (Raspberry Pi Script) or x11VNC (64 bit script)

- Makes a folder called utilties on the Desktop

- Creates a shortcut/launcher for the UDev Script in utilities on the Desktop

- Creates a shortcut/launcher for the Astrometry Index File Install Script in utilities on the Desktop

- Turns off powersave for Wifi so hotspots/adhoc networks don't shut down in the observing field

- Creates a hotspot Wifi profile for the observing field

- Makes a shortcut/launcher in utilities on the desktop to start the hotspot

- Makes a shortcut/launcher in utitlies to restart nm-applet for NetworkManager which crashes sometimes

- Sets up samba and caja filesharing so you can share any folder by right clicking

- (DISABLED) Creates 2GB of Swap memory to increase the memory capacity of the SBC

- Creates zRAM to get ~ 1.5x the current RAM capacity

- Ensures Serial connections will not be disabled

- Installs INDI and KStars

- Installs the kdeglobals configuration file so that KStars can have breeze icons

- Installs GSC

- Installs Astrometry.net

- Installs PHD2

- Puts Shortcuts for Kstars and PHD2 on the Desktop

- Installs INDI Web Manager App, indiweb, and python3-pip

- Places a shortcut/launcher for INDI Web Manager App on the Desktop

Icons included in repo:
The icons for INDI, KStars, and PHD2 are included in their respective packages and are the same
no matter what operating system you are currently using.  The icons I used
for my scripts in the utilities folder are available freely on Ubuntu-MATE systems, but are not
all available on other operating systems.  To make them appear the same on different systems, I have
included these in the icons folder.  These are listed below with their respective source and copyright info:

irda.png (Hicolor icon theme, GPL)
mate-preferences-desktop-display.svg (Hicolor icon theme, GPL)
plip.png (Hicolor icon theme, GPL)
preferences-system-network.svg (MATE icon theme, GPL)
system-software-update.svg (Humanity icon theme, GPL)
system-upgrade.svg (MATE icon theme, GPL)


