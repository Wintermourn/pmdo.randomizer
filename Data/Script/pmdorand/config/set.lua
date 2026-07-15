local base = require 'pmdorand.config.base'
local _set = require 'pmdorand.util.set'

---@class Config.Set : Config.Base
--- Automatic type for tables used in config data.
local set = base.extend("Config.Set")
set.default = {}
---@type string?
set.name = nil

function set:get_default_value()
    return self.default
end

function set:validate(t)
    local entries = {}
    for i,k in ipairs(t) do
        if entries[k] then
            print(string.format('Duplicate entry in set: "%s"', k))
        end
        entries[k] = true
    end
    return true
end

function set:stringify()
    if self.name then return ('"%s"'):format(self.name) end
    return ("[%d]"):format(#self.default)
end

---@return Config.Table
function set:with_name(name)
    return setmetatable({name = name, default = self.default}, set)
end

---@return Config.Table
function set.new(default)
    return setmetatable({default = default}, set)
end

return set.new