local setter = require 'pmdorand.randomizer.core.config.setter'

return setter.builder() --[[@as ConfigSetterBuilder<Config.Table>]]
    :with_title 'Config.Table'
    :with_select(function(entry)
        entry:push()
    end)
    :register()