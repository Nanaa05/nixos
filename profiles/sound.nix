{ pkgs, ... }:
let

  mk = import ../lib/controls.nix pkgs;
  
  volumeControls = mk {
    name = "volume";
    alias = "vol";
    label = "Volume";
    get = ''
    STATUS="$(${pkgs.wireplumber}/bin/wpctl get-volume @DEFAULT_AUDIO_SINK@)"
    CURRENT="$(printf '%s\n' "$STATUS" | ${pkgs.gawk}/bin/awk '{ printf "%.0f", $2 * 100 }')"
    if [[ "$STATUS" == *"[MUTED]"* ]]; then
      echo "''${CURRENT}% (muted)"
    else
      echo "''${CURRENT}%"
    fi
  '';
    set = ''${pkgs.wireplumber}/bin/wpctl set-volume @DEFAULT_AUDIO_SINK@ "$VALUE%"'';
  };
in
{
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.enable = true;
  };

  environment.systemPackages = [ volumeControls ];

}
