local cfg = {
    use_fzf = true,
}

local buffer_history = {}

vis.events.subscribe(vis.events.WIN_OPEN, function(win)
    if win.file and win.file.name then
        for i, name in ipairs(buffer_history) do
            if name == win.file.name then
                table.remove(buffer_history, i)
                break
            end
        end
        table.insert(buffer_history, 1, win.file.name)
    end
end)

local function get_safe_name(filename)
    return filename:gsub(" ", "\\ ")
end

local function get_menu_cmd(prompt_str, multi)
    if cfg.use_fzf then
        local multi_flag = multi and " -m" or ""
        return string.format("fzf%s --prompt='%s> ' --height=40%% --layout=reverse", multi_flag, prompt_str)
    else
        return string.format("vis-menu -i -p '%s:'", prompt_str)
    end
end

local function get_find_cmd()
    return "if command -v fd >/dev/null 2>&1; then fd --type f --hidden --exclude .git; elif command -v rg >/dev/null 2>&1; then rg --files --hidden -g '!.git'; elif git rev-parse --is-inside-work-tree >/dev/null 2>&1; then git ls-files --cached --others --exclude-standard; else find . -type f -not -path '*/.git/*' 2>/dev/null | sed 's|^\\./||'; fi"
end

local switch_buffer = function()
    local current_file = (vis.win and vis.win.file) and vis.win.file.name or ""
    local switch_options = {}

    for _, name in ipairs(buffer_history) do
        if name ~= current_file then
            table.insert(switch_options, name)
        end
    end

    if #switch_options == 0 then
        vis:info("No alternative tracking buffers active.")
        return
    end

    local menu_bin = get_menu_cmd("Switch Buffer")
    local cmd = "printf '" .. table.concat(switch_options, "\n"):gsub("'", "'\\''") .. "' | " .. menu_bin
    local status, out, err = vis:pipe(cmd)
    
    if status ~= 0 and status ~= 130 and not out then
        if err and #err > 0 then vis:info(err) end
        return
    end
    
    if out and #out > 0 then
        out = out:gsub("\n$", "")
        vis:command("e " .. get_safe_name(out))
    end
end

local find_file = function()
    local menu_bin = get_menu_cmd("Find File")
    local cmd = "(" .. get_find_cmd() .. ") | " .. menu_bin
    local status, out, err = vis:pipe(cmd)
    
    if status ~= 0 and status ~= 130 and not out then
        if err and #err > 0 then vis:info(err) end
        return
    end
    
    if out and #out > 0 then
        out = out:gsub("\n$", "")
        vis:command("e " .. get_safe_name(out))
    end
end

local kill_buffer = function()
    if #buffer_history == 0 then
        vis:info("No buffers to close.")
        return
    end

    local menu_bin = get_menu_cmd("Kill Buffer")
    local cmd = "printf '" .. table.concat(buffer_history, "\n"):gsub("'", "'\\''") .. "' | " .. menu_bin
    local status, out, err = vis:pipe(cmd)
    
    if status ~= 0 and status ~= 130 and not out then
        if err and #err > 0 then vis:info(err) end
        return
    end
    
    if not out or #out == 0 then return end
    out = out:gsub("\n$", "")

    local killing_current = (vis.win and vis.win.file and vis.win.file.name == out)
    local fallback_file = nil

    for i, name in ipairs(buffer_history) do
        if name == out then
            table.remove(buffer_history, i)
            fallback_file = buffer_history[i] or buffer_history[i-1]
            break
        end
    end
    
    if killing_current then
        if fallback_file then
            vis:command("e " .. get_safe_name(fallback_file))
            vis:info("Killed active buffer. Switched to: " .. fallback_file)
        else
            vis:command("q")
        end
    else
        vis:info("Killed background buffer: " .. out)
    end
end

local bundle_project_files = function()
    local menu_bin = get_menu_cmd("Select Files to Bundle (Tab to multi-select)", true)
    local cmd = "(" .. get_find_cmd() .. ") | " .. menu_bin
    local status, out, err = vis:pipe(cmd)

    if status ~= 0 and status ~= 130 and not out then
        if err and #err > 0 then vis:info(err) end
        return
    end

    if not out or #out == 0 then return end

    local tmp_filepath = os.tmpname()
    local tmp_file = io.open(tmp_filepath, "w")
    
    if not tmp_file then
        vis:info("Error: Cannot create temporary file.")
        return
    end

    local file_count = 0

    for relpath in out:gmatch("[^\r\n]+") do
        local f = io.open(relpath, "r")
        if f then
            local content = f:read("*all")
            f:close()

            tmp_file:write("-- FILE: " .. relpath .. "\n")
            tmp_file:write(content)
            
            if content:sub(-1) ~= "\n" then
                tmp_file:write("\n")
            end
            tmp_file:write("\n")
            
            file_count = file_count + 1
        end
    end
    
    tmp_file:close()

    if file_count > 0 then
        vis:command("e " .. get_safe_name(tmp_filepath))
        vis:info("Bundled " .. file_count .. " file(s) into " .. tmp_filepath)
    else
        os.remove(tmp_filepath)
        vis:info("No valid files were read.")
    end
end

vis:map(vis.modes.NORMAL, " b", function() switch_buffer()        end, "Switch Buffer")
vis:map(vis.modes.NORMAL, " f", function() find_file()            end, "Find File")
vis:map(vis.modes.NORMAL, " k", function() kill_buffer()          end, "Kill Buffer")
vis:map(vis.modes.NORMAL, " c", function() bundle_project_files() end, "Bundle Project Files to /tmp")