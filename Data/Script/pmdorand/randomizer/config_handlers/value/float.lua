local setter = require 'pmdorand.randomizer.core.config.setter'
local displays = require 'pmdorand.randomizer.core.registry' .get 'config.display'

local __Input = luanet.namespace 'Microsoft.Xna.Framework.Input'
    local __Keys = __Input.Keys

return setter.builder() --[[@as ConfigSetterBuilder<Config.Float>]]
    :with_title 'Config.Float'
    :with_move(function(entry, input, delta)
        local lower_bound, upper_bound = entry.setting.minimum, entry.setting.maximum
        if (entry.value <= lower_bound and delta < 0) or (entry.value >= upper_bound and delta > 0) then return false end

        local --[[@type number]] step = delta * entry.setting.step_size

        if input:BaseKeyDown(__Keys.LeftShift) then
            step = step * 5
        elseif input:BaseKeyDown(__Keys.LeftControl) then
            step = step / 10
        end
        entry:set(math.min(upper_bound, math.max(lower_bound, entry.value + step)))

        if #entry.texts > 1 then
            entry.texts[2][1] = displays:get 'Config.Float' .display(entry.setting, entry.value)
        end
        return true
    end)
    :register()