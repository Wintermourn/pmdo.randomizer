local base = require 'pmdorand.config.base'

---@class Config.String : Config.Base
---@operator bor(Config.Base): Config.Any
local str = base.extend("Config.String")
str.default = ''
str.illegal_characters = ''

---@return string
function str:get_default_value()
    return self.default
end

function str:validate(t)
    if type(t) ~= 'string' then
        return false, ('Expected string, got %s'):format(type(t))
    end
    if t:find(string.format('[%s]', self.illegal_characters)) then
        return false, ('Value cannot contain the following characters: "%s"'):format(self.illegal_characters)
    end
    return true
end

function str:stringify()
    return ("(Default: %s)"):format( self.default )
end

---@return Config.String
function str.new(default, illegal)
    if illegal and illegal:sub(1,1) ~= '[' then
        illegal = string.format('[%s]', illegal)
    end
    return setmetatable({default = default or '', illegal_characters = illegal or ''}, str)
end

return str.new