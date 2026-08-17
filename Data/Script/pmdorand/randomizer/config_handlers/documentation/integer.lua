local documentation = require 'pmdorand.randomizer.core.config.documentation'

local name = STRINGS:FormatKey 'pmdorand:config.integer'
local body = STRINGS:FormatKey 'pmdorand/documentation:config.integer' :match '^%s*(.-)%s*$'

return documentation.builder() --[[@as pmdorand.config.documentation.builder<Config.Integer>]]
    :with_title 'Config.Integer'
    :with_documentation(function(s, _v, _e)
        return {name, body:format(s.default, s.minimum, s.maximum)}
    end)
    :register()