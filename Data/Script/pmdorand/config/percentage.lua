local base = require 'pmdorand.config.base'

---@class Config.Percentage : Config.Base
--- Automatic type for tables used in config data.
local per = base.extend("Config.Percent")
per.default = 0.20
per.step_size = 0.01

---@return number
function per:get_default_value()
    return self.default
end

function per:validate(t, enforce)
    if type(t) ~= 'number' then return false, ('Value is not percentage (got \'%s\')'):format(type(t)) end
    if enforce and (t < 0 or t > 1) then print(('Value is outside reasonable bounds (expected [0, 1], got %f)'):format(t)) end
    return true
end

function per:stringify()
    return ("(Default: %f, Step: %f)"):format( self.default, self.step_size )
end

---@return Config.Percentage
function per.new(default, step)
    return setmetatable({default = default or 20, step_size = step or 0.01}, per)
end

return per.new