{ stdenv, fetchFromGitHub, nim, libX11, libXrandr, libGL, nim_1_0 }:

let
  x11-nim = fetchFromGitHub {
    owner = "nim-lang";
    repo = "x11";
    rev = "29aca5e519ebf5d833f63a6a2769e62ec7bfb83a";
    hash = "sha256-jBNsv8meDvF2ySKewbA+rF2XS+gqydZUl1xhEevD15o=";
  };
  opengl-nim = fetchFromGitHub {
    owner = "nim-lang";
    repo = "opengl";
    rev = "8e2e098f82dc5eefd874488c37b5830233cd18f4";
    sha256 = "sha256-v3bMDobYQZqX0anBFIUfZx5q5/vxTHO6PDtKQlf5mgU=";
  };
in stdenv.mkDerivation rec {
  pname = "boomer";
  version = "unstable-2020-01-23";
  src = fetchFromGitHub {
    owner = "Nanaa05";
    repo = "boomer";
    rev = "f95ea8327f6162d2c25d69bc4a520a29c153748e";
    hash = "sha256-zLhR6m7E+fzw4RDsO5zCrubS075S7LeZ9oyr+70esVg=";
  };
  buildInputs = [ nim_1_0 libX11 libXrandr libGL ];
  buildPhase = ''
    HOME=$TMPDIR
    nim -p:${x11-nim}/ -p:${opengl-nim}/src c -d:release src/boomer.nim
  '';
  installPhase = "install -Dt $out/bin src/boomer";
  fixupPhase = "patchelf --set-rpath ${stdenv.lib.makeLibraryPath [stdenv.cc.cc libX11 libXrandr libGL]} $out/bin/boomer";
}
