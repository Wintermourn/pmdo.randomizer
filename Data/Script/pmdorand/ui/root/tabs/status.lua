local input_type = RogueEssence.FrameInput.InputType

local generation_manager = require 'pmdorand.randomizer.core.manager'
local component_registry = require 'pmdorand.randomizer.core.registry' .get 'components'
local provider_registry = require 'pmdorand.randomizer.core.registry' .get 'providers'
local strings = {
    component_title = STRINGS:FormatKey 'pmdorand:stats.components.title',
    provider_count = STRINGS:FormatKey 'pmdorand:stats.providers.count',
    component_count = STRINGS:FormatKey 'pmdorand:stats.components.count',
    component_span = STRINGS:FormatKey 'pmdorand:stats.components.span',
    start_randomizer = STRINGS:FormatKey 'pmdorand:randomize',
    browse_configurations = STRINGS:FormatKey 'pmdorand:configurations.browse'
}

local cursor = 0
local last_dir
local inputs = {
    directions = {
        [RogueElements.Dir8.Up] = function(menu)
            cursor = cursor == 1 and 0 or 1
            menu.elements.cursor.Loc = RogueElements.Loc(11, menu.menu.Bounds.Height--[[@as int]] - 33 - (cursor * 12))
            _GAME:SE("Menu/Select")
        end,
        [RogueElements.Dir8.Down] = function(menu)
            cursor = cursor == 1 and 0 or 1
            menu.elements.cursor.Loc = RogueElements.Loc(11, menu.menu.Bounds.Height--[[@as int]] - 33 - (cursor * 12))
            _GAME:SE("Menu/Select")
        end
    },
    bindings = {
        [input_type.Confirm] = function()
            _GAME:SE("Menu/Confirm")
            if cursor == 0 then
                generation_manager.start()
            else

            end
        end
    }
}

local texts = {
    {strings.component_title, 0, 2, RogueElements.DirH.Left},
    nil,
    {strings.provider_count:format(provider_registry.count), 0, 14, RogueElements.DirH.Left},
    {strings.browse_configurations, 7, -16, RogueElements.DirH.Left},
    {strings.start_randomizer, 7, -4, RogueElements.DirH.Left}
}

local last_state
local function update_texts()
    if generation_manager.get_state() == 1 then
        texts[5][1] = '[color=#999999]'.. strings.start_randomizer
    else
        texts[5][1] = strings.start_randomizer 
    end
    
    return generation_manager.get_state() ~= last_state
end

return {
    name = STRINGS:FormatKey 'pmdorand:tab.status',
    ---@param menu pmdorand.ui.root
    entered = function(menu)
        last_dir = nil
        cursor = 0
        menu.elements.cursor.Loc = RogueElements.Loc(11, menu.menu.Bounds.Height--[[@as int]] - 33)

        local enabled_count_min, enabled_count_max = generation_manager.get_enabled_count()

        texts[2] = {
            enabled_count_min == enabled_count_max and
                strings.component_count:format(component_registry.count, enabled_count_min) or 
                strings.component_span:format(component_registry.count, enabled_count_min, enabled_count_max),
            -2, 2, RogueElements.DirH.Right
        }
        update_texts()
        last_state = generation_manager.get_state()
        return texts
    end,
    ---@param menu pmdorand.ui.root
    left = function(menu)

    end,
    ---@param menu pmdorand.ui.root
    input = function(menu, input)
        for i, k in pairs(inputs.bindings) do
            if input:JustPressed(i) then
                k(menu, input)
                return 
            end
        end
        if inputs.directions[input.Direction] and menu.state.input_debounce == 0 then
            menu.elements.cursor:ResetTimeOffset()
            inputs.directions[input.Direction](menu, input)
            menu.state.input_debounce = input.Direction == last_dir and 6 or 18
        end
        last_dir = input.Direction

        if update_texts() then
            last_state = generation_manager.get_state()
            return texts
        end
    end
}