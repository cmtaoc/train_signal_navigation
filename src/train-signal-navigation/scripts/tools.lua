local tools = {}

local function recursive_build_gui(parent, def, path, def_map)

    local ref = def.ref
    local children = def.children
    local style_mods = def.style_mods

    def.ref = nil
    def.children = nil
    def.style_mods = nil
    def.tabs = nil

    local element = parent.add(def)

    if not ref and def.name then
        def_map[def.name] = element
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
                recursive_build_gui(element, child_def, path, def_map)
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

                local ui_tab = recursive_build_gui(element, tab, path, def_map)
                local ui_content = recursive_build_gui(element, content, path, def_map)
                element.add_tab(ui_tab, ui_content)

                table.remove(path)
            end
        end
    end

    if ref then
        local lamp = def_map
        for index, i_path in ipairs(ref) do
            if index == #ref then
                lamp[i_path] = element
            else
                local m = lamp[i_path]
                if not m then
                    m = {}
                    lamp[i_path] = m
                end
                lamp = m
            end
        end
    end

    if style_mods then
        for name, value in pairs(style_mods) do
            element.style[name] = value
        end
    end

    return element
end

local function build_gui(parent, def)

    local def_map = {}
    if not def.type then
        for index, sub_def in ipairs(def) do
            recursive_build_gui(parent, sub_def, { index}, def_map)
        end
    else
        recursive_build_gui(parent, def, {}, def_map)
    end
    return def_map
end

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

local function debug(msg)
    if game then
        for _, player in pairs(game.players) do player.print(msg) end
    end
end

local function table2json(t)
    --将表格转换为json
    local function serialize(tbl)
        local tmp = {}
        for k, v in pairs(tbl) do
            local k_type = type(k)
            local v_type = type(v)
            local key = (k_type == "string" and "\"" .. k .. "\":") or (k_type == "number" and "")
            local value = (v_type == "table" and serialize(v)) or (v_type == "boolean" and tostring(v)) or (v_type == "string" and "\"" .. v .. "\"") or (v_type == "number" and v)
            tmp[#tmp + 1] = key and value and tostring(key) .. tostring(value) or nil
        end
        if table.maxn(tbl) == 0 then
            return "{" .. table.concat(tmp, ",") .. "}"
        else
            return "[" .. table.concat(tmp, ",") .. "]"
        end
    end
    assert(type(t) == "table")
    return serialize(t)
end

local function debug_obj(table)
    debug(table2json(table))
end

tools.get_child = get_child
tools.build_gui = build_gui
tools.debug_obj = debug_obj
tools.debug = debug

return tools