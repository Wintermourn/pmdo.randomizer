local graphics = require 'pmdorand.util.graphics'

local public = {}

---@param on_cancel function
function public.open(on_cancel, ...)
    local ww, wh = graphics.get_screen_dimensions()
    local options = {...}
    --[[ options[#options + 1] = {'Cancel', true, function()
        _MENU:RemoveMenu()
    end} ]]
    local menu = RogueEssence.Menu.ScriptableSingleStripMenu('PMDORAND_CHOICE', 0, 0, math.floor(ww * 0.3) - 16, options, #options - 1, function()
        on_cancel()
        _MENU:RemoveMenu()
    end)
    menu.Bounds = RogueElements.Rect(ww - 8 - menu.Bounds.Width --[[@as int]], wh - 8 - menu.Bounds.Height --[[@as int]], menu.Bounds.Width, menu.Bounds.Height)
    _MENU:AddMenu(menu, true)
end

return public