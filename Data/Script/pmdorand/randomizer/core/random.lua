local pseudorandom = require 'lib.pmdorand.pseudorandom'

local __SHA256 = luanet.import_type 'System.Security.Cryptography.SHA256'
local __BitConverter = luanet.import_type 'System.BitConverter'
local Text = luanet.namespace 'System.Text'
    local __Encoding = Text.Encoding

---@class pmdorand.random
local random = {
    ---@type random.mersenne_twister
    generator = nil
}
random.__index = random

---Generates an integer number from `a` to `b`. If `b` is `nil`, the range is `0` to `a`. If both are nil, the range is `0` to `MAXINTEGER`.
---@param a integer?
---@param b integer?
---@return integer
function random:next_integer(a, b)
    local ca, cb = a ~= nil, b ~= nil

    if ca and cb then
        return self.generator:random(a, b)
    elseif ca then
        return self.generator:random(0, a)
    else
        return self.generator:random(0, math.maxinteger)
    end
end

---Generates a decimal number between 0 and 1.
---@return number (0..1)
function random:next()
    return self.generator:random()
end

---Generates a boolean value.
---@param true_chance number (0..1)
---@return boolean
function random:bool(true_chance)
    if true_chance >= 1 then return true end
    if true_chance <= 0 then return false end
    return self.generator:random() < true_chance
end

---Returns a random value from the input array.
---@param tbl any[]
---@return any value
function random:select_array(tbl)
    return tbl[self:next_integer(1, #tbl)]
end

---Returns a random value and its key from the input table.
---@param tbl {[any]: any}
---@return any value
---@return any key
function random:select_dict(tbl)
    local keys = {}
    for i, _k in pairs(tbl) do
        keys[#keys + 1] = i
    end

    if #keys == 0 then return nil, nil end

    local out_key = keys[self:next_integer(1, #keys)]
    return tbl[out_key], out_key
end

---Returns a decimal number between a `minimum` and `maximum` with weighting towards `origin` based on `strength`.
---### Behavior
---Splits the range into two sides, below `origin` and above `origin`.
---The segment used is determined by `positive_rate`.
---
---`strength` controls the pull towards the `origin` value:
---* Positive values pull the result closer to the origin.
---* Negative values pull the result further from the origin, towards the extremes.
---* A `strength` of `0` selects between the entire side evenly.
---
---If the minimum is greater than `origin` or the maximum less than `origin`, the range of values will be resized to include it.
---
---This function does not round the return value.
---@param minimum number
---@param maximum number
---@param origin number
---@param strength number The strength of the pull towards the origin value. Negative pushes away instead.
---@param positive_rate number? (0..1) Chance of the result being higher or equal to the origin value. Defaults to `0.5` (50%).
function random:bipolar_weighted(minimum, maximum, origin, strength, positive_rate)
    minimum = math.min(minimum, origin)
    maximum = math.max(maximum, origin)
    positive_rate = positive_rate or 0.5

    local is_positive, max_range

    is_positive = self:bool(positive_rate)
    max_range = is_positive and (maximum - origin) or (origin - minimum)
    if max_range == 0 then return origin end

    local raw, curved, scaled

    raw = self:next()
    curved = raw

    if strength > 0 then
        curved = raw ^ (1 + strength)
    elseif strength < 0 then
        curved = 1 - (1 - raw) ^ (1 - strength)
    end

    scaled = curved * max_range
    return is_positive and ( origin + scaled ) or ( origin - scaled )
end

---Returns a decimal number between a `minimum` and `maximum` with weighting towards `origin` based on `strength`.
---### Behavior
---Splits the range into two sides, below `origin` and above `origin`.
---The segment used is determined by the proportional size of each side.
---This means a smaller "increase" side is less likely to be selected than a larger "decrease" side.
---
---`strength` controls the pull towards the `origin` value:
---* Positive values pull the result closer to the origin.
---* Negative values pull the result further from the origin, towards the extremes.
---* A `strength` of `0` selects between the entire side evenly.
---
---If the minimum is greater than `origin` or the maximum less than `origin`, the range of values will be resized to include it.
---
---This function does not round the return value.
---@param minimum number
---@param maximum number
---@param origin number
---@param strength number The strength of the pull towards the origin value. Negative pushes away instead.
function random:origin_weighted(minimum, maximum, origin, strength)
    minimum = math.min(minimum, origin)
    maximum = math.max(maximum, origin)

    local full_range = maximum - minimum
    if full_range == 0 then return origin end

    local is_positive, max_range, positive_chance

    positive_chance = (maximum - origin) / full_range
    is_positive = self:next() < positive_chance
    max_range = is_positive and (maximum - origin) or (origin - minimum)
    if max_range == 0 then return origin end

    local raw, curved, scaled

    raw = self:next()
    curved = raw

    if strength > 0 then
        curved = raw ^ (1 + strength)
    elseif strength < 0 then
        curved = 1 - (1 - raw) ^ (1 - strength)
    end

    scaled = curved * max_range
    return is_positive and ( origin + scaled ) or ( origin - scaled )
end

---@param options {[number]: number} {[value]: weight}
---@param interpolation boolean|fun(low_bound: number, low_weight: number, high_bound: number, high_weight: number, between_step: number): number
---@return number|any?
function random:weighted(options, interpolation)
    if type(options) ~= 'table' then return options end
end

local public = {}

function public.new(seed)
    if type(seed) ~= 'number' then
        seed = __BitConverter.ToUInt64(__SHA256.Create():ComputeHash(__Encoding.UTF8:GetBytes(seed)), 0)
    end
    return setmetatable({
        generator = pseudorandom.twister(seed)
    }, random)
end

return public