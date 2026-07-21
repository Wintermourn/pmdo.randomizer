local display = require 'pmdorand.randomizer.core.config.display'

return display.builder() --[[@as ConfigDisplayBuilder<Config.Float>]]
    :with_title 'Config.Float'
    :with_display(function(_structure, value)
        return string.format('%.4g', value)
    end)
    :register()