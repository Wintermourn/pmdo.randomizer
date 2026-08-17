local play_sound = require 'pmdorand.util.play_sound'
local text_pool = require 'pmdorand.util.text_pool'

local info = {
    title = STRINGS:FormatKey 'pmdorand:tab/settings'
}

local state = {
    info = info,
    position = {},
    lines = {}
}
state.__index = state

function state:entered(menu)
    self.position = {
        cursor = 1,
        height = 0
    }

    text_pool.hide_all(menu.menu, menu.elements.pool)
end

function state:update(menu, input)

end

function state:left(menu) end

function state:move(menu, dy)
    self.position.cursor = self.position.cursor + dy
    play_sound('Menu/Select', menu.input.sound_volume, math.random() * (1/12) - (1/24))
end

local public = {}
function public.new()
    return setmetatable({}, state)
end
return public