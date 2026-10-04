# nixos

Lynaten's multi-profile NixOS flake.

## Local-only files

`env.nix`, `gpu.nix` and `hardware-configuration.nix` are git-ignored and machine specific. Copy the `*.example` files and edit them. They are `git add -N`'d locally only because flakes need files to be indexed.

## Secrets (sops-nix)

API keys (OpenRouter, Kilo) live encrypted in `secrets/secrets.yaml` and are decrypted at boot to `/run/secrets/<name>`. OpenCode reads them via `{file:/run/secrets/...}` in `dotfiles.nix`, so nothing secret enters the nix store. Declared in `profiles/secrets.nix`; recipients in `.sops.yaml`.

### 1. One personal key (not system-wide)
Your key is `~/.config/sops/age/keys.txt` (`&lynaten` in `.sops.yaml`). There is no system key and no system-wide `SOPS_AGE_KEY_FILE`. Nix does not create it, you do it once:
```sh
mkdir -p ~/.config/sops/age
age-keygen -o ~/.config/sops/age/keys.txt   # prints the public key (age1...)
chmod 600 ~/.config/sops/age/keys.txt
grep 'public key' ~/.config/sops/age/keys.txt   # print it again later
```
Put the `age1...` public key in `.sops.yaml` as the only recipient (`&lynaten`).
- **You** edit secrets with it: `sops` finds that path by itself, no sudo and no env var.
- **sops-nix** reads the same file at boot (`sops.age.keyFile` in `profiles/secrets.nix`) to create `/run/secrets/*`.

Back up the private key; if you lose it the secrets are unrecoverable.

On a **fresh machine**: run the commands above, put the new public key in `.sops.yaml`, recreate `secrets/secrets.yaml` with `sops` (or run `sops updatekeys` from a machine that can already decrypt), `git add` it, then rebuild.

### 2. Add or edit secrets
```sh
sops secrets/secrets.yaml
```
This opens `$EDITOR` on plain YAML (the first run creates the file):
```yaml
openrouter-api-key: sk-or-...
kilo-api-key: eyJ...
```
Saving encrypts the values. Commit the file (it is encrypted) and `git add` it before building, since flakes only see tracked files.

### 3. Add a new secret later
Run the same `sops` command and add a line, then declare it in `profiles/secrets.nix`, e.g. `my-token.owner = "lynaten";`. It appears at `/run/secrets/my-token`.

### 4. Add another device or key
1. Get its public key (`ssh-ed25519 ...` or `age1...`).
2. In `.sops.yaml` add `- &name <pubkey>` under `keys:` and `- *name` under the rule's `age:` list.
3. Re-encrypt: `sops updatekeys secrets/secrets.yaml`.
4. Commit, pull on the other machine, rebuild.

### 5. Apply
```sh
sudo nixos-rebuild switch --flake .#<config>
ls -l /run/secrets/
```

## Running AI agents safely

`profiles/agent.nix` defines an unprivileged `agent` user (no sudo, not in `users`). It cannot read `/run/secrets/*`, the sops key, or `~lynaten`. Run harnesses as that user:
```sh
sudo -u agent -i
```
Give it its own checkout (e.g. `/home/agent/nixos`) and its own limited API keys. Don't let it connect to your X display.
