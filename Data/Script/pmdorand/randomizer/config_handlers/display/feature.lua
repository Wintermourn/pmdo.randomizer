local display = require 'pmdorand.randomizer.core.config.display'
local displays = require 'pmdorand.randomizer.core.registry' .get 'config.display'

return display.builder() --[[@as ConfigDisplayBuilder<Config.Feature>]]
    :with_title 'Config.Feature'
    :with_display(function(structure, value, entry)
        return displays:get 'Config.Boolean' .display(structure.enabled, value.enabled, entry) ..' [color=#aaaaaa]>'
    end)
    :register()