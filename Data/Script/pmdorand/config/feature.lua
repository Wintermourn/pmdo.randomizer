local config = require 'pmdorand.config'
local base = require 'pmdorand.config.base'

---@class Config.Feature : Config.Base
---@operator bor(Config.Base): Config.Any
--- Table extension with enabled and randomization chance fields.
---@field enabled Config.Boolean
---@field randomization_chance Config.Percentage
---@field sorted_keys {[string]: integer}?
---@field ordered_keys string[]
local ftr = base.extend("Config.Feature")
---@type Config.Table
ftr.options = nil
---@type string?
ftr.name = nil

local blank = {}

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

local function order_keys(conf, tbl)
    local keys = {}
    for i in pairs(tbl) do
        keys[#keys + 1] = i
    end
    if conf.sorted_keys == nil then
        table.sort(keys)
    else
        table.sort(keys, function(a, b)
            local prio_a, prio_b = conf.sorted_keys[a], conf.sorted_keys[b]

            if prio_a and prio_b then
                return prio_a < prio_b
            elseif prio_a then
                return true
            elseif prio_b then
                return false
            end
            return a < b
        end)
    end

    return keys
end

---@return table
function ftr:get_default_value()
    local v = self.options:get_default_value()
    local root = {options = v}
    for i in pairs(required_fields) do
        root[i] = self[i]:get_default_value()
    end
    setmetatable(v, options_mt)
    return setmetatable(root, root_mt)
end

function ftr:validate(t, enforce)
    for i,k in pairs(required_fields) do
        if k(t[i]) then
            if t[i] ~= nil then
                return false, ('Invalid value for required feature entry \'%s\''):format(i) 
            else
                t[i] = self[i]:get_default_value()
            end
        end
    end
    if t.options then
        local entry, success, message
        for i,k in pairs(self.options.content) do
            entry = t.options[i]
            if entry == nil then
                t.options[i] = k:get_default_value()
                goto continue
            end

            success, message = k:validate(t.options[i], enforce)
            if not success then
                return false, ('Validation failed in table entry \'%s\': "%s"'):format(i, message)
            end
            ::continue::
        end
    else
        local o = {}
        for i,k in pairs(self.options.content) do
            o[i] = k:get_default_value()
        end
        t.options = o
    end
    return true
end

function ftr:stringify()
    if self.name then return ('"%s"'):format(self.name) end
    local samples = ""
    local i = 0
    for k, v in pairs(self.options) do
        if i == 2 or #samples > 30 then samples = samples ..', ... ' break end
        samples = samples .. ("%s%s = %s"):format(i > 0 and ', ' or '', k, tostring(v))
        i = i + 1
    end
    return ("{%s}"):format(samples)
end

---@return Config.Feature
function ftr:with_name(name)
    local o = {name = name, options = self.options, sorted_keys = self.sorted_keys, ordered_keys = self.ordered_keys}
    for i in pairs(required_fields) do
        o[i] = self[i]
    end
    return setmetatable(o, ftr)
end

---@param keys string[]
---@return Config.Feature
function ftr:with_sorted_keys(keys)
    local reversed = {}
    for i, k in ipairs(keys) do
        reversed[k] = i
    end
    local o = {name = self.name, options = self.options, sorted_keys = reversed}
    o.ordered_keys = order_keys(o, self.options.content)
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
    ---@type {[string]: Config.Base}
    local out = {}
    local mtt
    for i,k in pairs(table) do
        if type(k) ~= 'table' then error('Entries in a feature must either be a table or configuration value') end
        if out[i] ~= nil then error('Invalid key in feature: '.. tostring(i)) end
        mtt = getmetatable(k) or blank
        if mtt.is_configuration then
            out[i] = k --[[@as Config.Base]]
        else
            out[i] = config.table(k --[[@as Config.FromTable]])
        end
    end
    if default_enabled == nil then default_enabled = true end
    local conf = {
        enabled = config.boolean(default_enabled):permit_boolable(true), randomization_chance = config.percentage(default_rate or 1.00, 0.01), options = config.table(out)
    }
    conf.ordered_keys = order_keys(conf, out)
    return setmetatable(conf, ftr)
end

---@return Config.Feature
function ftr.new(options, default_enabled, default_rate)
    return ftr.from(default_enabled, default_rate, options)
end

return ftr.new