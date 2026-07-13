---@class pmdorand.provider.builder<T>
local builder = { data = {} }
builder.__index = builder

function builder:with_id( identifier )
    self.data.id = identifier
    return self
end

do
    local disowner = require 'lib.pmdorand.disown'

    ---@class pmdorand.provider.builder.methods<T> : pmdorand.provider.builder<T>
    local method_builder = {
        builder = {},
        methods = {}
    }

    function method_builder:__index(idx)
        local candidate = rawget(self.builder, idx) or method_builder[idx]
        if candidate then return candidate end
        candidate = builder[idx]
        if type(candidate) == 'function' then
            return disowner(self.builder, function(s, ...)
                self.builder.data.methods = self.methods
                return candidate(s, ...)
            end)
        end
    end

    ---@return pmdorand.provider.builder.methods<T>
    function builder:with_methods()
        if getmetatable(self) == method_builder then return self end
        return setmetatable({builder = self, methods = {}}, method_builder)
    end

    ---@param fn fun(state: pmdorand.state.provider): (fun(): string?)
    function method_builder:iterate_keys(fn)
        self.methods.iterate_keys = fn
        return self
    end

    ---@param fn fun(state: pmdorand.state.provider): integer
    function method_builder:count_keys(fn)
        self.methods.count_keys = fn
        return self
    end

    ---@param fn fun<T>(key: string, state: pmdorand.state.provider): T
    function method_builder:get(fn)
        self.methods.get = fn
        return self
    end

    ---@param fn fun<T>(key: string, data: T, state: pmdorand.state.provider)
    function method_builder:flush(fn)
        self.methods.flush = fn
        return self
    end
end

---@return pmdorand.provider<T>
function builder:build()
    local provider = require 'pmdorand.randomizer.core.provider' .meta.provider

    return setmetatable({
        id = self.data.id,
        methods = self.data.methods or {}
    }, provider)
end

---@return boolean, pmdorand.provider<T>
function builder:register()
    local provider = require 'pmdorand.randomizer.core.provider' .meta.provider

    local out = setmetatable({
        id = self.data.id,
        methods = self.data.methods or {}
    }, provider)

    local success = require 'pmdorand.randomizer.core.registry' .get 'providers' :register(out)
    return success, out
end

---@return pmdorand.provider.builder<any>
return function()
    return setmetatable({ data = {} }, builder)
end