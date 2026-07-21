local display = require 'pmdorand.randomizer.core.config.display'

return display.builder() --[[@as ConfigDisplayBuilder<Config.Integer>]]
    :with_title 'Config.Integer'
    :with_display(function(_structure, value)
        return tostring(value)
    end)
    :register()