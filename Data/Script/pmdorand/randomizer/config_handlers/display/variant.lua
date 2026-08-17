local display = require 'pmdorand.randomizer.core.config.display'
local displays = require 'pmdorand.randomizer.core.registry' .get 'config.display'

local text = '[color=#aaaaaa]?'
return display.builder() --[[@as ConfigDisplayBuilder<Config.Variant>]]
    :with_title 'Config.Variant'
    :with_display(function(structure, value, entry)
        local variant = structure.variants[value.type]
        if variant == nil then return text end
        local variant_display = displays:get(variant.__title)
        if variant_display == nil then
            return string.format("%s %s", value.type or '', text)
        end
        return string.format("%s %s", variant_display.display(variant, value.value, entry), text)
    end)
    :register()