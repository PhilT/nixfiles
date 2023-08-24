wireless_interface=`ls /sys/class/ieee80211/*/device/net/`
wpa_supplicant -B -i$wireless_interface -c./wpa_supplicant.conf

