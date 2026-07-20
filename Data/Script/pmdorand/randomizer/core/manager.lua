local configuration = require 'pmdorand.randomizer.cache.configurations'
local state_cache = require 'pmdorand.randomizer.cache.states'
local random_cache = require 'pmdorand.randomizer.cache.random'
local pass = require 'pmdorand.randomizer.core.pass'
local components = require 'pmdorand.randomizer.core.registry' .get 'components'

local manager = {
    ---@type string?
    err = nil,
    ---@type boolean
    is_generating = false,
    ---@type pmdorand.pass.manager
    pass_manager = nil,
    ---@type Async.Promise?
    promise = nil,
    subscribers = {
        on_success = {
            by_id = {},
            by_method = {}
        },
        on_failed = {
            by_id = {},
            by_method = {}
        }
    }
}

local public = {
    enum = {
        ---@enum pmdorand.manager.state
        states = {
            NOT_RUN = 0,
            RUNNING = 1,
            FINISHED = 2,
            FAILED = 3
        }
    }
}

function public.get_status()
    return manager.pass_manager and manager.pass_manager.state
end

function public.get_error()
    return manager.err
end

function public.get_state()
    if manager.pass_manager == nil then return 0 end
    if manager.err ~= nil then return 3 end
    if manager.is_generating then return 1 end
    return 2
end

---@return int
---@return int
function public.get_enabled_count()
    local min, max = 0, 0
    local config
    for component_id in configuration.keys() do
        config = configuration.get_master( component_id )
        if config.enabled == true then
            min = min + 1
            max = max + 1
        elseif type(config.enabled) == 'number' and config.enabled > 0 then
            if config.enabled >= 1 then
                min = min + 1
                max = max + 1
            else
                max = max + 1 
            end
        end
    end
    
    return min, max
end

function public.start(dry_run)
    if manager.is_generating then return false end
    state_cache.dump()
    random_cache.construct_all()
    configuration.copy_to_working_path()

    local random = random_cache.get_generator()

    local config
    ---@type pmdorand.component[]
    local active_components = {}
    for component_id in configuration.keys() do
        config = configuration.get_master( component_id )
        if config.enabled == true or (type(config.enabled) == 'number' and random:bool(config.enabled)) then
            local component = components:get( component_id )
            if component.pre_init_step then
                component.pre_init_step(state_cache.component(component_id)) 
            end
            active_components[#active_components + 1] = component
        end
    end

    manager.err = nil
    manager.pass_manager = pass.generate_passes(active_components)
    manager.is_generating = true
    manager.promise = manager.pass_manager:run(configuration.get().personal.log_spoilers, dry_run):on_resolved(function()
        manager.is_generating = false
        for _, component in ipairs(active_components) do
            if component.post_gen_step then
                component.post_gen_step(state_cache.component(component.id)) 
            end
        end
        for _, fn in pairs(manager.subscribers.on_success.by_id) do
            fn()
        end
    end):on_rejected(function(err)
        manager.is_generating = false
        manager.err = err
        for _, fn in pairs(manager.subscribers.on_success.by_id) do
            fn()
        end
    end)
    return true
end

do
    local event = manager.subscribers.on_success
    function public.on_success(fn)
        table.insert(event.by_id, fn)
        event.by_method[fn] = #event.by_id
    end

    function public.off_success(fn)
        local id = event.by_method[fn]
        if id ~= nil then
            event.by_id[id] = nil
            event.by_method[fn] = nil 
        end
    end
end

do
    local event = manager.subscribers.on_failed
    function public.on_failed(fn)
        table.insert(event.by_id, fn)
        event.by_method[fn] = #event.by_id
    end

    function public.off_failed(fn)
        local id = event.by_method[fn]
        if id ~= nil then
            event.by_id[id] = nil
            event.by_method[fn] = nil 
        end
    end
end

return public