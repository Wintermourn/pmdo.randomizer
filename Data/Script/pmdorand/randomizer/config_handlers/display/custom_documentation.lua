local display = require 'pmdorand.randomizer.core.config.display'
local displays = require 'pmdorand.randomizer.core.registry' .get 'config.display'

return display.builder() --[[@as ConfigDisplayBuilder<Config.CustomDocumentation>]]
    :with_title 'Config.CustomDocumentation'
    :with_display(function(structure, v, e)
        return displays:get(structure.config.__title).display(structure, v, e)
    end)
    :register()