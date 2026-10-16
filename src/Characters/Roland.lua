local prefix = SMODS.current_mod.prefix

local states = {
    idle = {
        atlas_key = "RolandCombatIdle",
        path = "RolandCombatIdle.png",
        width = 427,
        height = 520,
        content = { x = 0, y = 5, width = 226, height = 509 }
    },
    moving = {
        atlas_key = "RolandCombatMove",
        path = "RolandCombatMove.png",
        width = 512,
        height = 470,
        content = { x = 0, y = 6, width = 288, height = 461 }
    },
    slash = {
        atlas_key = "RolandCombatSlash",
        path = "RolandCombatSlash.png",
        width = 339,
        height = 594,
        content = { x = 41, y = 5, width = 294, height = 435 }
    }
}

for _, state in pairs(states) do
    SMODS.Atlas {
        key = state.atlas_key,
        path = state.path,
        px = state.width,
        py = state.height
    }
    state.atlas = prefix .. "_" .. state.atlas_key
end

return {
    name = "Roland",
    team = "Nice",
    display_height = 2.5,
    hitbox = {
        width = 1.4,
        height = 2.4
    },
    states = states
}