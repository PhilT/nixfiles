#!/usr/bin/env sh

[ -z "$home" ] && home="/home/nixos"
codedir="/mnt/data/code"

prepare() {
  askpass 'Password for KeePass'
  RUN "mkdir -p $home/.ssh"
  keepass_export_keys $prefix $machine "github"
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

clone() {
  [ -z "$branch" ] && branch="main"

  # Fetch latest nixfiles repo
  SUDO "mkdir -p $codedir"
  SUDO "git clone -b $branch --single-branch --depth 1 git@github.com:PhilT/nixfiles.git" "$codedir"

  SUDO "chown nixos:users $codedir/nixfiles/secrets"
  keepass_export_hashed_password "$codedir/nixfiles/secrets/hashed_password"
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
  SUDO "ln -fs $codedir/nixfiles/src/machines/$machine/minimal.nix /mnt/etc/nixos/configuration.nix"
  SUDO "nixos-install --no-root-password"
  STATE "REBT" "Reboot?"
  RUN "rm $codedir/nixfiles/secrets/*"
  SUDO "chown -R 1000:users /mnt/data"
  WAIT
  reboot
}

showconfig() {
  STATE "CONF" "Show hardware configuration"
  RUN "nixos-generate-config --show-hardware-config"
  SHOW_RESULT
}