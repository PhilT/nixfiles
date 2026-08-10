---
description: Update the claude-code pin in modules/development.nix to the latest release
allowed-tools: Bash(nixx:*)
---

Run `nixx update-claude`. It reads the current `version` from `modules/development.nix`, fetches the latest from npm (`@anthropic-ai/claude-code-linux-x64`), and if it differs: prefetches the GCS binary for the SRI hash, rewrites the `version` and `hash` lines, prints the version bump and the changelog entries for every release in the jump, then builds and switches. If already current it reports so and makes no changes.

Report what it printed (the bump and changelog, or "already up to date"). Do not commit — leave that for Phil.

The command lives in `src/claude_code.rs` if the logic needs changing.
