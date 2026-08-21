local base = require 'pmdorand.config.base'
local tostring_quot = require 'pmdorand.util.string' .tostring_quot

---@class Config.Constant<T> : Config.Base
--- Allows the value to be any of a set of config types.
---@field value T
local const = base.extend("Config.Constant")
const.enforce_limits = true

---@return any
function const:get_default_value()
    return self.value
end


function const:validate(t, enforce)
    if t == self.value or not (self.enforce_limits or enforce) then return true end
    return false, string.format(
        'Value is not valid (expected %s, got %s)',
        tostring_quot(self.value),
        tostring_quot(t)
    )
end

function const:stringify()
    return ("%s"):format( tostring_quot(self.value) )
end

--- Disables enforced value, useful for Variants as they already require a `type` name.
function const:soft()
    return setmetatable({value = self.value, enforce_limits = false}, const)
end

---@param v T
---@return Config.Constant<T>
function const.new(v)
    return setmetatable({value = v}, const)
end

return const.new