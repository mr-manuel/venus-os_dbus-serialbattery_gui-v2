#!/bin/bash

# check if at least 20 MB free space is available on the system partition
freeSpace=$(df -m / | awk 'NR==2 {print $4}')
if [ $freeSpace -lt 20 ]; then

    # try to expand system partition
    bash /opt/victronenergy/swupdate-scripts/resize2fs.sh

    freeSpace=$(df -m / | awk 'NR==2 {print $4}')
    if [ $freeSpace -lt 8 ]; then
        echo
        echo
        echo "ERROR: Not enough free space on the system partition. At least 8 MB are required."
        echo
        echo "       Please please try to execute this command"
        echo
        echo "       bash /opt/victronenergy/swupdate-scripts/resize2fs.sh"
        echo
        echo "       and try the installation again after."
        echo
        echo
        exit 1
    else
        echo
        echo
        echo "INFO: System partition was expanded. Now there are $freeSpace MB free space available."
        echo
        echo
    fi

fi


# handle read only mounts
# TODO: system should not remain in read-only mode
bash /opt/victronenergy/swupdate-scripts/remount-rw.sh


echo ""
echo "Installing GUIv2 WASM build..."

wget -O /tmp/venus-webassembly.zip https://raw.githubusercontent.com/mr-manuel/venus-os_dbus-serialbattery_gui-v2/master/venus-webassembly.zip

unzip -o /tmp/venus-webassembly.zip -d /tmp > /dev/null

# remove unneeded files
if [ -f "/tmp/wasm/Makefile" ]; then
    rm -f /tmp/wasm/Makefile
fi

# move original wasm build, if it's a folder
if [ -d "/var/www/venus/gui-v2" ] && [ ! -L "/var/www/venus/gui-v2" ] && [ ! -d "/var/www/venus/gui-v2.bak" ]; then
    mv /var/www/venus/gui-v2 /var/www/venus/gui-v2.bak
# remove if it's a symlink
elif [ -L "/var/www/venus/gui-v2" ]; then
    rm -f /var/www/venus/gui-v2
fi
mv /tmp/wasm /var/www/venus/gui-v2

cd /var/www/venus/gui-v2 || return

# create missing files for VRM portal check
if [ ! -f "venus-gui-v2.wasm.gz" ]; then
    echo "GZip WASM build..."
    gzip -k venus-gui-v2.wasm
    echo "Create SHA256 checksum..."
    sha256sum /var/www/venus/gui-v2/venus-gui-v2.wasm > /var/www/venus/gui-v2/venus-gui-v2.wasm.sha256
fi

echo
echo "The GUIv2 with the dbus-serialbattery mods was installed successfully."
echo
echo "Please check https://github.com/mr-manuel/venus-os_dbus-serialbattery_gui-v2/tree/master for more details."
echo
