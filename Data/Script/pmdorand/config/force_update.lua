local base = require 'pmdorand.config.base'

---@class Config.ForceUpdate : Config.Base
---@operator bor(Config.Base): Config.Any
---@field config Config.Base
local cd = base.extend("Config.ForceUpdate")

function cd:get_default_value()
    return self.config:get_default_value()
end

function cd:validate(t, enforce)
    return self.config:validate(t, enforce)
end

function cd:stringify(...)
    return self.config:stringify(...)
end

---@return Config.ForceUpdate
function cd.new(setting)
    return setmetatable({config = setting}, cd)
end

return cd.new