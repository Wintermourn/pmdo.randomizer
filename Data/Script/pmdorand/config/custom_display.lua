local base = require 'pmdorand.config.base'

---@class Config.CustomDisplay : Config.Base
--- Automatic type for tables used in config data.
---@field config Config.Base
---@field method fun(value: any): string
local cd = base.extend("Config.CustomDisplay")

function cd:get_default_value()
    return self.config:get_default_value()
end

function cd:validate(t, enforce)
    return self.config:validate(t, enforce)
end

function cd:stringify(...)
    return self.config:stringify(...)
end

---@return Config.Boolean
function cd.new(setting, method)
    return setmetatable({config = setting, method = method}, cd)
end

return cd.new