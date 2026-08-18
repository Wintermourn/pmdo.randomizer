local display = require 'pmdorand.randomizer.core.config.display'

return display.builder() --[[@as ConfigDisplayBuilder<Config.DynamicInteger>]]
    :with_title 'Config.DynamicInteger'
    :with_display(function(_structure, value)
        return tostring(value)
    end)
    :register()