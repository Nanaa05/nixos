# nixos

Lynaten's multi-profile NixOS flake.

## Local-only files

`env.nix`, `gpu.nix` and `hardware-configuration.nix` are git-ignored and machine specific. Copy the `*.example` files and edit them. They are `git add -N`'d locally only because flakes need files to be indexed.

## Secrets (sops-nix)

API keys (OpenRouter, Kilo) live encrypted in `secrets/secrets.yaml` and are decrypted at boot to `/run/secrets/<name>`. OpenCode reads them via `{file:/run/secrets/...}` in `dotfiles.nix`, so nothing secret enters the nix store. Declared in `profiles/secrets.nix`; recipients in `.sops.yaml`.

### 1. Create this device's age key
```sh
sudo mkdir -p /var/lib/sops-nix
nix shell nixpkgs#age -c sudo age-keygen -o /var/lib/sops-nix/key.txt
sudo chmod 600 /var/lib/sops-nix/key.txt
sudo grep 'public key' /var/lib/sops-nix/key.txt   # prints age1...
```
Put the `age1...` public key in `.sops.yaml` in place of `REPLACE_WITH_AGE_PUBLIC_KEY`.

To edit secrets as your normal user, copy the key to `~/.config/sops/age/keys.txt`, or set `SOPS_AGE_KEY_FILE=/var/lib/sops-nix/key.txt` and use `sudo`.

### 2. Add or edit secrets
```sh
nix shell nixpkgs#sops -c sops secrets/secrets.yaml
```
This opens `$EDITOR` on plain YAML (the first run creates the file):
```yaml
openrouter-api-key: sk-or-...
kilo-api-key: eyJ...
```
Saving encrypts the values. Commit the file (it is encrypted) and `git add` it before building, since flakes only see tracked files.

### 3. Add a new secret later
Run the same `sops` command and add a line, then declare it in `profiles/secrets.nix`, e.g. `my-token.owner = "lynaten";`. It appears at `/run/secrets/my-token`.

### 4. Add another device
1. On the new machine, repeat step 1 and note its public key.
2. On a machine that can already decrypt: in `.sops.yaml` add `- &laptop2 age1...` under `keys:` and `- *laptop2` under the rule's `age:` list.
3. Re-encrypt: `sops updatekeys secrets/secrets.yaml`.
4. Commit, pull on the new machine, rebuild.

### 5. Apply
```sh
sudo nixos-rebuild switch --flake .#<config>
ls -l /run/secrets/
```

Back up `/var/lib/sops-nix/key.txt` (e.g. in a password manager). If it is your only key and you lose it, the secrets are unrecoverable.
