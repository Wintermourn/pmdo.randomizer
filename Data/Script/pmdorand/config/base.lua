---@class Config.Base
---@field __title string
---@operator bor(Config.Base): Config.Any
local _conf = {__title = "Config.Base", is_configuration = true}
function _conf:__index(key)
    return rawget(self, key) or rawget(_conf, key)
end

function _conf:get_default_value() return {} end

--- Requires that validation enforce things like minimum and maximum values.
--- <br><b>It is recommended to only use this if out-of-bounds values cause errors.</b>
function _conf:always_enforce_limits()
    self.enforce_limits = true
    return self
end

---@param enforce_limits boolean?
---@return boolean, string?
function _conf:validate(v, enforce_limits) return true end

---@return string?
function _conf:stringify() return nil end
function _conf:__tostring()
    local my_value = self:stringify()
    return ("<%s>%s"):format(self.__title or "Unnamed Config Class", my_value and (' '.. my_value) or '')
end

local any_key = 'Config.Any'
local case_key = 'Config.Case'
local variant_key = 'Config.Variant'
---@param a Config.Base
---@param b Config.Base
function _conf.__bor(a, b)
    if b.__title == case_key then
        ---@cast b Config.Case
        if a.__title == variant_key then
            ---@cast a Config.Variant
            a.variants[b.key] = b.config
            return a
        elseif a.__title == any_key then
            ---@cast a Config.Any
            table.insert(a.options, b.config)
            return a
        elseif a.__title == case_key then
            ---@cast a Config.Case
            ---@cast b Config.Case
            return require 'pmdorand.config' .variant(a.key, {[a.key] = a.config, [b.key] = b.config})
        else
            error(string.format("config type %s is not compatible with a case-wrapped value.", a.__title))
        end
    else
        if a.__title == any_key then
            ---@cast a Config.Any
            table.insert(a.options, b)
            return a
        elseif a.__title == case_key then
            error(string.format("config type %s is not compatible with a case-wrapped value.", b.__title))
        else
            return require 'pmdorand.config' .any(a, b)
        end
    end
end

---@return {}
function _conf.new() error("Base config does not have a constructor") end

---@return Config.Base?
function _conf:get_parent() return nil end

return {
    extend = function(title)
        local out = {__title = title, is_configuration = true}

        out.__tostring = _conf.__tostring
        out.__bor = _conf.__bor
        function out:__index(key)
            return rawget(self, key) or out[key] or _conf[key]
        end

        function out.new()
            return setmetatable({}, out)
        end

        return setmetatable(out, _conf)
    end
}