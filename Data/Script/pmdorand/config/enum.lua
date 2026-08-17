local base = require 'pmdorand.config.base'

---@class Config.Enum : Config.Base
---@operator bor(Config.Base): Config.Any
local enum = base.extend("Config.Enum")
enum.values = {
    by_index = {},
    by_value = {}
}
enum.default = nil

local function reverse(tbl)
    local o = {}
    for i, k in ipairs(tbl) do
        o[k] = i
    end
    return o
end

---@return any
function enum:get_default_value()
    return self.values.by_index[self.default]
end

---@return any
function enum:get_value(idx)
    return self.values.by_index[idx]
end

function enum:validate(t)
    if not self.values.by_index[t] then 
        if not self.values.by_value[t] then return false, ('%s is not a valid choice'):format(tostring(t)) end
    end
    return true
end

function enum:stringify()
    return ("[%d] (Default: '%s')"):format( #self.values.by_index, self.values.by_index[self.default] )
end

---@return Config.Enum
function enum.new(default, values)
    local rev = reverse(values)
    local def_idx = rev[default]
    return setmetatable({default = def_idx, values = {by_index = values, by_value = rev}}, enum)
end

return enum.new