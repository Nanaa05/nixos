{ inputs, lib, ... }:
let
  secretsFile = ../secrets/secrets.yaml;
in {
  imports = [ inputs.sops-nix.nixosModules.sops ];

  sops = {
    # personal key only (create it once, see README): used by you (sops finds it by itself) and by sops-nix at boot
    age.keyFile = "/home/lynaten/.config/sops/age/keys.txt";

    # don't load extra keys
    gnupg.sshKeyPaths = [ ];
    defaultSopsFile = secretsFile;

    # skipped until secrets/secrets.yaml exists so the build doesn't break
    secrets = lib.mkIf (builtins.pathExists secretsFile) {
      # opencode (user lynaten) reads these too
      openrouter-api-key = { owner = "lynaten"; mode = "0440"; };
      kilo-api-key = { owner = "lynaten"; mode = "0440"; };
    };
  };
}
