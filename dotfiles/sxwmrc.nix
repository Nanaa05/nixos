{ env, currentHz }:
''
focused_border_colour    : #31827f
unfocused_border_colour  : #0a1719
swap_border_colour       : #eeeeee

gaps                    : 30
border_width            : 2
master_width            : 50
resize_master_amount    : 1
resize_stack_amount     : 20
move_window_amount      : 50
resize_window_amount    : 50
snap_distance           : 5

# TODO: Dynamic Motion Throttle
motion_throttle         : ${currentHz}
should_float            : "pcmanfm", "obs"
new_win_focus           : true
warp_cursor             : true
floating_on_top         : true
new_win_master          : false
can_swallow             : "st"
can_be_swallowed        : "mpv", "sxiv"
start_fullscreen        : "mpv", "vlc"

mod_key : super

bind : mod + Return : "st -e /bin/sh -c '. ~/.profile && /bin/sh'"
bind : mod + e : "pcmanfm"
bind : mod + space : "dmenu_run -l 5 -fn 'JetBrains Mono:style=Medium:size=20' -p ' Run > ' -nb '#0a1719' -nf '#c1c5c5' -sb '#154C4E' -sf '#c1c5c5'"
bind : mod + z : "boomer"
bind : Print : "maim -s | xclip -selection clipboard -t image/png"
bind : mod + Print : "/home/lynaten/.local/bin/screenshot.sh"

# TODO: Dynamic Script: Output Names
bind : mod + F1 : "xrandr --output ${env.monitorPrimary} --auto --primary --output ${env.monitorExternal} --auto --right-of ${env.monitorPrimary}"
bind : mod + F2 : "xrandr --output ${env.monitorPrimary} --mode ${env.resFHD} --output ${env.monitorExternal} --mode ${env.resFHD} --same-as ${env.monitorPrimary}"
bind : mod + F3 : "xrandr --output ${env.monitorExternal} --off --output ${env.monitorPrimary} --auto --primary"

call : mod + shift + q : close_window
call : mod + c : centre_window
call : mod + shift + e : quit
call : mod + m : toggle_monocle

call : mod + j : focus_next
call : mod + k : focus_prev
call : mod + comma : focus_prev_mon
call : mod + period : focus_next_mon
call : mod + shift + comma : move_prev_mon
call : mod + shift + period : move_next_mon

call : mod + shift + j : master_next
call : mod + shift + k : master_prev

call : mod + l : master_increase
call : mod + h : master_decrease
call : mod + ctrl + l : stack_increase
call : mod + ctrl + h : stack_decrease

call : mod + Up : move_win_up
call : mod + Down : move_win_down
call : mod + Left : move_win_left
call : mod + Right : move_win_right

call : mod + shift + Up : resize_win_up
call : mod + shift + Down : resize_win_down
call : mod + shift + Left : resize_win_left
call : mod + shift + Right : resize_win_right

call : mod + equal : increase_gaps
call : mod + minus : decrease_gaps

call : mod + p : toggle_floating
call : mod + shift + p : global_floating
call : mod + shift + f : fullscreen
call : mod + r : reload_config

scratchpad : mod + alt + 1 : create 1
scratchpad : mod + alt + 2 : create 2
scratchpad : mod + alt + 3 : create 3
scratchpad : mod + alt + 4 : create 4

scratchpad : mod + ctrl + 1 : toggle 1
scratchpad : mod + ctrl + 2 : toggle 2
scratchpad : mod + ctrl + 3 : toggle 3
scratchpad : mod + ctrl + 4 : toggle 4

scratchpad : mod + alt + shift + 1 : remove 1
scratchpad : mod + alt + shift + 2 : remove 2
scratchpad : mod + alt + shift + 3 : remove 3
scratchpad : mod + alt + shift + 4 : remove 4

workspace : mod + 1          : move 1
workspace : mod + shift + 1  : swap 1
workspace : mod + 2          : move 2
workspace : mod + shift + 2  : swap 2
workspace : mod + 3          : move 3
workspace : mod + shift + 3  : swap 3
workspace : mod + 4          : move 4
workspace : mod + shift + 4  : swap 4
workspace : mod + 5          : move 5
workspace : mod + shift + 5  : swap 5
workspace : mod + 6          : move 6
workspace : mod + shift + 6  : swap 6
workspace : mod + 7          : move 7
workspace : mod + shift + 7  : swap 7
workspace : mod + 8          : move 8
workspace : mod + shift + 8  : swap 8
workspace : mod + 9          : move 9
workspace : mod + shift + 9  : swap 9
''
