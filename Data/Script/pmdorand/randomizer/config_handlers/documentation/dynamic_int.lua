local documentation = require 'pmdorand.randomizer.core.config.documentation'

local name = STRINGS:FormatKey 'pmdorand:config.integer'
local body = STRINGS:FormatKey 'pmdorand/documentation:config.integer' :match '^%s*(.-)%s*$'

return documentation.builder() --[[@as pmdorand.config.documentation.builder<Config.DynamicInteger>]]
    :with_title 'Config.DynamicInteger'
    :with_documentation(function(s, _v, _e)
        return {name, body:format(s:get_default_value(), s:get_minimum_value(), s:get_maximum_value())}
    end)
    :register()