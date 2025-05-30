#!/usr/bin/env sh

[ -z "$home" ] && home="/home/nixos"
codedir="/mnt/data/code"

prepare() {
  askpass 'Password for KeePass'
  RUN "mkdir -p $home/.ssh"
  keepass_export_keys "$home/.ssh" $machine "github"
  keepass_fetch_wifi
}

connect() {
  [ "$dryrun" -eq "1" ] && ssid="ssid"
  [ "$dryrun" -eq "1" ] && psk="psk"

  ping -c 1 google.com > /dev/null 2>&1
  if [ "$?" -eq "0"  ] && [ "$dryrun" -ne "1" ]; then
    STATE " NET" "Connected"
  else
    STATE " NET" "Disconnected. Establish Wifi connection"
    SUDO "sh -c 'wpa_passphrase \"$ssid\" \"$psk\" > /etc/wpa_supplicant.conf'"
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
  local nixfiles_repo="git@github.com:PhilT/nixfiles.git"
  local ssh_command="GIT_SSH_COMMAND='ssh -i $HOME/.ssh/id_ed25519_github'"

  # Fetch latest nixfiles repo
  SUDO "mkdir -p $codedir"
  SUDO "$ssh_command git clone -b $branch --single-branch --depth 1 $nixfiles_repo" "$codedir"

  SUDO "chown nixos:users $codedir/nixfiles/secrets"
  keepass_export_hashed_password "$codedir/nixfiles/secrets/hashed_password"
}

channels() {
  STATE "CHAN" "Add channels"
  SUDO "nix-channel --add https://github.com/catppuccin/nix/archive/main.tar.gz catppuccin"
  SUDO "nix-channel --add https://github.com/NixOS/nixos-hardware/archive/master.tar.gz nixos-hardware"
  SUDO "nix-channel --add https://nixos.org/channels/nixos-unstable nixos"
  SUDO "nix-channel --update"
}

install() {
  STATE "INST" "Installing NixOS"
  SUDO "mkdir -p /mnt/etc/nixos"
  SUDO "ln -fs $codedir/nixfiles/src/machines/$machine/$installtype.nix /mnt/etc/nixos/configuration.nix"
  SUDO "nixos-install --no-root-password"
  STATE "REBT" "Rebooting..."
  RUN "rm $codedir/nixfiles/secrets/*"
  SUDO "mkdir -p /mnt/data/sync"
  SUDO "cp $db /mnt/data/sync"
  SUDO "chmod +w /mnt/data/sync/*"
  SUDO "chown 1000:users /mnt/data"
  SUDO "chown -R 1000:users /mnt/data/sync"
  SUDO "umount -l /mnt"
  SUDO "zpool export -a"
  reboot
}

showconfig() {
  STATE "CONF" "Show hardware configuration"
  RUN "nixos-generate-config --show-hardware-config"
  SHOW_RESULT
}