local documentation = require 'pmdorand.randomizer.core.config.documentation'
local documentations = require 'pmdorand.randomizer.core.registry' .get 'config.documentation'

local name = STRINGS:FormatKey 'pmdorand:config.feature'
local body = STRINGS:FormatKey 'pmdorand/documentation:config.feature' :match '^%s*(.-)%s*$'

return documentation.builder() --[[@as pmdorand.config.documentation.builder<Config.Feature>]]
    :with_title 'Config.Feature'
    :with_documentation(function(s, v, e)
        return {name, body}, documentations:get 'Config.Boolean' .documentation(s, v, e)
    end)
    :register()