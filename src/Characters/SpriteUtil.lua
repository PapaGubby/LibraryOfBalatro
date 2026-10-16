local SpriteUtil = {}

function SpriteUtil.create(atlas_key, anchor, layout)
    if not G or not G.ROOM or not G.ROOM_ATTACH then
        error("room is in naught", 2)
    end

    local atlas = SMODS.get_atlas(atlas_key)
    if not atlas then
        error("Sprite atlas not found: " .. tostring(atlas_key), 2)
    end

    local width = layout.width
    local height = layout.height
    if type(width) ~= "number" or type(height) ~= "number" or width <= 0 or height <= 0 then
        error("Sprite dimensions need to b positive", 2)
    end
    if not atlas.py or atlas.py == 0 or math.abs(width / height - atlas.px / atlas.py) > 0.001 or
        math.abs(width / layout.source_width - height / layout.source_height) > 0.001 then
        error("Sprite dimensions should keep the same aspect ratio " .. atlas_key, 2)
    end

    local x = layout.x
    local y = layout.y
    local success, sprite = pcall(SMODS.create_sprite, x, y, width, height, atlas, { x = 0, y = 0 })
    if not success then
        error("Failed to create sprite from atlas " .. atlas_key .. ": " .. tostring(sprite), 2)
    end
    if not sprite or not sprite.states or type(sprite.draw_self) ~= "function" then
        error("SMODS gave an invalid sprite for atlas " .. atlas_key, 2)
    end

    local anchor_x = anchor.moveable.T.x
    local anchor_y = anchor.moveable.T.y
    local image_box = {
        x = x,
        y = y,
        width = width,
        height = height,
        offset_x = x - anchor_x,
        offset_y = y - anchor_y,
        scale = layout.scale,
        source_width = layout.source_width,
        source_height = layout.source_height,
        content = layout.content,
        sprite = sprite
    }

    sprite.draw_self = function(self, overlay)
        if not self.states.visible then
            return
        end
        if self.sprite_pos.x ~= self.sprite_pos_copy.x or self.sprite_pos.y ~= self.sprite_pos_copy.y then
            self:set_sprite_pos(self.sprite_pos)
        end

        prep_draw(self, 1)
        love.graphics.scale(1 / (self.scale.x / self.VT.w), 1 / (self.scale.y / self.VT.h))
        love.graphics.setColor(overlay or G.BRUTE_OVERLAY or G.C.WHITE)
        local scale_x = self.VT.w / self.T.w
        if self.flipped_h then
            scale_x = -scale_x
        end
        love.graphics.draw(
            self.atlas.image,
            self.sprite,
            self.flipped_h and self.atlas.px or 0,
            0,
            0,
            scale_x,
            self.VT.h / self.T.h
        )
        love.graphics.pop()
        add_to_drawhash(self)
        self:draw_boundingrect()
        if self.shader_tab then
            love.graphics.setShader()
        end

        local library = rawget(_G, "LibraryOfBalatro")
        if library and library.show_sprite_hitboxes and self.states.visible then
            prep_draw(self, 1)
            love.graphics.scale(self.VT.w / self.scale.x, self.VT.h / self.scale.y)
            love.graphics.setColor(1, 0, 0, 0.35)
            local hitbox_width = anchor.width / image_box.scale
            local hitbox_height = anchor.height / image_box.scale
            local hitbox_x = image_box.content.x + image_box.content.width / 2 - hitbox_width / 2
            local hitbox_y = image_box.content.y + image_box.content.height - hitbox_height
            love.graphics.rectangle(
                "fill",
                hitbox_x,
                hitbox_y,
                hitbox_width,
                hitbox_height
            )
            love.graphics.pop()
        end
    end

    if not anchor.moveable or not anchor.moveable.T then
        SpriteUtil.remove(sprite)
        error("The sprite anchor is not available", 2)
    end

    local box_success, sprite_box = pcall(UIBox, {
        T = {
            x = x,
            y = y,
            w = width,
            h = height
        },
        definition = {
            n = G.UIT.ROOT,
            config = {
                align = "cm",
                colour = G.C.CLEAR
            },
            nodes = {
                {
                    n = G.UIT.O,
                    config = {
                        object = sprite,
                        w = width,
                        h = height,
                        can_collide = false
                    }
                }
            }
        },
        config = {
            align = "a",
            offset = {
                x = image_box.offset_x,
                y = image_box.offset_y
            },
            major = anchor.moveable
        }
    })
    if not box_success or not sprite_box then
        SpriteUtil.remove(sprite)
        error("Failed to attach sprite to the menu overlay: " .. tostring(sprite_box), 2)
    end

    sprite.states.visible = false
    image_box.ui_box = sprite_box
    table.insert(anchor.image_boxes, image_box)
    sprite.lob_anchor = anchor
    sprite.lob_image_box = image_box
    return sprite, {
        x = x,
        y = y,
        width = width,
        height = height,
        ui_box = sprite_box
    }
end

function SpriteUtil.set_visible(sprite, visible)
    if sprite and sprite.states then
        sprite.states.visible = visible
    end
end

function SpriteUtil.set_facing(sprite, facing)
    if sprite then
        sprite.flipped_h = facing == "right"
        local anchor = sprite.lob_anchor
        local image_box = sprite.lob_image_box
        if anchor and image_box then
            local center_x = image_box.content.x + image_box.content.width / 2
            if sprite.flipped_h then
                center_x = image_box.source_width - center_x
            end
            image_box.x = anchor.x - center_x * image_box.scale
            image_box.offset_x = image_box.x - anchor.moveable.T.x
            image_box.ui_box.role.offset.x = image_box.offset_x
            image_box.ui_box.config.offset.x = image_box.offset_x
            sprite:hard_set_T(image_box.x, image_box.y, image_box.width, image_box.height)
            image_box.ui_box:hard_set_T(image_box.x, image_box.y, image_box.width, image_box.height)
        end
    end
end

function SpriteUtil.remove(sprite)
    if sprite then
        local anchor = sprite.lob_anchor
        if anchor and anchor.image_boxes and sprite.lob_image_box then
            for index = #anchor.image_boxes, 1, -1 do
                if anchor.image_boxes[index] == sprite.lob_image_box then
                    table.remove(anchor.image_boxes, index)
                    break
                end
            end
        end
        local ui_box = sprite.lob_ui_box
        if ui_box and ui_box.remove then
            ui_box:remove()
        end
        if sprite.remove then
            sprite:remove()
        end
    end
end

return SpriteUtil