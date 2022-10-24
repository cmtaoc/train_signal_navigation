local controller = {}
local station_dict = {}

local red_signal = { type = "virtual", name = "signal-red" }
local green_signal = { type = "virtual", name = "signal-green" }

local navigation_name = "nav-train-signal"
local supply_station_out_signal = navigation_name .. "-out-signal"
local supply_station_suffix_name = navigation_name .. "-supply-name"
local supply_station_auto_created = navigation_name .. "-auto-created"

local function print_msg(msg)
    if game then
        for _, player in pairs(game.players) do
            player.print(msg)
        end
    end
end

local function get_input_signal_count(control_behavior, wire_type, signal)
    local circuit_network = control_behavior.get_circuit_network(wire_type, defines.circuit_connector_id.combinator_input)
    if not circuit_network then
        return 0
    end

    return circuit_network.get_signal(signal)
end

local function get_output_parameter(signal, count)
    return {
        first_constant = count,
        second_constant = 0,
        operation = "+",
        output_signal = signal
    }
end

local function in_train_stopped(navigation)
    local entity = navigation.entity
    local control_behavior = entity.get_or_create_control_behavior()

    local item = navigation.item
    if not item then
        control_behavior.parameters = get_output_parameter(red_signal, 1)
    else
        local need_count = get_input_signal_count(control_behavior, defines.wire_type.green, item.signal)

        if need_count > item.upper_limit then
            control_behavior.parameters = get_output_parameter(red_signal, 1)
        end
    end
end

local function get_station(navigation)
    local station = navigation.station
    if station and station.valid then
        return station
    end

    local entity = navigation.entity
    local stations = entity.surface.find_entities_filtered {
        position = entity.position,
        radius = 3,
        type = "train-stop"
    }

    if #stations == 0 then
        print_msg("You must place a station near the controller.")
        return false
    end
    if #stations ~= 1 then
        print_msg("You must place the only station near the controller.")
        return false
    end

    station = stations[1]
    navigation.station = station

    return station;
end

local function reset_station_name(navigation, station)
    local station_name = navigation.station_name
    if station and station_name and station.backer_name ~= station_name then
        station.backer_name = station_name
    end
end

local function get_supply_station_match()
    local supply_station_suffix = settings.global[supply_station_suffix_name].value
    return "^(%b[])" .. supply_station_suffix .. "$"
end

local function on_train_created(event)
    local train = event.train
    local front_movers = train.locomotives.front_movers

    if not front_movers then return end

    local created = settings.global[supply_station_auto_created].value
    if not created then return end

    if train.schedule and train.schedule.records and #train.schedule.records ~= 0 then return end

    local stations = game.get_train_stops()
    local supply_station_match = get_supply_station_match()
    for _, station in pairs(stations) do
        local trains = station.get_train_stop_trains()
        if not trains or #trains == 0 then

            local match_name = string.match(station.backer_name, supply_station_match)
            if match_name then
                local records = {}
                table.insert(records, { station = station.backer_name, wait_conditions = { { type = "full", compare_type = "or" } } })
                table.insert(records, { station = match_name, wait_conditions = { { type = "inactivity", compare_type = "or", ticks = 180 }, { type = "circuit", compare_type = "or", condition = {first_signal = red_signal, constant = 0, comparator = ">"} } } })
                train.schedule = {current = 1, records = records}
                return
            end
        end
    end
end

local function get_station_string_name(signal)
    local entity_name = station_dict[signal.name]

    if entity_name then
        return entity_name
    end

    local stations = game.get_train_stops()
    local supply_station_match = get_supply_station_match()
    for _, station in pairs(stations) do
        local match_name = string.match(station.backer_name, supply_station_match)
        if match_name then
            print_msg("match_name： " .. match_name)
            entity_name = string.match(match_name, "^%[.+=(.+)%]%d*$")
            if entity_name == signal.name then
                print_msg("entity_name： " .. entity_name)
                station_dict[signal.name] = match_name
                return match_name
            end
        end
    end
    return false
end

local function change_station_name(navigation, station, signal)
    local station_name = navigation.station_name
    if not station_name then
        station_name = station.backer_name
        navigation.station_name = station_name
    end

    local change_name = get_station_string_name(signal)
    if change_name then
        station.backer_name = change_name
    end
end

local function exec_navigation(navigation)
    local station = get_station(navigation)
    if not station then
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

    if station.trains_count > 0 then
        return
    end

    local count = navigation.count
    if count and count > 0 and count < 8 then
        count = count + 1
        navigation.count = count
        return
    end

    local index = navigation.last
    if not index or index >= #item_map then
        index = 1
    else
        index = index + 1
    end
    navigation.last = index

    local item = item_map[index]
    navigation.item = item

    if not item then
        reset_station_name(navigation, station)
    end

    local signal = item.signal
    local control_behavior = navigation.entity.get_or_create_control_behavior()
    local need_count = get_input_signal_count(control_behavior, defines.wire_type.green, signal)

    if need_count <= item.lower_limit then
        navigation.count = 1
        local is_green = settings.global[supply_station_out_signal].value
        if is_green then
            control_behavior.parameters = get_output_parameter(green_signal, index)
        else
            control_behavior.parameters = get_output_parameter(signal, 1)
        end

        change_station_name(navigation, station, signal)
    else
        navigation.count = 0
        control_behavior.parameters = get_output_parameter(nil, 0)
        reset_station_name(navigation, station)
    end
end

controller.exec_navigation =  function()
    print_msg("B模式")
end
controller.on_train_created = function()
    print_msg("B模式")
end

return controller