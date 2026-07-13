local random = require 'pmdorand.randomizer.core.random'

local cache = {
    fallback_generator = {},
    generators = {},
    shape = {},
    seeds = {
        base_seed = '',
        ---@type {[string]: (string|number)?}
        specific_seeds = {}
    }
}

local function resolve_seed( name, shape )
    local candidate = cache.seeds.specific_seeds[name]
    if candidate then return candidate end
    for _i,k in ipairs(shape) do
        candidate = cache.seeds.specific_seeds[k]
        if candidate then return candidate end
    end
    return cache.seeds.base_seed
end

local public = {}

function public.dump()
    cache.generators = {}
end

function public.set_seed( identifier, seed )
    if identifier == nil then
        cache.seeds.base_seed = seed
    elseif seed == nil then
        cache.seeds.base_seed = identifier
    else
        cache.seeds.specific_seeds[identifier] = seed
    end
end

function public.clear_seed( identifier )
    if identifier == nil then
        cache.seeds.base_seed = nil
    else
        cache.seeds.specific_seeds[identifier] = nil
    end
end

function public.get_seed( identifier )
    if identifier == nil then
        return cache.seeds.base_seed
    end
    return resolve_seed(identifier)
end

function public.construct_all()
    cache.fallback_generator = random.new(cache.seeds.base_seed)
    for i in pairs(cache.shape) do
        cache.generators[i] = random.new(resolve_seed(i, cache.shape[i]))
    end
end

function public.get_generator( identifier )
    return cache.generators[identifier] or cache.fallback_generator
end

function public.add_shape( identifier, ... )
    cache.shape[identifier] = {...}
end

return public