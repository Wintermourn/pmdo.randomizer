local create_text = require 'pmdorand.util.create_text'
local play_sound = require 'pmdorand.util.play_sound'
local text_pool = require 'pmdorand.util.text_pool'

local info = {
    title = STRINGS:FormatKey 'pmdorand:tab/archipelago'
}

local state = {
    info = info,
    position = {},
    elements = {},
    lines = {}
}
state.__index = state

function state:entered(menu)
    self.position = {
        cursor = 1,
        height = 0
    }
    ---@type integer, integer
    local mw, mh = menu.menu.Bounds.Width, menu.menu.Bounds.Height
    self.elements.divider.Loc = RogueElements.Loc(10, mh - 20)
    self.elements.divider.Length = menu.menu.Bounds.Width - 20
    self.elements.status.Loc = RogueElements.Loc(math.floor(mw / 2), mh - 17)

    text_pool.hide_all(menu.menu, menu.elements.pool)

    local elements = menu.menu.Elements
    elements:Add(self.elements.divider)
    elements:Add(self.elements.status)

    menu:set_cursor_pos(-10, 0)
end

function state:update(menu, input)

end

function state:left(menu)
    local elements = menu.menu.Elements
    elements:Remove(self.elements.divider)
    elements:Remove(self.elements.status)
    elements:Remove(self.elements.progress)
end

function state:move(menu, dy)
    self.position.cursor = self.position.cursor + dy
    play_sound('Menu/Select', menu.input.sound_volume, math.random() * (1/12) - (1/24))
end

local public = {}
function public.new()
    return setmetatable({
        elements = {
            divider = RogueEssence.Menu.MenuDivider(RogueElements.Loc(10, 0), 1),
            status = create_text(STRINGS:FormatKey 'pmdorand:nyi', 8, 12, RogueElements.DirH.None)
        }
    }, state)
end
return public