local navigation_name = "nav-train-signal"

-- Entity definition
local entity = table.deepcopy(data.raw["lamp"]["small-lamp"])
entity.name = navigation_name
entity.icon = "__train-signal-navigation__/graphics/nav-train-signal.png"
entity.icon_size = 64
entity.icon_mipmaps = 4
entity.picture_off.layers[1].filename = "__train-signal-navigation__/graphics/hr-power-switch-off.png"
entity.picture_off.layers[1].hr_version.filename = "__train-signal-navigation__/graphics/hr-power-switch-off.png"
entity.picture_off.layers[2].hr_version.filename = "__train-signal-navigation__/graphics/hr-power-switch-shadow.png"
entity.active_energy_usage = '1KW'
entity.energy_source = { type = "void" }
entity.render_no_network_icon = false
entity.render_no_power_icon = false

entity.minable = {
    mining_time = 0.1,
    result = navigation_name
}

-- Add all
data:extend {
    entity,
    ---- item
    {
        type = "item",
        name = navigation_name,
        icon = "__train-signal-navigation__/graphics/nav-train-signal.png",
        icon_size = 64,
        stack_size = 50,
        place_result = navigation_name,
        subgroup = "train-transport",
    },

    ---- recipe
    {
        type = 'recipe',
        name = navigation_name,
        enabled = 'false',
        ingredients = {
            { name = "iron-plate", amount = 5 },
            { name = "copper-plate", amount = 5 },
            { name = "electronic-circuit", amount = 5 },
        },
        result = navigation_name,
        energy_required = 5,
        always_show_made_in = true
    }
}

table.insert(data.raw["technology"]["rail-signals"].effects, { type = "unlock-recipe", recipe = navigation_name })

