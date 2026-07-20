local base = require 'pmdorand.config.base'

---@class Config.Variant : Config.Base
---@operator bor(Config.Base): Config.Variant
--- Automatic type for tables used in config data.
local var = base.extend("Config.Variant")
---@type {[string]: Config.Base}
var.variants = {}
var.default = ''

---@return {type: string, value: any}
function var:get_default_value()
    return {
        type = self.default,
        value = self.variants[self.default]:get_default_value()
    }
end

function var:validate(t, enforce)
    local ty = type(t)
    if ty ~= 'table' then return false, "Value must be a table { type, value }." end
    local selection = self.variants[t.type]
    if selection == nil then return false, ("Type '%s' does not exist in variant list.") end
    return selection:validate(t.value, enforce)
end

function var:stringify()
    return ("(Default: %s)"):format( self.default )
end

---@return Config.Variant
function var.new(default, variants)
    if variants[default] == nil then error(string.format("default variant '%s' does not exist", default)) end
    return setmetatable({default = default, variants = variants}, var)
end

return var.new