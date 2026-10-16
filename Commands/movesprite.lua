return {
    name = "movesprite",
    shortDesc = "Move a character sprite to the mouse",
    desc = "Usage: movesprite <spritename>",
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
            return "Usage: movesprite <spritename>", "ERROR"
        end

        local library = rawget(_G, "LibraryOfBalatro")
        if not library then
            return "lob is not loaded.", "ERROR"
        end

        local controller, err = library.get_active_character(character_name)
        if not controller then
            return err, "ERROR"
        end

        local success, x, y = pcall(library.MovementUtil.mouse_position)
        if not success then
            return "can't find mouse pos": " .. tostring(x), "ERROR"
        end

        local moved, move_error = controller:set_position(x, y)
        if not moved then
            return move_error, "ERROR"
        end
        library.face_opponents()
        return controller.character_name .. " moved to " .. tostring(x) .. ", " .. tostring(y) .. "."
    end
}