local load_init, err = SMODS.load_file("src/init.lua")
if not load_init then
    error(err)
end

load_init()