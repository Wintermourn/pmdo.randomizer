local base = require 'pmdorand.config.base'

---@class Config.Float : Config.Base
---@operator bor(Config.Base): Config.Any
--- Automatic type for tables used in config data.
local float = base.extend("Config.Float")
float.minimum = 0
float.maximum = 50
float.default = 20
float.step_size = 1

---@return integer
function float:get_default_value()
    return self.default
end

function float:clamp_value(v)
    return math.max(self.minimum, math.min(v, self.maximum))
end

function float:validate(t, enforce)
    if type(t) ~= 'number' then return false, ('Value is not integer (got \'%s\')'):format(type(t)) end
    if t % 1 ~= 0 then return false, ('Value is not integer (has decimal)') end
    if enforce then
        local min, max = self.minimum, self.maximum
        if enforce and (t < min or t > max) then print(('Value is outside reasonable bounds (expected [%d, %d], got %f)'):format(min, max, t)) end
    end
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