#!/bin/sh

state="BOOT"

RUN() {
  echo "[$state] $1"
  if [ "$dryrun" -eq "0" ]; then
    temp_result=$(eval "$1")
    resultcode=$?
    if [ "$resultcode" -ne "0" ]; then
      echo "[FAIL] $1"
      echo "       Exit code: $resultcode"
      echo "       Result: $temp_result"
      echo "[HELP] If this was a nixos-<command> error, check prefix/nix/var/log/nix"
      exit $resultcode
    fi
  fi
}

SUDO() {
  RUN "sudo $1"
}

RUN_WITH_RESULT() {
  RUN "$1"
  run_result=$temp_result
}

SHOW_RESULT() {
  if [ "$dryrun" -eq "0" ]; then
    echo "$run_result"
  else
    echo "(result of command would appear here)"
  fi
}

STATE() {
  local title=$2
  state=$1

  echo ""
  echo "[$state] $title"
}

WAIT() {
  local message=$1

  [ ! -z "$message" ] && echo "[$state] $1"
  [ "$dryrun" -eq "0" ] && read
}