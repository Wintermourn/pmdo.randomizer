local setter = require 'pmdorand.randomizer.core.config.setter'
local displays = require 'pmdorand.randomizer.core.registry' .get 'config.display'

local __Input = luanet.namespace 'Microsoft.Xna.Framework.Input'
    local __Keys = __Input.Keys

return setter.builder() --[[@as ConfigSetterBuilder<Config.DynamicInteger>]]
    :with_title 'Config.DynamicInteger'
    :with_move(function(entry, input, delta)
        local lower_bound, upper_bound = entry.setting:get_minimum_value(), entry.setting:get_maximum_value()
        if (entry.value <= lower_bound and delta < 0) or (entry.value >= upper_bound and delta > 0) then return false end

        local --[[@type number]] step = delta > 0 and 1 or -1

        if input:BaseKeyDown(__Keys.LeftShift) then
            local jump_size = entry.setting:get_jump_size()
            step = jump_size and math.floor(jump_size * step + 0.5) or (step * math.ceil((upper_bound - lower_bound) / 10) )
        end
        entry:set(math.min(upper_bound, math.max(lower_bound, entry.value + step)))

        if #entry.texts > 1 then
            entry.texts[2][1] = displays:get 'Config.DynamicInteger' .display(entry.setting, entry.value, entry)
        end
        return true
    end)
    :register()