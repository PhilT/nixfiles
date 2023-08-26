#!/bin/sh

machine=$1 || $(hostname)

case $machine in
  "darko")
    ;;
  "spruce")
    ;;
  *)
    echo "Usage: $0 <darko|spruce>"
    exit
    ;;
esac

source ./common.env
source ./$machine.env

echo "[REBUILD] $machine"

# Copy SSH dir if not already
[ -d "~/.ssh" ] || cp -R ./.ssh ~/

# Setup Wifi if not already
ping -c 1 google.com > /dev/null 2>&1 || sudo iwctl --passphrase=$psk station wlan0 connect $ssid

./copy_config.sh $machine /etc/nixos 0 # 0 - No dryrun

cd ~                   # Needed as rebuild symlinks the result from the current path
sudo nixos-rebuild test
cd -
