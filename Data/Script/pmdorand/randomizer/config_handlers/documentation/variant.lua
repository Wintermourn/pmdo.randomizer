local documentation = require 'pmdorand.randomizer.core.config.documentation'
local documentations = require 'pmdorand.randomizer.core.registry' .get 'config.documentation'

local name = STRINGS:FormatKey 'pmdorand:config.variant'
local body = STRINGS:FormatKey 'pmdorand/documentation:config.variant' :match '^%s*(.-)%s*$'

return documentation.builder() --[[@as pmdorand.config.documentation.builder<Config.Variant>]]
    :with_title 'Config.Variant'
    :with_documentation(function(s, v, e)
        local out = {}
        local keys = {}
        for i,k in pairs(s.variants) do
            keys[#keys + 1] = i
        end
        table.sort(keys)
        local temp, variant
        for i,k in ipairs(keys) do
            variant = s.variants[k]
            temp = {documentations:get(variant.__title).documentation(variant, v.value, e)}
            for _c,v in ipairs(temp) do
                if type(v) == 'table' then
                    v[1] = string.format("[color=#aaaaaa]V:[color] %s [color=#aaaaaa]>[color] %s", k, v[1])
                end
                out[#out + 1] = v
            end
        end
        return {name, body}, table.unpack(out)
    end)
    :register()