local registries = require 'pmdorand.randomizer.core.registry'

registries.create('config.setter', 
    function(obj)
        return type(obj) == 'table' and type(obj.title) == 'string'
    end,
    function(o)
        return o.title
    end
)