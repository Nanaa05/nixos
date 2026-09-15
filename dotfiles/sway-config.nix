{ env }:
''
# ==== DISPLAY & BACKGROUND ====
# (Sway handles this natively, no need for xwallpaper)
output * bg /etc/nixos/wallpaper.jpg fill

# ==== STYLING & GAPS ====
gaps inner 30
default_border pixel 2

# Colors: class                 border  bground text    indicator child_border
client.focused                  #31827f #31827f #ffffff #31827f   #31827f
client.unfocused                #0a1719 #0a1719 #888888 #0a1719   #0a1719

# ==== AUTO-FLOATING ====
for_window [app_id="pcmanfm"] floating enable
for_window [class="pcmanfm"] floating enable
for_window [app_id="obs"] floating enable
for_window [class="obs"] floating enable

# ==== VARIABLES ====
set $mod Mod4

# ==== CORE SHORTCUTS ====
bindsym $mod+Return exec "st -e /bin/sh -c '. ~/.profile && /bin/sh'"
bindsym $mod+e exec pcmanfm

# Note: XWayland will run dmenu just fine, but in the future look into 'bemenu' or 'wofi'
bindsym $mod+space exec wmenu-run -l 5 -f 'JetBrains Mono 20' -p ' Run > ' -N '#0a1719' -n '#c1c5c5' -S '#154C4E' -s '#c1c5c5'
bindsym $mod+z exec boomer

# Screenshots (Wayland native)
bindsym Print exec grim -g "$(slurp)" - | wl-copy
bindsym $mod+Print exec /home/lynaten/.local/bin/screenshot.sh

# ==== DYNAMIC DISPLAYS (Translated from xrandr) ====
# F1: Extend (External right of Primary)
bindsym $mod+F1 exec swaymsg output ${env.monitorPrimary} enable, output ${env.monitorExternal} enable pos 1920 0
# F2: (Wayland doesn't mirror via output natively like X11, you may need to install wl-mirror for this in the future)
bindsym $mod+F2 exec swaymsg output ${env.monitorPrimary} mode ${env.resFHD}
# F3: Primary Only
bindsym $mod+F3 exec swaymsg output ${env.monitorExternal} disable, output ${env.monitorPrimary} enable

# ==== WINDOW MANAGEMENT ====
bindsym $mod+Shift+q kill
bindsym $mod+c floating enable, move position center
bindsym $mod+Shift+e exit
bindsym $mod+m layout toggle split tabbed

bindsym $mod+j focus right
bindsym $mod+k focus left
bindsym $mod+comma focus output left
bindsym $mod+period focus output right
bindsym $mod+Shift+comma move workspace to output left
bindsym $mod+Shift+period move workspace to output right

bindsym $mod+Shift+j move right
bindsym $mod+Shift+k move left

# Resizing
bindsym $mod+l resize grow width 50 px
bindsym $mod+h resize shrink width 50 px
bindsym $mod+Control+l resize grow height 50 px
bindsym $mod+Control+h resize shrink height 50 px

# Floating Movement
bindsym $mod+Up move up 50 px
bindsym $mod+Down move down 50 px
bindsym $mod+Left move left 50 px
bindsym $mod+Right move right 50 px

# Gaps
bindsym $mod+equal gaps inner current plus 5
bindsym $mod+minus gaps inner current minus 5

bindsym $mod+p floating toggle
bindsym $mod+Shift+f fullscreen toggle
bindsym $mod+r reload

# ==== SCRATCHPAD ====
# Sway uses a unified scratchpad. Hides current window to it, or shows the next hidden one.
bindsym $mod+Mod1+1 move scratchpad
bindsym $mod+Control+1 scratchpad show

# ==== WORKSPACES ====
bindsym $mod+1 workspace number 1
bindsym $mod+Shift+1 move container to workspace number 1
bindsym $mod+2 workspace number 2
bindsym $mod+Shift+2 move container to workspace number 2
bindsym $mod+3 workspace number 3
bindsym $mod+Shift+3 move container to workspace number 3
bindsym $mod+4 workspace number 4
bindsym $mod+Shift+4 move container to workspace number 4
bindsym $mod+5 workspace number 5
bindsym $mod+Shift+5 move container to workspace number 5
bindsym $mod+6 workspace number 6
bindsym $mod+Shift+6 move container to workspace number 6
bindsym $mod+7 workspace number 7
bindsym $mod+Shift+7 move container to workspace number 7
bindsym $mod+8 workspace number 8
bindsym $mod+Shift+8 move container to workspace number 8
bindsym $mod+9 workspace number 9
bindsym $mod+Shift+9 move container to workspace number 9
''
