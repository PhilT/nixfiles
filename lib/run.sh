#!/usr/bin/env sh

dryrun=0
installonly=0
showconfig=0
options='nish'

run() {
  while getopts $options OPTION; do
    case "$OPTION" in
      n) dryrun=1 ;;
      i) installonly=1 ;;
      s) showconfig=1 ;;
      h) echo "Usage: $0 -$options [branch] <machine>"
        echo " -n(o op), -i(nstall only), -s(how hardware config), -h(elp)."
        exit 0 ;;
    esac
  done
  shift $(($OPTIND - 1))

  if [ -z $2 ]; then
    machine=$1
  else
    branch=$1
    machine=$2
  fi

  if [ -z "$machine" ]; then
    echo "What machine do you want to install?"
    exit 1
  fi

  if [ "$showconfig" -eq "1" ]; then
    showconfig
  elif [ "$installonly" -eq "1" ]; then
    prepare
    install
  else
    prepare
    connect
    format
    unstable
    install
  fi
}