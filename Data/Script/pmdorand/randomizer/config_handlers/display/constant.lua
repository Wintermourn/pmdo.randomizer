local display = require 'pmdorand.randomizer.core.config.display'
local tostring_quot = require 'pmdorand.util.string' .tostring_quot

return display.builder() --[[@as pmdorand.config.display.builder<Config.Constant<any>>]]
    :with_title 'Config.Constant'
    :with_display(function(structure)
        return tostring_quot(structure.value)
    end)
    :register()