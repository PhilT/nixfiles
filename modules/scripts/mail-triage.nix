{ pkgs, ... }: {
  # Thin wrappers: the actual binaries live in /data/code/mail and are
  # rebuilt locally with cargo. This module just puts stable command names
  # on $PATH so mail-sync timers and other consumers don't have to know
  # the source path.
  environment.systemPackages = with pkgs; [
    (writeShellScriptBin "mail-triage" ''
      exec /data/code/mail/target/release/mail-triage "$@"
    '')
    (writeShellScriptBin "mail-dump" ''
      exec /data/code/mail/target/release/mail-dump "$@"
    '')
    (writeShellScriptBin "mail-find" ''
      exec /data/code/mail/target/release/mail-find "$@"
    '')
    (writeShellScriptBin "mail-thread-analyse" ''
      exec /data/code/mail/target/release/mail-thread-analyse "$@"
    '')
  ];
}
