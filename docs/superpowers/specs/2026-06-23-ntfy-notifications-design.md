# Design: ntfy notifications (replacing email)

**Date:** 2026-06-23

## Goal

Self-host an [ntfy](https://ntfy.sh) push-notification server on minoo so that:

1. **Claude Code** (running on spruce/aramid) notifies Phil's phone when it finishes a
   task or needs input.
2. The existing **system alerts** (ZFS events, systemd unit failures, zpool health,
   unison failures) are migrated off email and onto ntfy.

Email notification (himalaya/SMTP) is removed entirely.

## Decisions

| Decision | Choice | Rationale |
| --- | --- | --- |
| Hosting | Self-host on minoo | Always-on file server; private, no third party. |
| Reachability | Home Wi-Fi only | Phone subscribes over LAN (`http://minoo:2586`). No public exposure. |
| Catch-up when away | 30-day server cache | Self-hosted ntfy app reconnects on return home and replays missed messages from cache. |
| Scope | Replace email entirely | All system alerts move to ntfy. Email code removed. |
| Topics | `system` + `claude` | Independent mute/prioritise on the phone. |
| Auth | None (LAN open) | LAN-only; can add a token later if ever exposed. |

### Reachability trade-off (accepted)

ntfy reaches the phone only on home Wi-Fi. Alerts raised while Phil is away replay from
the server cache when the phone reconnects to home Wi-Fi (within the 30-day window). Phil
accepted this in place of email's reach-anywhere delivery.

### dpool independence (preserved)

The email path was deliberately built so a "dpool suspended" alert still sends (credential
cached on the root pool). ntfy preserves this automatically: its cache DB lives under
`/var/lib/ntfy-sh` (root pool, via systemd `StateDirectory`), so a suspended dpool does not
break alerting.

## Components

### 1. ntfy server — `modules/ntfy.nix` (new, imported by minoo only)

```nix
{ ... }: {
  services.ntfy-sh = {
    enable = true;
    settings = {
      base-url = "http://minoo:2586";  # include port so generated links resolve
      listen-http = ":2586";           # module default is 127.0.0.1:2586; bind all for LAN
      cache-duration = "720h";   # ~30 days catch-up
      behind-proxy = false;
    };
  };
  networking.firewall.allowedTCPPorts = [ 2586 ];
}
```

- Runs as DynamicUser `ntfy-sh`; cache at `/var/lib/ntfy-sh/cache-file.db`.
- Config rendered to `/etc/ntfy/server.yml` by the module.

### 2. Sender helper + rewiring — `modules/notify.nix` (rewritten)

A small `notify` shell application replaces `notify-email`:

```
notify <topic> "Title" [body|stdin]
```

It POSTs via `curl` to `http://localhost:2586/<topic>` with a `Title` header (prefixed with
hostname, matching the old `[host] subject` style), an appropriate `Priority`, and `Tags`.
Failure-type alerts use high priority + a warning tag.

Rewired triggers (all → topic `system`):

| Trigger | Was | Now |
| --- | --- | --- |
| ZFS events (zed) | `notify-email-zed` | `notify system ...` wrapper |
| systemd `OnFailure` template (`notify-email@`) | `notify-email-unit` | `notify system ...` wrapper |
| `zpool-health-check` timer | `notify-email` | `notify system ...` |
| `unison-failure-gate` (in `hosts/minoo/default.nix`) | `notify-email` | `notify system ...` |

The `zpool-health-check` transition-flag logic is kept (prevents spam; the single
transition alert replays from cache on return home).

**Removed:** himalaya config (`himalayaConfig`), SMTP password caching
(`cacheCredentials` + `notify-credentials` service), maildir tmpfiles, the `recipient`
constant and all SMTP plumbing.

### 3. Claude Code hooks — `~/.claude/settings.json` (outside the repo)

Add hooks that `curl` minoo's ntfy on topic `claude`:

- **`Notification`** — Claude needs input/permission → "needs your input".
- **`Stop`** — Claude finished a turn → "task done".

Runs on spruce/aramid (home LAN → reaches minoo). Independent of the existing
`agentPushNotifEnabled` / Remote Control PushNotification path, which is left untouched.

### 4. Phone (manual, one-time)

Install the ntfy Android app → subscribe to `http://minoo:2586`, topics `system` and `claude`.

## Build / test workflow (minoo)

Per repo convention, minoo changes are built and tested **on minoo**:

1. Edit on spruce.
2. `scp modules/ntfy.nix modules/notify.nix hosts/minoo/default.nix minoo:/data/code/nixfiles/...`
3. `ssh minoo 'nixx build -s -m minoo'` — must build cleanly.
4. Verify: `curl -d "hi" http://minoo:2586/system`, confirm phone receives it; trigger a
   test systemd failure to confirm the `system` topic path.
5. Commit + push from spruce; finalize minoo with checkout + pull.

Claude Code hook changes (settings.json) are independent of the Nix build and tested by
triggering a real notification/stop.

## Out of scope

- Public/remote exposure (Tailscale, reverse proxy, TLS, auth) — revisit only if
  away-from-home delivery becomes a requirement.
- Removing the existing Remote Control push path.
