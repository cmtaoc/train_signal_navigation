local tools = require("scripts.tools11")
local debug = tools.debug

local empty_string = "-- Empty --"
local tick_delay = 10
local prefix = "train_signal_navigation"
local class_name = prefix .. "-controller"
local default_pattern = "(signal) (C)"
local controllers
local station_map
local train_map

local state_wait_signal = 0
local state_wait_train = 1
local state_train_in_station = 2

local function get_controllers()
    if controllers then return controllers end

    controllers = {}
    global.controllers = controllers
    station_map = {}
    global.station_map = station_map
    train_map = {}
    global.train_map = train_map
    return controllers
end

local function restore_original_name(controller)
    local station = controller.station
    if station and station.valid then
        local name = controller.org_name
        if name ~= controller.station.backer_name then
            controller.station.backer_name = name
        end
    end
end

local function check_station(controller)

    local station = controller.station
    local entity = controller.entity
    if not entity or not entity.valid then 
        controllers[controller.id] = nil
        return false 
    end

    if not station or not station.valid then

        controller.station = nil
        if controller.station_id then
            station_map[controller.station_id] = nil
            controller.station_id = nil
            controller.station = nil
        end

        local position = entity.position
        local stations = controller.entity.surface.find_entities_filtered {
            position = position,
            radius = 2,
            type = "train-stop"
        }
        if #stations == 0 then 
            debug("no station found")
            return false 
        end

        if #stations ~= 1 then
            debug("Too many train stop around controller")
            return false
        end

        station = stations[1]
        controller.station = station
        controller.org_name = station.backer_name
        controller.station_id = station.unit_number
        controller.current = nil
        controller.state = state_wait_signal
        station_map[controller.station_id] = controller
        -- debug("Found station: " .. station.backer_name)
    end

    return true
end



local function process_controller(controller, group_signals)
    local station = controller.station
    local entity = controller.entity
    local state = controller.state

    if not station then return end

    if state == state_wait_train then
        if station.trains_count == 0 and not station.get_stopped_train() then
            local wait_count = controller.wait_count
            wait_count = wait_count + 1
            controller.wait_count = wait_count
            if wait_count > 10 then
                state = state_wait_signal
                controller.state = state
                controller.current = nil
                -- debug("["..station.unit_number.."] Reschedule train request")
            else
                return
            end
        else
            return
        end
    end

    if state == state_wait_signal then
        if station.trains_count == 0 and not station.get_stopped_train() then

            local signals = group_signals or entity.get_merged_signals(defines.circuit_connector_id.lamp)


            if signals == nil or next(signals) == nil then
                restore_original_name(controller)
                controller.current = nil
                return
            end

            -- debug("["..station.unit_number.."] Process signal: "..string.gsub(serpent.block(signals), "%s", ""))

            local histo = controller.histo
            if not histo then
                histo = {}
                controller.histo = histo
            end

            local found_sprite, found, first
            for _, s in pairs(signals) do
                found_sprite = tools.signal_to_sprite(s.signal)
                if s.count > 0 then
                    if not histo[found_sprite] then
                        histo[found_sprite] = true
                        found = s
                        break
                    elseif not first then
                        first = s
                    end
                end
            end

            if not found then
                if not first then
                    restore_original_name(controller)
                    controller.current = nil
                    return
                end
                found = first
                found_sprite = tools.signal_to_sprite(found.signal)
                histo = {}
                histo[found_sprite] = true
                controller.histo = histo
            end

            if group_signals then
                group_signals[found_sprite] = nil
            end

            local station_name
            if controller.compiled_map then
                station_name = controller.compiled_map[found_sprite]
            end

            -- debug("["..station.unit_number.."] Process station name: "..station_name.. ",sprite_signal=" .. tostring(found_sprite))

            local stations = entity.force.get_train_stops {
                name = station_name,
                surface = entity.surface
            }
            if #stations == 0 then
                -- debug("["..station.unit_number.."] Station not found:" .. station_name)
                return
            end

            if station.backer_name ~= station_name then
                station.backer_name = station_name
            end
            controller.state = state_wait_train
            controller.wait_count = 0
            controller.current = found_sprite
        end
    end
end


local function merge_signals(signal_map, signals)
    if not signals then return signal_map end
    for _, signal in pairs(signals) do
        local signal_name = tools.signal_to_sprite(signal.signal)
        local psignal = signal_map[signal_name]
        if not psignal then
            signal_map[signal_name] = signal
        else
            psignal.count =  psignal.count + signal.count
        end
    end
    return signal_map
end


local function on_ntick()
    if not controllers then return end

    local groups = {}
    local group_histo = global.group_histo
    if not group_histo then
        group_histo = {}
        global.group_histo = group_histo
    end

    for _, controller in pairs(controllers) do

        if check_station(controller) then 
             process_controller(controller)
        end
    end

    for name, group in pairs(groups) do

        for _, controller in pairs(group.controllers) do
            if controller.current then 
                group.signals[controller.current] = nil 
            end
        end

        local histo = group.histo
        for _, controller in pairs(group.controllers) do
            controller.histo = histo
            process_controller(controller, group.signals)
            histo = controller.histo
        end
        group_histo[name] = histo
    end
end

local function on_built(evt)
    local e = evt.created_entity or evt.entity

    if e.name == class_name then
        if not e or not e.valid then return end

        local controllers = get_controllers();

        local id = e.unit_number
        local controller = {id = id, entity = e}

        controllers[id] = controller
        controller.state = state_wait_signal
        controller.entity = e
        
        --debug("create controller:" .. id)
        local tags = evt.tags
        if evt.tags then
            controller.compiled_map = tags.compiled_map and game.json_to_table(tags.compiled_map)
            controller.signal_map = tags.signal_map and game.json_to_table(tags.signal_map)
        end
    end
end

local function on_destroyed(evt)

    local e = evt.entity
    if e.name == class_name then
        if not controllers then return end

        local id = e.unit_number
        local controller = controllers[id]

        restore_original_name(controller)
        controllers[id] = nil
        if controller.station_id then station_map[controller.station_id] = nil end
        if controller.train_id then train_map[controller.train_id] = nil end

        --debug("destroy controller:" .. id)
        if next(controllers, nil) == nil then
            controllers = nil
            station_map = nil
            train_map = nil
            global.controllers = nil
            global.station_map = nil
            global.train_map = nil
            --debug("free controller table")
        end
    end
end

local entity_filter = {{filter = 'name', name = class_name}}

script.on_event(defines.events.on_built_entity, on_built, entity_filter)
script.on_event(defines.events.on_robot_built_entity, on_built, entity_filter)
script.on_event(defines.events.script_raised_built, on_built, entity_filter)
script.on_event(defines.events.script_raised_revive, on_built, entity_filter)

script.on_event(defines.events.on_pre_player_mined_item, on_destroyed, entity_filter)
script.on_event(defines.events.on_robot_pre_mined, on_destroyed, entity_filter)
script.on_event(defines.events.on_entity_died, on_destroyed, entity_filter)
script.on_event(defines.events.script_raised_destroy, on_destroyed,
                entity_filter)

script.on_nth_tick(20, on_ntick)

------------------------------------

local train_trace = false

local train_states = {
    [defines.train_state.on_the_path] = "on_the_path", -- Normal state following the path.
    [defines.train_state.path_lost] = "path_lost", -- Had path and lost it  must stop.
    [defines.train_state.no_schedule] = "no_schedule", -- Doesn't have anywhere to go.
    [defines.train_state.no_path] = "no_path", -- Has no path and is stopped.
    [defines.train_state.arrive_signal] = "arrive_signal", -- Braking before a rail signal.
    [defines.train_state.wait_signal] = "", -- Waiting at a signal.
    [defines.train_state.arrive_station] = "arrive_station", -- before a station.
    [defines.train_state.wait_station] = "wait_station", -- Waiting at a station.
    [defines.train_state.manual_control_stop] = "manual_control_stop", -- Switched to manual control and has to stop.
    [defines.train_state.manual_control] = "manual_control", -- Can move if user explicitly sits in and rides the train.
    [defines.train_state.destination_full] = "destination_full"
}

local function train_info(train)

    local schedule = train.schedule
    return "state=" .. train_states[train.state] ..
               (train.station and (", station=" .. train.station.backer_name) or
                   "") .. ((schedule and #schedule.records > 0) and
               (", schedule=" ..
                   tostring(schedule.records[schedule.current].station)) or "")
end

local function on_train_changed_state(e)

    if not train_map then return end

    local train = e.train
    if train_trace then
        debug("[" .. train.id .. "] on_train_changed_state, old_state=[" ..
                  (e.old_state and train_states[e.old_state] or "") .. "]," ..
                  train_info(train))
    end

    if train.state == defines.train_state.wait_station then
        if train.station then
            local controller = station_map[train.station.unit_number]
            if controller then
                -- debug("["..train.station.unit_number.."] Train arrive => Wait train ")
                controller.state = state_train_in_station
                controller.train_id = train.id
                train_map[controller.train_id] = controller
                restore_original_name(controller)
                return
            end
        end
    end

    local controller = train_map[train.id]
    if controller then
        train_map[train.id] = nil
        controller.train_id = nil
        controller.state = state_wait_signal
        controller.current = nil
        -- debug("["..controller.station.unit_number.."] Train leave => Clear controller  ")
    end
end

script.on_event(defines.events.on_train_changed_state, on_train_changed_state)

------------------------------------

local function on_init() global.controllers = {} end

tools.on_init(on_init)

------------------------------------

local function on_load()
    controllers = global.controllers
    station_map = global.station_map
    train_map = global.train_map
end

tools.on_load(on_load)

------------------------------------

local function on_configuration_changed(data)
    for _, force in pairs(game.forces) do
        local tech = force.technologies['automated-rail-transportation']
        if tech.researched then force.recipes[class_name].enabled = true end
    end
end

script.on_configuration_changed(on_configuration_changed)

------------------------------------
local controller_panel = prefix .. "-panel"

local function gui_clean(player)
    local panel = player.gui.screen[controller_panel]
    if panel then panel.destroy() end
end

local function on_gui_opened(event)

    local player = game.players[event.player_index]
    -- gui_clean(player)

    local entity = event.entity
    if not entity or not entity.valid then return end
    if entity.name ~= class_name then return end

    local controller = controllers[entity.unit_number]
    tools.build_trace = false

    local function get_signals_def()

        local children = {
            {
                type = "label",
                caption = {controller_panel .. ".signal"},
                style_mods = {top_margin = 10, width = 50}
            }, {
                type = "label",
                caption = {controller_panel .. ".upper_limit"},
                style_mods = {top_margin = 10, width = 50}
            }, {
                type = "label",
                caption = {controller_panel .. ".lower_limit"},
                style_mods = {top_margin = 10, width = 50}
            }, {
                type = "label",
                caption = {controller_panel .. ".control"},
                style_mods = {top_margin = 10, width = 50}
            }
        }

        local signal_map = controller.signal_map
        local stops = player.force.get_train_stops()
        local station_names = {}
        local surface = entity.surface
        local duplicates = {}
        for _, station in pairs(stops) do
            if station.surface == surface and not duplicates[station.backer_name] then
                table.insert(station_names, station.backer_name)
                duplicates[station.backer_name] = true
            end
        end
        table.sort(station_names)
        table.insert(station_names, 1, empty_string)

        if not signal_map then signal_map = {} end

        for i = 1, 10 do
            local signal, upper_limit, lower_limit, control
            if i <= #signal_map then
                signal = signal_map[i].signal
                upper_limit = signal_map[i].upper_limit
                lower_limit = signal_map[i].lower_limit
                control = signal_map[i].control
            end
            table.insert(children, {
                type = "choose-elem-button",
                name = "signal-" .. i,
                tooltip = {controller_panel .. ".signal-tooltip"},
                elem_type = "signal",
                signal = signal
            })
             table.insert(children, {
                type = "textfield",
				numeric = true,
                name = "upper_limit-" .. i,
                tooltip = {controller_panel .. ".upper_limit-tooltip"},
				style_mods = {left_margin = 20, right_margin = 20},
				text = upper_limit
            })
			 table.insert(children, {
                type = "textfield",
                name = "lower_limit-" .. i,
				numeric = true,
                tooltip = {controller_panel .. ".lower_limit-tooltip"},
				style_mods = {left_margin = 20, right_margin = 20},
				text = lower_limit
            })
			 table.insert(children, {
                type = "choose-elem-button",
                name = "control-" .. i,
                tooltip = {controller_panel .. ".control-tooltip"},
                elem_type = "signal",
                signal = control
            })
        end
        return children
    end

    local refs = tools.build_gui(player.gui.screen, {
        type = "frame",
        name = controller_panel,
        ref = {"panel"},
        direction = "vertical",
        children = {
            {
                type = "flow",
                direction = "horizontal",
                ref = {"titlebar"},
                children = {
                    {
                        type = "label",
                        style = "frame_title",
                        caption = {controller_panel .. ".title"},
                        ignored_by_interaction = true
                    }, {
                        type = "empty-widget",
                        style = "flib_titlebar_drag_handle",
                        ignored_by_interaction = true
                    }, {
                        type = "sprite-button",
                        style = "frame_action_button",
                        sprite = "utility/close_white",
                        hovered_sprite = "utility/close_black",
                        clicked_sprite = "utility/close_black",
                        name = controller_panel .. ".close"
                    }
                }
            }, {
                type = "frame",
                style = "inside_shallow_frame",
                direction = "vertical",
                style_mods = {padding = 10},
                children = {

                    {
                        type = "table",
                        style_mods = {margin = 10},
                        ref = {controller_panel .. ".signals_table"},
                        column_count = 4,
                        name = "signals_table",
                        children = get_signals_def()
                    }, {
                        type = "button",
                        name = controller_panel .. ".ok",
                        caption = {controller_panel .. ".ok"},
                        style_mods = {top_margin = 10, left_margin = 50}
                    }
                }
            }
        }
    })

    player.opened = refs.panel
    refs.panel.tags = {id = entity.unit_number}
    refs.titlebar.drag_target = refs.panel
    refs.panel.force_auto_center()
end

local function save_controller(player)
    local panel = player.gui.screen[controller_panel]
    local id = panel.tags.id
    local controller = controllers[id]

    local fsignals = tools.get_child(panel, "signals_table")
    local signal_map = {}
    local compiled_map = {}
    for i = 1, 10 do
        local felem = fsignals["signal-" .. i]
        local fupper = fsignals["upper_limit-" .. i]
        local flower = fsignals["lower_limit-" .. i]
        local fcontrol = fsignals["control-" .. i]

        local signal = felem.elem_value
        local upper_limit = fupper.text
        local lower_limit = flower.text
        local control = fcontrol.elem_value

        if signal and upper_limit and lower_limit and control then
            local full_signal = signal
            local full_upper = upper_limit
            local full_lower = lower_limit
            local full_control = control
            table.insert(signal_map,
                         {signal = full_signal, upper_limit = full_upper, lower_limit = full_lower, control = full_control})
            compiled_map[tools.signal_to_sprite(full_signal)] = full_signal
        end
    end
    controller.signal_map = signal_map
    controller.compiled_map = compiled_map
    gui_clean(player)
end

local function on_gui_closed(event)
    local player = game.players[event.player_index]

    if event.element and event.element.name == controller_panel then
        gui_clean(player)
    end
end

local function on_gui_confirmed(event)
    local player = game.players[event.player_index]
    local name = event.element.name
end

tools.on_gui_click(controller_panel .. ".ok", function(e)
    save_controller(game.players[e.player_index])
end)
tools.on_gui_click(controller_panel .. ".close",
                   function(e) gui_clean(game.players[e.player_index]) end)

tools.on_event(defines.events.on_gui_opened, on_gui_opened)
tools.on_event(defines.events.on_gui_confirmed, on_gui_confirmed)
tools.on_event(defines.events.on_gui_closed, on_gui_closed)

------------------------------------

local function on_entity_renamed(e)

    if e.by_script then return end
    if not station_map then return end

    local controller = station_map[e.entity.unit_number]
    if not controller then return end
    if not controllers then return end

    controller.org_name = e.entity.backer_name
    for _, controller in pairs(controllers) do
        if controller.org_name == e.old_name then return end
    end

    global.group_histo[e.old_name] = nil
end

----------------------------------------------

tools.on_event(defines.events.on_entity_renamed, on_entity_renamed)

tools.on_event(defines.events.on_entity_settings_pasted, function(e)

    if not controllers then return end
    local source = controllers[e.source.unit_number]
    local dest = controllers[e.destination.unit_number]
    if not source or not dest then return end

    dest.compiled_map = source.compiled_map
    dest.signal_map = source.signal_map
    

end)
