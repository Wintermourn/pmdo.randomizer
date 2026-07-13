---@diagnostic disable: need-check-nil
local provider_state = require 'pmdorand.randomizer.core.states.provider'
local component_state = require 'pmdorand.randomizer.core.states.component'

local cache = {
    providers = {},
    passes = {},
    components = {}
}

local function make_state(source, key)
    local out = _ENV[source ..'_state'].new()
    cache[source ..'s'][key] = out
    return out
end

local state_makers = {
    provider = function(key)
        local out = provider_state.new()
        cache.providers[key] = out
        return out
    end,
    component = function(key)
        local out = component_state.new(key)
        cache.components[key] = out
        return out
    end
}

return {
    ---@return pmdorand.state.provider
    provider = function(key)
        return cache.providers[key] or state_makers.provider(key)
    end,
    ---@return pmdorand.state.component
    component = function(key)
        return cache.components[key] or state_makers.component(key)
    end,
    dump = function()
        cache.providers = {}
        cache.passes = {}
        cache.components = {}
    end
}