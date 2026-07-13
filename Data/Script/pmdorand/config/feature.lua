local base = require 'pmdorand.config.base'

---@class Config.Feature : Config.Base
--- Automatic type for tables used in config data.
local ftr = base.extend("Config.Feature")
ftr.content = {}
---@type string?
ftr.name = nil

function ftr:get_default_value()
    local v = {
        enabled = true,
        randomization_chance = 1.00
    }
    for i,k in pairs(self.content) do
        v[i] = k:get_default_value()
    end
    return v
end

---@type {[string]: boolean}
local required_fields = {
    enabled = true,
    randomization_chance = true
}

function ftr:validate(t)
    for i,k in pairs(t) do

        if required_fields[i] then goto continue end

        if not self.content[i] then
            print('Unknown key for table entry: '.. i)
        end
        
        local child = self.content[i]
        if child ~= nil then
            local res, msg = child:validate(k)
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
    return setmetatable({name = name, content = self.content}, ftr)
end

---@return Config.Feature
function ftr.new(content)
    return setmetatable({content = content}, ftr)
end

return ftr.new