return {
    name = "spritehitboxes",
    shortDesc = "Show or hide character sprite hitboxes",
    desc = "Usage: spritehitboxes true|false",
    exec = function(args)
        local value = args[1] and args[1]:lower()
        if value ~= "true" and value ~= "false" then
            return "Usage: spritehitboxes true|false", "ERROR"
        end

        local library = rawget(_G, "LibraryOfBalatro")
        if not library then
            error("lob is not loaded", 0)
        end

        library.show_sprite_hitboxes = value == "true"
        return "Sprite hitboxes " .. (library.show_sprite_hitboxes and "enabled" or "disabled") .. "."
    end
}