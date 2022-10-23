local navigation_name = "nav-train-signal"

local arithmetic = data.raw["arithmetic-combinator"]["arithmetic-combinator"]

local navigation_entity = {
    type = "arithmetic-combinator",
    name = navigation_name,
    icon = "__train-signal-navigation__/graphics/nav-train-signal.png",
    flags = { "placeable-player", "player-creation" },
    icon_size = 64,
    icon_mipmaps = 8,
    minable = { mining_time = 0.5, result = navigation_name },
    max_health = 150,
    collision_box = { { -0.9, -0.9 }, { 0.9, 0.9 } },
    selection_box = { { -1, -1 }, { 1, 1 } },
    energy_source = { type = "electric", usage_priority = "secondary-input" },
    active_energy_usage = "5KW",
    activity_led_light = { intensity = 0, size = 1, color = { r = 1.0, g = 1.0, b = 1.0 } },
    activity_led_light_offsets = { { 0.2, -0.5 }, { 0.5, -0.1 }, { -0.2, 0.1 }, { -0.4, -0.5 } },
    screen_light = { intensity = 0, size = 0.6, color = { r = 1.0, g = 1.0, b = 1.0 } },
    screen_light_offsets = { { 0.1, -0.3 }, { 0.1, -0.3 }, { 0.1, -0.3 }, { 0.1, -0.3 } },
    input_connection_bounding_box = { { -0.5, 0 }, { 0.5, 1 } },
    output_connection_bounding_box = { { -0.5, -1 }, { 0.5, 0 } },
    input_connection_points = {
        { shadow = { green = { 0.4, 0.7 }, red = { 0.8, 0.7 } }, wire = { green = { -0.3, 0.3 }, red = { 0.3, 0.3 } } }, -- s-n
        { shadow = { green = { -0.3, -0.1 }, red = { -0.3, 0.3 } }, wire = { green = { -0.35, 0.25 }, red = { -0.35, -0.7 } } }, -- w-e
        { shadow = { green = { 0.8, -0.4 }, red = { 0.2, -0.3 } }, wire = { green = { 0.3, -0.65 }, red = { -0.3, -0.65 } } }, -- n-s
        { shadow = { green = { 1.3, 0.3 }, red = { 1.3, -0.1 } }, wire = { green = { 0.38, -0.68 }, red = { 0.38, 0.3 } } } -- e-w
    },
    output_connection_points = {
        { shadow = { green = { 0.4, -0.4 }, red = { 0.8, -0.4 } }, wire = { green = { -0.3, -0.65 }, red = { 0.3, -0.65 } } }, -- s-n
        { shadow = { green = { 1.3, -0.2 }, red = { 1.3, 0.4 } }, wire = { green = { 0.3, 0.3 }, red = { 0.3, -0.65 } } }, -- w-e
        { shadow = { green = { 0.8, 0.7 }, red = { 0.3, 0.7 } }, wire = { green = { 0.3, 0.3 }, red = { -0.3, 0.3 } } }, -- n-s
        { shadow = { green = { -0.1, 0.3 }, red = { -0.1, -0.1 } }, wire = { green = { -0.3, -0.65 }, red = { -0.27, 0.3 } } } -- e-w
    },
    circuit_wire_max_distance = 9
}

--navigation_entity.equal_symbol_sprites = decider.equal_symbol_sprites
--navigation_entity.greater_or_equal_symbol_sprites = decider.greater_or_equal_symbol_sprites
--navigation_entity.greater_symbol_sprites = decider.greater_symbol_sprites
--navigation_entity.less_or_equal_symbol_sprites = decider.less_or_equal_symbol_sprites
--navigation_entity.not_equal_symbol_sprites = decider.not_equal_symbol_sprites
navigation_entity.activity_led_sprites = arithmetic.activity_led_sprites
navigation_entity.and_symbol_sprites = arithmetic.and_symbol_sprites
navigation_entity.divide_symbol_sprites = arithmetic.divide_symbol_sprites
navigation_entity.left_shift_symbol_sprites = arithmetic.left_shift_symbol_sprites
navigation_entity.minus_symbol_sprites = arithmetic.minus_symbol_sprites
navigation_entity.modulo_symbol_sprites = arithmetic.modulo_symbol_sprites
navigation_entity.multiply_symbol_sprites = arithmetic.multiply_symbol_sprites
navigation_entity.or_symbol_sprites = arithmetic.or_symbol_sprites
navigation_entity.plus_symbol_sprites = arithmetic.plus_symbol_sprites
navigation_entity.power_symbol_sprites = arithmetic.power_symbol_sprites
navigation_entity.right_shift_symbol_sprites = arithmetic.right_shift_symbol_sprites
navigation_entity.xor_symbol_sprites = arithmetic.xor_symbol_sprites

navigation_entity.less_symbol_sprites = {
    north = util.draw_as_glow {
        filename = "__train-signal-navigation__/graphics/blank.png",
        x = 15,
        y = 22,
        width = 15,
        height = 11,
        shift = util.by_pixel(0, -4.5),
        hr_version = {
            scale = 0.5,
            filename = "__train-signal-navigation__/graphics/blank.png",
            x = 30,
            y = 44,
            width = 30,
            height = 22,
            shift = util.by_pixel(0, -4.5)
        }
    },
    east = util.draw_as_glow {
        filename = "__train-signal-navigation__/graphics/blank.png",
        x = 15,
        y = 22,
        width = 15,
        height = 11,
        shift = util.by_pixel(0, -13.5),
        hr_version = {
            scale = 0.5,
            filename = "__train-signal-navigation__/graphics/blank.png",
            x = 30,
            y = 44,
            width = 30,
            height = 22,
            shift = util.by_pixel(0, -13.5)
        }
    },
    south = util.draw_as_glow {
        filename = "__train-signal-navigation__/graphics/blank.png",
        x = 15,
        y = 22,
        width = 15,
        height = 11,
        shift = util.by_pixel(0, -4.5),
        hr_version = {
            scale = 0.5,
            filename = "__train-signal-navigation__/graphics/blank.png",
            x = 30,
            y = 44,
            width = 30,
            height = 22,
            shift = util.by_pixel(0, -4.5)
        }
    },
    west = util.draw_as_glow {
        filename = "__train-signal-navigation__/graphics/blank.png",
        x = 15,
        y = 22,
        width = 15,
        height = 11,
        shift = util.by_pixel(0, -13.5),
        hr_version = {
            scale = 0.5,
            filename = "__train-signal-navigation__/graphics/blank.png",
            x = 30,
            y = 44,
            width = 30,
            height = 22,
            shift = util.by_pixel(0, -13.5)
        }
    }
}

navigation_entity.sprites = make_4way_animation_from_spritesheet({ layers = {
    {
        filename = "__train-signal-navigation__/graphics/decider-combinator.png",
        width = 78,
        height = 66,
        frame_count = 1,
        shift = util.by_pixel(0, 7),
        hr_version = {
            scale = 0.5,
            filename = "__train-signal-navigation__/graphics/hr-decider-combinator.png",
            width = 156,
            height = 132,
            frame_count = 1,
            shift = util.by_pixel(0, 7)
        }
    },
    {
        filename = "__train-signal-navigation__/graphics/decider-combinator-shadow.png",
        width = 78,
        height = 76,
        frame_count = 1,
        shift = util.by_pixel(5, 2),
        draw_as_shadow = true,
        hr_version = {
            scale = 0.5,
            filename = "__train-signal-navigation__/graphics/hr-decider-combinator-shadow.png",
            width = 156,
            height = 138,
            frame_count = 1,
            shift = util.by_pixel(5, 2),
            draw_as_shadow = true
        }
    }
}
})

data:extend(
        {
            ---- entity
            navigation_entity,
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