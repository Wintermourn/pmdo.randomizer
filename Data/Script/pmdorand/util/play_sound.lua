local SoundManager = RogueEssence.Content.SoundManager
local IO = luanet.namespace 'System.IO'

if luanet.ctype(SoundManager):GetMethod("SetBGMPitch") then
    return function(se, volume, pitch)
        local path = RogueEssence.PathMod.ModPath(RogueEssence.Content.GraphicsManager.SOUND_PATH .. se ..'.ogg')
        if IO.File.Exists(path) then
            _GAME:SE(se, volume or 1, pitch)
        end
    end
else
    return function(se, volume, _pitch)
        local path = RogueEssence.PathMod.ModPath(RogueEssence.Content.GraphicsManager.SOUND_PATH .. se ..'.ogg')
        if IO.File.Exists(path) then
            SoundManager.PlaySound(path, volume or 1)
        end
    end
end