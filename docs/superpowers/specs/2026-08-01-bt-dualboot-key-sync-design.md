# Bluetooth dual-boot key sync (spruce)

## Problem

Bluetooth devices store one pairing key per host adapter MAC. NixOS and
Windows on spruce share the same adapter (`88:D8:2E:79:7B:3C`), so whichever
OS pairs last overwrites the key the device holds, and the other OS can no
longer connect. Affected devices: Px8 S2 (`EC:66:D1:D4:DB:98`) and Shokz
OpenRun Pro (`C0:86:B3:80:58:9A`). Both are paired BR/EDR-only in BlueZ,
each with a single `[LinkKey]` section in
`/var/lib/bluetooth/<adapter>/<device>/info`.

The previous fix (documented as a comment in `modules/hardware/bluetooth.nix`)
was manual: take ownership of the `BTHPORT\Parameters\Keys` registry key in
regedit on Windows, export it, and hand-edit the BlueZ info file.

## Solution

A `bt-sync-windows` script (spruce only) that copies Windows' pairing keys
into BlueZ. Run as root after pairing on both OSes, Windows last:

1. Pair the device on NixOS.
2. Reboot into Windows, pair it there (the device now holds Windows' key).
3. Reboot into NixOS, run `sudo bt-sync-windows`.

### Script behaviour

- Mounts the Windows partition (`/dev/disk/by-uuid/0CA043B0A0439ED8`)
  read-only at a `mktemp -d` mountpoint; unmounts on exit via trap. On mount
  failure, advises a full Windows shutdown (fast startup leaves the volume
  dirty).
- Exports `ControlSet001\Services\BTHPORT\Parameters\Keys` from
  `Windows/System32/config/SYSTEM` with chntpw's `reged -x`. No writes to
  the Windows partition, ever.
- Derives the adapter MAC from the single directory under
  `/var/lib/bluetooth/` and locates the matching registry subkey
  (lowercase, colon-free).
- Classic keys are values named `"<12-hex device mac>"=hex:aa,bb,...` under
  the adapter subkey. For each: if the device is paired in BlueZ with a
  `[LinkKey]` section, rewrite its `Key=` line (strip commas, uppercase).
  Already-matching keys are reported as in sync and skipped.
- Reports, without changing anything: registry devices not paired in BlueZ
  ("pair on NixOS first"), BlueZ devices with no Windows key ("pair on
  Windows"), and LE subkeys (`Keys\<adapter>\<device>` with LTK/EDIV/ERand/
  IRK values) matching a BlueZ device — LE translation is out of scope until
  a device needs it, since both headphones pair classic-only in BlueZ.
- Restarts `bluetooth.service` only if a key changed; prints a per-device
  summary using the device alias from the info file.

### Files

- `modules/scripts/bt-sync-windows.nix` — new; `writeShellApplication` with
  `chntpw` and `gawk` as runtime inputs.
- `hosts/spruce/default.nix` — import the new module.
- `modules/hardware/bluetooth.nix` — replace the manual regedit comment with
  the three-step workflow above.
- `modules/scripts/tools.nix` — one reminder line in the `misc` group.

### Out of scope

- LE key translation (LTK/IRK byte-order conversion) — warn only.
- aramid: no Windows dual-boot there.
- `ControlSet002`/`Select` handling — `ControlSet001` is hardcoded; the
  script errors clearly if the key path is missing.
- Pushing BlueZ keys into the Windows registry (reverse direction).

### Verification

`nixx build` for evaluation; a live run before Windows pairing exercises
mount/export/parse and reports both headphones as unpaired on Windows.
Full end-to-end (Phil): pair both devices on Windows, rerun the script,
confirm both connect on NixOS, reboot to Windows, confirm there too.
