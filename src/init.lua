local function load_module(path)
    local load_module_file, err = SMODS.load_file(path)
    if not load_module_file then
        error(err)
    end
    return load_module_file()
end

load_module("src/Balatro/Jokers.lua")

local CharacterUtil = load_module("src/Utility/Character/CharUtil.lua")

local LibraryOfBalatro = {
    CharacterUtil = CharacterUtil,
    ValidCharacters = CharacterUtil.characters,
    SpriteUtil = load_module("src/Characters/SpriteUtil.lua"),
    MovementUtil = load_module("src/Utility/Character/MovementUtil.lua"),
    CharacterController = load_module("src/Characters/CharacterController.lua"),
    Hooks = load_module("src/Hooks.lua"),
    characters = {},
    active_character = nil,
    show_sprite_hitboxes = false
}

function LibraryOfBalatro.create_sprite(character_name, options)
    local character = CharacterUtil.get(character_name)
    if not character then
        return nil, "Unknown character: " .. tostring(character_name)
    end

    options = options or {}
    local team = options.team or character.team or "Nice"
    if type(team) ~= "string" or (team:lower() ~= "nice" and team:lower() ~= "evil") then
        return nil, "Team must be Nice or Evil"
    end
    options.team = team:sub(1, 1):upper() .. team:sub(2):lower()

    if options.x == nil and options.y == nil then
        local mouse_x, mouse_y = LibraryOfBalatro.MovementUtil.mouse_position()
        for _, existing in ipairs(LibraryOfBalatro.characters) do
            if existing.team:lower() ~= options.team:lower() then
                local minimum_gap = (existing.anchor.width +
                    (character.hitbox and character.hitbox.width or character.display_height * 0.55)) / 2 + 0.4
                if math.abs(existing.x - mouse_x) < minimum_gap and
                    math.abs(existing.y - mouse_y) < existing.anchor.height / 2 then
                    mouse_x = existing.x + (options.team == "Evil" and minimum_gap or -minimum_gap)
                    mouse_y = existing.y
                    break
                end
            end
        end
        options.x = mouse_x
        options.y = mouse_y
    end

    local success, controller = pcall(
        LibraryOfBalatro.CharacterController.new,
        character,
        LibraryOfBalatro.SpriteUtil,
        LibraryOfBalatro.MovementUtil,
        options
    )
    if not success then
        return nil, controller
    end

    table.insert(LibraryOfBalatro.characters, controller)
    LibraryOfBalatro.active_character = controller
    LibraryOfBalatro.face_opponents()
    return controller
end

function LibraryOfBalatro.face_opponents()
    for _, character in ipairs(LibraryOfBalatro.characters) do
        local closest
        local closest_distance
        for _, opponent in ipairs(LibraryOfBalatro.characters) do
            if character ~= opponent and character.team:lower() ~= opponent.team:lower() then
                local dx = opponent.x - character.x
                local dy = opponent.y - character.y
                local distance = dx * dx + dy * dy
                if not closest_distance or distance < closest_distance then
                    closest = opponent
                    closest_distance = distance
                end
            end
        end
        if closest and closest.x ~= character.x then
            character:set_facing(closest.x < character.x and "left" or "right")
        end
    end
end

function LibraryOfBalatro.get_active_character(character_name)
    for index = #LibraryOfBalatro.characters, 1, -1 do
        local controller = LibraryOfBalatro.characters[index]
        if not character_name or controller.character_name:lower() == character_name:lower() then
            return controller
        end
    end
    return nil, "lob failed 2 find matching sprite"
end

function LibraryOfBalatro.get_character_names()
    return CharacterUtil.get_names()
end

function LibraryOfBalatro.clear_sprites(character_name)
    if type(character_name) ~= "string" or character_name == "" then
        return nil, "A character name or 'all' is needed"
    end

    local clear_all = character_name:lower() == "all"
    local removed = 0
    for index = #LibraryOfBalatro.characters, 1, -1 do
        local controller = LibraryOfBalatro.characters[index]
        if clear_all or controller.character_name:lower() == character_name:lower() then
            controller:remove()
            table.remove(LibraryOfBalatro.characters, index)
            removed = removed + 1
        end
    end

    if removed == 0 then
        return nil, "No spawned sprites matched '" .. character_name .. "'"
    end

    LibraryOfBalatro.active_character = LibraryOfBalatro.characters[#LibraryOfBalatro.characters]
    return removed
end

_G.LibraryOfBalatro = LibraryOfBalatro
LibraryOfBalatro.Hooks.install(LibraryOfBalatro)

local api_loaded, debugplus_api = pcall(require, "debugplus-api")
if api_loaded and debugplus_api.isVersionCompatible(1) then
    local debugplus = debugplus_api.registerID("LibraryOfBalatro")
    if debugplus then
        for _, command_name in ipairs({
            "createsprite",
            "spritehitboxes",
            "spritedata",
            "editsprite",
            "movesprite",
            "clearsprites"
        }) do
            local load_command, err = SMODS.load_file("Commands/" .. command_name .. ".lua")
            if not load_command then
                error(err)
            end
            debugplus.addCommand(load_command())
        end
    end
end