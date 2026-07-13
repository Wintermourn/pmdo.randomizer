local registries = require 'pmdorand.randomizer.core.registry'
local provider = require 'pmdorand.randomizer.core.provider'

registries.create('providers', 
    function(obj)
        print(type(obj), getmetatable(obj) == provider.meta.provider, obj.id)
        return type(obj) == 'table' and getmetatable(obj) == provider.meta.provider and obj.id ~= ''
    end,
    function(o)
        return o.id
    end
)