local base = require 'pmdorand.config.base'

---@class Config.Boolean : Config.Base
--- Automatic type for tables used in config data.
local bool = base.extend("Config.Boolean")
bool.default = false

---@return boolean
function bool:get_default_value()
    return self.default
end

function bool:validate(t)
    if type(t) ~= 'boolean' then return false, ('Value is not boolean (got \'%s\')'):format(type(t)) end
    return true
end

function bool:stringify()
    return ("(Default: %d)"):format( self.default )
end

---@return Config.Boolean
function bool.new(default)
    return setmetatable({default = default or false}, bool)
end

return bool.new