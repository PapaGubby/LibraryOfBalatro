local prefix = SMODS.current_mod.prefix

local states = {
    idle = {
        atlas_key = "BackstreetsButcherIdle",
        path = "BackstreetsButcherIdle.png",
        width = 312,
        height = 448,
        content = { x = 4, y = 4, width = 305, height = 439 }
    },
    hurt = {
        atlas_key = "BackstreetsButcherHurt",
        path = "BackstreetsButcherHurt.png",
        width = 366,
        height = 406,
        content = { x = 5, y = 4, width = 356, height = 399 }
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
    name = "BackstreetsButcher",
    team = "Evil",
    display_height = 2.5,
    hitbox = {
        width = 1.4,
        height = 2.4
    },
    states = states
}