export LANG=en_US.UTF-8
alias doas='sudo'
# alias emacs="TERM=xterm emacs -nw"
export PS1="\[\033[1;32m\]\w\[\033[0m\]\n$ "

wallpaper="/etc/nixos/wallpaper.jpg"

background='#0a1719'
foreground='#c1c5c5'
cursor='#c1c5c5'

color0='#0a1719'
color1='#154C4E'
color2='#2A5A4F'
color3='#266B6F'
color4='#475046'
color5='#B04237'
color6='#4E9D6C'
color7='#c1c5c5'
color8='#596c6e'
color9='#154C4E'
color10='#2A5A4F'
color11='#266B6F'
color12='#475046'
color13='#B04237'
color14='#4E9D6C'
color15='#c1c5c5'

export FZF_DEFAULT_OPTS="
    $FZF_DEFAULT_OPTS
    --color fg:7,bg:0,hl:1,fg+:232,bg+:1,hl+:255
    --color info:7,prompt:2,spinner:1,pointer:232,marker:1
"

export LS_COLORS="${LS_COLORS}:su=30;41:ow=30;42:st=30;44:"

if [ "${TERM:-none}" = "linux" ]; then
    printf '%b' '\e]P00a1719\e]P1154C4E\e]P22A5A4F\e]P3266B6F\e]P4475046\e]P5B04237\e]P64E9D6C\e]P7c1c5c5\e]P8596c6e\e]P9154C4E\e]PA2A5A4F\e]PB266B6F\e]PC475046\e]PDB04237\e]PE4E9D6C\e]PFc1c5c5\ec'
    clear
fi

if [ -z "$XDG_RUNTIME_DIR" ]; then
    export XDG_RUNTIME_DIR=/tmp/run-$(id -u)
    if [ ! -d "$XDG_RUNTIME_DIR" ]; then
        mkdir -p "$XDG_RUNTIME_DIR"
        chmod 700 "$XDG_RUNTIME_DIR"
    fi
fi

if [ -z "$DISPLAY" ] && [ "$(tty 2>/dev/null)" = "/dev/tty1" ]; then
    startx
fi
