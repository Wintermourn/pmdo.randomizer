local display = require 'pmdorand.randomizer.core.config.display'

local text = '[color=#777777]~'
return display.builder() --[[@as ConfigDisplayBuilder<Config.Null>]]
    :with_title 'Config.Null'
    :with_display(function(_structure, _value)
        return text
    end)
    :register()