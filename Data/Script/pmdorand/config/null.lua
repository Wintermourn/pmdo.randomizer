local base = require 'pmdorand.config.base'

---@class Config.Null : Config.Base
local null = base.extend("Config.Null")
local null_mt = {
    __nyamlType = 'null',
    __njsonType = 'null'
}

function null:get_default_value()
    return setmetatable({}, null_mt)
end

function null:validate(v, enforce)
    return true
end

function null:stringify()
    return 'null'
end

---@return Config.Stat
function null.new()
    return setmetatable({}, null)
end

return null.new