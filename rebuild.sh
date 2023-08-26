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

sudo cp ./bootstrap.nix /etc/nixos/bootstrap.nix
sudo cp ./common.nix /etc/nixos/common.nix
sudo cp ./$machine.nix /etc/nixos/configuration.nix
sudo ./replace_vars.sh $machine /etc/nixos/bootstrap.nix

cd ~                   # Needed as rebuild symlinks the result from the current path
sudo nixos-rebuild test
cd -
