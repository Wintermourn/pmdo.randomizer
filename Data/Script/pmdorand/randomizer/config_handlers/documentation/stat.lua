local documentation = require 'pmdorand.randomizer.core.config.documentation'

local name = STRINGS:FormatKey 'pmdorand:config.stat'
local body = STRINGS:FormatKey 'pmdorand/documentation:config.stat' :match '^%s*(.-)%s*$'

return documentation.builder() --[[@as pmdorand.config.documentation.builder<Config.Stat>]]
    :with_title 'Config.Stat'
    :with_documentation(function(_s, _v, _e)
        return {name, body}
    end)
    :register()