local setter = require 'pmdorand.randomizer.core.config.setter'
local displays = require 'pmdorand.randomizer.core.registry' .get 'config.display'

return setter.builder() --[[@as ConfigSetterBuilder<Config.Enum>]]
    :with_title 'Config.Enum'
    :with_move(function(entry, input, delta)
        local idx = entry.setting.values.by_value[entry.value] or 1
        local size = #entry.setting.values.by_index

        local step = delta > 0 and 0 or -2

        idx = (idx + step) % size + 1

        entry:set(entry.setting.values.by_index[idx])
        if #entry.texts > 1 then
            entry.texts[2][1] = displays :get 'Config.Enum' .display(entry.setting, entry.value, entry)
        end

        return true
    end)
    :register()