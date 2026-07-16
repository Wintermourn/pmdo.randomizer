local base = require 'pmdorand.config.base'

---@class Config.Boolean : Config.Base
--- Automatic type for tables used in config data.
local bool = base.extend("Config.Boolean")
bool.default = false
bool.allow_boolable = false

---@return boolean
function bool:get_default_value()
    return self.default
end

function bool:validate(t)
    local ty = type(t)
    if ty ~= 'boolean' and (ty ~= 'number' or not self.allow_boolable) then 
        return false, ('Value is not booleanable (got \'%s\')'):format(type(t)) 
    end
    return true
end

function bool:stringify()
    return ("(Default: %d)"):format( self.default )
end

--- Enable to allow numbers as a valid value. Can be used to set a chance of true or false.
function bool:permit_boolable(enable)
    self.allow_boolable = enable
    return self
end

---@return Config.Boolean
function bool.new(default)
    return setmetatable({default = default or false}, bool)
end

return bool.new