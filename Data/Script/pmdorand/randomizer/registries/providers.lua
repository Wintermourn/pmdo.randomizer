local registries = require 'pmdorand.randomizer.core.registry'
local provider = require 'pmdorand.randomizer.core.provider'

registries.create('providers', 
    function(obj)
        return type(obj) == 'table' and getmetatable(obj) == provider.meta.provider and obj.id ~= ''
    end,
    function(o)
        return o.id
    end
)