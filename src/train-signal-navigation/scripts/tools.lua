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

local function dumpTab(tab,ind)
    if(tab==nil)then return "nil" end;
    local str="{";
    if(ind==nil)then ind="  "; end;
    --//each of table
    for k,v in pairs(tab) do
        --//key
        if(type(k)=="string")then
            k=tostring(k).." = ";
        else
            k="["..tostring(k).."] = ";
        end;--//end if
        --//value
        local s="";
        if(type(v)=="nil")then
            s="nil";
        elseif(type(v)=="boolean")then
            if(v) then s="true"; else s="false"; end;
        elseif(type(v)=="number")then
            s=v;
        elseif(type(v)=="string")then
            s="\""..v.."\"";
        elseif(type(v)=="table")then
            s=dumpTab(v,ind.."  ");
            s=string.sub(s,1,#s-1);
        elseif(type(v)=="function")then
            s="function : "..v;
        elseif(type(v)=="thread")then
            s="thread : "..tostring(v);
        elseif(type(v)=="userdata")then
            s="userdata : "..tostring(v);
        else
            s="nuknow : "..tostring(v);
        end;--//end if
        --//Contact
        str=str.."\n"..ind..k..s.." ,";
    end --//end for
    --//return the format string
    local sss=string.sub(str,1,#str-1);
    if(#ind>0)then ind=string.sub(ind,1,#ind-2) end;
    sss=sss.."\n"..ind.."}\n";
    return sss;
end


local function debug_obj(table)
    debug(dumpTab(table))
end

tools.get_child = get_child
tools.build_gui = build_gui
tools.debug_obj = debug_obj
tools.debug = debug

return tools