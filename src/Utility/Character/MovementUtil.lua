local MovementUtil = {}

local function get_scale()
    local scale = G and G.TILESIZE and G.TILESCALE and G.TILESIZE * G.TILESCALE
    if type(scale) ~= "number" or scale <= 0 then
        error("tile size can't b found", 2)
    end
    return scale
end

function MovementUtil.mouse_position()
    local cursor = G and G.CONTROLLER and G.CONTROLLER.cursor_position
    if not cursor or type(cursor.x) ~= "number" or type(cursor.y) ~= "number" then
        error("can't find mouse pos", 2)
    end
    local container = G.ROOM
    if not container or not container.T then
        error("el room is unavailable", 2)
    end

    local scale = get_scale()
    local point = {
        x = cursor.x / scale,
        y = cursor.y / scale
    }
    point_translate(point, {
        x = -container.T.w / 2,
        y = -container.T.h / 2
    })
    point_rotate(point, container.T.r)
    point_translate(point, {
        x = container.T.w / 2 - container.T.x,
        y = container.T.h / 2 - container.T.y
    })
    return point.x, point.y
end

function MovementUtil.create_anchor(x, y, width, height)
    if type(width) ~= "number" or type(height) ~= "number" or width <= 0 or height <= 0 then
        error("Anchor dimensions need to b positive", 2)
    end

    local parent = G.ROOM
    if not parent then
        error("room aint ready", 2)
    end

    local anchor = {
        x = x,
        y = y,
        width = width,
        height = height,
        image_boxes = {}
    }
    anchor.moveable = Moveable {
        T = {
            x = x - width / 2,
            y = y - height,
            w = width,
            h = height
        },
        container = parent
    }
    return anchor
end

function MovementUtil.set_anchor(anchor, x, y, width, height)
    if not anchor or not anchor.moveable or type(anchor.moveable.hard_set_T) ~= "function" then
        error("can't find sprite cuz the anchor is gone", 2)
    end
    if type(width) ~= "number" or type(height) ~= "number" or width <= 0 or height <= 0 then
        error("Anchor dimensions need to b positive", 2)
    end

    anchor.x = x
    anchor.y = y
    anchor.width = width
    anchor.height = height
    anchor.moveable:hard_set_T(x - width / 2, y - height, width, height)
    local anchor_x = x - width / 2
    local anchor_y = y - height
    for _, image_box in ipairs(anchor.image_boxes) do
        image_box.x = anchor_x + image_box.offset_x
        image_box.y = anchor_y + image_box.offset_y
        image_box.sprite:hard_set_T(
            image_box.x,
            image_box.y,
            image_box.width,
            image_box.height
        )
        image_box.ui_box:hard_set_T(
            image_box.x,
            image_box.y,
            image_box.width,
            image_box.height
        )
    end
end

function MovementUtil.remove_anchor(anchor)
    if anchor and anchor.moveable and anchor.moveable.remove then
        anchor.moveable:remove()
        anchor.moveable = nil
    end
end

return MovementUtil