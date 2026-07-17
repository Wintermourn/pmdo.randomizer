local async = require 'lib.pmdorand.async'
local play_sound = require 'pmdorand.util.play_sound'
local soft_translate = require 'pmdorand.util.soft_translate'
local configurations = require 'pmdorand.randomizer.cache.configurations'
local generation_manager = require 'pmdorand.randomizer.core.manager'
local configure = require 'pmdorand.ui.configure'
local component_registry = require 'pmdorand.randomizer.core.registry' .get 'components'
local provider_registry = require 'pmdorand.randomizer.core.registry' .get 'providers'
local strings = {
    component_count = soft_translate 'pmdorand:stats.components.count',
    component_span = soft_translate 'pmdorand:stats.components.span',
    enabled = soft_translate('pmdorand:enabled'),
    disabled = soft_translate('pmdorand:disabled')
}

local input_type = RogueEssence.FrameInput.InputType


local cache = {
    current_scroll = 0,
    cursor = 1,
    lines = {
        texts = {},
        at = {}
    },
    components = {},
    pending_update = nil
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
        enabledness = configurations.get_master(id).enabled
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
    cache.components = components

    table.sort(providers, function(a, b)
        return soft_translate('pmdorand/provider:'.. a) < soft_translate('pmdorand/provider:'.. b)
    end)

    local current_height = 0
    local dynamic_text, component_names, provider_enabled_count
    for _, provider_id in ipairs(providers) do
        ---@type table
        component_names = components[provider_id]
        ---@type {min: int, max: int}
        provider_enabled_count = enabled_counts[provider_id]
        table.sort(component_names, function(a, b)
            return soft_translate('pmdorand/component:'.. a) < soft_translate('pmdorand/component:'.. b)
        end)

        if provider_enabled_count.min == provider_enabled_count.max then
            dynamic_text = strings.component_count:format(#component_names, provider_enabled_count.min)
        else
            dynamic_text = strings.component_span:format(#component_names, provider_enabled_count.min, provider_enabled_count.max)
        end

        current_height = current_height + 2
        texts[#texts + 1] = {
            {soft_translate('pmdorand/provider:'.. provider_id), 6, current_height, RogueElements.DirH.Left},
            {dynamic_text, -2, current_height, RogueElements.DirH.Right}
        }
        at[#texts] = {0, current_height, type = 'provider', id = provider_id}
        current_height = current_height + 12
        for _, component_id in ipairs(component_names) do
            enabledness = configurations.get_master(component_id).enabled
            if enabledness == true then
                dynamic_text = soft_translate 'pmdorand:enabled'
            elseif enabledness == false then
                dynamic_text = soft_translate 'pmdorand:disabled'
            else
                dynamic_text = soft_translate 'pmdorand:dynamic' .. ('[color] (%02d%%)'):format(math.floor(enabledness * 100 + 0.5))
            end

            texts[#texts + 1] = {
                {soft_translate('pmdorand/component:'.. component_id), 10, current_height, RogueElements.DirH.Left},
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
    local max = math.maxinteger
    if #cache.lines.at > 0 then
        max = cache.lines.at[#cache.lines.at][2] + 2 - menu_height
    end
    if cache.current_scroll > v then
        if cache.current_scroll - v > menu_height / 3 then
            cache.current_scroll = math.min(max, math.max(0, math.floor(cache.current_scroll - (cache.current_scroll - v - menu_height / 3))))
        end
    elseif y > menu_height / 3 * 2 then
        cache.current_scroll = math.min(max, v)
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

local function prompt_enabledness(menu, id)
    local promise = async.promise()
    ---@type table
    local actions
    actions = {
        {soft_translate 'pmdorand:set_all_to' .. soft_translate 'pmdorand:enabled', true, function()
            for _, component_id in ipairs(cache.components[id]) do
                configurations.get_master(component_id).enabled = true
            end
            promise:resolve()
            _MENU:RemoveMenu()
        end},
        {soft_translate 'pmdorand:set_all_to' .. soft_translate 'pmdorand:dynamic', true, function()
            for _, component_id in ipairs(cache.components[id]) do
                configurations.get_master(component_id).enabled = 0.5
            end
            promise:resolve()
            _MENU:RemoveMenu()
        end},
        {soft_translate 'pmdorand:set_all_to' .. soft_translate 'pmdorand:disabled', true, function()
            for _, component_id in ipairs(cache.components[id]) do
                configurations.get_master(component_id).enabled = false
            end
            promise:resolve()
            _MENU:RemoveMenu()
        end}
    }

    local function close()
        promise:reject()
        _MENU:RemoveMenu()
    end
    actions[#actions + 1] = {'Cancel', true, close}
    require 'pmdorand.ui.choice' .open(
        function() promise:reject() end,
        table.unpack(actions)
    )
    return promise
end

local function prompt_component(menu, id)
    local component = component_registry:get(id)
    configure.open(component, configurations.get_master(id)):on_resolved(function()
        create_lines()
        cache.pending_update = create_display_texts(menu)
    end)
    --[[ local promise = async.promise()
    local actions = {}
    actions[#actions + 1] = {'Set Enabledness', true, function()
        prompt_enabledness(menu, 'component', id):on_resolved(function()
            create_lines()
            cache.pending_update = create_display_texts(menu)
            _MENU:RemoveMenu()
        end):on_rejected(function()
            _MENU:RemoveMenu()
        end)
    end}
    actions[#actions + 1] = {'Configure', true, function()
        _MENU:RemoveMenu()
        local component = component_registry:get(id)
        configure.open(component, configurations.get(id))
    end}
    local function close()
        promise:reject()
        _MENU:RemoveMenu()
    end
    actions[#actions + 1] = {'Cancel', true, close}
    require 'pmdorand.ui.choice' .open(
        function() promise:reject() end,
        table.unpack(actions)
    ) ]]
end

local function jump_to_previous_provider(menu)
    if #cache.lines.at > 1 then cache.cursor = (cache.cursor - 2) % #cache.lines.at + 1 else cache.cursor = 1 end
    while cache.lines.at[cache.cursor].type ~= 'provider' do
        if #cache.lines.at > 1 then cache.cursor = (cache.cursor - 2) % #cache.lines.at + 1 else cache.cursor = 1; break end
    end
    ---@type int[]
    local cursor_pos = cache.lines.at[(cache.cursor - 1) % #cache.lines.at + 1]
    set_cursor_pos(menu, cursor_pos[1], cursor_pos[2])
    _GAME:SE 'Menu/Skip'
    return create_display_texts(menu)
end

local function jump_to_next_provider(menu)
    if #cache.lines.at > 1 then cache.cursor = cache.cursor % #cache.lines.at + 1 else cache.cursor = 1 end
    while cache.lines.at[cache.cursor].type ~= 'provider' do
        if #cache.lines.at > 1 then cache.cursor = cache.cursor % #cache.lines.at + 1 else cache.cursor = 1; break end
    end
    ---@type int[]
    local cursor_pos = cache.lines.at[(cache.cursor - 1) % #cache.lines.at + 1]
    set_cursor_pos(menu, cursor_pos[1], cursor_pos[2])
    _GAME:SE 'Menu/Skip'
    return create_display_texts(menu)
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
        [input_type.Confirm] = function(menu, _i)
            _GAME:SE("Menu/Confirm")
            local at = cache.lines.at[cache.cursor]
            if at == nil then return end
            if at.type == 'component' then
                prompt_component(menu, at.id)
            else
                prompt_enabledness(menu, at.id):on_resolved(function()
                    create_lines()
                    cache.pending_update = create_display_texts(menu)
                end)
            end
        end,
        [input_type.LeaderSwap1] = jump_to_previous_provider,
        [input_type.LeaderSwap2] = jump_to_next_provider,
        [input_type.LeaderSwapBack] = jump_to_previous_provider,
        [input_type.LeaderSwapForth] = jump_to_next_provider
    }
}

return {
    name = select(2, RogueEssence.Text.Strings:TryGetValue('pmdorand:tab.components')) or 'pmdorand:tab.components',
    ---@param menu pmdorand.ui.root
    entered = function(menu)
        create_lines()
        ---@type int[]
        local cursor_pos = cache.lines.at[(cache.cursor - 1) % #cache.lines.at + 1]
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
                menu.elements.cursor:ResetTimeOffset()
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

        if pending then
            return pending
        elseif cache.pending_update then
            local out = cache.pending_update
            cache.pending_update = nil
            return out
        end
    end
}