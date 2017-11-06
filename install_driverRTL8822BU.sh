echo "~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo "Attempting to Install Realtek drivers for Wifi Dongle using chipset RTL8822BU"
if [ "$(whoami)" != "root" ]; then
	display "Please run this script with sudo due to the fact that it must do a number of sudo tasks.  Exiting now."
	exit 1
fi
sudo apt-get -y install git
sudo apt-get -y install dkms
sudo apt-get install raspberrypi-kernel-headers
git clone https://github.com/drwilco/RTL8822BU.git
cd RTL8822BU
sudo make dkms-install
make
sudo make install
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo "Script Execution Complete.  You may need to restart for the wifi dongle to work well."