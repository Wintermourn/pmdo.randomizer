local display = require 'pmdorand.randomizer.core.config.display'

return display.builder() --[[@as ConfigDisplayBuilder<Config.Percentage>]]
    :with_title 'Config.Percentage'
    :with_display(function(_structure, value)
        return string.format('%.1f%%', value * 100)
    end)
    :register()