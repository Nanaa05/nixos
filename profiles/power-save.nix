{ config, lib, pkgs, ... }:
{
  
  environment.systemPackages = with pkgs; [
    powertop
    # ryzenadj # Added to allow manual TDP limiting if needed
  ];

  # Enable Powertop auto-tuning on boot
  powerManagement.powertop.enable = true;

  # systemd.services.ryzenadj-limit = {
  #   description = "Limit AMD CPU TDP to 2W";
  #   wantedBy = [ "multi-user.target" ];
  #   after = [ "multi-user.target" ];
  #   serviceConfig = {
  #     Type = "oneshot";
  #     ExecStart = "${pkgs.ryzenadj}/bin/ryzenadj --stapm-limit=2000 --fast-limit=2000 --slow-limit=2000";
  #     RemainAfterExit = true;
  #   };
  # };

  # # TLP for advanced power management
  # services.tlp = {
  #   enable = true;
  #   settings = {
  #     # Force battery optimization regardless of power state
  #     TLP_DEFAULT_MODE = "BAT";
  #     TLP_PERSISTENT_DEFAULT = 1;

  #     # Platform Profiles
  #     PLATFORM_PROFILE_ON_AC = "low-power";
  #     PLATFORM_PROFILE_ON_BAT = "low-power";

  #     # CPU Tweaks: Lock to powersave, disable turbo boost
  #     CPU_SCALING_GOVERNOR_ON_AC = "powersave";
  #     CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
  #     CPU_ENERGY_PERF_POLICY_ON_AC = "power";
  #     CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
      
  #     # EXTREME THROTTLE: Cap performance at 20%
  #     CPU_MAX_PERF_ON_AC = 20;
  #     CPU_MAX_PERF_ON_BAT = 20;
      
  #     CPU_BOOST_ON_AC = 0;
  #     CPU_BOOST_ON_BAT = 0;
  #     CPU_HWP_DYN_BOOST_ON_AC = 0;
  #     CPU_HWP_DYN_BOOST_ON_BAT = 0;

  #     # PCIe and Runtime Power Management
  #     RUNTIME_PM_ON_BAT = "auto";
  #     PCIE_ASPM_ON_BAT = "powersupersave";
      
  #     # Disable radios automatically on startup
  #     DEVICES_TO_DISABLE_ON_STARTUP = "bluetooth wifi wwan";
      
  #     # Aggressive audio power saving
  #     SOUND_POWER_SAVE_ON_AC = 1;
  #     SOUND_POWER_SAVE_ON_BAT = 1;
  #     SOUND_POWER_SAVE_CONTROLLER = "Y";
  #   };
  # };

  boot.blacklistedKernelModules = [
    # Webcam
    "uvcvideo"
    
    # MediaTek Wi-Fi & Bluetooth
    "mt7921e" "mt7921_common" "mt792x_lib" "mt76_connac_lib" "mt76"
    "btmtk" "btusb" "bluetooth" "btintel" "btrtl" "btbcm"

    # Other common Wi-Fi Drivers
    "iwlwifi" "iwlmvm" "ath9k" "ath10k" "ath11k" "rtw88" "rtw89" "wl" "mac80211" "cfg80211"
    
    # Audio / Earphone Jack / HDMI Audio
    "snd_hda_intel" "snd_soc_core" "snd_hda_codec_hdmi" 
    "snd_hda_codec_realtek" "soundcore" "snd" 
    "snd_pci_acp3x" "snd_rn_pci_acp3x" "snd_sof_amd_renoir"
    
    # Thunderbolt & Type-C Data (Charging will still work)
    "thunderbolt" "typec" "typec_ucsi" "ucsi_acpi" "roles"
    
    # USB Host Controllers (Kills all external USBs)
    "xhci_pci" "ehci_pci" "ohci_pci"
  ];
  
  # Explicitly disable networking services
  networking.wireless.enable = lib.mkForce false;
  networking.networkmanager.enable = lib.mkForce false;

  # # Aggressive kernel parameters
  # boot.kernelParams = [
  #   "nmi_watchdog=0"        # Disable NMI watchdog to save wakeups
  #   "pcie_aspm=force"       # Force PCIe Active State Power Management
    
  #   # CPU Core Limits
  #   "amd_pstate=active"     # Use active AMD power scaling
  #   "nosmt"                 # Disable Hyperthreading
  #   "maxcpus=2"             # Shut down all but 2 physical cores
  # ];
}
