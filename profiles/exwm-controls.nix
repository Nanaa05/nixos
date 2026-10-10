{ ... }:
{
  # lets Emacs (dotfiles/.emacs) find the control manifests written by lib/controls.nix;
  # drop this import when leaving EXWM
  environment.pathsToLink = [ "/share/emacs-controls" ];
}
