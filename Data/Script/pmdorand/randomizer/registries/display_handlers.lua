local registries = require 'pmdorand.randomizer.core.registry'

registries.create('config.display', 
    function(obj)
        return type(obj) == 'table' and type(obj.title) == 'string' and type(obj.display) == "function"
    end,
    function(o)
        return o.title
    end,
    {
        title = '',
        display = function() return '' end
    }
)