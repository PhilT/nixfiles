#!/bin/sh

state="BOOT"

RUN() {
  echo "[$state] $1"
  [ "$dryrun" -eq "0" ] && eval "$1"
}

STATE() {
  state=$1
  echo ""
  echo "[$state] ------ $2 ------"
}

WAIT() {
  echo "[$state] $1"
  read
}
