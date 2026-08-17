local documentation = require 'pmdorand.randomizer.core.config.documentation'

local name = STRINGS:FormatKey 'pmdorand:config.percentage'
local body = STRINGS:FormatKey 'pmdorand/documentation:config.percentage' :match '^%s*(.-)%s*$'

return documentation.builder() --[[@as pmdorand.config.documentation.builder<Config.Percentage>]]
    :with_title 'Config.Percentage'
    :with_documentation(function(s, _v, _e)
        return {name, body:format(math.floor((s.default or 0.20) * 100))}
    end)
    :register()