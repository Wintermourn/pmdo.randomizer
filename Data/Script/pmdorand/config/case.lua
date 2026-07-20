local base = require 'pmdorand.config.base'

---@class Config.Case : Config.Base
---@operator bor(Config.Case): Config.Variant
---@field key string
---@field config Config.Base
local case = base.extend("Config.Case")

function case:get_default_value()
    return self.config:get_default_value()
end

function case:validate(t, enforce)
    return self.config:validate(t, enforce)
end

function case:stringify(...)
    return string.format('"%s" %s', self.key, tostring(self.config))
end

---@return Config.Case
function case.new(key, setting)
    return setmetatable({config = setting, key = key}, case)
end

return case.new