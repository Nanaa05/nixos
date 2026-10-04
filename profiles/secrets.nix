{ inputs, lib, ... }:
let
  secretsFile = ../secrets/secrets.yaml;
in {
  imports = [ inputs.sops-nix.nixosModules.sops ];

  sops = {
    age.keyFile = "/var/lib/sops-nix/key.txt";
    gnupg.sshKeyPaths = [ ];
    defaultSopsFile = secretsFile;

    # skipped until secrets/secrets.yaml exists so the build doesn't break
    secrets = lib.mkIf (builtins.pathExists secretsFile) {
      openrouter-api-key.owner = "lynaten";
      kilo-api-key.owner = "lynaten";
    };
  };
}
