local display = require 'pmdorand.randomizer.core.config.display'

return display.builder() --[[@as ConfigDisplayBuilder<Config.CustomDisplay>]]
    :with_title 'Config.CustomDisplay'
    :with_display(function(structure, v)
        return structure.method(v)
    end)
    :register()