#!/bin/sh

state="BOOT"

RUN() {
  echo "[$state] $1"
  [ "$dryrun" -eq "0" ] && temp_result=$(eval "$1")
  [ "$?" -ne "0" ] && exit 1
}

RUN_WITH_RESULT() {
  RUN "$1"
  run_result=$temp_result
}

STATE() {
  state=$1
  local title=$2
  echo ""
  echo "[$state] ------ $title ------"
}

WAIT() {
  echo "[$state] $1"
  read
}