# Copies Bluetooth pairing keys from the Windows partition into BlueZ, so
# devices paired on both OSes keep working across dual boot (spruce only).
# Devices store one key per adapter MAC and both OSes share the adapter, so
# the last OS to pair overwrites the other's key. Workflow:
# 1. Pair the device on NixOS.
# 2. Reboot into Windows and pair it there too.
# 3. Back on NixOS: sudo bt-sync-windows
# Re-pairing on either OS later invalidates the other; redo from that step.
#
# Reads the SYSTEM registry hive with chntpw's reged from a read-only mount;
# never writes to the Windows partition. Only classic (BR/EDR) link keys are
# synced - LE-only devices are skipped and LE keys are reported, not copied.
{ pkgs, ... }: {
  environment.systemPackages = [
    (pkgs.writeShellApplication {
      name = "bt-sync-windows";
      runtimeInputs = with pkgs; [ chntpw gawk util-linux ];
      text = ''
        if [ "$(id -u)" -ne 0 ]; then
          echo "Run as root: sudo bt-sync-windows" >&2
          exit 1
        fi

        # spruce's Windows partition (nvme0n1p3, NTFS label SYSTEM)
        win_dev="/dev/disk/by-uuid/0CA043B0A0439ED8"

        adapter_dir=$(find /var/lib/bluetooth -mindepth 1 -maxdepth 1 -type d -name '??:??:??:??:??:??' | head -n 1)
        if [ -z "$adapter_dir" ]; then
          echo "No Bluetooth adapter found under /var/lib/bluetooth" >&2
          exit 1
        fi
        adapter_mac=$(basename "$adapter_dir")
        adapter_key=$(echo "$adapter_mac" | tr -d ':' | tr '[:upper:]' '[:lower:]')

        mnt=$(mktemp -d)
        reg=$(mktemp)
        cleanup() {
          umount "$mnt" 2>/dev/null || true
          rmdir "$mnt" 2>/dev/null || true
          rm -f "$reg"
        }
        trap cleanup EXIT

        if ! mount -o ro "$win_dev" "$mnt" 2>/dev/null; then
          echo "Could not mount the Windows partition read-only." >&2
          echo "If Windows didn't shut down fully (fast startup), boot it, shut down from the power menu, and retry." >&2
          exit 1
        fi

        hive="$mnt/Windows/System32/config/SYSTEM"
        if [ ! -f "$hive" ]; then
          echo "SYSTEM hive not found at $hive" >&2
          exit 1
        fi

        if ! reged -x "$hive" 'HKEY_LOCAL_MACHINE\SYSTEM' 'ControlSet001\Services\BTHPORT\Parameters\Keys' "$reg" >/dev/null; then
          echo "reged failed to export the Bluetooth keys from the Windows registry" >&2
          exit 1
        fi

        if ! grep -qF "\\Keys\\$adapter_key]" "$reg"; then
          echo "Windows has no Bluetooth pairings for adapter $adapter_mac" >&2
          exit 1
        fi

        # One line per entry: "CLASSIC <mac> <key>" (lowercase mac, no colons)
        # or "LE <mac>". Continuation lines are joined and CRs stripped first.
        parse_registry() {
          tr -d '\r' <"$reg" | sed -e ':a' -e '/\\$/{N;s/\\\n *//;ba}' | awk -v adapter="$adapter_key" '
            /^\[/ {
              sect = "other"
              if (index($0, "\\Keys\\" adapter "]") > 0) sect = "classic"
              else if (index($0, "\\Keys\\" adapter "\\") > 0) {
                le = $0
                sub(/\]$/, "", le)
                sub(/^.*\\/, "", le)
                print "LE " le
              }
              next
            }
            sect == "classic" && /^"[0-9a-f]+"=hex:/ {
              mac = $0
              sub(/^"/, "", mac)
              sub(/".*$/, "", mac)
              if (length(mac) != 12) next
              key = $0
              sub(/^[^:]*:/, "", key)
              gsub(/,/, "", key)
              print "CLASSIC " mac " " toupper(key)
            }
          '
        }

        declare -A win_classic
        le_macs=" "
        while read -r kind mac key; do
          case "$kind" in
            CLASSIC) win_classic[$mac]=$key ;;
            LE) le_macs="$le_macs$mac " ;;
          esac
        done < <(parse_registry)

        # BlueZ devices with a classic pairing; LE-only devices are out of scope.
        bluez_devs=" "
        for dev_dir in "$adapter_dir"/??:??:??:??:??:??; do
          [ -f "$dev_dir/info" ] || continue
          grep -q '^\[LinkKey\]' "$dev_dir/info" || continue
          bluez_devs="$bluez_devs$(basename "$dev_dir" | tr -d ':' | tr '[:upper:]' '[:lower:]') "
        done

        changed=0
        for dev_key in $bluez_devs; do
          dev_mac=$(echo "$dev_key" | sed 's/../&:/g;s/:$//' | tr '[:lower:]' '[:upper:]')
          info="$adapter_dir/$dev_mac/info"
          dev_alias=$(sed -n 's/^Alias=//p' "$info" | head -n 1)
          [ -n "$dev_alias" ] || dev_alias=$(sed -n 's/^Name=//p' "$info" | head -n 1)
          [ -n "$dev_alias" ] || dev_alias=$dev_mac

          if [ -n "''${win_classic[$dev_key]:-}" ]; then
            win_key=''${win_classic[$dev_key]}
            cur_key=$(awk '/^\[/ { s = ($0 == "[LinkKey]") } s && /^Key=/ { sub(/^Key=/, ""); print }' "$info")
            if [ "$cur_key" = "$win_key" ]; then
              echo "$dev_alias ($dev_mac): already in sync"
            else
              tmp=$(mktemp)
              awk -v key="$win_key" '
                /^\[/ { s = ($0 == "[LinkKey]") }
                s && /^Key=/ { print "Key=" key; next }
                { print }
              ' "$info" >"$tmp"
              chmod 600 "$tmp"
              mv "$tmp" "$info"
              echo "$dev_alias ($dev_mac): link key updated from Windows"
              changed=$((changed + 1))
            fi
          else
            echo "$dev_alias ($dev_mac): no Windows pairing - pair it on Windows, then rerun"
          fi

          case "$le_macs" in
            *" $dev_key "*)
              echo "$dev_alias ($dev_mac): Windows also holds LE keys; only the classic link key is synced" ;;
          esac
        done

        for mac in "''${!win_classic[@]}"; do
          case "$bluez_devs" in
            *" $mac "*) ;;
            *)
              pretty=$(echo "$mac" | sed 's/../&:/g;s/:$//' | tr '[:lower:]' '[:upper:]')
              echo "$pretty: paired on Windows but not on NixOS - pair it here, on Windows again, then rerun" ;;
          esac
        done

        if [ "$changed" -gt 0 ]; then
          systemctl restart bluetooth
          echo "Restarted bluetooth: $changed key(s) synced"
        else
          echo "No keys changed"
        fi
      '';
    })
  ];
}
