---@class pmdorand.config.setter.builder<T>
---@field with_title fun(self: self, title: string): self
---@field with_select fun(self: self, fn: fun(entry: pmdorand.config.entry<T>): boolean?): self
---@field with_move fun(self: self, fn: fun(entry: pmdorand.config.entry<T>, input: RogueEssence.InputManager, delta: int): boolean?): self
local builder = {data = {}}
builder.__index = builder

---Sets the title of the display handler. This should match some config value's title, or it will never be used.
---@see ConfigModule
function builder:with_title( title )
    self.data.title = title
    return self
end

---### Function Returns
---Output should be if the call was successful.
function builder:with_select( fn )
    self.data.select = fn
    return self
end

---### Function Parameters
---* structure: should match config values with the same `__title` as the builder.
---* entry: provides important data for changing UI text, setting the value in its original table, and retrieving translation keys.
---* delta: should usually be `-1`, `0`, or `1`. 
---### Function Returns
---Output should be if the call was successful.
---@see Async.Promise
function builder:with_move( fn )
    self.data.move = fn
    return self
end

---@return pmdorand.config.setter<T>
function builder:build()
    return {
        title = self.data.title,
        select = self.data.select,
        move = self.data.move
    }
end

function builder:register()
    local out = self:build()

    local success = require 'pmdorand.randomizer.core.registry' .get 'config.setter' :register(out)
    return out, success
end

---@return pmdorand.config.setter.builder<Config.Base>
return function()
    return setmetatable({data = {}}, builder)
end

---@alias ConfigSetterBuilder<T> pmdorand.config.setter.builder<T>