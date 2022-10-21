
local function get_input_signal_count(control_behavior, wire_type, signal)
    local circuit_network = control_behavior.get_circuit_network(wire_type, defines.circuit_connector_id.combinator_input)
    if not circuit_network then return 0 end

    return circuit_network.get_signal(signal)
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

local function check_station(station)
    if not station or not station.valid then
        for _, player in pairs(players) do
            player.print("No train stop found.")
        end
        return false
    end
    return true;
end

local function reset_station_name(navigation, station)
    local station_name = navigation.station_name
    if not station_name and station.backer_name ~= station_name then
        station.backer_name = station_name
    end
end

local function exec_navigation(navigation)
    local station = navigation.station
    local has_station = check_station(station)
    if not has_station then return end

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
    if count < 5 then
        count = count +1
        navigation.count = count
        return
    end

    local item = navigation.item
    if not item then
        item = item_map[0]
        navigation.item = item
    end


end

local function on_tick(event)
    for index, navigation in pairs(navigations) do
        if navigation then
            if navigation.entity and navigation.entity.valid then
                exec_navigation(navigation)
            else
                navigations[index] = nil
            end
        end
    end
end