local Hooks = {
    installed = false
}

local function is_team(character, team)
    return character.team and character.team:lower() == team
end

local function find_combat_pair(characters)
    for _, attacker in ipairs(characters) do
        if is_team(attacker, "nice") and attacker.sprites.moving and attacker.sprites.slash then
            for _, victim in ipairs(characters) do
                if is_team(victim, "evil") and victim ~= attacker and victim.sprites.hurt then
                    return attacker, victim
                end
            end
        end
    end
end

local function begin_combat(characters)
    local attacker, victim = find_combat_pair(characters)
    if not attacker then
        return nil
    end

    local dx = victim.x - attacker.x
    local gap = math.max(
        0.35,
        (attacker.display_height * attacker.size + victim.display_height * victim.size) * 0.22
    )
    local combat = {
        attacker = attacker,
        victim = victim,
        original_x = attacker.x,
        original_y = attacker.y,
        original_facing = attacker.facing,
        original_state = attacker.state,
        victim_facing = victim.facing,
        target_x = victim.x - (dx >= 0 and gap or -gap),
        target_y = victim.y,
        phase = "approach",
        elapsed = 0,
        duration = 0.7
    }

    attacker:set_facing(dx >= 0 and "right" or "left")
    attacker:set_state("moving")
    victim:set_facing(dx >= 0 and "left" or "right")
    return combat
end

local function ease(progress)
    return progress * progress * (3 - 2 * progress)
end

local function update_combat(combat, dt, is_playing_hand)
    combat.elapsed = combat.elapsed + dt
    local progress = math.min(combat.elapsed / combat.duration, 1)
    local eased = ease(progress)
    local attacker = combat.attacker

    if combat.phase == "approach" then
        attacker:set_position(
            combat.original_x + (combat.target_x - combat.original_x) * eased,
            combat.original_y + (combat.target_y - combat.original_y) * eased
        )
        attacker:set_state("moving")
        if progress >= 1 then
            attacker:set_position(combat.target_x, combat.target_y)
            combat.phase = "windup"
            combat.elapsed = 0
            combat.duration = 1
        end
    elseif combat.phase == "windup" then
        attacker:set_position(combat.target_x, combat.target_y)
        attacker:set_state("moving")
        if progress >= 1 then
            attacker:set_state("slash")
            combat.victim:set_state("hurt")
            combat.phase = "strike"
            combat.elapsed = 0
            combat.duration = 1
        end
    elseif combat.phase == "strike" then
        if progress >= 1 then
            combat.victim:set_state("idle")
            attacker:set_state("moving")
            combat.phase = "retreat"
            combat.elapsed = 0
            combat.duration = 0.7
        end
    elseif combat.phase == "retreat" then
        attacker:set_position(
            combat.target_x + (combat.original_x - combat.target_x) * eased,
            combat.target_y + (combat.original_y - combat.target_y) * eased
        )
        attacker:set_state("moving")
        if progress >= 1 then
            attacker:set_position(combat.original_x, combat.target_y)
            attacker:set_facing(combat.original_facing)
            attacker:set_state(is_playing_hand and "moving" or combat.original_state)
            combat.victim:set_facing(combat.victim_facing)
            combat.victim:set_state(combat.victim_state)
            return nil
        end
    end
    return combat
end

function Hooks.install(library)
    if Hooks.installed then
        return true
    end
    if not Game or type(Game.update) ~= "function" then
        error("can't install hooks the game might js b broken bro")
    end

    local game_update = Game.update
    local was_playing_hand = false
    local combat = nil
    Game.update = function(self, dt)
        local result = game_update(self, dt)
        local stage = G and G.STAGE
        local stages = G and G.STAGES
        local states = G and G.STATES
        local is_playing_hand = stage and stages and states and
            stage == stages.RUN and G.STATE == states.HAND_PLAYED

        if is_playing_hand and not was_playing_hand then
            combat = begin_combat(library.characters)
        end
        was_playing_hand = is_playing_hand

        if combat then
            combat = update_combat(combat, math.max(tonumber(dt) or 0, 0), is_playing_hand)
        end

        for _, character in ipairs(library.characters) do
            if is_team(character, "nice") and (not combat or character ~= combat.attacker) then
                local desired_state = is_playing_hand and "moving" or "idle"
                if character.sprites[desired_state] and character.state ~= desired_state then
                    character:set_state(desired_state)
                end
            end
        end

        return result
    end

    Hooks.installed = true
    return true
end

return Hooks