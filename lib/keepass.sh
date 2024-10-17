#!/usr/bin/env sh

db=/data/sync/HomeDatabase.kdbx
prefix=id_ed25519

kp_cli() {
  echo $passwd | keepassxc-cli $@
}

[ -f $db ] || db=/usb/HomeDatabase.kdbx
if [ ! -f $db ]; then
  echo "No Keepass database found!"
  exit 1
fi

# args: "Question text"
askpass() {
  if [ -z "$passwd" ]; then
    echo $1
    stty -echo
    read passwd
    stty echo
  fi
}

# args: <prefix>_<machine>[_<service>]
keepass_create() {
  local keyfile=$1
  kp_cli add -q $db $keyfile
}

# args: <prefix>_<machine>[_<service>]
keepass_exists() {
  local keyfile=$1
  kp_cli show -q $db $keyfile > /dev/null 2>&1
}

# args: <prefix>_<machine>[_<service>]
keepass_import_keys() {
  local keyfile=$1
  kp_cli attachment-import -q $db $keyfile public secrets/$keyfile.pub
  kp_cli attachment-import -q $db $keyfile private secrets/$keyfile
}

# args: <public|private> <prefix>_<machine>[_<service>] <path>
keepass_export_key() {
  local public_private=$1
  local keyfile=$2
  local path=$3
  [ "$public_private" = "private" ] || local ext=".pub"

  rm -f $path/$keyfile$ext
  kp_cli attachment-export -q $db $keyfile $public_private $path/$keyfile$ext 2> /dev/null
}

# args: <prefix> <machine> [service]
keepass_export_keys() {

  if [ -z "$3" ]; then
    local keyfile=$1_$2
    local without_machine=$1
  else
    local keyfile=$1_$2_$3
    local without_machine=$1_$3
  fi
  local ssh_dir=$HOME/.ssh

  keepass_export_key "public" $keyfile $ssh_dir
  mv $ssh_dir/$keyfile.pub $ssh_dir/$without_machine.pub
  keepass_export_key "private" $keyfile $ssh_dir
  mv $ssh_dir/$keyfile $ssh_dir/$without_machine

  chmod 644 $ssh_dir/$without_machine.pub
  chmod 600 $ssh_dir/$without_machine
}

keepass_export_password() {
  kp_cli show -qsa Password $db password | tr -d '\n'
}

keepass_export_hashed_password() {
  rm -f secrets/hashed_password
  kp_cli show -qsa Password $db hashed_password | tr -d '\n' > secrets/hashed_password
}

keepass_export_wifi() {
  rm -f secrets/wifi
  echo ssid=$(kp_cli show -qsa Username $db wifi_home | tr -d '\n') > secrets/wifi
  echo psk=$(kp_cli show -qsa Password $db wifi_home | tr -d '\n') >> secrets/wifi
}

keepass_export_luks_key() {
  rm -rf secrets/luks.key
  keepass_export_key private luks_key secrets/luks.key
}