{ config, pkgs, ... }: {
  security = {
    rtkit.enable = true; # Realtime priority for PulseAudio

    pam.loginLimits = [
      {
        domain = "@audio";
        type = "-";
        item = "rtprio";
        value = "95";
      }
    ];
  };

  services = {
    pulseaudio.enable = false;
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
      wireplumber.enable = true;
    };
  };

  environment.systemPackages = with pkgs; [
    pavucontrol           # Audio control panel
  ];

  # This forces Pipewire to use the USB DAC as the default output device.
  # This fixes an issue where it would keep switching profiles causing
  # audio stutter.
  environment.etc = {
    "wireplumber/scripts/lock-usb-dac-profile.lua".text = ''
      local function handle_object(obj)
        if obj.props["api.alsa.card.name"] == "usb-CA_CA_DacMagic_200M_2.0-00" then
          obj:set_prop("api.alsa.card.profile", "pro-output-0")
        end
      end

      wp.register_filter("module-alsa-card", handle_object)
    '';

    "wireplumber/wireplumber.conf.d/lock-usb-dac-profile.conf".text = ''
      context.modules = {
        ["module-alsa-card"] = {
          filters = {
            {
              name = "lock-usb-dac-profile",
              script = "lock-usb-dac-profile.lua",
              priority = 1000,
            }
          }
        }
      }
    '';
  };
}