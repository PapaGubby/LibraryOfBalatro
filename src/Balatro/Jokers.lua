SMODS.Atlas {
    key = "Bullet",
    px = 71,
    py = 95,
    path = "Bullet.png"
}

SMODS.Joker {
    key = "NewJoker",
    config = {
        extra = {
            mult = 4
        }
    },
    loc_vars = function(self, info_queue, card)
        return {
            vars = {
                card.ability.extra.mult
            }
        }
    end,
    calculate = function(self, card, context)
        if context.joker_main then
            return {
                mult = card.ability.extra.mult
            }
        end
    end
}

SMODS.Joker {
    key = "Bullet",
    atlas = "Bullet",
    config = {
        extra = {
            mult = 4
        }
    },
    loc_vars = function(self, info_queue, card)
        return {
            vars = {
                card.ability.extra.mult
            }
        }
    end,
    calculate = function(self, card, context)
        if context.joker_main then
            return {
                mult = card.ability.extra.mult
            }
        end
    end
}