local registries = require 'pmdorand.randomizer.core.registry'

registries.create('config.documentation', 
    function(obj)
        return type(obj) == 'table' and type(obj.title) == 'string' and type(obj.documentation) == "function"
    end,
    function(o)
        return o.title
    end,
    {
        title = '',
        documentation = function() return end
    }
)