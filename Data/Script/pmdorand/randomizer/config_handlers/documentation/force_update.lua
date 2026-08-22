local documentation = require 'pmdorand.randomizer.core.config.documentation'
local documentations = require 'pmdorand.randomizer.core.registry' .get 'config.documentation'

return documentation.builder() --[[@as pmdorand.config.documentation.builder<Config.ForceUpdate>]]
    :with_title 'Config.ForceUpdate'
    :with_documentation(function(s, v, e)
        return documentations:get(s.config.__title) .documentation(s.config, v, e)
    end)
    :register()