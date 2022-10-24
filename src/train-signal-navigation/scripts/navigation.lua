local tools = require("scripts.tools")
local controller

if settings.startup["nav-train-signal-mode"].value == "A" then
    controller = require("scripts.controller")
else
    controller = require("scripts.controller2")
end

require("scripts.controller")

local navigation_panel = "nav-panel"
local navigation_name = "nav-train-signal"

local navigations

local function get_or_create_navigations()
    if navigations then return navigations end

    navigations = global.navigations;

    if navigations then return navigations end

    navigations = {}
    global.navigations = navigations
    return navigations
end

local function get_navigation(unit_number)
    local navigations = get_or_create_navigations()

    local navigation = navigations[unit_number]

    if not navigation then
        navigation = {}
        navigations[unit_number] = navigation
    end

    local item_map = navigation.item_map
    if not item_map then
        item_map = {}
        navigation.item_map = item_map
    end

    return navigation
end

local function get_panel_items(item_map)

    local children = {
        {
            type = "label",
            caption = { navigation_panel .. ".signal" },
            style_mods = { top_margin = 10 }
        }, {
            type = "label",
            caption = { navigation_panel .. ".upper_limit" },
            style_mods = { top_margin = 10, left_margin = 20, width = 50 }
        }, {
            type = "label",
            caption = { navigation_panel .. ".lower_limit" },
            style_mods = { top_margin = 10, left_margin = 20, width = 50 }
        }
    }

    for i = 1, 10 do
        local signal, upper_limit, lower_limit
        if i <= #item_map then
            signal = item_map[i].signal
            upper_limit = item_map[i].upper_limit
            lower_limit = item_map[i].lower_limit
        end
        table.insert(children, {
            type = "choose-elem-button",
            name = "signal-" .. i,
            tooltip = { navigation_panel .. ".signal-tooltip" },
            elem_type = "signal",
            signal = signal
        })
        table.insert(children, {
            type = "textfield",
            numeric = true,
            name = "upper_limit-" .. i,
            tooltip = { navigation_panel .. ".upper_limit-tooltip" },
            style_mods = { left_margin = 20, right_margin = 20 },
            text = upper_limit
        })
        table.insert(children, {
            type = "textfield",
            name = "lower_limit-" .. i,
            numeric = true,
            tooltip = { navigation_panel .. ".lower_limit-tooltip" },
            style_mods = { left_margin = 20, right_margin = 20 },
            text = lower_limit
        })
    end
    return children
end

local function get_panel_table(item_map)
    local table = {
        type = "frame",
        name = navigation_panel,
        ref = { "panel" },
        direction = "vertical",
        children = {
            {
                type = "flow",
                direction = "horizontal",
                ref = { "title_bar" },
                children = {
                    {
                        type = "label",
                        style = "frame_title",
                        caption = { navigation_panel .. ".title" },
                        ignored_by_interaction = true
                    }, {
                        type = "empty-widget",
                        style = "draggable_space_header",
                        style_mods = { height = 24, horizontally_stretchable = true, right_margin = 4 },
                        ignored_by_interaction = true,
                    }, {
                        type = "sprite-button",
                        style = "frame_action_button",
                        sprite = "utility/close_white",
                        hovered_sprite = "utility/close_black",
                        clicked_sprite = "utility/close_black",
                        name = navigation_panel .. ".close"
                    }
                }
            }, {
                type = "frame",
                style = "inside_shallow_frame",
                direction = "vertical",
                style_mods = { padding = 10 },
                children = {

                    {
                        type = "table",
                        style_mods = { margin = 10 },
                        ref = { navigation_panel .. ".signals_table" },
                        column_count = 3,
                        name = "signals_table",
                        children = get_panel_items(item_map)
                    }, {
                        type = "button",
                        name = navigation_panel .. ".ok",
                        caption = { navigation_panel .. ".ok" },
                        style_mods = { top_margin = 10, left_margin = 400 }
                    }
                }
            }
        }
    }
    return table
end

local opened
local function navigation_panel_destroy(player)
    local panel = player.gui.screen[navigation_panel]
    if panel then
        opened = false
        panel.destroy()
    end
end

local in_open = false
local function navigation_panel_open(event)
    if opened then
        navigation_panel_destroy(game.players[event.player_index])
    end

    in_open = true

    local entity = event.entity
    if not entity or not entity.valid then
        return
    end
    if entity.name ~= navigation_name then
        return
    end

    local navigation = get_navigation(entity.unit_number)
    local item_map = navigation.item_map
    if not navigation.entity then
        navigation.entity = entity
    end

    local player = game.players[event.player_index]
    local refs = tools.build_gui(player.gui.screen, get_panel_table(item_map))

    player.opened = refs.panel

    refs.panel.tags = { id = entity.unit_number }
    refs.title_bar.drag_target = refs.panel
    refs.panel.force_auto_center()
    opened = true
    in_open = false
end

local function on_tick(event)
    get_or_create_navigations()

    for index, navigation in pairs(navigations) do
        if navigation then
            if navigation.entity and navigation.entity.valid then
                controller.exec_navigation(navigation)
            else
                navigations[index] = nil
            end
        end
    end
end

local function save_navigation(player)
    local panel = player.gui.screen[navigation_panel]
    local id = panel.tags.id
    local navigation = get_navigation(id)

    local items = tools.get_child(panel, "signals_table")
    local item_map = {}
    for i = 1, 10 do
        local ele = items["signal-" .. i]
        local upper = items["upper_limit-" .. i]
        local lower = items["lower_limit-" .. i]

        local signal = ele.elem_value
        local upper_limit = upper.text
        local lower_limit = lower.text

        local up = string.match(upper_limit, "^%d+$")
        local low = string.match(lower_limit, "^%d+$")
        if signal and up and low then
            local full_signal = signal
            local full_upper = tonumber(upper_limit)
            local full_lower = tonumber(lower_limit)
            table.insert(item_map, { signal = full_signal, upper_limit = full_upper, lower_limit = full_lower })
        end
    end

    navigation.count = nil
    navigation.item = nil
    navigation.item_map = item_map

    navigation_panel_destroy(player)
end

local function navigation_panel_save(event)
    if event.element and event.element.valid and event.element.name == navigation_panel .. ".ok" then
        save_navigation(game.players[event.player_index])
    end
end

local function navigation_panel_close(event)
    if event.element and event.element.valid and event.element.name == navigation_panel .. ".close" then
        navigation_panel_destroy(game.players[event.player_index])
    end
end

local function navigation_panel_close_event(event)
    if not in_open then
        navigation_panel_destroy(game.players[event.player_index])
    end
end

local function navigation_panel_click_event(event)
    navigation_panel_save(event)
    navigation_panel_close(event)
end

local function on_load_event()

end

script.on_load(on_load_event)
script.on_nth_tick(30, on_tick)
script.on_event(defines.events.on_gui_opened, navigation_panel_open)
script.on_event(defines.events.on_gui_click, navigation_panel_click_event)
script.on_event(defines.events.on_gui_confirmed, navigation_panel_save)
script.on_event(defines.events.on_gui_closed, navigation_panel_close_event)
script.on_event(defines.events.on_train_created, controller.on_train_created)
script.on_configuration_changed(controller.on_config_change)