{ config, pkgs, ... }: {
  services.dunst = {
    enable = true;
    settings = {
      global = {
        width = 300;
        height = 150;
        offset = "10x50";
        origin = "top-right";
        font = "JetBrains Mono 10";
        background = "#282c34";
        foreground = "#abb2bf";
        frame_color = "#61afef";
      };
    };
  };
}
