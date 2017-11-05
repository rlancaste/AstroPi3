sudo apt-get -y install git
sudo apt-get -y install dkms
# sudo apt-get install raspberrypi-kernel-headers
git clone https://github.com/drwilco/RTL8822BU.git
sudo make dkms-install
make
sudo make install