local display = require 'pmdorand.randomizer.core.config.display'
local math_util = require 'pmdorand.util.math'

local strings = {
    enabled = STRINGS:FormatKey 'pmdorand:enabled',
    disabled = STRINGS:FormatKey 'pmdorand:disabled',
    dynamic = STRINGS:FormatKey 'pmdorand:dynamic'
}

return display.builder()
    :with_title 'Config.Boolean' --[[@as pmdorand.config.display.builder<Config.Boolean>]]
    :with_display(function(_structure, v)
        local ty = type(v)
        if ty == "boolean" then
            return v and strings.enabled or strings.disabled
        elseif ty == 'number' then
            if v < 0 then
                return strings.disabled
            elseif v > 1 then
                return strings.enabled
            else
                return strings.dynamic .. ('[color] (%02d%%)'):format(math_util.round(v * 100))
            end
        end
    end)
    :register()