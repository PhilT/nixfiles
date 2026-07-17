# Needed for some ZSA tools to work
# https://github.com/ungoogled-software/ungoogled-chromium/blob/master/docs/flags.md
{ config, pkgs, lib, ... }:
let
  # ungoogled-chromium has no Web Store, so each extension is fetched
  # as a CRX, unpacked into the nix store, and symlinked to a stable
  # path under the home dir. Install once via:
  #   chrome://extensions → Developer mode → Load unpacked → <path>
  #
  # When upstream updates, the build will fail with a hash mismatch;
  # replace the sha256 with the value nix reports.
  unpackExtension = { name, id, sha256 }: pkgs.stdenvNoCC.mkDerivation {
    pname = "chromium-ext-${name}";
    version = id;
    src = pkgs.fetchurl {
      url = "https://clients2.google.com/service/update2/crx"
        + "?response=redirect&acceptformat=crx2,crx3&prodversion=120.0.0.0"
        + "&x=id%3D${id}%26uc";
      inherit sha256;
    };
    nativeBuildInputs = [ pkgs.unzip pkgs.jq ];
    unpackPhase = "unzip -o $src -d ext || true"; # CRX header trips unzip; payload extracts fine
    installPhase = ''
      mkdir -p $out
      cp -r ext/* $out/
      # _metadata/ holds CRX-signing verification data Chromium can't
      # validate for an unpacked load. Keep "key" though: it's what makes
      # Chromium assign the same extension ID as the Web Store listing,
      # which extensions doing origin-checked auth (e.g. Claude) require.
      rm -rf $out/_metadata
      if [ -f $out/manifest.json ]; then
        chmod +w $out/manifest.json
        jq 'del(.update_url)' $out/manifest.json > $out/manifest.json.tmp
        mv $out/manifest.json.tmp $out/manifest.json
      fi
    '';
  };

  extensions = [
    {
      name = "ublock-origin";
      id = "cgbcahbpdhpcegmbfconppldiemgcoii";
      sha256 = "sha256-bBZwpd2WjDqve9mTXo1iwAF32DSaBOiQTk/Xs95WqKc=";
    }
    {
      name = "garmin-workouts";
      id = "odgdfpclpfmmemajpmgfipfdfmjgihac";
      sha256 = "0sc51myq7a3dl38l9bsqk3my94zg0rnssmxpj50iqfkj96177npk";
    }
    {
      name = "claude";
      id = "fcoeoabgfenejglbffodgkkbkcdhcgfn";
      sha256 = "sha256-qE1R4SousMAjFeblDNqGX12SxA9ywV6vMLXeBn/1We0=";
    }
  ];

  extensionsDir = "${config.persistedHomeDir}/chromium-extensions";
in {
  programs = {
    chromium = {
      enable = true; # This just enables the policies. Package is added below.
      defaultSearchProviderEnabled = true;
      defaultSearchProviderSearchURL = "https://duckduckgo.com/?q={searchTerms}";
      homepageLocation = "https://claude.ai";
      extraOpts = {
        BrowserSignin = 0;
        SyncDisabled = true;
        PasswordManagerEnabled = false;
        SpellcheckEnabled = true;
        SpellcheckLanguage = [ "en-GB" ];
        BookmarkBarEnabled = true;
        RestoreOnStartup = 1; # 1 means restore the last session
        MetricsReportingEnabled = false;
        DownloadDirectory = "${config.dataDir}/downloads";
        DefaultGeolocationSetting = 2;
        DefaultNotificationsSetting = 2;
        VideoCaptureAllowedUrls = [ "https://*.google.com" "https://*.microsoft.com" ];
        AudioCaptureAllowedUrls = [ "https://*.google.com" ];
      };
      initialPrefs = {
        "browser" = {
          "custom_chrome_frame" = false; # Ensure borders and gaps are removed
        };
      };
    };
  };

  systemd.tmpfiles.rules = [
    "d ${config.persistedHomeDir}/chromium - ${config.username} users -"
    "d ${extensionsDir} - ${config.username} users -"
  ] ++ map (e:
    "L+ ${extensionsDir}/${e.name} - - - - ${unpackExtension e}"
  ) extensions;

  environment = {
    systemPackages = with pkgs; [
      (writeShellScriptBin "s" ''chromium --force-dark-mode "https://duckduckgo.com/?q=$@" &'')

      (writeShellScriptBin "ch" ''
        app-sync chromium chromium 8 $@
      '')

      (ungoogled-chromium.override {
        enableWideVine = true;
        commandLineArgs = [
          "--password-store=basic"
          "--no-first-run"
          "--no-default-browser-check"
          "--ozone-platform-hint=auto"
          "--user-data-dir=/data/home/chromium"
          # NVIDIA's VAAPI WebRTC decode path produces corrupted ("noise")
          # video tiles in Google Meet. Force software video decode.
          "--disable-accelerated-video-decode"
        ];
      })

      (writeShellScriptBin "quit-chromium" ''
        focused=$(swaymsg -t get_tree | jq -r 'recurse(.nodes[]?, .floating_nodes[]?) | select(.focused) | .app_id')
        if echo "$focused" | grep -q chromium; then
          pkill chromium
        else
          swaymsg kill
        fi
      '')
    ];
  };
}
