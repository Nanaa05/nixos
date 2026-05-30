-- load  vis module, providing parts of the Lua AP
require('vis')
require('plugins/buffer-manager')

vis.events.subscribe(vis.events.INIT, function()
	vis:map(vis.modes.NORMAL, ' p', '"*p')
	vis:map(vis.modes.VISUAL, ' p', '"*p')
	vis:map(vis.modes.VISUAL, '<M-w>', '"*y')
	vis:map(vis.modes.NORMAL, '<M-w>', '"*yy')
end)

vis.events.subscribe(vis.events.WIN_OPEN, function(win) -- luacheck: no unused args
	vis:command('set relativenumber')
	win:style_define(win.STYLE_SELECTION, 'back:#0055ff,fore:#ffffff')
	vis:command('set tabwidth 2')
end)