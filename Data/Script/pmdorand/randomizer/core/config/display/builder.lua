---@class pmdorand.config.display.builder<T>
local builder = {data = {}}
builder.__index = builder

---Sets the title of the display handler. This should match some config value's title, or it will never be used.
---@see ConfigModule
---@return self
function builder:with_title( title )
    self.data.title = title
    return self
end

---### Function Returns
---Output should be a string, a string that's returned later (via `Async.Promise`), or nothing.
---@param fn fun(structure: T, value: any): (string|Async.Promise?)
---@return self
function builder:with_display( fn )
    self.data.display = fn
    return self
end

function builder:build()
    return {
        title = self.data.title,
        display = self.data.display
    }
end

function builder:register()
    local out = self:build()

    local success = require 'pmdorand.randomizer.core.registry' .get 'config.display' :register(out)
    return out, success
end

---@return pmdorand.config.display.builder<Config.Base>
return function()
    return setmetatable({data = {}}, builder)
end

---@alias ConfigDisplayBuilder<T> pmdorand.config.display.builder<T>