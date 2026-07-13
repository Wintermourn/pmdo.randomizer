local base = require 'pmdorand.config.base'

---@class Config.Table : Config.Base
--- Automatic type for tables used in config data.
local tbl = base.extend("Config.Table")
tbl.content = {}
---@type string?
tbl.name = nil

function tbl:get_default_value()
    local v = {}
    for i,k in pairs(self.content) do
        v[i] = k:get_default_value()
    end
    return v
end

function tbl:validate(t)
    for i,k in pairs(t) do

        if not self.content[i] then
            print('Unknown key for table entry: '.. i)
        end
        
        ---@type Config.Base
        local child = self.content[i]
        if child ~= nil then
            local res, msg = child:validate(k)
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

---@return Config.Table
function tbl.new(content)
    return setmetatable({content = content}, tbl)
end

return tbl.new