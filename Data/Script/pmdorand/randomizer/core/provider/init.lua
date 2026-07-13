local state_cache = require 'pmdorand.randomizer.cache.states'
local async = require 'lib.pmdorand.async'
local __Environment = luanet.import_type 'System.Environment'

---@class pmdorand.provider.guaranteed_key<T>

---@class pmdorand.provider<T>
local provider = {
    ---@type string
    id = '',
    ---@class pmdorand.provider.methods<T>
    ---@field count_keys fun(state: pmdorand.state.provider): integer
    ---@field iterate_keys fun(state: pmdorand.state.provider): (fun(): pmdorand.provider.guaranteed_key<T>?)
    ---@field get fun(key: pmdorand.provider.guaranteed_key<T>, state: pmdorand.state.provider): T
    ---@field get fun(key: string, state: pmdorand.state.provider): T?
    ---@field flush fun(key: string, data: T, state: pmdorand.state.provider)
    methods = {
    }
}
provider.__index = provider

---@param key pmdorand.provider.guaranteed_key<T>
---@param state pmdorand.state.provider
---@overload fun(key: string): (T?)
---@overload fun(key: pmdorand.provider.guaranteed_key<T>): T
function provider:get(key, state)
    state = state or state_cache.provider(self.id)
    return self.methods.get(key, state_cache.provider(self.id))
end

--- Forces the data to be held in cache until the next flush.
---@param key pmdorand.provider.guaranteed_key<T>
---@param state pmdorand.state.provider
---@return T
---@overload fun(key: string): T?
function provider:get_and_cache(key, state)
    state = state or state_cache.provider(self.id)
    local out = state.cache[key]
    if not out then
        out = self.methods.get(key, state_cache.provider(self.id))
        state.cache[key] = out
    end
    return out
end

---@async
function provider:flush_cache()
    local next_pause = __Environment.TickCount64 + 100
    local state = state_cache.provider(self.id)
    for key, object in pairs(state.cache) do
        self.methods.flush(key, object, state)
        if __Environment.TickCount64 > next_pause then
            next_pause = __Environment.TickCount64 + 100
            async.yield()
        end
    end
    state.cache = {}
end

return {
    meta = {
        provider = provider
    },
    builder = require 'pmdorand.randomizer.core.provider.builder'
}