local display = require 'pmdorand.randomizer.core.config.display'

local text = '[color=#aaaaaa]>'
return display.builder() --[[@as ConfigDisplayBuilder<Config.Table>]]
    :with_title 'Config.Table'
    :with_display(function(structure, value)
        return text
    end)
    :register()