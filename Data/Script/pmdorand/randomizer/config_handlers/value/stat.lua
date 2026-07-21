local setter = require 'pmdorand.randomizer.core.config.setter'

return setter.builder() --[[@as ConfigSetterBuilder<Config.Stat>]]
    :with_title 'Config.Stat'
    :with_select(function(entry)
        entry:push()
    end)
    :register()