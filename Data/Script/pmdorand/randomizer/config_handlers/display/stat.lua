local display = require 'pmdorand.randomizer.core.config.display'

return display.builder() --[[@as ConfigDisplayBuilder<Config.Stat>]]
    :with_title 'Config.Stat'
    :with_display(function(structure, value)
        return structure.stringify_value(value, true)
    end)
    :register()