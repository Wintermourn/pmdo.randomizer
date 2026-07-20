---@class pmdorand.component
---@field step_fn fun(id: string, data: any, state: pmdorand.state.component)
---@field pre_init_step fun(state: pmdorand.state.component)?
---@field pre_pass_step fun(state: pmdorand.state.component)?
---@field post_pass_step fun(state: pmdorand.state.component)?
---@field post_gen_step fun(state: pmdorand.state.component)?
local component = {
    ---@type string
    id = '',
    ---@type string
    provider_id = '',
    ---@type string?
    associated_generator = nil,
    ---@type Config.Feature?
    settings = nil,
    ---@type pmdorand.component.dependency[]
    dependencies = {}
}
component.__index = component

---@enum pmdorand.enum.dependency_conditions
local conditions = {
    BEFORE = 0,
    AFTER = 1,
    INCOMPATIBLE = -1
}

---@class pmdorand.component.dependency
---@field key string
---@field condition pmdorand.enum.dependency_conditions
---@field is_hard boolean

---@param state pmdorand.state.component
function component.log_spoilers(file, state)
    file:write 'NYI'
end

return {
    meta = {
        component = component
    },
    enums = {
        dependency_conditions = conditions
    },
    builder = require 'pmdorand.randomizer.core.component.builder'
}