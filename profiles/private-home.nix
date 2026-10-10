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

  # Paths the lockdown chmod skips entirely: their modes are left exactly as they are, nothing is
  # added or removed. For files a container bind-mounts and reads as another uid (e.g. rabbitmq uid 100
  # reading its config). Set their modes once by hand; this only stops them being reset.
  options.privateHome.keepAsIs = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [ ];
    description = "Absolute paths (and everything under them) the recursive go-rwx chmod does not touch.";
  };

  config = lib.mkMerge [
    {
      privateHome.enable = true; # <- toggle here
      privateHome.keepAsIs = [
        "/home/lynaten/Projects/distributed-hazard-coordination/infra/rabbitmq"
        "/home/lynaten/Projects/distributed-hazard-coordination/services/aggregator/migrations"
        "/home/lynaten/Projects/distributed-hazard-coordination/services/auth-service/migrations"
      ];
    }
    (lib.mkIf config.privateHome.enable {
      # find prunes keepAsIs so chmod never sees those paths; -not -type l mirrors chmod -R, which skips symlinks.
      systemd.services.agent-acl.script = lib.mkBefore ''
        ${pkgs.findutils}/bin/find /home/lynaten ${lib.optionalString (config.privateHome.keepAsIs != [ ])
          "\\( ${lib.concatMapStringsSep " -o " (p: "-path ${lib.escapeShellArg p}") config.privateHome.keepAsIs} \\) -prune -o"} \
          -not -type l -exec ${pkgs.coreutils}/bin/chmod go-rwx {} +
      '';
      users.users.lynaten.homeMode = "0700";
      security.loginDefs.settings.UMASK = "077";
    })
  ];
}
# (agent comment test)
