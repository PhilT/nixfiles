---
description: Update the claude-code pin in modules/development.nix to the latest release
allowed-tools: Bash(curl:*), Bash(nix:*), Bash(jq:*), Bash(awk:*), Read, Edit
---

Update the `claude-code` overlay derivation in `modules/development.nix` to the latest published release.

The pin lives in the `nixpkgs.overlays` block of `modules/development.nix`:
- `version = "X.Y.Z";`
- `hash = "sha256-...=";` (SRI hash of the linux-x64 binary fetched from the GCS bucket)

Steps:

1. Read the current `version` from `modules/development.nix`.

2. Fetch the latest version. The npm `linux-x64` package is authoritative and matches the GCS bucket:
   ```
   curl -fsSL https://registry.npmjs.org/@anthropic-ai/claude-code-linux-x64/latest | jq -r .version
   ```
   (GitHub releases / the GCS `claude-code-releases/stable` pointer can lag — prefer npm.)

3. If the latest version equals the current version, report "already up to date" and stop — make no edits.

4. Compute the SRI hash of the new binary. Use the same GCS URL template that is in the file, substituting the new version:
   ```
   nix --extra-experimental-features nix-command store prefetch-file --json --name claude \
     "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases/<VERSION>/linux-x64/claude" \
     | jq -r .hash
   ```
   This downloads the binary and prints `sha256-...=`. If it errors, the version may not be in the GCS bucket yet — report and stop.

5. Edit `modules/development.nix`: update the `version` line and the `hash` line with the new values.

6. Fetch the changelog entries for every release in the jump. The upstream `CHANGELOG.md` has one `## X.Y.Z` heading per release, newest first, so an `awk` range from the new heading down to (but excluding) the old heading yields exactly the releases between them:
   ```
   curl -fsSL https://raw.githubusercontent.com/anthropics/claude-code/main/CHANGELOG.md \
     | awk -v old="<OLD_VERSION>" -v new="<NEW_VERSION>" '$0=="## "new{p=1} $0=="## "old{p=0} p'
   ```
   If it returns nothing (e.g. the changelog hasn't published the new version yet), note that and carry on.

7. Report the version bump (old → new), followed by the changelog entries from step 6 grouped by version.

8. Build and switch to the new configuration:
   ```
   nixx build -s
   ```
   Report the result. Do not commit — leave that for Phil.
