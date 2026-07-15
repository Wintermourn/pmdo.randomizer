local base = require 'pmdorand.config.base'

---@class Config.Any : Config.Base
--- Allows the value to be any of a set of config types.
---@field options Config.Base[]
---@field default Config.Base
local any = base.extend("Config.Any")

---@return any
function any:get_default_value()
    return self.default:get_default_value()
end

function any:validate(t, enforce)
    local temp_res, reason
    for _, entry in ipairs(self.options) do
        temp_res, reason = entry:validate(t, enforce)
        if temp_res == true then
            return true
        end
    end
    local names = {}
    for _, entry in ipairs(self.options) do
        names[#names + 1] = entry:stringify()
    end
    return false, ('value does not fit any possible config types:\n\t\t%s'):format(table.concat(names, '\n\t\t'))
end

function any:stringify()
    return ("(%d Options)"):format( #self.options )
end

---@return Config.Any
function any.new(default, ...)
    return setmetatable({options = {default, ...}, default = default}, any)
end

return any.new