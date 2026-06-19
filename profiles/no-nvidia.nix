{ lib, ... }:
let
  env = import ../env.nix;
in
{
  boot.blacklistedKernelModules = [ "nouveau" "nvidia" "nvidia_drm" "nvidia_modeset" ];
  
  services.udev.extraRules = ''
    # Sever NVIDIA VGA from PCI bus
    ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x03[0-9]*", ATTR{power/control}="auto", ATTR{remove}="1"
    # Sever NVIDIA Audio from PCI bus
    ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x040300", ATTR{power/control}="auto", ATTR{remove}="1"
  '';
  
  services.xserver.videoDrivers = lib.mkForce [ env.gpuDriver ];
}
