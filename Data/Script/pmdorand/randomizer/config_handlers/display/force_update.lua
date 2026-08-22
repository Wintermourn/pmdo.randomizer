local display = require 'pmdorand.randomizer.core.config.display'
local displays = require 'pmdorand.randomizer.core.registry' .get 'config.display'

return display.builder() --[[@as ConfigDisplayBuilder<Config.ForceUpdate>]]
    :with_title 'Config.ForceUpdate'
    :with_display(function(structure, v, e)
        return displays:get(structure.config.__title).display(structure.config, v, e)
    end)
    :register()