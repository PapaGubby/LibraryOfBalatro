return {
    name = "editsprite",
    shortDesc = "Edit character sprite settings",
    desc = "Usage: editsprite <spritename> <Size|State|Facing|X|Y> <value>",
    autocomplete = function(args, argument_index)
        local library = rawget(_G, "LibraryOfBalatro")
        if argument_index == 1 then
            return library and library.get_character_names() or {}
        end
        if argument_index == 2 then
            return { "Size", "State", "Facing", "X", "Y" }
        end
        local character = library and library.CharacterUtil.get(args[1])
        local field = (args[2] or ""):lower()
        if field == "state" and character then
            local states = {}
            for state in pairs(character.states) do
                table.insert(states, state)
            end
            table.sort(states)
            return states
        end
        if field == "facing" then
            return { "Left", "Right" }
        end
        if field == "size" then
            return { "0.5", "1", "1.5", "2" }
        end
        return {}
    end,
    exec = function(args)
        local character_name = args[1]
        local field = args[2] and args[2]:lower()
        local value = args[3]
        if not character_name or not field or not value then
            return "Usage: editsprite <spritename> <Size|State|Facing|X|Y> <value>", "ERROR"
        end

        local library = rawget(_G, "LibraryOfBalatro")
        if not library then
            return "lob is not loaded.", "ERROR"
        end

        local controller, err = library.get_active_character(character_name)
        if not controller then
            return err, "ERROR"
        end

        if field == "size" then
            local size = tonumber(value)
            if not size then
                return "Size must be numeric.", "ERROR"
            end
            local success, size_error = controller:set_size(size)
            if not success then
                return size_error, "ERROR"
            end
            return controller.character_name .. " size set to " .. tostring(controller.size) .. "."
        elseif field == "state" then
            local success, state_error = controller:set_state(value:lower())
            if not success then
                return state_error, "ERROR"
            end
            return controller.character_name .. " state set to " .. controller.state .. "."
        elseif field == "facing" then
            local success, facing_error = controller:set_facing(value:lower())
            if not success then
                return facing_error, "ERROR"
            end
            return controller.character_name .. " facing set to " .. controller.facing .. "."
        elseif field == "x" or field == "y" then
            local coordinate = tonumber(value)
            if not coordinate then
                return field:upper() .. " must be numeric.", "ERROR"
            end
            local x = field == "x" and coordinate or controller.x
            local y = field == "y" and coordinate or controller.y
            local success, position_error = controller:set_position(x, y)
            if not success then
                return position_error, "ERROR"
            end
            library.face_opponents()
            return controller.character_name .. " moved to " .. tostring(controller.x) .. ", " ..
                tostring(controller.y) .. "."
        end

        return "Use Size, State, Facing, X, or Y.", "ERROR"
    end
}