---@class pmdorand.state.component
local component_state = {
    ---@type string
    identifier = ''
}
component_state.__index = component_state

---@return pmdorand.provider<any>
function component_state.get_provider( identifier )
    return require 'pmdorand.randomizer.core.registry' .get 'providers' :get ( identifier )
end

---## Usage
---* `state:get_config( identifier )` gets the configuration for this or another component.
---* `state:get_config()` gets the configuration for this component.
---* `state.get_config()` gets the configuration for the randomizer core.
---@param self pmdorand.state.component
---@return table
function component_state.get_config( self, identifier )
    return require 'pmdorand.randomizer.cache.configurations' .get( identifier or (self and self.identifier) ).options --[[@as table]]
end

function component_state.get_randomization_chance( self, identifier )
    if identifier == nil and self == nil then return 1.00 end
    return require 'pmdorand.randomizer.cache.configurations' .get( identifier or self.identifier ).randomization_chance --[[@as number]]
end

---@return pmdorand.random
function component_state.get_random( self, identifier )
    return require 'pmdorand.randomizer.cache.random' .get_generator( identifier or (self and self.identifier) ) --[[@as pmdorand.random]]
end

local public = {}

---@return pmdorand.state.component
function public.new(id)
    local o = {
        identifier = id
    }

    return setmetatable(o, component_state)
end

return public