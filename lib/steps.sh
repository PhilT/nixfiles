#!/usr/bin/env sh

[ -z "$home" ] && home="/home/nixos"

prepare() {
  [ -z "$branch" ] && branch="main"

  askpass 'Password for KeePass'
  RUN "mkdir -p $home/.ssh"
  keepass_export_keys $prefix $machine "github"

  # Fetch latest nixfiles repo
  RUN "git clone -b $branch --single-branch --depth 1 git@github.com:PhilT/nixfiles.git"

  keepass_export_password 'nixfiles/secrets/password'
  keepass_export_hashed_password 'nixfiles/secrets/hashed_password'
  keepass_fetch_wifi
}

connect() {
  STATE " NET" "Wifi"

  [ "$dryrun" -eq "1" ] && ssid="ssid"
  [ "$dryrun" -eq "1" ] && psk="psk"

  if [ ! ping -c 1 google.com > /dev/null 2>&1 ] || [ "$dryrun" -eq "1" ]; then
    SUDO "wpa_passphrase \"$ssid\" \"$psk\" > /etc/wpa_supplicant.conf"
    RUN "ls /sys/class/ieee80211/*/device/net/"
    SUDO "wpa_supplicant -B -i$temp_result -c/etc/wpa_supplicant.conf"
    RUN "while ! ping -c 1 google.com > /dev/null 2>&1; do sleep 1; done"
  fi
}

format() {
  $machine
}

unstable() {
  STATE "CHAN" "Switch to unstable channel"
  SUDO "nix-channel --add https://nixos.org/channels/nixos-unstable nixos"
  SUDO "nix-channel --update"
}

install() {
  STATE "INST" "Install NixOS?"
  WAIT
  SUDO "mkdir -p /mnt/etc/nixos"
  SUDO "ln -fs $(pwd)/nixfiles/src/machines/$machine/minimal.nix /mnt/etc/nixos/configuration.nix"
  SUDO "nixos-install --no-root-password"
}

showconfig() {
  STATE "CONF" "Show hardware configuration"
  RUN "nixos-generate-config --show-hardware-config"
  SHOW_RESULT
}