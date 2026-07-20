local base = require 'pmdorand.config.base'

---@class Config.Option : Config.Base
---@operator bor(Config.Base): Config.Any
--- Automatic type for tables used in config data.
local option = base.extend("Config.Option")
option.values = {
    by_index = {},
    by_value = {}
}
option.default = nil

local function reverse(tbl)
    local o = {}
    for i, k in ipairs(tbl) do
        o[k] = i
    end
    return o
end

---@return any
function option:get_default_value()
    return self.values.by_index[self.default]
end

---@return any
function option:get_value(idx)
    return self.values.by_index[idx]
end

function option:validate(t)
    if not self.values.by_index[t] then 
        if not self.values.by_value[t] then return false, ('%s is not a valid choice'):format(tostring(t)) end
    end
    return true
end

function option:stringify()
    return ("[%d] (Default: '%s')"):format( #self.values.by_index, self.values.by_index[self.default] )
end

---@return Config.Option
function option.new(default, values)
    local rev = reverse(values)
    local def_idx = rev[default]
    return setmetatable({default = def_idx, values = {by_index = values, by_value = rev}}, option)
end

return option.new