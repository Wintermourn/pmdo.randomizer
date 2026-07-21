local config = require 'pmdorand.config'

---@class pmdorand.component.builder
local builder = { data = {} }
builder.__index = builder

---Sets the identifier of the output component.
function builder:with_id( identifier )
    self.data.id = identifier
    return self
end

---Controls whether the component defaults to being randomized, or not, or having a chance to be.
---@param enabledness boolean|number
function builder:default_enabledness( enabledness )
    self.data.enabledness = enabledness
    return self
end

---Sets the associated pseudorandom generator for the component, allowing easy access in the step function via `state.get_random()`.
function builder:associate_random( identifier )
    self.data.associated_generator = identifier
    return self
end

---Sets the associated provider, an object that passes in game data to be mutated by the step function.
function builder:using_provider( identifier )
    self.data.provider_id = identifier
    return self
end

---Provides a step function to the component, run once for every key provided by a provider. Can be used to mutate game data and mark them as modified and to be saved when finished.
---<br>It is recommended to use *`random:bool(state:get_randomization_chance())`* to support randomly skipping entries or portions of entries.
---@param fn fun(id: string, data: any, state: pmdorand.state.component)
function builder:on_step(fn)
    self.data.step_fn = fn
    return self
end

---Provides a function to be fired before any passes are created.
---@param fn fun(state: pmdorand.state.component)
function builder:pre_init(fn)
    self.data.pre_init_step = fn
    return self
end

---Provides a function to be fired before the pass running this component has started.
---@param fn fun(state: pmdorand.state.component)
function builder:pre_pass(fn)
    self.data.pre_pass_step = fn
    return self
end

---Provides a function to be fired after the pass running this component has finished.
---@param fn fun(state: pmdorand.state.component)
function builder:post_pass(fn)
    self.data.post_pass_step = fn
    return self
end

---Provides a function to be fired after the randomization manager has finished all passes of generation.
---@param fn fun(state: pmdorand.state.component)
function builder:post_generation(fn)
    self.data.post_generation = fn
    return self
end

---Provides a spoiler-logging function to the component, run after all changes have been made. Lines have to be written to the file via `file:write(...)`.
---@param fn fun(file: file, state: pmdorand.state.component)
function builder:log_spoilers(fn)
    self.data.spoiler_fn = fn
    return self
end

---Used to provide configurable settings for the user.
---@see ConfigModule
---@param tbl Config.FromTable
function builder:with_settings(tbl)
    self.data.settings = tbl
    return self
end

---Organizes keys in the settings table to appear in the order specified, and alphabetically otherwise.
---@see pmdorand.component.builder.with_settings
---@param tbl string[]
function builder:sorted_keys(tbl)
    self.data.sorted_settings = tbl
    return self
end

do
    local disowner = require 'lib.pmdorand.disown'

    ---@class pmdorand.component.builder.dependencies : pmdorand.component.builder
    local dependencies_builder = {
        builder = {},
        dependencies = {}
    }

    function dependencies_builder:__index(idx)
        local candidate = rawget(self.builder, idx) or dependencies_builder[idx]
        if candidate then return candidate end
        candidate = builder[idx]
        if type(candidate) == 'function' then
            return disowner(self.builder, function(s, ...)
                self.builder.data.dependencies = self.dependencies
                return candidate(s, ...)
            end)
        end
    end

    ---Enables the dependency builder.
    ---@see pmdorand.component.builder.dependencies
    ---@return pmdorand.component.builder.dependencies
    function builder:with_dependencies()
        if getmetatable(self) == dependencies_builder then return self end
        return setmetatable({builder = self, dependencies = {}}, dependencies_builder)
    end

    do
        ---@class pmdorand.component.builder.dependency : pmdorand.component.builder.dependencies
        local dependency_builder = {
            builder = {},
            key = '',
            ---@type pmdorand.enum.dependency_conditions
            condition = 0,
            is_hard = true
        }

        ---@return any
        function dependency_builder:__index(idx)
            local candidate = rawget(self.builder, idx) or dependency_builder[idx]
            if candidate then return candidate end
            candidate = dependencies_builder[idx]
            if type(candidate) == 'function' then
                return disowner(self.builder, function(s, ...)
                    self.builder.dependencies[self.key] = {key = self.key, condition = self.condition, is_hard = self.is_hard}
                    return candidate(s, ...)
                end)
            end
            candidate = builder[idx]
            if type(candidate) == 'function' then
                return disowner(self.builder.builder, function(s, ...)
                    self.builder.dependencies[self.key] = {key = self.key, condition = self.condition, is_hard = self.is_hard}
                    self.builder.builder.data.dependencies = self.builder.dependencies
                    return candidate(s, ...)
                end)
            end
        end

        ---Starts building a dependency that comes before this component.
        ---@see pmdorand.component.builder.dependency
        ---@param identifier string
        ---@return pmdorand.component.builder.dependency
        function dependencies_builder:before( identifier )
            return setmetatable({builder = self, key = identifier, condition = 0, is_hard = true}, dependency_builder)
        end

        ---Starts building a dependency that comes after this component.
        ---@see pmdorand.component.builder.dependency
        ---@param identifier string
        ---@return pmdorand.component.builder.dependency
        function dependencies_builder:after( identifier )
            return setmetatable({builder = self, key = identifier, condition = 1, is_hard = true}, dependency_builder)
        end

        ---Starts building a dependency that cannot be used with this component.
        ---@see pmdorand.component.builder.dependency
        ---@param identifier string
        ---@return pmdorand.component.builder.dependency
        function dependencies_builder:incompatible_with( identifier )
            return setmetatable({builder = self, key = identifier, condition = -1, is_hard = true}, dependency_builder)
        end

        ---@enum (key) pmdorand.enum.dependency.hardness
        local is_hard = {
            optional = false,
            soft = false,
            required = true,
            hard = true
        }

        ---Configures whether this dependency is required or optional. The default is required.
        ---@param state pmdorand.enum.dependency.hardness
        function dependency_builder:is( state )
            self.is_hard = is_hard[state]
            return self
        end
    end
end

---@return pmdorand.component
function builder:build()
    local component = require 'pmdorand.randomizer.core.component' .meta.component

    local remaining_requirements = {}
    if self.data.id == nil then remaining_requirements[#remaining_requirements+1] = 'an id' end
    if self.data.provider_id == nil then remaining_requirements[#remaining_requirements+1] = 'a provider id' end
    if self.data.step_fn == nil then remaining_requirements[#remaining_requirements+1] = 'a step function' end

    if #remaining_requirements > 0 then
        local reqs = table.concat(remaining_requirements, ', ', 1, #remaining_requirements - 1)
        if #remaining_requirements > 1 then
            reqs = reqs .. (', and %s'):format(remaining_requirements[#remaining_requirements]) 
        end
        error(("component requires %s before building"):format(reqs))
    end

    local settings
    if self.data.settings then
        settings = config.feature(self.data.settings, self.data.enabledness == nil and true or self.data.enabledness, nil)
        if self.data.sorted_settings then
            settings = settings:with_sorted_keys(self.data.sorted_settings)
        end
    end

    local deps = {}
    if self.data.dependencies then
        for i,k in pairs(self.data.dependencies) do
            deps[#deps + 1] = k
        end    
    end

    return setmetatable({
        id = self.data.id,
        provider_id = self.data.provider_id,
        associated_generator = self.data.associated_generator,
        settings = settings,
        step_fn = self.data.step_fn,
        log_spoilers = self.data.spoiler_fn,
        dependencies = deps,

        pre_init_step = self.data.pre_init_step,
        pre_pass_step = self.data.pre_pass_step,
        post_pass_step = self.data.post_pass_step,
        post_gen_step = self.data.post_generation
    }, component)
end

---@return pmdorand.component, boolean
function builder:register()
    local out = self:build()

    local success = require 'pmdorand.randomizer.core.registry' .get 'components' :register(out)
    if success and out.settings then
        require 'pmdorand.randomizer.cache.configurations' .publish(self.data.id, out.settings) 
    end
    return out, success
end

---@return pmdorand.component.builder
return function()
    return setmetatable({ data = {} }, builder)
end