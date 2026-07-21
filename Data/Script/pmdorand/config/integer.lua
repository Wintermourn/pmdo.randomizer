local base = require 'pmdorand.config.base'

---@class Config.Integer : Config.Base
---@operator bor(Config.Base): Config.Any
---@field jump_size int?
local int = base.extend("Config.Integer")
int.minimum = 0
int.maximum = 50
int.default = 20

---@return integer
function int:get_default_value()
    return self.default
end

function int:clamp_value(v)
    return math.max(self.minimum, math.min(v, self.maximum))
end

function int:validate(t, enforce)
    if type(t) ~= 'number' then return false, ('Value is not integer (got \'%s\')'):format(type(t)) end
    if t % 1 ~= 0 then return false, 'Value is not integer (has decimal)' end
    if enforce then
        local min, max = self.minimum, self.maximum
        if enforce and (t < min or t > max) then print(('Value is outside reasonable bounds (expected [%d, %d], got %f)'):format(min, max, t)) end
    end
    return true
end

function int:stringify()
    return ("[%d, %d] (Default: %d)"):format( self.minimum, self.maximum, self.default )
end

---@return Config.Integer
function int.new(default, min, max, jump)
    return setmetatable({default = default or 20, minimum = min or 0, maximum = max or 50, jump_size = jump}, int)
end

return int.new