# Makes /home/lynaten private (0700, recursively, on every boot and rebuild).
# Toggle with the one line below. Turning it off stops enforcing; it does not loosen modes that were
# already tightened. The agent keeps its access to agent.projects either way (see agent.nix).
#
# If it doesn't work, run this and give the output to the agent:
#   journalctl -b -u agent-acl --no-pager; \
#   systemctl status agent-acl --no-pager; \
#   getfacl -p /home/lynaten /home/lynaten/nixos
# Quick fix if the agent lost access to the project: sudo systemctl restart agent-acl
# (write test: the agent was able to edit this file after the lockdown was applied)
{ config, lib, pkgs, ... }:
{
  options.privateHome.enable = lib.mkEnableOption "recursive 0700 on /home/lynaten";

  config = lib.mkMerge [
    {
      privateHome.enable = true; # <- toggle here
    }
    (lib.mkIf config.privateHome.enable {
      # go-rwx keeps the owner's bits, so git doesn't see mode changes (a literal 0700 made every file executable).
      # It runs inside agent-acl, first, because chmod resets ACL masks and the agent's ACLs are re-applied right after.
      systemd.services.agent-acl.script = lib.mkBefore ''
        ${pkgs.coreutils}/bin/chmod -R go-rwx /home/lynaten
      '';
      users.users.lynaten.homeMode = "0700";
      security.loginDefs.settings.UMASK = "077";
    })
  ];
}
# (agent comment test)
