local base = require 'pmdorand.config.base'

---@class Config.Floating : Config.Base
--- Automatic type for tables used in config data.
local float = base.extend("Config.Float")
float.minimum = 0
float.maximum = 50
float.default = 20
float.step_size = 1
float.should_clamp = false

---@return integer
function float:get_default_value()
    return self.default
end

function float:clamp() self.should_clamp = true; return self end

function float:validate(t)
    if type(t) ~= 'number' then return false, ('Value is not integer (got \'%s\')'):format(type(t)) end
    return true
end

function float:stringify()
    return ("[%f, %f] (Default: %f, Step: %f)"):format( self.minimum, self.maximum, self.default )
end

---@return Config.Integer
function float.new(default, min, max, step)
    return setmetatable({default = default, minimum = min, maximum = max, step_size = step}, float)
end

return float.new