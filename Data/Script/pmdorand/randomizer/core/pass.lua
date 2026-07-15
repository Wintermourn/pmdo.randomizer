---@diagnostic disable: unnecessary-if

local dependency_condition = require 'pmdorand.randomizer.core.component' .enums.dependency_conditions
local providers = require 'pmdorand.randomizer.core.registry' .get 'providers'
local state_cache = require 'pmdorand.randomizer.cache.states'
local random_cache = require 'pmdorand.randomizer.cache.random'
local async = require 'lib.pmdorand.async'

local __Environment = luanet.import_type 'System.Environment'

---@class pmdorand.pass.manager
---@field promise Async.Promise
---@field state string
local pass_manager = {
    ---@type pmdorand.pass<any>[]
    passes = {},
    ---@type {[string]: integer}
    final_provider_pass = {},
    state = '',
    current_pass = 0
}
pass_manager.__index = pass_manager

function pass_manager:run()
    state_cache.dump()
    self.promise = async.spawn(
        function()
            local pass
            for i = 1, #self.passes do
                self.current_pass = i
                pass = self.passes[i]
                pass:run(self)
                if false == false and self.final_provider_pass[pass.provider.id] == i then
                    self.state = ("Saving [%s]..."):format(pass.provider.id)
                    pass.provider:flush_cache()
                end
            end
            self.state = "Done!"
        end
    )
    return self.promise
end

---@class pmdorand.pass<T>
---@field pass_id integer
---@field provider pmdorand.provider<T>
---@field components pmdorand.component[]
local pass = {}
pass.__index = pass

---@async
---@param manager pmdorand.pass.manager
function pass:run(manager)
    local component_states = {}
    ---@type {[string]: number}
    local iteration_chance = {}
    for _, component in ipairs(self.components) do
        local state = state_cache.component(component.id)
        component_states[component.id] = state
        iteration_chance[component.id] = state:get_randomization_chance()
    end

    local random = random_cache.get_generator()
    local provider = self.provider
    local provider_state = state_cache.provider(provider.id)
    local next_yield = __Environment.TickCount64 + 100
    local get_method = false and provider.get or provider.get_and_cache -- todo: replace false with config value
    local key_count = provider.methods.count_keys(provider_state)
    local digits = #tostring(key_count)
    local pass_template = table.concat({"Pass %d [%s]: %", digits, 'd/%', digits, 'd'})
    local n = 0
    ---@type number
    local ichance
    for identifier in provider.methods.iterate_keys(provider_state) do
        n=n+1
        local data = get_method(provider, identifier, provider_state)
        for _, component in ipairs(self.components) do
            ichance = iteration_chance[component.id]
            if ichance >= 1 or random:bool(ichance) then
                component.step_fn(identifier --[[@as string]], data, component_states[component.id])
            end
        end
        if false == true then
            provider.methods.flush(identifier --[[@as string]], data, provider_state) 
        end
        
        if __Environment.TickCount64 > next_yield then
            manager.state = pass_template:format(self.pass_id, provider.id, n, key_count)
            async.yield()
            next_yield = __Environment.TickCount64 + 100
        end
    end
end

local public = {}

---@param enabled_components pmdorand.component[]
function public.generate_passes(enabled_components)
    local graph, in_degree, by_id, dependencies, final_provider_pass = {}, {}, {}, {}, {}

    for _, component in ipairs(enabled_components) do
        graph[component.id] = {}
        in_degree[component.id] = 0
        by_id[component.id] = component
        dependencies[component.id] = component
    end

    local comp_key, dep_key
    for _, component in ipairs(enabled_components) do
        comp_key = component.id
        for _, dependency in ipairs(component.dependencies) do
            dep_key = dependency.key
            if dependency.condition == dependency_condition.BEFORE then
                table.insert(graph[comp_key], dep_key)
                table.insert(dependencies[dep_key], comp_key)
                in_degree[dep_key] = in_degree[dep_key] + 1 
            else
                table.insert(graph[dep_key], comp_key)
                table.insert(dependencies[comp_key], dep_key)
                in_degree[comp_key] = in_degree[comp_key] + 1
            end
        end
    end

    ---@type pmdorand.component[]
    local sorted, queue = {}, {}

    for id, ct in pairs(in_degree) do
        if ct == 0 then table.insert(queue, id) end
    end

    local current_id
    while #queue > 0 do
        current_id = table.remove(queue, 1)
        table.insert(sorted, by_id[current_id])

        for _, target in ipairs(graph[current_id]) do
            in_degree[target] = in_degree[target] - 1
            if in_degree[target] == 0 then
                table.insert(queue, target)
            end
        end
    end

    if #sorted ~= #enabled_components then
        error "cannot generate passes; circular dependencies in components"
    end

    ---@type pmdorand.pass<any>[]
    local passes, pass_indices = {}, {}

    local min_pass, previous_pass, placed
    for _, component in ipairs(sorted) do
        min_pass = 1

        for _, dependency_id in ipairs(dependencies[component.id]) do
            previous_pass = pass_indices[dependency_id]
            if previous_pass and previous_pass > min_pass then
                min_pass = previous_pass
            end
        end

        placed = false
        for p = min_pass, #passes do
            if passes[p].provider.id == component.provider_id then
                table.insert(passes[p].components, component)
                pass_indices[component.id] = p
                placed = true
                break
            end
        end

        if not placed then
            table.insert(passes, setmetatable({
                pass_id = #passes + 1,
                provider = providers:get(component.provider_id),
                components = { component }
            }, pass))
            final_provider_pass[component.provider_id] = #passes
            pass_indices[component.id] = #passes
        end
    end

    return setmetatable({
        passes = passes,
        final_provider_pass = final_provider_pass,
        current_pass = 0
    }, pass_manager)
end

return public