#!/bin/sh

state="BOOT"

RUN() {
  echo "[$state] $1"
  [ "$dryrun" -eq "0" ] && temp_result=$(eval "$1")
  resultcode=$?
  if [ "$resultcode" -ne "0" ]; then
    echo "[FAIL] $1"
    echo "       Exit code: $resultcode"
    echo "       Result: $temp_result"
    echo "[HELP] If this was a nixos-<command> error, check prefix/nix/var/log/nix"
    exit $resultcode
  fi
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