sudo dpkg --add-architecture armhf
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
