return {
    name = "spritedata",
    shortDesc = "Show character sprite settings",
    desc = "Usage: spritedata <spritename>",
    autocomplete = function(args, argument_index)
        if argument_index == 1 then
            local library = rawget(_G, "LibraryOfBalatro")
            return library and library.get_character_names() or {}
        end
        return {}
    end,
    exec = function(args)
        local character_name = args[1]
        if not character_name then
            return "Usage: spritedata <spritename>", "ERROR"
        end

        local library = rawget(_G, "LibraryOfBalatro")
        if not library then
            return "lob is not loaded.", "ERROR"
        end

        local controller, err = library.get_active_character(character_name)
        if not controller then
            return err, "ERROR"
        end

        local data = controller:get_sprite_data()
        local lines = {
            data.name,
            "Size: " .. tostring(data.size),
            "State: " .. data.state,
            "Facing: " .. data.facing,
            "Position: " .. tostring(data.x) .. ", " .. tostring(data.y)
        }
        for _, state_name in ipairs({ "idle", "moving", "slash", "hurt" }) do
            local sprite = data.sprites[state_name]
            if sprite then
                table.insert(lines, state_name .. ": " .. sprite.path .. " (canvas " ..
                    tostring(sprite.width) .. " x " .. tostring(sprite.height) ..
                    ", visible " .. tostring(sprite.visible_width) .. " x " ..
                    tostring(sprite.visible_height) .. ")")
            end
        end
        return table.concat(lines, "\n")
    end
}