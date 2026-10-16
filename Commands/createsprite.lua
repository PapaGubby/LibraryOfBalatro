return {
    name = "createsprite",
    shortDesc = "Spawn a character sprite at the mouse",
    desc = "Usage: createsprite <charactername> [Nice|Evil]",
    autocomplete = function(args, argument_index)
        local library = rawget(_G, "LibraryOfBalatro")
        if argument_index == 1 then
            return library and library.get_character_names() or {}
        end
        if argument_index == 2 then
            return { "Nice", "Evil" }
        end
        return {}
    end,
    exec = function(args)
        local character_name = args[1]
        if not character_name then
            return "Usage: createsprite <charactername>", "ERROR"
        end

        local library = rawget(_G, "LibraryOfBalatro")
        if not library or type(library.create_sprite) ~= "function" then
            return "lob is not loaded.", "ERROR"
        end

        local team = args[2]
        local success, controller, err = pcall(library.create_sprite, character_name, { team = team })
        if not success then
            return "Sprite spawn failed: " .. tostring(controller), "ERROR"
        end
        if not controller then
            return "Sprite spawn failed: " .. tostring(err or "unknown error"), "ERROR"
        end
        return controller.character_name .. " spawned in the " .. controller.state .. " state at " ..
            tostring(controller.x) .. ", " .. tostring(controller.y) .. "."
    end
}