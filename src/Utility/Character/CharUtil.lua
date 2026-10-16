local CharacterUtil = {
    characters = {}
}

for _, character_name in ipairs({ "Roland", "BackstreetsButcher" }) do
    local load_character, err = SMODS.load_file("src/Characters/" .. character_name .. ".lua")
    if not load_character then
        error(err)
    end
    local character = load_character()
    CharacterUtil.characters[character.name:lower()] = character
end

function CharacterUtil.get(character_name)
    if type(character_name) ~= "string" then
        return nil
    end
    return CharacterUtil.characters[character_name:lower()]
end

function CharacterUtil.get_names()
    local names = {}
    for _, character in pairs(CharacterUtil.characters) do
        table.insert(names, character.name)
    end
    table.sort(names)
    return names
end

return CharacterUtil