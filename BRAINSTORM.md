# Configuration Brainstorm

These are design notes, not committed implementation decisions.

## Wallpaper-derived themes

- Use a maintained wallpaper palette generator, probably Wallust for its
  ANSI/pywal-style 16-color output and template support.
- Keep the generator, templates, and theme command declarative in Nix.
- Keep the selected wallpaper and generated palette as mutable runtime state.
- Reapply the saved wallpaper and palette at the beginning of every X session.
- Potential consumers: TTY, `st`, SXWM borders, dmenu, FZF, Vis, Dunst,
  Picom, tuigreet, and GRUB.
- Existing terminals should receive updated ANSI escape sequences where
  possible. Services such as Dunst and Picom should reload or restart.
- Tuigreet and GRUB need special handling because they run outside the user
  session; updating them may require a privileged helper or a rebuild.

## Dynamic transparency and blur

- Treat opacity and blur as independent theme dimensions rather than deriving
  them blindly from wallpaper colors.
- `st` is currently the main transparency/blur consumer, but more applications
  may use these effects later.
- A theme should be able to specify values such as:
  - terminal opacity;
  - focused and unfocused window opacity;
  - blur enabled/disabled;
  - blur strength, kernel, and exclusions;
  - shadows, corner radius, and animation policy.
- Provide performance presets independently of color themes, for example:
  `effects off`, `effects light`, and `effects full`.
- Allow combinations such as a wallpaper-derived palette with blur disabled
  for battery saving, or the same palette with full effects in `max` mode.
- Picom should remain the central X11 effects implementation, with explicit
  exclusions for menus, tooltips, screen sharing, Zoom, and other unsuitable
  windows.
- Changes should be live-reloadable when practical and restored on login.

## Related ideas

- Enable and wallpaper-theme Dunst notifications in `min` and `max` while
  keeping them out of `save` if desired.
- Eventually centralize hard-coded colors instead of maintaining duplicate
  palettes in the TTY, shell, `st`, SXWM, dmenu, FZF, and GRUB.
- Keep authentication and locking security in established tools; custom work
  should focus on visual frontends and themes.

## Background media manager

- Manage static wallpapers and video backgrounds through one library and GUI.
- The GUI should support:
  - browsing, importing, tagging, favoriting, and deleting media;
  - previewing wallpapers and videos before applying them;
  - selecting the current background per monitor;
  - playlists, ordering, shuffle, history, and repeat modes;
  - time-based rotation and optional per-workspace backgrounds;
  - video looping and random video playback;
  - explicit audio modes: muted video, video audio, or a separate audio source;
  - playback controls and volume when background audio is enabled.
- Keep the media library outside the Nix store. Nix should install and configure
  the manager, while user media, playlists, tags, and playback state remain
  mutable runtime data.
- On X11/SXWM, investigate an established `mpv`-based root-window approach
  rather than embedding a new media player. Keep the backend replaceable for a
  possible future Wayland session.
- Integrate background playback with system profiles and effects:
  - `save`: static wallpaper only;
  - `min`: static wallpaper by default, optional low-cost video;
  - `max`: video, audio, transitions, blur, and full effects.
- Pause or stop video when the session is locked, the display powers off, the
  system is on battery, a fullscreen application is active, or screen sharing
  begins.
- Define resource limits for resolution, frame rate, decoding, caching, and
  hardware acceleration.
- Use wallpaper/video selection as the input for dynamic color generation.
  Video palettes could come from a representative frame, thumbnail, or a
  slowly updated palette rather than recalculating every frame.

### Media acquisition

- Allow imports from local files and optional download integrations such as
  `yt-dlp` and a torrent client.
- Keep downloading separate from playback and library management, with a clear
  review/import step before new media becomes part of a playlist.
- Record source URL, title, author, license, download date, and local checksum
  when available.
- Never execute downloaded files, and validate media types before importing.
- Avoid embedding credentials in Nix or command history; authenticated sources
  should use an external credential store.
- Respect copyright, licenses, service terms, and local laws when acquiring
  media.

## Ideas borrowed from nixos-isabel

- Adapt its wallpaper picker into the planned wallpaper manager. Replace its
  Quickshell-specific IPC with an SXWM/X11 backend while retaining directory
  scanning, interactive selection, notifications, and a desktop entry.
- Reuse selected parts of its MPV setup as the media-manager foundation:
  hardware decoding, MPRIS integration, `yt-dlp`, playback history,
  thumbnails, and playback profiles. Do not copy personal cookie paths or
  Wayland-specific commands.
- Add a declarative PipeWire RNNoise microphone source for Discord, Zoom, and
  other calls.
- Improve low-memory behavior with either systemd-oomd or earlyoom after
  testing suitable thresholds. Avoid running both without a deliberate design.
- Bound persistent and runtime journald storage to prevent logs from growing
  indefinitely.
- Consider zswap when swap is configured, particularly for laptop profiles.
- Consider greetd polish such as automatic restart, `useTextGreeter`, and
  visible password asterisks. Remembered session selection can wait until
  multiple sessions are installed.
- Consider shell quality-of-life modules: `nix-your-shell`, `nix-direnv`,
  Atuin, `fzf` with `fd`, `eza`, `bat`, and `zoxide`. Any history syncing must
  use this configuration's own endpoint or remain local.
- Add Avahi and appropriate printer drivers if network-printer discovery is
  needed.
- Consider `fwupd` for firmware updates on hardware supported by LVFS.

### Do not copy wholesale

- Experimental read-only `/etc`, userborn, or nixos-init settings.
- Aggressive networking sysctl collections without validating each setting.
- AppArmor policies that kill unconfined applications by default.
- Hyprland/Quickshell-specific framework code that does not fit SXWM/X11.
- Device, GPU, monitor, TPM, or other hardware-specific declarations.
- Personal sync endpoints, credentials, cookie paths, or secrets.

## Distributed secrets management

- Manage encrypted secret specifications alongside the Nix configuration, with
  the private GitHub repository acting only as the synchronization mediator.
- Never commit plaintext secret values, machine private keys, decrypted files,
  access tokens, or recovery keys. Repository privacy is not a replacement for
  encryption.
- Evaluate `sops-nix` with age keys as the primary design. Keep declarative
  secret metadata in Nix and encrypted payloads in Git.
- Give each laptop its own age identity and authorize its public recipient in
  the encrypted secrets policy. A lost or retired laptop can then be removed
  without replacing every remaining machine identity.
- Separate shared secrets from host-specific and user-specific secrets. Only
  encrypt each secret to the machines or administrators that require it.
- Decrypt secrets during activation into protected runtime paths with explicit
  owner, group, and permission declarations. Applications should reference
  those paths rather than embedding values into the Nix store or environment.
- Provide a reproducible workflow for creating, editing, rekeying, rotating,
  and validating secrets before pushing changes.
- Keep an offline recovery identity outside GitHub and outside both laptops.
  Document recovery and laptop-replacement procedures without recording the
  recovery private key itself.
- Ensure Git diffs expose only encrypted payload changes. Add checks that
  reject obvious plaintext credentials and sensitive unencrypted files before
  commits or pushes.
- Keep GitHub credentials separate from the secrets repository contents. A
  compromised GitHub PAT should expose encrypted files, not their plaintext.

## Ephemeral cross-device messages

- Build a lightweight mechanism for sending temporary text, links, commands,
  and small payloads between the phone and either laptop.
- Treat this as a message drop or cross-device clipboard, not general file
  synchronization. It should work even when the sending and receiving devices
  are not online simultaneously.
- Use a small relay service as a mailbox. The relay should store only
  end-to-end encrypted envelopes and should not possess decryption keys.
- Give every device its own identity and public key. Pair a new device through
  an existing trusted device using a QR code or short authenticated pairing
  flow rather than a shared permanent password.
- Support targeting one device, a named device group, or all personal devices.
  Include sender identity, creation time, expiry time, content type, and a
  random message identifier in each signed envelope.
- Make expiration mandatory and configurable, with sensible presets such as
  10 minutes, one hour, one day, or delete after first retrieval. The relay
  should periodically purge expired and acknowledged messages.
- Start with text and URLs. Later payload types could include clipboard data,
  notification actions, small files, and commands, but commands must require
  an explicit allowlist and confirmation on the receiving device.
- Provide a minimal CLI and dmenu interface on the laptops, an Android share
  target or small web/PWA client on the phone, and desktop notifications for
  incoming messages.
- Support an optional `copy to clipboard` delivery action. A trusted device can
  mark a text or URL message for automatic clipboard placement on arrival,
  while ordinary messages remain notification-only.
- Make automatic clipboard writes opt-in per receiving device and per trusted
  sender. Reject expired, replayed, oversized, non-text, and unauthenticated
  payloads before interacting with the clipboard.
- Notify the receiver after an automatic copy and provide an action to view or
  clear it. Passwords and other declared secret types should require explicit
  confirmation and use a short clipboard-clear timer.
- On X11, implement clipboard delivery through a small user service using a
  suitable clipboard utility and the active graphical-session environment.
  Queue the message if the X session or clipboard is not currently available.
- On the phone, integrate with platform clipboard APIs where permitted;
  otherwise expose a one-tap copy action from the notification or application.
- Keep local history optional, bounded, and encrypted. Offer an incognito mode
  that avoids clipboard history and deletes the message immediately after it
  is opened.
- Design for unreliable networks with acknowledgements, idempotent retrieval,
  retries, and deduplication. Delivery state should distinguish queued,
  received, opened, expired, and deleted.
- Protect metadata where practical, rate-limit submissions, restrict maximum
  payload size, and prevent the relay from becoming a public upload service.
- Package laptop clients and services declaratively through Nix while keeping
  device identities and session state outside the Nix store.
- Possible first implementation: a tiny HTTPS/WebSocket relay backed by SQLite
  plus age-compatible or libsodium-based client encryption. Avoid inventing
  cryptographic primitives; use a maintained authenticated-encryption library.

## Further configuration improvements

- Add an encrypted backup system for documents, configuration, and application
  state, with automatic schedules, retention policy, restore testing, and at
  least one destination that is not another laptop.
- Provide one `profile` command that shows the active `save`, `min`, or `max`
  configuration and safely builds, tests, switches, or rolls back profiles.
  Investigate whether NixOS specialisations would provide a cleaner boot-time
  profile selector than three mostly separate system outputs.
- Add a small system-health command or menu showing battery health, temperature,
  storage, failed systemd units, network state, current profile, generation,
  and whether the Git configuration is dirty or behind its remote.
- Add battery notifications and configurable charge thresholds where the
  hardware supports them, plus deliberate suspend, hibernate, lid, and
  critical-battery behavior.
- Add automatic Nix garbage collection and store optimisation with a policy
  that preserves enough generations for useful rollback. Monitor `/boot` and
  store usage rather than deleting all old generations indiscriminately.
- Add flake checks that evaluate all three profiles and detect formatting,
  accidental plaintext secrets, broken paths, duplicate packages, and machine-
  local files being staged. Run them locally before pushing and optionally in
  GitHub Actions without exposing secrets.
- Generalize hard-coded `/home/lynaten/nixos`, `DISPLAY=:0`, monitor names,
  modes, and refresh-rate assumptions into shared options or discovered runtime
  state, while retaining explicit per-host overrides where necessary.
- Add a declarative application-default layer: MIME handlers, browser, terminal,
  file manager, image/video viewers, URL opening, removable media, and desktop
  entries.
- Add a clipboard history interface with exclusions for password managers and
  sensitive message types. Integrate it with the cross-device message system
  without persisting incognito messages.
- Extend screenshots with annotation, OCR, QR decoding, optional upload/send to
  another device, and automatic cleanup of temporary captures.
- Add a removable-device workflow: mount notifications, safe unmount/eject,
  encrypted-volume support, and profile-specific automatic mounting policy.
- Consider per-application resource controls for background video, browsers,
  Discord, builds, and AI tools so that `save`, `min`, and `max` can adjust CPU,
  I/O, and memory priorities in addition to visual effects.

### Current configuration audit items

- Decouple PipeWire, WirePlumber, and their sockets from `picom.service`.
  Compositor restarts should not stop or restart the audio stack.
- Reconsider blacklisting USB host-controller, Type-C, sound, wireless, and
  webcam modules in `save`. Prefer explicit capability switches when possible,
  and clearly indicate which changes require a reboot.
- Import and profile the existing Dunst module if notifications are intended;
  it currently exists without being included by the three flake outputs.
- Remove harmless duplication such as the repeated Docker group and Krita
  package, then split the large base configuration into focused modules.
- Review OpenSSH authentication and firewall policy before treating either
  laptop as reachable outside trusted networks.

## AI waifu

- Create a local-first AI waifu that visibly lives inside the SXWM desktop
  rather than behaving like a conventional chat application.
- Give her an actual persistent body, not merely a portrait, floating head, or
  chat avatar. Possible renderers include a rigged 2D/VTuber-style model and a
  fully rigged 3D character rendered over the desktop with transparency.
- Treat the desktop as a physical 2D world in which her body has position,
  scale, direction, velocity, animation state, and simple collision surfaces.
  The 3D body can move and animate normally while its feet remain grounded in
  screen coordinates.
- Render her as a transparent, borderless desktop entity that can idle, walk,
  run, turn, sit, lie down, gesture, dance, and transition naturally between
  actions.
- Let her use screen geometry as part of the world: stand on the bottom edge,
  sit on window borders, lean against windows, peek around edges, follow the
  pointer, and avoid covering important controls or text.
- Give windows simple physical influence over her body. She can stand on or
  climb across their borders, appear partly behind them, peek around corners,
  jump down when a supporting window closes, and step aside or be gently
  displaced when a window moves. Physics should remain playful and predictable,
  never prevent normal window movement or input.
- Make windows and monitors navigable surfaces. She should be able to move
  between monitors and SXWM workspaces with a visible transition rather than
  simply disappearing and respawning, while still getting out of the way of
  fullscreen applications.
- Give the body direct but optional interaction: click or drag to reposition,
  hover reactions, head and eye tracking, contextual gestures, and clearly
  bounded interaction regions so the overlay does not steal normal desktop
  input.
- Let her point at real screen locations when explaining something, noticing an
  error, referring to part of an image, or guiding the user through an
  interface. Combine body pose, gaze, and an optional temporary highlight or
  arrow so the intended target is unambiguous.
- Ground screen references in captured geometry. A referenced target should
  retain its window, workspace, and coordinates, then be invalidated or found
  again when the window moves or its contents change rather than pointing at a
  stale location.
- Hovering can make her notice the pointer, look toward it, reveal available
  interactions, or pause locomotion. Clicking can open chat or trigger a small
  contextual interaction; different actions should remain discoverable rather
  than relying on hidden click combinations.
- Dragging should physically pick her up and place her anywhere in the current
  workspace. While dragging near a workspace boundary, show the neighboring
  workspace and allow dropping her there without moving unrelated windows.
- Model SXWM workspaces as connected spaces with exits at their screen edges.
  She can deliberately walk off one edge, become absent from the current
  workspace, and enter the adjacent workspace instead of teleporting.
- Preserve her location independently per workspace or track one continuous
  location across the workspace map. When she returns, she should walk in from
  the corresponding edge so her movement remains spatially understandable.
- Allow autonomous travel: she may leave the current workspace, visit another,
  or walk back to the user when she wants attention. Provide a visible cue or
  small notification indicating where she went, and a simple summon action that
  always brings her back.
- Give autonomy boundaries such as `stay here`, `follow me`, `wander`, `do not
  disturb`, and `summon`. She should not repeatedly cross workspaces or cover
  focused content without respecting the selected behavior.
- Let her carry contextual objects between workspaces, such as a note, link,
  notification, or cross-device message, then hand it to the user or place it
  visibly in the destination workspace.
- Separate the body runtime from intelligence. A renderer should consume a
  small action protocol such as `walk`, `look`, `speak`, `sit`, `emote`, and
  `change-outfit`, allowing either a Live2D-like or 3D body to use the same AI
  and desktop integration.
- Keep animation responsive without continuously running the language model.
  Idle behavior, locomotion, gaze, lip sync, and basic reactions should be
  handled locally by a lightweight state machine; the model decides only
  higher-level intent and dialogue.
- Support text chat through a small popup and voice conversation through local
  speech recognition, voice-activity detection, and text-to-speech. Push-to-talk
  should be the simple and private default; wake-word mode can remain optional.
- Make speech part of the body: face the user or referenced object, animate
  expression and gestures, and drive lip sync from generated audio. Allow the
  user to interrupt her naturally while she is speaking.
- Let her inspect the user and physical surroundings through a webcam when
  explicitly enabled. Possible uses include eye contact, gesture recognition,
  showing her an object, reading visible text, checking posture, and discussing
  something happening away from the desktop.
- Camera access must be visibly embodied and controllable: show an unmistakable
  camera-active state, offer `look once`, timed, and continuous modes, and make
  it possible to revoke access immediately. Do not record or retain frames by
  default, and keep camera processing local unless the user deliberately sends
  an image elsewhere.
- Let her understand the screen through explicit observation modes: a manually
  shared region, the focused window, or periodic screenshots. Show an obvious
  visual indicator whenever screen observation or microphone capture is active.
- Combine visual understanding with lightweight context such as active window,
  workspace, selected text, clipboard content, notifications, media state, and
  time. Avoid continuous expensive vision analysis when nothing has changed.
- Give her useful small actions: explain selected content, OCR an image, read a
  notification aloud, copy or rewrite text, open a link, control media, set a
  timer, switch wallpaper/theme, and send something to another personal device.
- Require confirmation for destructive commands, shell execution, secret
  access, purchases, messages to other people, and anything that leaves the
  machine. Use a narrow declarative action allowlist rather than unrestricted
  agent access.
- Store personality, appearance, voice, and behavior as a portable AI-waifu
  specification. Keep model choice independent so local models can be replaced
  without rewriting the desktop character.
- Make memory layered and inspectable: temporary conversation context, optional
  daily notes, and explicitly approved long-term memories. Provide simple
  commands to view, edit, forget, export, or disable memory entirely.
- Reuse the encrypted cross-device mechanism so the same AI waifu can leave
  short messages or continue a conversation between the phone and both laptops
  without exposing plaintext to the relay.
- Integrate resource use with system profiles:
  - `save`: character and text only, model asleep unless invoked;
  - `min`: lightweight local chat and push-to-talk;
  - `max`: animation, local vision, continuous voice, and richer effects.
- Keep the first implementation small: one character, a few animation states,
  a text bubble, push-to-talk, one local model endpoint, and a handful of safe
  actions. Workspace walking, vision, memory, phone continuity, and autonomous
  behaviors can be added independently afterward.

### Phone and Apple integration

- Let the AI waifu exist on the phone as well as the laptops, with chat, voice
  calls, camera-based video calls, notifications, and an animated 2D VTuber
  body. During a video call, the phone camera is her vision while her model is
  the visible participant shown to the user.
- Treat device travel as a signed handoff. Only one device normally hosts her
  awake body; the others show her current location. She can leave one screen
  edge carrying conversation context, messages, or clipboard content and
  appear on another personal device.
- Start iPhone support as an installable PWA. Cache its interface, model assets,
  and basic behavior for offline use so static hosting is only a distribution
  point, not a trusted AI server.
- Separate the phone frontend from inference. Use a small on-device fallback
  when practical and connect directly to whichever laptop is awake for larger
  local models. The system should degrade gracefully when no laptop is
  reachable.
- Do not assume that a web frontend requires paid cloud compute. Possible
  deployments include free static hosting, serving from a personal machine,
  direct encrypted device connections, or a tiny store-and-forward relay that
  cannot decrypt message contents.
- Accept the limitations of an iPhone PWA: foreground chat, voice, camera, and
  animation are the initial target; reliable background execution and genuine
  system incoming calls may require a native application.
- Keep a future native iOS client possible for CallKit integration, better
  background audio and notifications, smoother rendering, and deeper device
  handoff. Account for Apple's signing, Xcode/macOS, provisioning, and annual
  developer-program constraints before choosing this route.
- Do not depend on jailbreaking. Jailbreak availability is specific to device,
  processor, and OS version and may not exist for the current phone. Treat it
  only as an optional future deployment environment, never as a core
  architectural requirement.
- Keep identity, memory, and state portable between PWA, native phone client,
  and Linux desktop implementations. The phone UI must not become a separate
  personality or incompatible data silo.

## Emacs-centred desktop and EXWM

Status: exploring. Nothing here is implemented or tested yet.

### Goal

- Make Emacs the control centre of the desktop (launcher, controls, shell
  output, logs) while keeping the existing sxwm, picom, `opacity` and
  `window-wallpaper` setup working.
- Keep packages defined by Nix. Do not use `package.el`, MELPA, straight.el or
  Elpaca: they download into `~/.emacs.d` and break the one-copy-in-the-store
  rule.

### Layers (stop at any level)

1. Emacs daemon plus `emacsclient`, run as a user service. Packages come from
   Nix (`programs.emacs.extraPackages`).
2. Emacs replaces dmenu: a small `emacsclient -c` frame with `completing-read`
   as launcher. The controls (`volume`, `light`, `font`, `opacity`) stay shell
   commands built by `lib/controls.nix`; Elisp wrappers call them and show the
   output immediately, like `M-!`. Long-running commands run async with a
   capped log, like `M-&`.
3. Emacs replaces the terminal (`eshell`/`vterm` instead of st). Loses the st
   swallow behaviour and the runtime-alpha patch.
4. EXWM replaces sxwm. Every X window, Firefox included, becomes a buffer.
   Last step, hardest to reverse.

Current plan: layers 1 and 2 first, on top of sxwm. EXWM only if wanted later,
and first in a nested session (Xephyr) so the real desktop is not lost.

### What EXWM would cost

- The sxwm pinned layer, the veil, and the `GLOBAL_OPACITY` patch
  (`dotfiles/sxwm-global-opacity.patch`) are sxwm features and would be lost.
  picom stays.
- `window-wallpaper` makes the focused window an override-redirect window
  below everything. It also sends sxwm a synthetic `DestroyNotify` so sxwm
  forgets the window; that step is sxwm-specific and would need rework.
- EXWM needs the GUI Emacs build (X support). The current config uses
  `pkgs.emacs-nox`, which cannot run EXWM or show images.
- Restarting the EXWM Emacs ends the X session and every app in it. A hung
  Emacs freezes the desktop.

### Narrowing the restart problem: two Emacs processes

- Keep the Emacs that runs EXWM small and rarely changed: only EXWM, its
  keybindings, and the few packages it needs.
- Do the package-heavy work (magit, language modes, shells, the launcher) in a
  separate Emacs daemon, not the window manager. Restarting that one is cheap
  (`systemctl --user restart emacs`) and does not touch any X window.
- Restarting a daemon still closes its buffers. Mitigate with
  `desktop-save-mode`, `savehist-mode`, `recentf-mode`, `save-place-mode`, and
  an explicit `M-x desktop-save` or `desktop-auto-save-timeout` before a
  restart. Unverified: whether a systemd restart (SIGTERM) triggers the
  save-on-exit hook.
- Without any restart: the running Emacs can pick up packages added by a
  rebuild with a reload function (see below).

### Reloading packages without restarting Emacs

Current state: `reload-config` in `dotfiles/.emacs` is only
`(load-file user-init-file)`. `~/.emacs` is an out-of-store symlink to
`dotfiles/.emacs`, so config edits are live, but packages added by a rebuild
are not found by the running Emacs.

Draft (untested), based on home-manager issue #3480, combined with
`reload-config`:

```elisp
(defun nix-reload-packages ()
  "Pick up packages from the latest rebuild without restarting Emacs."
  (interactive)
  (let* ((bin (file-truename (executable-find "emacs")))
         (root (file-name-directory (directory-file-name (file-name-directory bin))))
         (share (expand-file-name "share/emacs" root))
         (subdirs (expand-file-name "site-lisp/subdirs.el" share)))
    (when (file-exists-p subdirs)
      (load-file subdirs))
    (when (boundp 'native-comp-eln-load-path)
      (add-to-list 'native-comp-eln-load-path
                   (expand-file-name "native-lisp/" share)))))

(defun reload-config ()
  (interactive)
  (nix-reload-packages)
  (load-file user-init-file))
```

- It uses `file-truename` instead of `nix-store --query`, so no Nix command
  runs.
- It only adds new packages. Packages already loaded keep the old code until
  a restart.
- It only works if the daemon finds `emacs` through a path that updates on
  rebuild (for example `/etc/profiles/per-user/<user>/bin/emacs`). If the
  service hardcodes a store path, `file-truename` returns the old one.

Alternatives found: `twist.el` (hot reload via `exportManifest` and
`twist-update`, but a whole separate Nix framework and probably a new flake
input), `exwm-restart` (restarts EXWM in place; whether open X windows survive
is not confirmed by the EXWM wiki), and `emacsWithPackagesFromUsePackage`
from emacs-overlay (derives the package list from `init.el`, but adds a flake
input).

### Open items

- Check how the daemon is started (`services.emacs` or a custom unit) and
  which path it uses.
- Remove the MELPA archive and `package-initialize` lines from
  `dotfiles/.emacs` (all packages come from Nix), and clean the stray
  `~/.emacs.d/elpa/archives` cache.
- Decide between `emacs-nox` and the GUI build.
- Test `exwm-restart`, the reload function, and `window-wallpaper` under EXWM
  in a nested session before any real switch.

Sources:
- https://github.com/nix-community/home-manager/issues/3480
- https://discourse.nixos.org/t/emacs-exwm-home-manager-and-loading-new-emacs-modules/10097
- https://github.com/emacs-twist/twist.el
- https://github.com/emacs-exwm/exwm/wiki
