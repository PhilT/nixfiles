#!/usr/bin/env sh

while getopts 'dic' OPTION; do
  case "$OPTION" in
    d)
      dryrun=1
      ;;
    i)
      installonly=1
      ;;
    c)
      showconfig=1
      ;;
  esac
done
shift $(($OPTIND - 1))

if [ -z "$1" ]; then
  echo "Usage: $0 [-] <machine>"
  echo "  -d Dry run the script (display commands only)"
  echo "  -i Skip everything except install step"
  echo "  -c Show the hardware configuration only"
  echo " Example: $0 -pf <aramid|spruce>"
  exit 0
fi

