---@class Config.Base
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
function _conf:__tostring()
    local my_value = self:stringify()
    return ("<%s>%s"):format(self.__title or "Unnamed Config Class", my_value and (' '.. my_value) or '')
end

---@return string?
function _conf:stringify() return nil end

---@return {}
function _conf.new() error("Base config does not have a constructor") end

---@return Config.Base?
function _conf:get_parent() return nil end

return {
    extend = function(title)
        local out = {__title = title, is_configuration = true}

        out.__tostring = _conf.__tostring
        function out:__index(key)
            return rawget(self, key) or out[key] or _conf[key]
        end

        function out.new()
            return setmetatable({}, out)
        end

        return setmetatable(out, _conf)
    end
}