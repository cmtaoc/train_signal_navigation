local tools = require("scripts.tools")

local controller = {}

local function get_input_signal_count(control_behavior, wire_type, signal)
    local circuit_network = control_behavior.get_circuit_network(wire_type, defines.circuit_connector_id.combinator_input)
    if not circuit_network then return 0 end

    return circuit_network.get_signal(signal)
end

local function out_green_signal(control_behavior, signal)
    control_behavior.set_signal(1, {{type = "virtual", name = "signal_green"}, count = 1})
    control_behavior.set_signal(2, {signal, count = 1})
    navigation.item = nil
end
local function out_red_signal(control_behavior)
    control_behavior.set_signal(1, {{type = "virtual", name = "signal_red"}, count = 1})
    control_behavior.set_signal(2, nil)
    navigation.item = nil
end

local function in_train_stopped(navigation)
    local entity = navigation.entity
    local control_behavior = entity.get_or_create_control_behavior()

    local item = navigation.item
    if not item then
        out_red_signal(control_behavior)
    else
        local need_count = get_input_signal_count(control_behavior, defines.wire_type.green, item.signal)

        if need_count > item.upper_limit then
            out_red_signal(control_behavior)
        end
    end
end

local function get_station(navigation)
    local station = navigation.station
    if not station or not station.valid then
        return station
    end

    local connect_entities = navigation.entity.circuit_connected_entities()
    if connect_entities and connect_entities.red then
        for i, v in pairs(connect_entities.red) do
            tools.debug(v.type .. " -- " .. v.name)
            if v.type == "train-stop" then
                station = v
                navigation.station = station
                return station
            end
        end
    end

    navigation.station = nil
    return nil;
end

local function reset_station_name(navigation, station)
    local station_name = navigation.station_name
    if not station_name and station.backer_name ~= station_name then
        station.backer_name = station_name
    end
end

local function change_station_name(navigation, station, signal)
    local station_name = navigation.station_name
    if not station_name then
        station_name = station.backer_name
    end
    station.backer_name = signal
end

local function exec_navigation(navigation)
    local station = get_station(navigation)
    if not station or not station.valid then
        tools.debug("No train stop found.")
        return
    end

    local item_map = navigation.item_map
    if not item_map or #item_map == 0 then
        reset_station_name(navigation, station)
        return
    end

    local train = station.get_stopped_train()
    if train then
        in_train_stopped(navigation)
        return
    end

    local trains = station.get_train_stop_trains()
    if trains and #trains > 0 then return end

    local count = navigation.count
    if count and count < 5 then
        count = count +1
        navigation.count = count
        return
    end

    navigation.count = 0

    local index = navigation.last
    if not index or index >= #item_map  then
        index = 1
    else
        index = index + 1
    end
    navigation.index = index

    local item = item_map[index]
    navigation.item = item

    if not item then
        reset_station_name(navigation, station)
    end

    local signal = item.signal
    local control_behavior = entity.get_or_create_control_behavior()
    local need_count = get_input_signal_count(control_behavior, defines.wire_type.green, signal)
    if need_count <= item.lower_limit then
        out_green_signal(control_behavior, signal)
        change_station_name(navigation, station, item)
    else
        reset_station_name(navigation, station)
    end
end

controller.exec_navigation = exec_navigation

return controller