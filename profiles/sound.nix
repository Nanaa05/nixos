{ pkgs, ... }:
let
  volumeCommand = pkgs.writeShellScriptBin "volume" ''
    SINK="@DEFAULT_AUDIO_SINK@"

    if [ "$#" -eq 0 ]; then
      STATUS="$(${pkgs.wireplumber}/bin/wpctl get-volume "$SINK")"
      CURRENT="$(printf '%s\n' "$STATUS" | ${pkgs.gawk}/bin/awk '{ printf "%.0f", $2 * 100 }')"

      if [[ "$STATUS" == *"[MUTED]"* ]]; then
        echo "''${CURRENT}% (muted)"
      else
        echo "''${CURRENT}%"
      fi
      exit 0
    fi

    if [ "$#" -ne 1 ] || ! [[ "$1" =~ ^[0-9]+$ ]] || [ "$1" -gt 100 ]; then
      echo "Usage: volume <0-100>"
      exit 1
    fi

    ${pkgs.wireplumber}/bin/wpctl set-volume "$SINK" "$1%"
    echo "Volume adjusted to $1%"
  '';
  volumeControls = pkgs.symlinkJoin {
    name = "volume-controls";
    paths = [ volumeCommand ];
    postBuild = ''ln -s "$out/bin/volume" "$out/bin/vol"'';
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

  systemd.user.services.pipewire.partOf = [ "picom.service" ];
  systemd.user.services.pipewire-pulse.partOf = [ "picom.service" ];
  systemd.user.services.wireplumber.partOf = [ "picom.service" ];
  systemd.user.sockets.pipewire.partOf = [ "picom.service" ];
  systemd.user.sockets.pipewire-pulse.partOf = [ "picom.service" ];
}
  
