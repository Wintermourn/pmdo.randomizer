local gfxman = RogueEssence.Content.GraphicsManager

local public = {}

---@return int
---@return int
function public.get_screen_dimensions()
    return gfxman.ScreenWidth, gfxman.ScreenHeight
end

return public