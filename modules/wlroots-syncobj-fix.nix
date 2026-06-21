{ pkgs, lib, ... }:
# Workaround for an upstream wlroots 0.19 crash: the explicit-sync
# (linux-drm-syncobj-v1) buffer-release path aborts the whole compositor via
# assert(buffer->n_locks > 0) when a new client surface (reliably: a new Kitty
# window) is slow to ack its first configure and sway force-applies the
# transaction. See modules/patches/wlroots-syncobj-release-guard.patch.
#
# IMPORTANT: this patch SUPPRESSES A SYMPTOM. It masks an upstream invariant
# (wlroots deliberately asserts n_locks > 0 here) rather than fixing the root
# buffer-lifetime race. It is not a real fix. The patch logs a WLR_ERROR
# marker whenever the guard fires (see sway-syncobj-guard-watch below), and the
# version pin throws on any wlroots bump so we re-check whether upstream has
# landed a proper fix and this can be dropped.
let
  # Bump this only after confirming the patch still applies AND checking whether
  # wlroots has fixed the underlying race (then drop the patch entirely):
  #   https://gitlab.freedesktop.org/wlroots/wlroots  (types/wlr_linux_drm_syncobj_v1.c)
  pinnedWlrootsVersion = "0.19.2";

  # Desktop toast when the guard fires, so a masked crash never goes unnoticed.
  # Relies on sway being launched under systemd-cat (see modules/sway/default.nix)
  # so its wlr_log output actually reaches the journal.
  guardWatcher = pkgs.writeShellScriptBin "sway-syncobj-guard-watch" ''
    ${pkgs.systemd}/bin/journalctl -t sway -f -o cat -n0 \
      | ${pkgs.gnugrep}/bin/grep --line-buffered 'skipped buffer release with n_locks==0' \
      | while read -r _; do
          ${pkgs.libnotify}/bin/notify-send -u critical \
            "Sway syncobj guard fired" \
            "Averted a compositor crash (linux-drm-syncobj-v1, n_locks==0). The wlroots workaround patch is doing its job."
        done
  '';
in
{
  environment.systemPackages = [ guardWatcher ];

  nixpkgs.overlays = [
    (final: prev: {
      wlroots_0_19 =
        assert lib.assertMsg (prev.wlroots_0_19.version == pinnedWlrootsVersion) ''
          wlroots is now ${prev.wlroots_0_19.version}, but the local
          linux-drm-syncobj-v1 release-guard workaround is pinned to
          ${pinnedWlrootsVersion}. Re-check modules/wlroots-syncobj-fix.nix:
          does the patch still apply, and has upstream fixed the underlying
          buffer-lifetime race (in which case drop the patch)? Update
          pinnedWlrootsVersion once you've decided.'';
        prev.wlroots_0_19.overrideAttrs (old: {
          patches = (old.patches or [ ]) ++ [
            ./patches/wlroots-syncobj-release-guard.patch
          ];
        });
    })
  ];
}
