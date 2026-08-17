---@class pmdorand.config.documentation.builder<T>
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
---Output should be any number of string pairs.
---@param fn fun(structure: T, value: any, entry: pmdorand.config.entry<T>?): string[2]...
---@return self
function builder:with_documentation( fn )
    self.data.documentation = fn
    return self
end

function builder:build()
    return {
        title = self.data.title,
        documentation = self.data.documentation
    }
end

function builder:register()
    local out = self:build()

    local success = require 'pmdorand.randomizer.core.registry' .get 'config.documentation' :register(out)
    return out, success
end

---@return pmdorand.config.documentation.builder<Config.Base>
return function()
    return setmetatable({data = {}}, builder)
end

---@alias ConfigDocumentationBuilder<T> pmdorand.config.documentation.builder<T>