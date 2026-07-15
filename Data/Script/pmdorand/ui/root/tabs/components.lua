local configurations = require 'pmdorand.randomizer.cache.configurations'
local generation_manager = require 'pmdorand.randomizer.core.manager'
local component_registry = require 'pmdorand.randomizer.core.registry' .get 'components'
local provider_registry = require 'pmdorand.randomizer.core.registry' .get 'providers'
local strings = {
    component_count = STRINGS:FormatKey 'pmdorand:stats.components.count',
    component_span = STRINGS:FormatKey 'pmdorand:stats.components.span',
    enabled = STRINGS:FormatKey('pmdorand:enabled'),
    disabled = STRINGS:FormatKey('pmdorand:disabled')
}

return {
    name = STRINGS:FormatKey 'pmdorand:tab.components',
    ---@param menu pmdorand.ui.root
    entered = function(menu)
        menu.elements.cursor.Loc = RogueElements.Loc(11, 21)
        local out = {}
        ---@type {[string]: string[]|{enabled_min:integer,enabled_max:integer}}
        local by_provider = {}
        local keys = {}

        ---@type string[]|{enabled_min:integer?,enabled_max:integer?}
        local current_list, enabled_value
        for id, component in pairs(component_registry.content.by_key) do
            if by_provider[component.provider_id] == nil then
                keys[#keys+1] = component.provider_id
                current_list = {}
            else
                current_list = by_provider[component.provider_id]
            end

            current_list[#current_list+1] = id
            current_list.enabled_min = current_list.enabled_min or 0
            current_list.enabled_max = current_list.enabled_max or 0
            enabled_value = configurations.get(id).enabled
            if enabled_value == true then
                current_list.enabled_min = current_list.enabled_min + 1
                current_list.enabled_max = current_list.enabled_max + 1
            elseif type(enabled_value) == 'number' and enabled_value > 0 then
                current_list.enabled_max = current_list.enabled_max + 1
                if enabled_value >= 1 then
                    current_list.enabled_min = current_list.enabled_min + 1
                end
            end

            table.sort(current_list, function(a, b)
                return STRINGS:FormatKey('pmdorand/component:'.. a) < STRINGS:FormatKey('pmdorand/component:'.. b)
            end)
            by_provider[component.provider_id] = current_list
        end
        table.sort(keys, function(a, b)
            return STRINGS:FormatKey('pmdorand/provider:'.. a) < STRINGS:FormatKey('pmdorand/provider:'.. b)
        end)

        local current_line, components = 2, nil
        for _, provider_id in ipairs(keys) do
            components = by_provider[provider_id]
            out[#out+1] = {STRINGS:FormatKey('pmdorand/provider:'.. provider_id), 6, current_line, RogueElements.DirH.Left}
            out[#out+1] = {
                components.enabled_min == components.enabled_max and strings.component_count:format(#components, components.enabled_min)
                or strings.component_span:format(#components, components.enabled_min, components.enabled_max), -2, current_line, RogueElements.DirH.Right
            }
            current_line = current_line + 12
            for _, component_id in ipairs(components) do
                out[#out+1] = {STRINGS:FormatKey('pmdorand/component:'.. component_id), 12, current_line, RogueElements.DirH.Left}
                out[#out+1] = {configurations.get(component_id).enabled ~= false and strings.enabled or strings.disabled, -12, current_line, RogueElements.DirH.Right}
                current_line = current_line + 12
            end
        end

        return out
    end,
    ---@param menu pmdorand.ui.root
    left = function(menu)

    end,
    ---@param menu pmdorand.ui.root
    input = function(menu, input)

    end
}