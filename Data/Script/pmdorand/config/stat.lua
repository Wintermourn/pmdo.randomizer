local config = require 'pmdorand.config'
local base = require 'pmdorand.config.base'

local modes = {
    raw = 'r',
    relative = 'e',
    anchor = 'a'
}

---@class Config.Stat : Config.Base
local stat = base.extend("Config.Stat")
stat.structure = {
    minimum = config.integer(0, 0, math.maxinteger, 5),
    maximum = config.integer(0, 0, math.maxinteger, 5),
    mode = config.option('r', {'r', 'e', 'a'}),
    value = config.integer(0, 0, math.maxinteger, 5),
    original_pull = config.float(0, -10, 10)
}
stat.config = {
    minimum = 0, maximum = 255, range = {
        mode = modes.raw,
        value = 30
    },
    originalPull = 1.00
}

function stat:get_default_value()
    return {
        minimum = self.config.minimum, maximum = self.config.maximum,
        range = {mode = self.config.range.mode, value = self.config.range.value},
        originalPull = self.config.originalPull
    }
end

function stat:validate(v, enforce)
    local typing = type(v)
    if typing ~= 'table' then
        if typing == 'number' then return true end
        return false, ('Stat must be in table format (got \'%s\')'):format(type(v))
    end
    if enforce then
        if v.minimum < 0 then return false, 'Stat minimum must be positive or zero' end
    end
    if v.maximum < v.minimum then v.maximum = v.minimum end
    if v.range.range < 0 then v.range.range = v.range.range * -1 end
    if not modes[string.lower(v.range.mode)] then v.range.mode = modes.raw end
    return true
end

function stat:stringify(colorize)
    return ("[%d, %d] %s(%s%d, %.2f)"):format(
        self.config.minimum,
        self.config.maximum,
        colorize and '[color=#777777]' or '',
        self.config.range.mode,
        self.config.range.value,
        self.config.originalPull
    )
end

function stat.stringify_value(val, colorize)
    return ("[%d, %d] %s(%s%d, %.2f)"):format(
        val.minimum,
        val.maximum,
        colorize and '[color=#777777]' or '',
        val.range.mode,
        val.range.value,
        val.originalPull
    )
end

---@return Config.Stat
function stat:with_defaults(min, max, range, pull)
    return setmetatable({config = {
        minimum = min or 0, maximum = max or 255, range = range and {
            mode = modes[range.mode and string.lower(range.mode) or 'raw'], value = range.value or 30
        } or {mode = modes.raw, range = 30}, originalPull = pull or 1.00
    }}, stat)
end

---@return Config.Stat
function stat.new()
    return setmetatable({config = {minimum = 0, maximum = 255, range = {mode = modes.raw, value = 30}, originalPull = 1.00}}, stat)
end

return stat.new