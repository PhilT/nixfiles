#!/usr/bin/env sh

db=/data/sync/HomeDatabase.kdbx
prefix=id_ed25519

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
keepass_export_key() {
  local public_private=$1
  local keyfile=$2
  local path=$3
  [ "$public_private" = "private" ] || local ext=".pub"

  rm -f $path/$keyfile$ext
  echo $passwd | keepassxc-cli attachment-export -q $db $keyfile $public_private $path/$keyfile$ext 2> /dev/null
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

# args: (none)
keepass_export_password() {
  rm -f secrets/hashed_password
  echo $passwd | keepassxc-cli show -qsa Password $db hashed_password | tr -d '\n' > secrets/hashed_password
}