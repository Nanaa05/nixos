pkgs:
{ name
, alias
, label                      # "Volume" -> "Volume adjusted to 40%"
, get                        # shell snippet that prints the current value
, set ? null                  # shell snippet; receives $VALUE (null = read-only control, no argument)
, accept ? "^[0-9]+$"        # bash regex for a valid argument
, hint ? "<0-100>"           # shown in the usage message
, max ? 100                  # numeric upper bound (null to skip, e.g. font)
, prepare ? ""               # optional snippet to adjust $VALUE (e.g. clamp)
, unit ? "%"
}:
let
  script = pkgs.writeShellScriptBin name ''
    ${if set == null then ''
    # read-only: no setter, so no argument either
    [ "$#" -eq 0 ] || { echo "Usage: ${name}" >&2; exit 1; }
    ${get}
    '' else ''
    usage() { echo "Usage: ${name} ${hint}" >&2; exit 1; }

    if [ "$#" -eq 0 ]; then
      ${get}
      exit 0
    fi

    [ "$#" -eq 1 ] && [[ "$1" =~ ${accept} ]] || usage
    ${pkgs.lib.optionalString (max != null) ''[ "$1" -le ${toString max} ] || usage''}

    VALUE=$1
    ${prepare}
    ${set}
    echo "${label} adjusted to $VALUE${unit}"
    ''}
  '';
in
pkgs.symlinkJoin {
  name = "${name}-controls";
  paths = [ script ];
  postBuild = ''
    ln -s "$out/bin/${name}" "$out/bin/${alias}"
  
    mkdir -p "$out/share/emacs-controls"
    ${if set == null
      then ''printf '%s\n%s\n' "${name}" "${alias}" > "$out/share/emacs-controls/${name}"''
      else ''printf '%s\n%s\n%s\n' "${name}" "${alias}" "${hint}" > "$out/share/emacs-controls/${name}"''}
  '';
}
