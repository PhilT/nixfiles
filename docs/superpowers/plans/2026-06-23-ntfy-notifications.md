# ntfy Notifications Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Self-host an ntfy server on minoo, migrate all system alerts (ZFS, systemd failures, zpool health, unison) from email onto it, and wire Claude Code to push to it.

**Architecture:** A new `modules/ntfy.nix` enables `services.ntfy-sh` on minoo (LAN-only, port 2586, 30-day cache). `modules/notify.nix` is rewritten: the himalaya/SMTP machinery is replaced by a small `notify <topic> "Title" [body|stdin]` helper that `curl`s the local ntfy server; all existing triggers are rewired to it. Claude Code hooks in `~/.claude/settings.json` curl minoo's ntfy on a separate topic.

**Tech Stack:** NixOS (`services.ntfy-sh`, nixos 25.11), `curl`, `writeShellApplication`, ntfy Android app.

## Global Constraints

- **minoo builds run on minoo.** `nixx build -m minoo` does not work from spruce. Edit on spruce → `scp` changed files to `minoo:/data/code/nixfiles/...` → `ssh minoo 'nixx build -s -m minoo'` → only commit/push from spruce once it builds clean → finalize minoo with `git checkout -- <file> && git pull`.
- **Do not `git commit` until Phil has tested the change.** Edit, build, verify, then stop and let Phil confirm before committing.
- ntfy server: `base-url = "http://minoo:2586"`, `listen-http = ":2586"`, `cache-duration = "720h"`, no auth, firewall port `2586` open (LAN).
- Topics: `system` (ZFS/systemd/zpool/unison), `claude` (Claude Code).
- Hostname-prefixed titles (`[<host>] <subject>`), matching the old email subject style.
- Preserve dpool-independence: ntfy state stays under `/var/lib/ntfy-sh` (root pool; module default — do not relocate to /data).

---

### Task 1: ntfy server on minoo

**Files:**
- Create: `modules/ntfy.nix`
- Modify: `hosts/minoo/default.nix` (imports list, ~line 47)

**Interfaces:**
- Produces: a running ntfy server reachable at `http://minoo:2586`, accepting `POST /<topic>`. Later tasks publish to `http://localhost:2586/<topic>` (from minoo) and `http://minoo:2586/<topic>` (from spruce/aramid/phone).

- [ ] **Step 1: Write `modules/ntfy.nix`**

```nix
# Self-hosted ntfy push-notification server (minoo, LAN-only). Replaces the
# former email notification path. State (cache DB) lives under /var/lib/ntfy-sh
# on the root pool via the module's systemd StateDirectory, so a suspended dpool
# never breaks alerting.
{ ... }: {
  services.ntfy-sh = {
    enable = true;
    settings = {
      base-url = "http://minoo:2586";  # include port so generated links resolve
      listen-http = ":2586";           # module default is 127.0.0.1:2586; bind all for LAN
      cache-duration = "720h";         # ~30 days, so missed alerts replay on return home
      behind-proxy = false;
    };
  };

  networking.firewall.allowedTCPPorts = [ 2586 ];
}
```

- [ ] **Step 2: Import it from minoo**

In `hosts/minoo/default.nix`, in the `imports` list, replace the notify.nix import line so both modules are imported (notify.nix is rewritten in Task 2 but its import stays):

```nix
    # Push notifications (ntfy server + system-alert senders)
    ../../modules/ntfy.nix
    ../../modules/notify.nix
```

- [ ] **Step 3: Build on minoo**

```bash
scp modules/ntfy.nix minoo:/data/code/nixfiles/modules/ntfy.nix
scp hosts/minoo/default.nix minoo:/data/code/nixfiles/hosts/minoo/default.nix
ssh minoo 'nixx build -s -m minoo'
```
Expected: builds and switches cleanly.

- [ ] **Step 4: Verify the server is up and reachable**

```bash
ssh minoo 'systemctl is-active ntfy-sh'        # expect: active
ssh minoo 'curl -s -d "server up" http://localhost:2586/system'   # expect JSON with an "id" field
```
Expected: `active`, and a JSON response (no error).

- [ ] **Step 5: STOP — Phil sets up phone + confirms receipt**

Phil installs the ntfy Android app, subscribes to `http://minoo:2586` topics `system` and `claude`, and confirms the `curl` from Step 4 (re-run if needed) arrives on the phone. Do not commit yet.

---

### Task 2: Rewrite notify.nix — ntfy sender + rewire system triggers

**Files:**
- Modify: `modules/notify.nix` (full rewrite)

**Interfaces:**
- Consumes: ntfy server from Task 1 at `http://localhost:2586`.
- Produces: a `notify` command on the system PATH with signature `notify <topic> "<title>" [<body>]` (body defaults to stdin). Used by Task 3.

- [ ] **Step 1: Replace `modules/notify.nix` with the ntfy version**

```nix
# Push notifications via the self-hosted ntfy server (see modules/ntfy.nix).
# Covers ZFS events (zed), systemd unit failures (notify@.service template),
# and zpool health (zpool-health-check timer). All publish to the `system`
# topic on the local ntfy server. The server's cache lives on the root pool,
# so alerts about a suspended dpool still send and replay when the phone
# returns to home Wi-Fi.
{ config, pkgs, lib, ... }:
let
  ntfyUrl = "http://localhost:2586";

  # notify <topic> "Title" [body]   — body defaults to stdin.
  # Failure-type alerts use high priority + warning tag.
  notify = pkgs.writeShellApplication {
    name = "notify";
    runtimeInputs = [ pkgs.curl pkgs.coreutils ];
    text = ''
      topic="$1"
      title="$2"
      body="''${3:-$(cat)}"
      host=$(hostname)
      curl -s \
        -H "Title: [$host] $title" \
        -H "Priority: high" \
        -H "Tags: warning" \
        -d "$body" \
        "${ntfyUrl}/$topic" > /dev/null
    '';
  };

  # ExecStart for notify@<unit>.service — builds body from the unit's journal.
  notifyUnit = pkgs.writeShellApplication {
    name = "notify-unit";
    runtimeInputs = [ pkgs.systemd notify ];
    text = ''
      unit="$1"
      body=$(journalctl -u "$unit" --no-pager -n 50 2>&1 || echo "(no journal)")
      notify system "Service failed: $unit" "$body"
    '';
  };

  # zed invokes: prog -s SUBJECT TO_ADDR   with body on stdin.
  zedNotify = pkgs.writeShellApplication {
    name = "notify-zed";
    runtimeInputs = [ notify ];
    text = ''
      subject="$2"
      notify system "ZFS: $subject"
    '';
  };

  # Alert on pool health transitions. The flag file records "alert sent"; it is
  # only touched after notify succeeds (set -e aborts first on a failed send),
  # so a failed send is retried on the next timer run.
  zpoolHealthCheck = pkgs.writeShellApplication {
    name = "zpool-health-check";
    runtimeInputs = [ pkgs.coreutils pkgs.zfs notify ];
    text = ''
      flag=/var/lib/notify/zpool-unhealthy
      state=$(zpool status -x)
      if [ "$state" = "all pools are healthy" ]; then
        if [ -e "$flag" ]; then
          printf '%s\n' "$state" | notify system "ZFS pools recovered"
          rm -f "$flag"
        fi
      else
        if [ ! -e "$flag" ]; then
          zpool status | notify system "ZFS pool UNHEALTHY"
          : > "$flag"
        fi
      fi
    '';
  };
in {
  environment.systemPackages = [ notify ];

  # Flag-file dir for the zpool watchdog (root pool).
  systemd.tmpfiles.rules = [
    "d /var/lib/notify 0700 root root -"
  ];

  # Opt-in OnFailure target. Use on any service you want to be notified about:
  #   systemd.services.foo.unitConfig.OnFailure = [ "notify@%n.service" ];
  systemd.services."notify@" = {
    description = "ntfy notification for failed unit %i";
    serviceConfig = {
      Type = "oneshot";
      Environment = [ "PATH=/run/current-system/sw/bin" ];
      ExecStart = "${notifyUnit}/bin/notify-unit %i";
    };
  };

  # ZFS event daemon — automatic notifications for pool/scrub/resilver events.
  services.zfs.zed.settings = {
    ZED_EMAIL_ADDR = [ "root" ];
    ZED_EMAIL_PROG = "${zedNotify}/bin/notify-zed";
    ZED_NOTIFY_VERBOSE = true;
  };
  systemd.services.zfs-zed.serviceConfig.Environment = [
    "PATH=/run/current-system/sw/bin"
  ];

  # Watchdog: a suspended/degraded pool does NOT make unison fail (it hangs in
  # uninterruptible I/O while systemd still sees it "active"), so OnFailure
  # can't catch it. Poll pool health directly and alert on transitions.
  systemd.services.zpool-health-check = {
    description = "Alert on unhealthy ZFS pools";
    serviceConfig = {
      Type = "oneshot";
      TimeoutStartSec = "2min";
      Environment = [ "PATH=/run/current-system/sw/bin" ];
      ExecStart = "${zpoolHealthCheck}/bin/zpool-health-check";
    };
  };
  systemd.timers.zpool-health-check = {
    wantedBy = [ "timers.target" ];
    timerConfig.OnCalendar = "*:0/10";
  };
}
```

Notes on the rewrite:
- Removed: `recipient`, `himalayaConfig`, `notifyEmail`, `cacheCredentials`, the `notify-credentials` service, the maildir tmpfiles, and the email-specific `Environment` PATH justification comments.
- `ZED_EMAIL_PROG`/`ZED_EMAIL_ADDR` are kept because that is zed's only hook for running an external program; `ZED_EMAIL_ADDR` is a required-but-unused arg (set to `root`).
- The `notify@` template renamed from `notify-email@`; no current caller references `notify-email@` by name except the unison gate (handled in Task 3).

- [ ] **Step 2: Build on minoo**

```bash
scp modules/notify.nix minoo:/data/code/nixfiles/modules/notify.nix
ssh minoo 'nixx build -s -m minoo'
```
Expected: builds and switches cleanly. (Will fail until Task 3 fixes the unison gate's `notify-email` reference — do Task 3 Step 1 before this build, or expect the build to surface that as a missing command at runtime, not build time. See Task 3.)

- [ ] **Step 3: Verify system-topic delivery**

```bash
ssh minoo 'notify system "test alert" "hello from minoo"'
```
Expected: phone receives `[minoo] test alert`.

- [ ] **Step 4: Verify the OnFailure template path**

```bash
ssh minoo 'sudo systemctl start notify@test-unit.service; systemctl status notify@test-unit.service --no-pager | head'
```
Expected: oneshot runs; phone receives a `Service failed: test-unit` notification (journal body may say "no journal").

- [ ] **Step 5: STOP — let Phil confirm before committing.**

---

### Task 3: Rewire the unison failure gate

**Files:**
- Modify: `hosts/minoo/default.nix` (the `unisonFailureGate` shell app + its service `Environment`, ~lines 1–73)

**Interfaces:**
- Consumes: `notify` from Task 2.

- [ ] **Step 1: Update the unison gate to use `notify`**

In `hosts/minoo/default.nix`, find the `unisonFailureGate` `writeShellApplication` whose text ends with:

```nix
      notify-email "Service failed: unison (suuno up, port 2222 $port_state)" "$body"
```

Replace that line with:

```nix
      notify system "Service failed: unison (suuno up, port 2222 $port_state)" "$body"
```

Ensure the shell app's `runtimeInputs` includes the `notify` command. Since `notify` is on the system PATH and the service sets `Environment = [ "PATH=/run/current-system/sw/bin" ]`, the existing `Environment` line is sufficient; no `runtimeInputs` change is needed if the script calls `notify` via PATH. Confirm the `unison-failure-notify` service still has:

```nix
      Environment = [ "PATH=/run/current-system/sw/bin" ];
```

- [ ] **Step 2: Build on minoo**

```bash
scp hosts/minoo/default.nix minoo:/data/code/nixfiles/hosts/minoo/default.nix
ssh minoo 'nixx build -s -m minoo'
```
Expected: builds and switches cleanly.

- [ ] **Step 3: Verify the unison gate path**

```bash
ssh minoo 'sudo systemctl start unison-failure-notify.service; journalctl -u unison-failure-notify.service --no-pager -n 20'
```
Expected: runs without error. If suuno is reachable, phone receives a unison failure notification; if suuno is offline the gate is silent by design (check the journal to confirm which path ran).

- [ ] **Step 4: STOP — Phil confirms, then commit + push from spruce, finalize minoo.**

```bash
# from spruce, after Phil confirms:
git add modules/ntfy.nix modules/notify.nix hosts/minoo/default.nix docs/superpowers/plans/2026-06-23-ntfy-notifications.md
git commit -m "Replace email notifications with self-hosted ntfy on minoo"
git push
ssh minoo 'git -C /data/code/nixfiles checkout -- modules/ntfy.nix modules/notify.nix hosts/minoo/default.nix && git -C /data/code/nixfiles pull'
```

---

### Task 4: Claude Code hooks → ntfy

**Files:**
- Modify: `~/.claude/settings.json` (the `hooks` object) — outside the nixfiles repo.

**Interfaces:**
- Consumes: ntfy server at `http://minoo:2586`, topic `claude`.

- [ ] **Step 1: Add `Notification` and `Stop` hooks**

Add to the `hooks` object in `~/.claude/settings.json` (alongside the existing `SessionStart`/`UserPromptSubmit` entries):

```json
    "Notification": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "curl -s -H \"Title: Claude Code needs you\" -H \"Tags: bell\" -d \"$(hostname): waiting for input\" http://minoo:2586/claude > /dev/null"
          }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "curl -s -H \"Title: Claude Code done\" -H \"Tags: white_check_mark\" -d \"$(hostname): task finished\" http://minoo:2586/claude > /dev/null"
          }
        ]
      }
    ]
```

- [ ] **Step 2: Verify the hook command works standalone**

Run from spruce:
```bash
curl -s -H "Title: Claude Code done" -H "Tags: white_check_mark" -d "$(hostname): task finished" http://minoo:2586/claude
```
Expected: JSON response; phone receives `Claude Code done` on the `claude` topic.

- [ ] **Step 3: Verify in a real session**

Start a Claude Code session on spruce, let it finish a turn → expect a `Stop` push; trigger a permission prompt → expect a `Notification` push.

- [ ] **Step 4: Confirm with Phil.** (settings.json is not in the repo; no commit needed.)

---

## Self-Review

**Spec coverage:**
- ntfy server on minoo (§Components 1) → Task 1. ✓
- Sender helper + rewire zed/OnFailure/zpool (§Components 2) → Task 2. ✓
- unison-failure-gate rewire (§Components 2 table) → Task 3. ✓
- Email machinery removal (§Components 2) → Task 2 Step 1 notes. ✓
- Claude Code hooks (§Components 3) → Task 4. ✓
- Phone subscription (§Components 4) → Task 1 Step 5. ✓
- dpool independence / 30-day cache → Task 1 (cache-duration, state dir). ✓
- minoo build workflow → Global Constraints + per-task scp/build/finalize. ✓

**Placeholder scan:** No TBD/TODO; all shell and Nix code is concrete.

**Type/name consistency:** `notify <topic> "Title" [body]` used consistently in Tasks 2–3; template renamed `notify@` consistently; topics `system`/`claude` consistent with spec.

**Known ordering note:** Task 2's build references `notify` which the unison gate (Task 3) must be updated to use. The old `notify-email` command disappears in Task 2, so Task 3 Step 1 should be applied before the final minoo switch to avoid a runtime-missing-command in the unison gate. Tasks 2 and 3 are built together in practice (both scp'd before the switch in Task 3 Step 2).
