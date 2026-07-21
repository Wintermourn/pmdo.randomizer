local setter = require 'pmdorand.randomizer.core.config.setter'
local displays = require 'pmdorand.randomizer.core.registry' .get 'config.display'

local __Input = luanet.namespace 'Microsoft.Xna.Framework.Input'
    local __Keys = __Input.Keys

return setter.builder() --[[@as ConfigSetterBuilder<Config.Percentage>]]
    :with_title 'Config.Percentage'
    :with_move(function(entry, input, delta)
        local --[[@type number]] step = delta
        if (entry.value <= 0 and delta < 0) or (entry.value >= 1 and delta > 0) then return false end
        if input:BaseKeyDown(__Keys.LeftShift) then
            step = step * 5
        elseif input:BaseKeyDown(__Keys.LeftControl) then
            step = step / 10
        end
        entry:set(math.max(0, math.min(1, entry.value + math.floor(step * 10)/1000)))

        if #entry.texts > 1 then
            entry.texts[2][1] = displays:get 'Config.Percentage' .display(entry.setting, entry.value)
        end
        return true
    end)
    :register()