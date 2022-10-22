
local log_index = 1
local tracing = true

local tools = {}
local function debug(msg)
    if not tracing then return end
    msg = "[" .. log_index .. "] " .. msg
    log_index = log_index + 1
    if game then
        for _, player in pairs(game.players) do player.print(msg) end
    end
    log(msg)
end

tools.debug = debug

local function cdebug(cond, msg) if cond then debug(msg) end end

tools.cdebug = cdebug

function tools.set_trace(trace) tracing = trace end

function tools.get_vars(player)

    local players = global.players
    if players == nil then
        players = {}
        global.players = players
    end
    local vars = players[player.index]
    if vars == nil then
        vars = {}
        players[player.index] = vars
    end
    return vars
end

function tools.get_id()
    local id = global.id or 1
    global.id = id + 1
    return id
end

function tools.comma_value(n) -- credit http://richard.warburton.it
    if not n then return "" end
    local left, num, right = string.match(n, '^([^%d]*%d)(%d*)(.-)$')
    return left .. (num:reverse():gsub('(%d%d%d)', '%1,'):reverse()) .. right
end

function tools.table_count(table)
    local count = 0
    for _, _ in pairs(table) do count = count + 1 end
    return count
end

function tools.table_merge(...)
    local result = {}
    for _, table in pairs(arg) do
        if table then
            for _, e in pairs(table) do table.insert(result, e) end
        end
    end
    return result
end

------------------------------------------------

function tools.on_event(event, handler, filters)
    local previous = script.get_event_handler(event)
    if not previous then
        script.on_event(event, handler)
    else
        local prev_filters = script.get_event_filter(event)
        local new_filters = nil
        if prev_filters == nil then
            new_filters = filters
        elseif filters == nil then
            new_filters = prev_filters
        else
            new_filters = tools.table_merge(prev_filters, filters)
        end

        script.on_event(event, function(e)
            previous(e)
            handler(e)
        end, new_filters)
    end
end

local on_load_handler

function tools.on_load(handler)
    if not on_load_handler then
        on_load_handler = handler
        script.on_load(function() on_load_handler() end)
    else
        local previous = on_load_handler
        on_load_handler = function()
            previous()
            handler()
        end
    end
end

function tools.fire_on_load() if on_load_handler then on_load_handler() end end

local on_init_handler

function tools.on_init(handler)
    if not on_init_handler then
        on_init_handler = handler
        script.on_init(function() on_init_handler() end)
    else
        local previous = on_init_handler
        on_init_handler = function()
            previous()
            handler()
        end
    end
end

local on_configuration_changed_handler

function tools.on_configuration_changed(handler)
    if not on_configuration_changed_handler then
        on_configuration_changed_handler = handler
        script.on_configuration_changed(function(data)
            on_configuration_changed_handler(data)
        end)
    else
        local previous = on_configuration_changed_handler
        on_configuration_changed_handler = function()
            previous()
            handler()
        end
    end
end

local on_debug_init_handler

function tools.on_debug_init(f)

    if on_debug_init_handler then
        local previous_init = on_debug_init_handler
        on_debug_init_handler = function()
            previous_init()
            f()
        end
    else
        on_debug_init_handler = f
        tools.on_event(defines.events.on_tick, function()
            if (on_debug_init_handler) then
                on_debug_init_handler()
                on_debug_init_handler = nil
            end
        end)
    end
end

local on_gui_click_map

local function on_gui_click_handler(e)

    if e.element.valid then
        local handler = on_gui_click_map[e.element.name]
        if handler then handler(e) end
    end
end

function tools.on_gui_click(button_name, f)

    if not on_gui_click_map then
        on_gui_click_map = {}
        tools.on_event(defines.events.on_gui_click, on_gui_click_handler)
    end
    on_gui_click_map[button_name] = f
end

------------------------------------------------

local function get_child(parent, name)

    local child = parent[name]
    if child then return child end

    local children= parent.children
    if not children then return nil end
    for _, e in pairs(children) do
        child = get_child(e, name)
        if child then return child end
    end
    return nil
end

tools.get_child = get_child
local build_trace = false

function tools.get_fields(parent)
    local fields = {}
    local mt = {
        __index = function(base, key)
            local value = rawget(base, key)
            if value then return value end
            value = tools.get_child(parent, key)
            rawset(base, key, value)
            return value
        end
    }
    setmetatable(fields, mt)
    return fields
end

local function recursive_build_gui(parent, def, path, refmap)

    local ref = def.ref
    local children = def.children
    local style_mods = def.style_mods
    local tabs = def.tabs

    if (build_trace) then
        debug("build: def=" .. serpent.block(def):gsub("%s", ""))
    end

    def.ref = nil
    def.children = nil
    def.style_mods = nil
    def.tabs = nil

    if not def.type then
        if not build_trace then
            debug("build: def=" .. serpent.block(def):gsub("%s", ""))
        end
        debug("Missing type")
    end

    local element = parent.add(def)

    if not ref and def.name then
        refmap[def.name] = element
    end

    if children then
        if def.type ~= "tabbed-pane" then
            for index, child_def in pairs(children) do
                local name = child_def.name
                if name then
                    table.insert(path, name .. ":" .. index)
                else
                    table.insert(path, index)
                end
                if build_trace then
                    debug("build: path=" .. serpent.block(path):gsub("%s", ""))
                end
                recursive_build_gui(element, child_def, path, refmap)
                table.remove(path)
            end
        else
            for index, t in pairs(children) do
                local tab = t.tab
                local content = t.content

                local name = tab.name
                if name then
                    table.insert(path, name .. ":" .. index)
                else
                    table.insert(path, index)
                end
                if build_trace then
                    debug("build: path=" .. serpent.block(path):gsub("%s", ""))
                end

                local ui_tab = recursive_build_gui(element, tab, path, refmap)
                local ui_content = recursive_build_gui(element, content, path,
                                                       refmap)
                element.add_tab(ui_tab, ui_content)

                table.remove(path)
            end
        end
    end

    if ref then
        local lmap = refmap
        for index, ipath in ipairs(ref) do
            if index == #ref then
                lmap[ipath] = element
            else
                local m = lmap[ipath]
                if not m then
                    m = {}
                    lmap[ipath] = m
                end
                lmap = m
            end
        end
    end

    if style_mods then
        if build_trace then
            debug("build: style_mods=" ..
                      serpent.block(style_mods):gsub("%s", ""))
        end
        for name, value in pairs(style_mods) do
            element.style[name] = value
        end
    end

    return element
end

function tools.build_gui(parent, def)

    local refmap = {}
    if not def.type then
        for index, subdef in ipairs(def) do
            recursive_build_gui(parent, subdef, {index}, refmap)
        end
    else
        recursive_build_gui(parent, def, {}, refmap)
    end
    return refmap
end

local user_event_handlers = {}

function tools.register_user_event(name, handler)

    local previous = user_event_handlers[name]
    if not previous then
        user_event_handlers[name] = handler
    else

        local new_handler = function(data)
            previous(data)
            handler(data)
        end
        user_event_handlers[name] = new_handler
    end
end

function tools.fire_user_event(name, data)

    local handler = user_event_handlers[name]
    if handler then
        handler(data)
    end
end

function tools.signal_to_sprite(signal)
    if not signal then return nil end
    local type = signal.type
    if type == "virtual" then
        return "virtual-signal/" .. signal.name
    else
        return type .. "/" .. signal.name
    end
end

function tools.sprite_to_signal(sprite)
    if not sprite or sprite == "" then return nil end
    local split = string.gmatch(sprite, "([^/]+)[/]([^/]+)")
    local type, name = split()
    if type=="virtual-signal" then
        type = "virtual"
    end
    return {type=type,name=name}
end

function tools.signal_to_name(signal)
    if not signal then return nil end
    local type = signal.type
    return "[" .. type .. "=" .. signal.name .. "]"
end


------------------------------------------------

local mt = {

    __newindex = function ( base, key, value ) 
        if key == "build_trace" then build_trace = value end
    end,
    __index = function(base, key)
        if key == "build_trace" then return build_trace end
    end
}

setmetatable(tools, mt)

------------------------------------------------

return tools

