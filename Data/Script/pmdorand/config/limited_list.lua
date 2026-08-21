local base = require 'pmdorand.config.base'

---@class Config.LimitedList<T> : Config.Base
---@field default T[]?
---@field validator (fun(t: T): boolean)?
local limlist = base.extend("Config.LimitedList")

---@return T[]
function limlist:get_default_value()
    if limlist.default == nil then return {} end
    local out = {}
    for i,k in ipairs(limlist.default) do
        out[i] = k
    end
    return out
end

function limlist:validate(t, enforce)
    if not enforce then return true end
    if self.validator then
        local success
        local invalid_entries = {}
        local seen_entries = {}
        for _i,k in ipairs(t) do
            if seen_entries[k] then
                print(string.format("duplicate entry in list: \"%s\"", tostring(k)))
            end
            seen_entries[k] = true
            success = self.validator(k)
            if not success then
                table.insert(invalid_entries, k)
            end
        end
        if #invalid_entries > 0 then
            return false, ('invalid entries in list:\n\t\t[\n\t\t\t%s\n\t\t]'):format(table.concat(invalid_entries, ',\n\t\t\t'))
        end
    end
    return true
end

function limlist:filter(t)
    local out = {}
    local seen_entries = {}
    if self.validator then
        for _i, k in ipairs(t) do
            if seen_entries[k] then
                print(string.format("duplicate entry in list: \"%s\"", tostring(k)))
                goto continue
            end
            seen_entries[k] = true
            if self.validator(k) then
                table.insert(out, k) 
            end
            ::continue::
        end
    end

    return out
end

function limlist:stringify()
    return ("<%s>"):format( self.validator or '?' )
end

---@param t T[]
function limlist:with_defaults(t)
    return setmetatable({default = t, validator = self.validator}, limlist)
end

---@param fn fun(t: T): boolean
function limlist:with_validator(fn)
    return setmetatable({default = self.default, validator = fn}, limlist)
end

---@return Config.Any
function limlist.new(default, validator)
    return setmetatable({default = default, validator = validator}, limlist)
end

return limlist.new