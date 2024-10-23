#!/usr/bin/env sh

db=/data/sync/HomeDatabase.kdbx
prefix=id_ed25519

[ -f $db ] || db=/etc/HomeDatabase.kdbx
if [ ! -f $db ]; then
  echo "No Keepass database found at ${db}!"
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
  echo $passwd | keepassxc-cli add -q $db $keyfile
}

# args: <prefix>_<machine>[_<service>]
keepass_exists() {
  local keyfile=$1
  echo $passwd | keepassxc-cli show -q $db $keyfile > /dev/null 2>&1
}

# args: <prefix>_<machine>[_<service>]
keepass_import_keys() {
  local keyfile=$1
  echo $passwd | keepassxc-cli attachment-import -q $db $keyfile public secrets/$keyfile.pub
  echo $passwd | keepassxc-cli attachment-import -q $db $keyfile private secrets/$keyfile
}

# args: <public|private> <prefix>_<machine>[_<service>] <path>
# if path not specified, sends files to stdout
keepass_export_key() {
  local public_private=$1
  local keyfile=$2
  local ext=""
  if [ -z "$3" ]; then
    local stdout="--stdout"
  else
    [ "$public_private" = "public" ] && ext=".pub"
    local path=$3/$keyfile$ext
  fi

  rm -f $path
  echo $passwd | keepassxc-cli attachment-export -q $stdout $db $keyfile $public_private $path #2> /dev/null
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
  local ssh_dir=$home/.ssh

  keepass_export_key "public" $keyfile $ssh_dir
  mv $ssh_dir/$keyfile.pub $ssh_dir/$without_machine.pub
  keepass_export_key "private" $keyfile $ssh_dir
  mv $ssh_dir/$keyfile $ssh_dir/$without_machine

  chmod 644 $ssh_dir/$without_machine.pub
  chmod 600 $ssh_dir/$without_machine
}

keepass_export_password() {
  local path=$1

  echo -n $(echo $passwd | keepassxc-cli show -qsa Password $db password | tr -d '\n') > $path
}

keepass_export_hashed_password() {
  local path=$1

  rm -f secrets/hashed_password
  echo $passwd | keepassxc-cli show -qsa Password $db hashed_password | tr -d '\n' > $path
}

keepass_fetch_wifi() {
  ssid=$(echo $passwd | keepassxc-cli show -qsa Username $db wifi_home | tr -d '\n')
  psk=$(echo $passwd | keepassxc-cli show -qsa Password $db wifi_home | tr -d '\n')
}