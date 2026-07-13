local base = require 'pmdorand.config.base'

local modes = {
    raw = 'r',
    relative = 'e'
}

---@class Config.Stat : Config.Base
local stat = base.extend("Config.Monster.Stat")
stat.config = {
    minimum = 0, maximum = 255, range = {
        mode = modes.raw,
        range = 30
    },
    originalPull = 1.00
}

function stat:get_default_value()
    return {
        minimum = self.config.minimum, maximum = self.config.maximum,
        range = {mode = self.config.range.mode, range = self.config.range.range},
        originalPull = self.config.originalPull
    }
end

function stat:validate(v)
    local typing = type(v)
    if typing ~= 'table' then
        if typing == 'number' then return true end
        return false, ('Stat must be in table format (got \'%s\')'):format(type(v))
    end
    if v.minimum < 0 then return false, 'Stat minimum must be positive or zero' end
    if v.range.range < 0 then v.range.range = v.range.range * -1 end
    if not modes[string.lower(v.range.mode)] then v.range.mode = modes.raw end
    return true
end

function stat:stringify()
    return ("[%d, %d] (%s%d, %.2f)"):format(
        self.config.minimum,
        self.config.maximum,
        self.config.range.mode,
        self.config.range.range,
        self.config.originalPull
    )
end

---@return Config.Stat
function stat:with_defaults(min, max, range, pull)
    return setmetatable({config = {
        minimum = min or 0, maximum = max or 255, range = range and {
            mode = modes[range.mode and string.lower(range.mode) or 'raw'], range = range.range or 30
        } or {mode = modes.raw, range = 30}, originalPull = pull or 1.00
    }}, stat)
end

---@return Config.Stat
function stat.new()
    return setmetatable({config = {minimum = 0, maximum = 255, range = {mode = modes.raw, range = 30}, originalPull = 1.00}}, stat)
end

return stat.new