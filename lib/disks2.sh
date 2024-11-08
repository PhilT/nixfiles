# Key-based drive encryption functions

generate_key() {
  local keyfile=$1

  sudo dd if=/dev/urandom bs=32 count=1 of=$keyfile
  sudo chmod 400 $keyfile
}

change_key() {
  local pool=$1
  local keyfile="file://$2"

  sudo zfs change-key -o keyformat=raw -o keylocation=$keyfile $pool
}