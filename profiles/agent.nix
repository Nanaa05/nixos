# Unprivileged user for running AI agents/harnesses, isolated from lynaten's secrets and home.
# Not in wheel, not in "users", so it cannot read /run/secrets/*, the sops key, or ~lynaten (mode 0700).
# Use: sudo -u agent -i
{ ... }:
{
  users.groups.agent = { };
  users.users.agent = {
    isNormalUser = true;
    group = "agent";
    home = "/home/agent";
    homeMode = "0700";
  };
}
