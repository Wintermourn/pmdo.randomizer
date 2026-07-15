local base = require 'pmdorand.config.base'

---@class Config.Feature : Config.Base
--- Table extension with enabled and randomization chance fields.
---@field enabled Config.Boolean
---@field randomization_chance Config.Percentage
local ftr = base.extend("Config.Feature")
---@type {[string|number]: Config.Base}
ftr.content = {}
---@type string?
ftr.name = nil

local root_mt = {
    __nyamlKeyOrder = {'enabled', 'randomization_chance'}
}
local options_mt = {
    __nyamlType = 'object'
}

---@type {[string]: fun(val): boolean}
local required_fields = {
    enabled = function(val) local ty = type(val); return ty ~= 'boolean' and ty ~= 'number' end,
    randomization_chance = function(val) return type(val) ~= 'number' end
}

function ftr:get_default_value()
    local v = {}
    local root = {options = v}
    for i in pairs(required_fields) do
        root[i] = self[i]:get_default_value()
    end
    local has_fields = false
    for i,k in pairs(self.content) do
        v[i] = k:get_default_value()
        has_fields = true
    end
    if not has_fields then setmetatable(v, options_mt) end
    return setmetatable(root, root_mt)
end

function ftr:validate(t, enforce)
    for i,k in pairs(t) do

        if required_fields[i] and required_fields[i](k) then goto continue end

        if not self.content[i] then
            print('Unknown key for table entry: '.. i)
        end
        
        local child = self.content[i]
        if child ~= nil then
            local res, msg = child:validate(k, enforce)
            -- propagate invalid results
            if res == false then return false, ('Validation failed in table entry \'%s\': "%s"'):format(i, msg) end
        end
        ::continue::

    end
    return true
end

function ftr:stringify()
    if self.name then return ('"%s"'):format(self.name) end
    local samples = ""
    local i = 0
    for k, v in pairs(self.content) do
        if i == 2 or #samples > 30 then samples = samples ..', ... ' break end
        samples = samples .. ("%s%s = %s"):format(i > 0 and ', ' or '', k, tostring(v))
        i = i + 1
    end
    return ("{%s}"):format(samples)
end

---@return Config.Feature
function ftr:with_name(name)
    local o = {name = name, content = self.content}
    for i in pairs(required_fields) do
        o[i] = self[i]
    end
    return setmetatable(o, ftr)
end

---@param table Config.FromTable
---@param default_enabled boolean|number?
---@param default_rate number?
---@return Config.Feature
function ftr.from(default_enabled, default_rate, table)
    if (getmetatable(table) or {}).__title == ftr.__title then return table --[[@as Config.Feature]] end
    local config = require 'pmdorand.config'
    ---@type {[string]: Config.Base}
    local out = {}
    local mtt
    for i,k in pairs(table) do
        if type(k) ~= 'table' then error('Entries in a feature must either be a table or configuration value') end
        if out[i] ~= nil then error('Invalid key in feature: '.. tostring(i)) end
        mtt = getmetatable(k)
        if mtt.is_configuration then
            out[i] = k --[[@as Config.Base]]
        else
            out[i] = config.table(k --[[@as Config.FromTable]])
        end
    end
    if default_enabled == nil then default_enabled = true end
    return setmetatable({enabled = config.boolean(default_enabled):allow_boolable(true), randomization_chance = config.percentage(default_rate or 1.00, 0.01), content = out}, ftr)
end

---@return Config.Feature
function ftr.new(content, default_enabled, default_rate)
    return ftr.from(default_enabled, default_rate, content)
end

return ftr.new