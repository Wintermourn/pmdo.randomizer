local base = require 'pmdorand.config.base'

---@class Config.DynamicInteger : Config.Base
---@operator bor(Config.Base): Config.Any
--- Automatic type for tables used in config data.
local int = base.extend("Config.DynamicInt")
int.minimum = 0
int.maximum = 50
int.default = 20
int.should_clamp = false

---@return integer
function int:get_default_value()
    return self.default
end

---@return integer
function int:get_maximum_value()
    return self.maximum
end

---@return integer
function int:get_minimum_value()
    return self.minimum
end

--- ! todo: buh
---@param fn fun(self: self, manager: any): integer
function int:dynamic_default(fn)
    self.get_default_value = fn
    return self
end

--- ! todo: buh
---@param fn fun(self: self, manager: any): integer
function int:dynamic_min(fn)
    self.get_minimum_value = fn
    return self
end

--- ! todo: buh
---@param fn fun(self: self, manager: any): integer
function int:dynamic_max(fn)
    self.get_maximum_value = fn
    return self
end

function int:clamp() self.should_clamp = true; return self end

function int:validate(t, enforce)
    if type(t) ~= 'number' then return false, ('Value is not integer (got \'%s\')'):format(type(t)) end
    if t % 1 ~= 0 then return false, 'Value is not integer (has decimal)' end
    if enforce then
        local min, max = self:get_minimum_value(), self:get_maximum_value()
        if enforce and (t < min or t > max) then print(('Value is outside reasonable bounds (expected [%d, %d], got %f)'):format(min, max, t)) end
    end
    return true
end

function int:stringify()
    return ("[%d, %d] (Default: %d)"):format( self.minimum, self.maximum, self.default )
end

---@return Config.DynamicInteger
function int.new(default, min, max)
    return setmetatable({default = default or 20, minimum = min or 0, maximum = max or 50}, int)
end

return int.new