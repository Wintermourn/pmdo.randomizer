local config = require 'pmdorand.config'

local cache = {
    core = {},
    components = {},
    structures = {
        core = require 'pmdorand.randomizer.core.settings' .structure,
        components = {}
    }
}

local function recursive_build_defaults(output, input)
    for i,k in pairs(input) do
        if k.is_configuration then
            ---@cast k Config.Base
            output[i] = k:get_default_value()
        else
            local o = {}
            recursive_build_defaults(o, k)
            output[i] = o
        end
    end

    return output
end

local function make_default( structure )
    return recursive_build_defaults( {}, structure )
end

local public = {}

---@param structure Config.FromTable
function public.publish( component_id, structure )
    cache.structures.components[component_id] = structure
    cache.components[component_id] = make_default( structure )
end

function public.construct_defaults()
    cache.core = make_default( cache.structures.core )
    for i,k in pairs(cache.structures.components) do
        cache.components[i] = make_default( k )
    end
    return { core = cache.core, components = cache.components }
end

function public.get( identifier )
    print('attempt to get configuration for', tostring(identifier))
    if identifier == nil then return cache.core end
    return cache.components[identifier]
end

return public