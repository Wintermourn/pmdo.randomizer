local base = require 'pmdorand.config.base'

---@class Config.Table : Config.Base
---@operator bor(Config.Base): Config.Any
--- Automatic type for tables used in config data.
local tbl = base.extend("Config.Table")
tbl.content = {}
---@type string?
tbl.name = nil

local blank = {}

function tbl:get_default_value()
    local v = {}
    for i,k in pairs(self.content) do
        v[i] = k:get_default_value()
    end
    return v
end

function tbl:validate(t, enforce)
    for i,k in pairs(t) do

        if not self.content[i] then
            print('Unknown key for table entry: '.. i)
        end
        
        ---@type Config.Base
        local child = self.content[i]
        if child ~= nil then
            local res, msg = child:validate(k, enforce)
            -- propagate invalid results
            if res == false then return false, ('Validation failed in table entry \'%s\': "%s"'):format(i, msg) end
        end

    end
    return true
end

function tbl:stringify()
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

---@return Config.Table
function tbl:with_name(name)
    return setmetatable({name = name, content = self.content}, tbl)
end

---@param table Config.FromTable
---@return Config.Table
function tbl.from(table)
    if (getmetatable(table) or {}).__title == tbl.__title then return table --[[@as Config.Table]] end
    local out = {}
    local mtt
    for i,k in pairs(table) do
        if type(k) ~= 'table' then error('Entries in a configuration table must either be a table or configuration value') end
        mtt = getmetatable(k) or blank
        if mtt.is_configuration then
            out[i] = k
        else
            out[i] = tbl.from(k --[[@as Config.FromTable]])
        end
    end
    return setmetatable({content = out}, tbl)
end

---@return Config.Table
function tbl.new(content)
    return tbl.from(content)
end

return tbl.new