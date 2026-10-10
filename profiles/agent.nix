# Unprivileged user for running AI agents/harnesses, isolated from lynaten's secrets and home.
# Not in wheel, not in "users", so it cannot read /run/secrets/*, the sops key, or ~lynaten (mode 0700).
# `claude`, `opencode` and `codex` run as this user automatically. Where it may read/write is declared
# here only (agent.projects) and re-applied on every rebuild; anything not listed is revoked.
{ config, lib, pkgs, ... }:
let
  cfg = config.agent;

  asAgent = name: bin: env: pkgs.writeShellScriptBin name ''
    exec /run/wrappers/bin/sudo -u agent -H --preserve-env=TERM,COLORTERM \
      ${pkgs.coreutils}/bin/env ${lib.concatStringsSep " " env} ${bin} "$@"
  '';

  opencodeConfig = builtins.toJSON {
    "$schema" = "https://opencode.ai/config.json";

    provider = {
      openrouter.options.apiKey = "{env:OPENROUTER_API_KEY}";

      kilo = {
        npm = "@ai-sdk/openai-compatible";
        name = "Kilo Gateway";

        options = {
          baseURL = "https://api.kilo.ai/api/gateway";
          apiKey = "{env:KILO_API_KEY}";
        };

        models."kilo-auto/free".name = "Kilo Auto Free";
      };
    };

    model = "openrouter/openrouter/free";
  };

  opencodeWrapper = pkgs.writeShellScriptBin "opencode-agent" ''
    set -euo pipefail

    export OPENROUTER_API_KEY="$(
      ${pkgs.coreutils}/bin/cat /run/secrets/openrouter-api-key
    )"

    export KILO_API_KEY="$(
      ${pkgs.coreutils}/bin/cat /run/secrets/kilo-api-key
    )"

    export OPENCODE_CONFIG_CONTENT=${lib.escapeShellArg opencodeConfig}

    exec ${pkgs.opencode}/bin/opencode "$@"
  '';

  setfacl = "${pkgs.acl}/bin/setfacl";

  revoke = "${setfacl} -R -x u:agent,d:u:agent";

  grant =
    "${setfacl} -R -m u:agent:rwX,d:u:agent:rwX,u:${cfg.owner}:rwX,d:u:${cfg.owner}:rwX";

  absolute = base: p:
    if lib.hasPrefix "/" p then p else "${base}/${p}";

  projects =
    lib.listToAttrs (
      map
        (p:
          lib.nameValuePair
            (absolute cfg.root p.path)
            { inherit (p) exclude; })
        cfg.projects
    );

  ancestors = path:
    let
      parts = lib.splitString "/" (lib.removePrefix "/" path);

      prefixes =
        lib.genList
          (n:
            "/" + lib.concatStringsSep "/" (lib.take (n + 1) parts))
          (lib.length parts - 1);
    in
      lib.drop 1 prefixes; # leave /home itself alone

  applyProject = path: p: ''
    if [ -e ${lib.escapeShellArg path} ]; then
      ${revoke} ${lib.escapeShellArg path}
      ${grant} ${lib.escapeShellArg path}

      ${lib.concatMapStringsSep "\n      "
        (x:
          "${revoke} ${lib.escapeShellArg (absolute path x)} || true")
        p.exclude}
    else
      echo "agent.projects: ${path} does not exist, skipping" >&2
    fi
  '';

in
{
  options.agent.owner = lib.mkOption {
    type = lib.types.str;
    default = "lynaten";
    description =
      "User who always keeps read/write access to everything in agent.projects.";
  };

  options.agent.root = lib.mkOption {
    type = lib.types.str;
    default = "/home/lynaten/Projects";
    description =
      "Base directory for the relative project names in agent.projects.";
  };

  options.agent.projects = lib.mkOption {
    default = [ ];

    description =
      "Directories the agent user may read/write (recursively). A plain string is a project with nothing withheld.";

    example = lib.literalExpression ''
      [
        "my-project"
        {
          path = "/home/lynaten/nixos";
          exclude = [ "secrets" ".env" ];
        }
      ]
    '';

    type =
      lib.types.listOf
        (
          lib.types.coercedTo
            lib.types.str
            (path: { inherit path; })
            (
              lib.types.submodule {
                options.path = lib.mkOption {
                  type = lib.types.str;
                  description =
                    "Absolute path, or a name relative to agent.root.";
                };

                options.exclude = lib.mkOption {
                  type = lib.types.listOf lib.types.str;
                  default = [ ];
                  description =
                    "Paths (relative to the project, or absolute) the agent must not access.";
                };
              }
            )
        );
  };

  config = {
    users.groups.agent = { };

    users.users.agent = {
      isNormalUser = true;
      group = "agent";
      home = "/home/agent";
      homeMode = "0700";
    };

    # Runs after systemd-tmpfiles
    # (e.g. the recursive chmod in private-home.nix, which resets ACL masks)
    # at boot and on every nixos-rebuild switch, so the ACLs are always applied last.
    systemd.services.agent-acl = {
      description = "ACLs for the agent user (agent.projects)";

      wantedBy = [ "multi-user.target" ];

      after = [
        "systemd-tmpfiles-setup.service"
        "systemd-tmpfiles-resetup.service"
      ];

      restartTriggers = [
        (builtins.toJSON config.systemd.tmpfiles.rules)
      ];

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };

      script = ''
        # Traverse-only (--x) on the parents of each project:
        # it can reach the project but not list or read anything else.
        ${lib.concatMapStringsSep "\n"
          (a:
            "${setfacl} -m u:agent:--x ${lib.escapeShellArg a} || true")
          (
            lib.unique (
              lib.concatMap ancestors (lib.attrNames projects)
            )
          )}

        ${lib.concatStringsSep "\n"
          (lib.mapAttrsToList applyProject projects)}
      '';
    };

    # lynaten may become agent, and only agent, without a password.
    security.sudo.extraRules = [
      {
        users = [ "lynaten" ];
        runAs = "agent";

        commands = [
          {
            command = "ALL";
            options = [
              "NOPASSWD"
              "SETENV"
            ];
          }
        ];
      }
    ];

    environment.systemPackages = [
      # OpenCode runs through the runtime wrapper.
      #
      # The wrapper:
      #   1. runs as agent through asAgent
      #   2. reads the API keys from /run/secrets
      #   3. injects OPENCODE_CONFIG_CONTENT
      #   4. execs the real OpenCode binary
      (asAgent
        "opencode"
        "${opencodeWrapper}/bin/opencode-agent"
        [ ])

      (asAgent
        "codex"
        "${pkgs.codex}/bin/codex"
        [ ])
      # (asAgent
      #   "claude"
      #   "${pkgs.claude-code}/bin/claude"
      #   [ ])
    ];

    agent.projects = [
      {
        path = "/home/lynaten/nixos";
        exclude = [ "secrets" ".git" ".sops.yaml" "profiles/secrets.nix"];
      }

      # agent's own home: lynaten gets rwX on it (and on whatever the agent creates later)
      {
        path = "/home/agent";
      }

      {
        path = "distributed-hazard-coordination";
      }

      {
        path = "nana";
      }
    ];
  };
}
