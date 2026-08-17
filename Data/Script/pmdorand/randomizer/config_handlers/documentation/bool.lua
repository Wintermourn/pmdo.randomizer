local documentation = require 'pmdorand.randomizer.core.config.documentation'

local name = STRINGS:FormatKey 'pmdorand:config.bool'
local body = STRINGS:FormatKey 'pmdorand/documentation:config.bool' :match '^%s*(.-)%s*$'

return documentation.builder() --[[@as pmdorand.config.documentation.builder<Config.Boolean>]]
    :with_title 'Config.Boolean'
    :with_documentation(function(_s, _v, _e)
        return {name, body}
    end)
    :register()