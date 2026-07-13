local registries = require 'pmdorand.randomizer.core.registry'
local component = require 'pmdorand.randomizer.core.component'


registries.create('components', 
    function(obj)
        print(type(obj), getmetatable(obj) == component.meta.component, obj.id)
        return type(obj) == 'table' and getmetatable(obj) == component.meta.component and obj.id ~= '' and obj.provider_id ~= ''
    end,
    function(o)
        return o.id
    end
)