local documentation = require 'pmdorand.randomizer.core.config.documentation'
local soft_translate = require 'Data.Script.pmdorand.util.soft_translate'

local name = STRINGS:FormatKey 'pmdorand:config.enum'
local body = STRINGS:FormatKey 'pmdorand/documentation:config.enum' :match '^%s*(.-)%s*$'
local none = soft_translate 'pmdorand/documentation:none' :match '^%s*(.-)%s*$'

return documentation.builder() --[[@as pmdorand.config.documentation.builder<Config.Enum>]]
    :with_title 'Config.Enum'
    :with_documentation(function(s, v, e)
        if e == nil then return end
        local out = {}
        local body_key, has_documentation, text, string_value
        for i,k in ipairs(s.values.by_index) do
            string_value = tostring(k)
            body_key = string.format("%s=%s", e.documentation_key, string_value)
            has_documentation, text = RogueEssence.Text.Strings:TryGetValue(body_key)
            out[#out + 1] = {
                string.format("[color=#999999]E:[color] %s", soft_translate(string.format('%s=%s', e.translation_key, string_value))),
                has_documentation and ( string.match (text, '^%s*(.-)%s*$') ) or none,
                key = body_key
            }
        end
        return {name, body}, table.unpack(out)
    end)
    :register()