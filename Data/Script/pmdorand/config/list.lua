local base = require 'pmdorand.config.base'

--[[
    Todo: add a function that returns all valid entries
]]

---@class Config.List<T> : Config.Base
---@field expected_type type|Config.Base?
---@field default T[]?
local list = base.extend("Config.List")

---@return T[]
function list:get_default_value()
    if list.default == nil then return {} end
    local out = {}
    for i,k in ipairs(list.default) do
        out[i] = k
    end
    return out
end

local function uncaring_comparison(_self, _n)
    return true
end

local function type_comparison(self, n)
    local ty = type(n)
    if ty == self.expected_type then return true end
    return false, string.format("expected %s, got %s", self.expected_type, ty)
end

local function config_comparison(self, n)
    ---@cast self.expected_type Config.Base
    local success, message = self.expected_type:validate(n)
    if success then return true end
    return false, string.format("expecting %s, validation failed: %s", self.expected_type.__title, message)
end

local function get_comparison(self)
    local ty = type(self.expected_type)
    if ty == 'string' then
        return type_comparison
    elseif ty == 'table' and self.expected_type.__title and self.expected_type.is_configuration then
        return config_comparison
    end
    return uncaring_comparison
end

function list:validate(t, enforce)
    if not enforce then return true end
    local comparison = get_comparison(self)
    local success, message
    for _i, k in ipairs(t) do
        success, message = comparison(self, k)
        if not success then
            return false, message
        end
    end
    return true
end

function list:filter(t)
    local out = {}
    local comparison = get_comparison(self)
    for _i, k in ipairs(t) do
        if comparison(self, k) then
            out[#out + 1] = k
        end
    end

    return out
end

function list:stringify()
    ---@type type|string
    local expected_type = type(self.expected_type)
    if expected_type == 'string' then
        expected_type = self.expected_type --[[@as string]]
    elseif expected_type == 'table' then
        ---@cast self.expected_type Config.Base|table
        if self.expected_type.__title and self.expected_type.is_configuration then
            ---@cast self.expected_type Config.Base
            expected_type = self.expected_type.__title
        end
    else
        expected_type = 'nil'
    end

    return ("<%s>"):format( self.expected_type or '?' )
end

---@param type type|Config.Base?
---@return Config.List<unknown>
function list.new(type, default)
    return setmetatable({expected_type = type, default = default}, list)
end

return list.new