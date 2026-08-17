local display = require 'pmdorand.randomizer.core.config.display'

return display.builder() --[[@as ConfigDisplayBuilder<Config.Enum>]]
    :with_title 'Config.Enum'
    :with_display(function(_structure, value, entry)
        if entry == nil then return tostring(value) end
        return STRINGS:FormatKey(string.format('%s=%s', entry.translation_key, tostring(value)))
    end)
    :register()