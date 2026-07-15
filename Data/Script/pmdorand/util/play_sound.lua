local SoundManager = RogueEssence.Content.SoundManager
local IO = luanet.namespace 'System.IO'

return function(se, volume)
    local path = RogueEssence.PathMod.ModPath(RogueEssence.Content.GraphicsManager.SOUND_PATH .. se ..'.ogg')
    if IO.File.Exists(path) then
        SoundManager.PlaySound(path, volume or 1) 
    end
end