local play_sound = require 'pmdorand.util.play_sound'
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

local input_type = RogueEssence.FrameInput.InputType


local cache = {
    current_scroll = 0,
    cursor = 1,
    lines = {
        texts = {},
        at = {}
    }
}

local function create_lines()
    local texts, at = {}, {}
    local providers, components, enabled_counts = {}, {}, {}

    local current_components_list, current_counts, enabledness
    for id, component in pairs(component_registry.content.by_key) do
        if components[component.provider_id] == nil then
            providers[#providers+1] = component.provider_id
            current_components_list = {}
            current_counts = {min = 0, max = 0}
            components[component.provider_id] = current_components_list
            enabled_counts[component.provider_id] = current_counts
        else
            current_components_list = components[component.provider_id]
            current_counts = enabled_counts[component.provider_id]
        end
        --[[@cast current_components_list -?]]
        --[[@cast current_counts -?]]

        current_components_list[#current_components_list + 1] = id
        enabledness = configurations.get(id).enabled
        if enabledness == true then
            current_counts.min = current_counts.min + 1
            current_counts.max = current_counts.max + 1 
        elseif type(enabledness) == 'number' and enabledness > 0 then
            current_counts.max = current_counts.max + 1
            if enabledness >= 1 then
                current_counts.min = current_counts.min + 1 
            end
        end
    end
    table.sort(providers, function(a, b)
        return STRINGS:FormatKey('pmdorand/provider:'.. a) < STRINGS:FormatKey('pmdorand/provider:'.. b)
    end)

    local current_height = 0
    local dynamic_text, component_names, provider_enabled_count
    for _, provider_id in ipairs(providers) do
        ---@type table
        component_names = components[provider_id]
        ---@type {min: int, max: int}
        provider_enabled_count = enabled_counts[provider_id]
        table.sort(component_names, function(a, b)
            return STRINGS:FormatKey('pmdorand/component:'.. a) < STRINGS:FormatKey('pmdorand/component:'.. b)
        end)

        if provider_enabled_count.min == provider_enabled_count.max then
            dynamic_text = strings.component_count:format(#component_names, provider_enabled_count.min)
        else
            dynamic_text = strings.component_span:format(#component_names, provider_enabled_count.min, provider_enabled_count.max)
        end

        current_height = current_height + 2
        texts[#texts + 1] = {
            {STRINGS:FormatKey('pmdorand/provider:'.. provider_id), 6, current_height, RogueElements.DirH.Left},
            {dynamic_text, -2, current_height, RogueElements.DirH.Right}
        }
        at[#texts] = {0, current_height, type = 'provider', id = provider_id}
        current_height = current_height + 12
        for _, component_id in ipairs(component_names) do
            enabledness = configurations.get(component_id).enabled
            if enabledness == true then
                dynamic_text = STRINGS:FormatKey 'pmdorand:enabled'
            elseif enabledness == false then
                dynamic_text = STRINGS:FormatKey 'pmdorand:disabled'
            else
                dynamic_text = STRINGS:FormatKey 'pmdorand:dynamic'
            end

            texts[#texts + 1] = {
                {STRINGS:FormatKey('pmdorand/component:'.. component_id), 10, current_height, RogueElements.DirH.Left},
                {dynamic_text, -2, current_height, RogueElements.DirH.Right}
            }
            at[#texts] = {4, current_height, type = 'component', id = component_id}
            current_height = current_height + 10
        end
    end

    cache.lines.texts = texts
    cache.lines.at = at
end

local function set_cursor_pos(menu, x, y)
    x, y = (x or 0) + 10, y or 0
    local menu_height = menu.menu.Bounds.Height - 50
    local v = math.floor(y - menu_height / 3 * 2)
    if cache.current_scroll > v then
        if cache.current_scroll - v > menu_height / 3 then
            cache.current_scroll = math.max(0, math.floor(cache.current_scroll - (cache.current_scroll - v - menu_height / 3)))
        end
    elseif y > menu_height / 3 * 2 then
        cache.current_scroll = v
    end
    menu.elements.cursor.Loc = RogueElements.Loc(x, y + 19 - cache.current_scroll)
end

local function create_display_texts(menu)
    local max_height = cache.current_scroll + (menu.menu.Bounds.Height - 50)
    local hidden_top, hidden_bottom = cache.lines.at[1][2] < cache.current_scroll, true
    local output = {}
    local height, lines, line
    for i = 1, #cache.lines.texts do
        lines = cache.lines.texts[i] --[[@as table[] ]]
        height = cache.lines.at[i][2]
        if height > max_height then goto skip_remaining_lines__entered end
        if height > cache.current_scroll then
            for l = 1, #lines do
                line = lines[l]
                output[#output + 1] = {line[1], line[2], line[3] - cache.current_scroll, line[4], line[5]}
            end
        end
    end
    hidden_bottom = false
    ::skip_remaining_lines__entered::

    if hidden_top then
        output[#output + 1] = {'...', math.floor((menu.menu.Bounds.Width - 24) / 2), 6, RogueElements.DirH.None, RogueElements.DirV.Down} 
    end

    if hidden_bottom then
        output[#output + 1] = {'...', math.floor((menu.menu.Bounds.Width - 24) / 2), -2, RogueElements.DirH.None} 
    end

    return output
end

local last_dir
local sound_volume = 1.00
local inputs = {
    directions = {
        [RogueElements.Dir8.Up] = function(menu)
            if #cache.lines.at > 1 then cache.cursor = (cache.cursor - 2) % #cache.lines.at + 1 else cache.cursor = 1 end
            ---@type int[]
            local cursor_pos = cache.lines.at[(cache.cursor - 1) % #cache.lines.at + 1]
            set_cursor_pos(menu, cursor_pos[1], cursor_pos[2])
            play_sound('Menu/Select', sound_volume)
            return create_display_texts(menu)
        end,
        [RogueElements.Dir8.Down] = function(menu)
            if #cache.lines.at > 1 then cache.cursor = cache.cursor % #cache.lines.at + 1 else cache.cursor = 1 end
            ---@type int[]
            local cursor_pos = cache.lines.at[(cache.cursor - 1) % #cache.lines.at + 1]
            set_cursor_pos(menu, cursor_pos[1], cursor_pos[2])
            play_sound('Menu/Select', sound_volume)
            return create_display_texts(menu)
        end
    },
    bindings = {
        [input_type.Confirm] = function(_m, _i)
            _GAME:SE("Menu/Confirm")
        end
    }
}

return {
    name = STRINGS:FormatKey 'pmdorand:tab.components',
    ---@param menu pmdorand.ui.root
    entered = function(menu)
        create_lines()
        ---@type int[]
        local cursor_pos = cache.lines.at[(cache.cursor - 1) % (#cache.lines.at - 1) + 1]
        set_cursor_pos(menu, cursor_pos[1], cursor_pos[2])
        return create_display_texts(menu)
    end,
    ---@param menu pmdorand.ui.root
    left = function(menu)

    end,
    ---@param menu pmdorand.ui.root
    input = function(menu, input)
        for i, k in pairs(inputs.bindings) do
            if input:JustPressed(i) then
                return k(menu, input)
            end
        end
        local pending
        if inputs.directions[input.Direction] and menu.state.input_debounce == 0 then
            menu.elements.cursor:ResetTimeOffset()
            if input.Direction == last_dir then
                sound_volume = sound_volume - (sound_volume * 0.05)
            else
                sound_volume = 1
            end
            pending = inputs.directions[input.Direction](menu, input)
            menu.state.input_debounce = input.Direction == last_dir and 6 or 18
        end
        last_dir = input.Direction
        return pending
    end
}