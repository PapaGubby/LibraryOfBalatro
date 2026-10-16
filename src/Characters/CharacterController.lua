local CharacterController = {}
CharacterController.__index = CharacterController

function CharacterController.new(character, sprite_util, movement_util, options)
    options = options or {}
    local mouse_x, mouse_y = movement_util.mouse_position()
    local size = options.size or 1
    if type(size) ~= "number" or size ~= size or size <= 0 or size > 4 then
        error("Size too big", 2)
    end
    local display_height = character.display_height or 2.5
    local hitbox = character.hitbox or {}
    local x = options.x or mouse_x
    local y = options.y or mouse_y
    local anchor = movement_util.create_anchor(
        x,
        y,
        (hitbox.width or display_height * 0.55) * size,
        (hitbox.height or display_height) * size
    )
    local controller = setmetatable({
        character = character,
        character_name = character.name,
        team = options.team or character.team or "Nice",
        state = "idle",
        facing = "left",
        size = size,
        display_height = display_height,
        x = x,
        y = y,
        anchor = anchor,
        sprites = {},
        hitboxes = {},
        sprite_util = sprite_util,
        movement_util = movement_util
    }, CharacterController)

    local success, err = controller:_replace_sprites(controller.size)
    if not success then
        controller:remove()
        error(err, 2)
    end

    local state_changed, state_error = controller:set_state("idle")
    if not state_changed then
        controller:remove()
        error(state_error, 2)
    end
    controller:set_facing("left")
    return controller
end

function CharacterController:_build_sprites(size)
    local sprites = {}
    local hitboxes = {}

    for state, definition in pairs(self.character.states) do
        local atlas = SMODS.get_atlas(definition.atlas)
        if not atlas or not atlas.px or not atlas.py or atlas.py == 0 then
            return false, "sprite has bad dimensions: " .. tostring(definition.atlas)
        end
        local content = definition.content or {
            x = 0,
            y = 0,
            width = atlas.px,
            height = atlas.py
        }
        if content.width <= 0 or content.height <= 0 or content.x < 0 or content.y < 0 or
            content.x + content.width > atlas.px or content.y + content.height > atlas.py then
            return false, "Sprite bounds are invalid for atlas: " .. tostring(definition.atlas)
        end

        local visible_height = self.display_height * size
        local scale = visible_height / content.height
        local image_width = atlas.px * scale
        local image_height = atlas.py * scale
        local image_x = self.anchor.x - (content.x + content.width / 2) * scale
        local image_y = self.anchor.y - visible_height - content.y * scale
        local success, sprite, hitbox = pcall(
            self.sprite_util.create,
            definition.atlas,
            self.anchor,
            {
                x = image_x,
                y = image_y,
                width = image_width,
                height = image_height,
                scale = scale,
                source_width = atlas.px,
                source_height = atlas.py,
                content = content
            }
        )
        if not success then
            for _, created_sprite in pairs(sprites) do
                self.sprite_util.remove(created_sprite)
            end
            return false, sprite
        end
        sprite.lob_ui_box = hitbox.ui_box
        sprites[state] = sprite
        hitboxes[state] = hitbox
    end

    return true, sprites, hitboxes
end

function CharacterController:_replace_sprites(size)
    local hitbox = self.character.hitbox or {}
    local anchor_width = (hitbox.width or self.display_height * 0.55) * size
    local anchor_height = (hitbox.height or self.display_height) * size
    local old_width = self.anchor.width
    local old_height = self.anchor.height
    self.movement_util.set_anchor(self.anchor, self.x, self.y, anchor_width, anchor_height)

    local success, sprites, hitboxes = self:_build_sprites(size)
    if not success then
        self.movement_util.set_anchor(self.anchor, self.x, self.y, old_width, old_height)
        return false, sprites
    end

    for _, sprite in pairs(self.sprites) do
        self.sprite_util.remove(sprite)
    end
    self.sprites = sprites
    self.hitboxes = hitboxes
    self.size = size

    local state = self.sprites[self.state] and self.state or "idle"
    local state_changed, state_error = self:set_state(state)
    if not state_changed then
        return false, state_error
    end
    self:set_facing(self.facing)
    return true
end

function CharacterController:set_state(state)
    if not self.sprites[state] then
        return false, "Unknown character state: " .. tostring(state)
    end

    self.state = state
    for sprite_state, sprite in pairs(self.sprites) do
        self.sprite_util.set_visible(sprite, sprite_state == state)
    end
    return true
end

function CharacterController:set_facing(facing)
    if facing ~= "left" and facing ~= "right" then
        return false, "Facing gotta b left or right"
    end

    self.facing = facing
    for _, sprite in pairs(self.sprites) do
        self.sprite_util.set_facing(sprite, facing)
    end
    return true
end

function CharacterController:set_position(x, y)
    if type(x) ~= "number" or type(y) ~= "number" then
        return false, "Position needs use numeric values boi"
    end

    local changed = self.x ~= x or self.y ~= y
    self.x = x
    self.y = y
    self.movement_util.set_anchor(self.anchor, x, y, self.anchor.width, self.anchor.height)

    if changed then
        self:set_state("moving")
    end
    return true
end

function CharacterController:set_size(size)
    if type(size) ~= "number" or size ~= size or size <= 0 or size > 4 then
        return false, "Size too big or small lmao"
    end
    if size == self.size then
        return true
    end
    return self:_replace_sprites(size)
end

function CharacterController:get_sprite_data()
    local data = {
        name = self.character_name,
        team = self.team,
        state = self.state,
        facing = self.facing,
        size = self.size,
        x = self.x,
        y = self.y,
        anchor = {
            x = self.anchor.x,
            y = self.anchor.y,
            width = self.anchor.width,
            height = self.anchor.height
        },
        sprites = {}
    }

    for state, definition in pairs(self.character.states) do
        local atlas = SMODS.get_atlas(definition.atlas)
        local content = definition.content or {
            x = 0,
            y = 0,
            width = atlas and atlas.px or 0,
            height = atlas and atlas.py or 0
        }
        local visible_height = self.display_height * self.size
        local scale = content.height > 0 and visible_height / content.height or 0
        data.sprites[state] = {
            atlas = definition.atlas,
            path = definition.path,
            width = atlas and atlas.px * scale or nil,
            height = atlas and atlas.py * scale or nil,
            visible_width = content.width * scale,
            visible_height = visible_height,
            content = content
        }
    end
    return data
end

function CharacterController:remove()
    for _, sprite in pairs(self.sprites) do
        self.sprite_util.remove(sprite)
    end
    self.sprites = {}
    self.hitboxes = {}
    self.movement_util.remove_anchor(self.anchor)
end

return CharacterController