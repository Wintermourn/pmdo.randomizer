---@diagnostic disable: unnecessary-if

local dependency_condition = require 'pmdorand.randomizer.core.component' .enums.dependency_conditions
local providers = require 'pmdorand.randomizer.core.registry' .get 'providers'
local state_cache = require 'pmdorand.randomizer.cache.states'
local random_cache = require 'pmdorand.randomizer.cache.random'
local async = require 'lib.pmdorand.async'

local IO = luanet.namespace 'System.IO'
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

function pass_manager:run(generate_spoilers, dry_run)
    -- Delete spoilers
    local path = IO.Path.Combine(RogueEssence.PathMod.APP_PATH, require 'pmdorand.util.header'.Path, 'Spoilers')
    if IO.Directory.Exists(path) then
        if generate_spoilers then
            for file in luanet.each(IO.Directory.GetFiles(path)) do
                IO.File.Delete(file)
            end
        else
            IO.Directory.Delete(path, true)
        end
    end

    self.promise = async.spawn(
        function()
            local pass
            for i = 1, #self.passes do
                self.current_pass = i
                pass = self.passes[i]
                pass:run(self, generate_spoilers, dry_run)
                if false == false and self.final_provider_pass[pass.provider.id] == i and not dry_run then
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
function pass:run(manager, generate_spoilers, dry_run)
    local spoiler_path = IO.Path.Combine(RogueEssence.PathMod.APP_PATH, require 'pmdorand.util.header'.Path, 'Spoilers')
    if generate_spoilers then
        if not IO.Directory.Exists(spoiler_path) then
            IO.Directory.CreateDirectory(spoiler_path) 
        end
    end

    local component_states = {}
    ---@type {[string]: file}
    local files = {}
    for _, component in ipairs(self.components) do
        local state = state_cache.component(component.id)
        component_states[component.id] = state
        if generate_spoilers then
            files[component.id] = io.open(IO.Path.Combine(spoiler_path, component.id ..'.txt'), 'w')
        end
        if component.pre_pass_step then
            component.pre_pass_step(state) 
        end
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
            component.step_fn(identifier --[[@as string]], data, component_states[component.id])
        end
        if false == true and not dry_run then
            provider.methods.flush(identifier --[[@as string]], data, provider_state) 
        end
        
        if __Environment.TickCount64 > next_yield then
            if dry_run then
                manager.state = 'Dry '.. pass_template:format(self.pass_id, provider.id, n, key_count)
            else
                manager.state = pass_template:format(self.pass_id, provider.id, n, key_count)
            end
            async.yield()
            next_yield = __Environment.TickCount64 + 100
        end
    end

    if generate_spoilers then
        local spoiler_template = "Pass %d [%s]: Spoiling %s ..."
        for _, component in ipairs(self.components) do
            if dry_run then
                manager.state = 'Dry '.. spoiler_template:format(self.pass_id, provider.id, component.id)
            else
                manager.state = spoiler_template:format(self.pass_id, provider.id, component.id)
            end
            local file = files[component.id]
            local state = component_states[component.id]

            component.log_spoilers(file, state)
            if io.type(file) == "file" then
                file:close()
            end
        
            if __Environment.TickCount64 > next_yield then
                if dry_run then
                    manager.state = 'Dry '.. spoiler_template:format(self.pass_id, provider.id, component.id)
                else
                    manager.state = spoiler_template:format(self.pass_id, provider.id, component.id)
                end
                async.yield()
                next_yield = __Environment.TickCount64 + 100
            end
        end
    end

    for _, component in ipairs(self.components) do
        if component.post_pass_step then
            component.post_pass_step(component_states[component.id]) 
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