local navigation_name = "nav-train-signal"

data:extend(
        {
            ---- entity
            {
                type = "lamp",
                name = navigation_name,
                energy_source = { type = "electric", usage_priority = "lamp" },
                energy_usage_per_tick = "5KW",
                light = {intensity = 0.9, size = 60, color = {r=0.8, g=1.8, b=0.5}},
                glow_size = 12,
                glow_color_intensity = 1,
                glow_render_mode = "multiplicative",
                icon = "__train-signal-navigation__/graphics/nav-train-signal.png",
                icon_size = 64, icon_mipmaps = 4,
                flags = {"placeable-neutral", "player-creation"},
                minable = {mining_time = 0.1, result = "small-lamp"},
                max_health = 100,
                corpse = "lamp-remnants",
                dying_explosion = "lamp-explosion",
                collision_box = {{-0.15, -0.15}, {0.15, 0.15}},
                selection_box = {{-0.5, -0.5}, {0.5, 0.5}},
                circuit_wire_connection_point = {
                    { shadow = { green = { 0.4, 0.7 }, red = { 0.8, 0.7 } }, wire = { green = { -0.3, 0.3 }, red = { 0.3, 0.3 } } }, -- s-n
                    { shadow = { green = { -0.3, -0.1 }, red = { -0.3, 0.3 } }, wire = { green = { -0.35, 0.25 }, red = { -0.35, -0.7 } } }, -- w-e
                    { shadow = { green = { 0.8, -0.4 }, red = { 0.2, -0.3 } }, wire = { green = { 0.3, -0.65 }, red = { -0.3, -0.65 } } }, -- n-s
                    { shadow = { green = { 1.3, 0.3 }, red = { 1.3, -0.1 } }, wire = { green = { 0.38, -0.68 }, red = { 0.38, 0.3 } } } -- e-w
                },
                circuit_wire_max_distance = 10,
                picture_off =
                {
                    layers =
                    {
                        {
                            filename = "__train-signal-navigation__/graphics/hr-power-switch-off.png",
                            priority = "high",
                            width = 90,
                            height = 60,
                            frame_count = 1,
                            axially_symmetrical = false,
                            direction_count = 1,
                            shift = util.by_pixel(0,3),
                            hr_version =
                            {
                                filename = "__train-signal-navigation__/graphics/hr-power-switch-off.png",
                                priority = "high",
                                width = 150,
                                height = 115,
                                frame_count = 1,
                                axially_symmetrical = false,
                                direction_count = 1,
                                shift = util.by_pixel(0,3),
                                scale = 0.5
                            }
                        },
                        {
                            filename = "__train-signal-navigation__/graphics/hr-power-switch-shadow.png",
                            priority = "high",
                            width = 90,
                            height = 60,
                            frame_count = 1,
                            axially_symmetrical = false,
                            direction_count = 1,
                            shift = util.by_pixel(0,4),
                            draw_as_shadow = true,
                            hr_version =
                            {
                                filename = "__train-signal-navigation__/graphics/hr-power-switch-shadow.png",
                                priority = "high",
                                width = 150,
                                height = 115,
                                frame_count = 1,
                                axially_symmetrical = false,
                                direction_count = 1,
                                shift = util.by_pixel(0, 4),
                                draw_as_shadow = true,
                                scale = 0.5
                            }
                        }
                    }
                },
                picture_on =
                {
                    filename = "__train-signal-navigation__/graphics/hr-power-switch-on.png",
                    priority = "high",
                    width = 90,
                    height = 60,
                    frame_count = 1,
                    axially_symmetrical = false,
                    direction_count = 1,
                    shift = util.by_pixel(0, 4),
                    hr_version =
                    {
                        filename = "__train-signal-navigation__/graphics/hr-power-switch-on.png",
                        priority = "high",
                        width = 150,
                        height = 115,
                        frame_count = 1,
                        axially_symmetrical = false,
                        direction_count = 1,
                        shift = util.by_pixel(0, 4),
                        scale = 0.5
                    }
                },
            },

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
)

--- technology
table.insert(data.raw["technology"]["rail-signals"].effects, { type = "unlock-recipe", recipe = navigation_name })