return {
    name = "clearsprites",
    shortDesc = "Remove spawned character sprites",
    desc = "Usage: clearsprites <spritename|all>",
    autocomplete = function(args, argument_index)
        if argument_index ~= 1 then
            return {}
        end

        local library = rawget(_G, "LibraryOfBalatro")
        local names = library and library.get_character_names() or {}
        table.insert(names, "all")
        return names
    end,
    exec = function(args)
        local character_name = args[1]
        if not character_name then
            return "Usage: clearsprites <spritename|all>", "ERROR"
        end

        local library = rawget(_G, "LibraryOfBalatro")
        if not library or type(library.clear_sprites) ~= "function" then
            return "lob is not loaded.", "ERROR"
        end

        local removed, err = library.clear_sprites(character_name)
        if not removed then
            return err, "ERROR"
        end
        return "Removed " .. tostring(removed) .. " sprite" .. (removed == 1 and "." or "s.")
    end
}