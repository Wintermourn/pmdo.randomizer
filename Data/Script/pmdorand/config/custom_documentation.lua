local base = require 'pmdorand.config.base'

---@class Config.CustomDocumentation : Config.Base
---@operator bor(Config.Base): Config.Any
---@field config Config.Base
---@field method fun(structure: Config.Base, value: any, entry: pmdorand.config.entry<Config.Base>?): string
local cd = base.extend("Config.CustomDocumentation")

function cd:get_default_value()
    return self.config:get_default_value()
end

function cd:validate(t, enforce)
    return self.config:validate(t, enforce)
end

function cd:stringify(...)
    return self.config:stringify(...)
end

---@return Config.CustomDisplay
function cd.new(setting, method)
    return setmetatable({config = setting, method = method}, cd)
end

return cd.new