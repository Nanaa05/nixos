self: super:

{
  nim_1_0 = super.callPackage ./nim_1_0.nix {};

  # picom with the _BOOMER_ZOOM root property (boomer --live); the build fails
  # loudly if a nixpkgs bump stops the patch from applying
  picom = super.picom.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [ ../picom-zoom.patch ];
  });
}
