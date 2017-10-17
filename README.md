# AstroPi3

This script is meant to automate the many setup steps involved with configuring a Raspberry Pi 3 so that it can be an 
Astrophotography hub using INDI, KStars, and Ekos.  I first developed the series of steps by research, trial, and error
in 2016.  Then several users on indilib.org, especially James Taylor ( u2pilotjt ), tested my steps and helped me revise them.
James Taylor wrote a beginners guide which can be accessed here:  http://www.indilib.org/support/tutorials/169-ekos-on-raspberry-pi-complete-guide.html
In Fall 2017,  I was configuring another PI, went back to my instructions and his guide and followed both.  I revised my steps and then
turned it into this script.  Hopefully this is much easier to use.

Before running the script, please be sure to do some research and read up on all that it will do to your Raspberry Pi.  You may want to 
use the script as is or add or remove certain lines before running it by adding or removing comment symbols from the front of the line (#).

When you are ready, you can follow these steps:

1.	Download latest version of Ubuntu mate https://ubuntu-mate.org/raspberry-pi/
2.	Unzip the xz file. You may need special software to do this.  I used "The UnArchiver" on my mac.
3.  Copy the disk image (img) file you unzipped onto the flash drive.  Operating System specific instructions are below.
4.  Before you remove the SD Card, You should edit this document in the edit the following file in the Pi-boot partition which should have automatically mounted after the imaging process: 

						/boot/config.txt 
						
	to make sure that your PI will have a decent resolution even when an HDMI display is not connected. Use the following options:
	
		hdmi_force_hotplug=1
		
		hdmi_group=2
		
		hdmi_mode=46 (1440 x 900@60Hz)
		
		For the 3rd one, you can set your resolution to whatever you like.  I set it to option 46 (1440 x 900) since that is my laptop resolution.

5.  Insert the SD Card into the Raspberry Pi, connect a mouse, keyboard, and display.  Then turn it on.
6.  You should get a setup window.  Configure your Raspberry Pi using the window.  Be sure to choose your login name and computer name carefully.  This is difficult to change later.
7.  Copy the script setupAstroPi3.sh to your Raspberry Pi and Open a Terminal Window.
8.  Navigate to the Folder containing the script.
8.  Make sure the file is executable using
	chmod +x setupAstroPi3.sh
9.  Run the script using sudo
	sudo ./setupAstroPi3.sh


