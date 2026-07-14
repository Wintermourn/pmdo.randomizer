local base = require 'pmdorand.config.base'

---@class Config.MatchupTable : Config.Base
local matchup = base.extend("Config.MatchupTable")
matchup.shape = {}
matchup.default = {}
---@type string?
matchup.name = nil

---@return boolean
function matchup.key_validator(key)
    return true
end

function matchup:get_default_value()
    return self:validate(self.default) and self.default or {}
end

function matchup:validate(t, enforce)
    for i,k in pairs(t) do
        if type(k) ~= 'table' then goto skip end

        if not self.key_validator(i) then
            print('Invalid key for matchup entry: '.. i)
        end
        
        for c,v in pairs(k) do
            if self.shape[c] then
                local res, msg = self.shape[c]:validate(v, enforce)
                ---@diagnostic disable-next-line: invert-if
                -- propagate invalid results
                if res == false then return false, ('Validation failed in matchup entry \'%s\': "%s"'):format(i, msg) end
            end
        end

        ::skip::
    end
    return true
end

function matchup:stringify()
    if self.name then return ('"%s"'):format(self.name) end
    local samples = ""
    local i = 0
    for k, v in pairs(self.shape) do
        if i == 2 or #samples > 30 then samples = samples ..', ... ' break end
        samples = samples .. ("%s%s = %s"):format(i > 0 and ', ' or '', k, tostring(v))
        i = i + 1
    end
    return ("{%s}"):format(samples)
end

---@param keying fun(i: string): boolean
---@return Config.MatchupTable
function matchup:with_keying(keying)
    return setmetatable({name = self.name, shape = self.shape, key_validator = keying, default = self.default}, matchup)
end

---@return Config.MatchupTable
function matchup:with_shape(shape)
    return setmetatable({name = self.name, shape = shape, key_validator = self.key_validator, default = self.default}, matchup)
end

---@return Config.MatchupTable
function matchup:with_name(name)
    return setmetatable({name = name, shape = self.shape, key_validator = self.key_validator, default = self.default}, matchup)
end

---@return Config.MatchupTable
function matchup:with_default(default)
    return setmetatable({name = self.name, shape = self.shape, key_validator = self.key_validator, default = default}, matchup)
end

---@return Config.MatchupTable
function matchup.new(keying_function)
    return setmetatable({shape = {}, key_validator = keying_function or matchup.key_validator, default = {}}, matchup)
end

return matchup.new