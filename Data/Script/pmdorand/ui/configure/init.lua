local async = require 'lib.pmdorand.async'
local config = require 'pmdorand.config'
local graphics = require 'pmdorand.util.graphics'
local create_text = require 'pmdorand.util.create_text'
local text_pool = require 'pmdorand.util.text_pool'
local play_sound = require 'pmdorand.util.play_sound'
local __InputType = RogueEssence.FrameInput.InputType

local handlers = require 'pmdorand.ui.configure.handlers'

local blank = {}

---@type {[string]: int?}
local priority_keys = {
    enabled = 1, randomization_chance = 2
}
local function sort_keys(a, b)
    local prio_a, prio_b = priority_keys[a.value.flat], priority_keys[b.value.flat]

    if prio_a and prio_b then
        return prio_a < prio_b
    elseif prio_a then
        return true
    elseif prio_b then
        return false
    end
    return a.value.flat < b.value.flat
end

local function compile_translation_key(state, key)
    local path = {}
    for _, level in ipairs(state.stack) do
        path[#path + 1] = level.id
    end
    path[#path + 1] = key
    return 'pmdorand/settings:'.. table.concat(path, '/')
end

local function current_values(state)
    return state.stack[#state.stack].values
end

local function current_structure(state)
    return state.stack[#state.stack].structure
end

local function data_key(structure, value)
    if type(structure) ~= 'table' then structure = {structure} end
    if type(value) ~= 'table' then value = {value} end
    structure.flat = table.concat(structure, '.')
    value.flat = table.concat(value, '.')
    return {config = structure, value = value}
end

local stat_entries = {
    {
        struct = {'structure', 'minimum'},
        value = 'minimum',
        translation = 'pmdorand/settings:stat/minimum'
    },
    {
        struct = {'structure', 'maximum'},
        value = 'maximum',
        translation = 'pmdorand/settings:stat/maximum'
    },
    {
        struct = {'structure', 'mode'},
        value = {'range', 'mode'},
        translation = 'pmdorand/settings:stat/mode'
    },
    {
        struct = {'structure', 'value'},
        value = {'range', 'value'},
        translation = 'pmdorand/settings:stat/mode'
    },
    {
        struct = {'structure', 'original_pull'},
        value = 'originalPull',
        translation = 'pmdorand/settings:stat/pull'
    }
}
local entry_fetch = {
    ['Config.Stat'] = function(struct, vals)
        local keys, configs, values, value_pointers, translation_keys = {}, {}, {}, {}, {}

        local out_key
        for _, entry in ipairs(stat_entries) do
            out_key = data_key(entry.struct, entry.value)
            keys[#keys + 1] = out_key
            local ptr = struct
            if #out_key.config > 1 then
                for i = 1, #out_key.config do
                    ptr = ptr[out_key.config[i]]
                end 
            end
            configs[out_key] = ptr
            ptr = vals
            if #out_key.value > 1 then
                for i = 1, #out_key.value - 1 do
                    ptr = ptr[out_key.value[i]]
                end
            end
            values[out_key] = ptr[out_key.value[#out_key.value]]
            value_pointers[out_key] = {ptr, out_key.value[#out_key.value]}
            translation_keys[out_key] = entry.translation
        end

        return keys, configs, values, value_pointers, translation_keys
    end,
    ['Config.Table'] = function(struct, vals)
        local keys, configs, values, value_pointers = {}, {}, {}, {}

        local out_key
        for key, conf in pairs(struct.content) do
            out_key = data_key({'content', key}, key)
            keys[#keys + 1] = out_key
            configs[out_key] = conf
            values[out_key] = vals[key]
            value_pointers[out_key] = {vals, key}
        end
        table.sort(keys, sort_keys)

        return keys, configs, values, value_pointers, blank
    end,
    ['Config.Feature'] = function(struct, vals)
        local keys, configs, values, value_pointers, translation_keys = {}, {}, {}, {}, {}

        local out_key
        for _, key in ipairs { 'enabled', 'randomization_chance' } do
            out_key = data_key(key, key)
            keys[#keys + 1] = out_key
            configs[out_key] = struct[key]
            values[out_key] = vals[key]
            value_pointers[out_key] = {vals, key}
            translation_keys[out_key] = 'pmdorand/settings:feature/'.. key
        end
        for _, key in ipairs(struct.ordered_keys) do
            out_key = data_key({'content', key}, {'options', key})
            keys[#keys + 1] = out_key
            configs[out_key] = struct.content[key]
            values[out_key] = vals.options[key]
            value_pointers[out_key] = {vals.options, key}
        end

        return keys, configs, values, value_pointers, translation_keys
    end
}

local function update_title(state)
    local translation_key = 'pmdorand/provider:'.. state.component.provider_id
    local segments = {(select(2, RogueEssence.Text.Strings:TryGetValue(translation_key))) or translation_key}--RogueEssence.Text.Strings:ContainsKey(translation_key) and STRINGS:FormatKey(translation_key) or translation_key}
    for _, level in ipairs(state.stack) do
        segments[#segments + 1] = (select(2, RogueEssence.Text.Strings:TryGetValue(level.translation_key))) or level.translation_key
        --__CollectionExtensions.GetValueOrDefault(RogueEssence.Text.Strings, level.translation_key, level.translation_key)--RogueEssence.Text.Strings:ContainsKey(level.translation_key) and STRINGS:FormatKey(level.translation_key) or level.translation_key
    end
    local text = state.elements.frame.title
    text:SetText(table.concat(segments, ' [color=#777777]>[color] '))
    local w = text:GetTextLength()
    if w > state.menu.Bounds.Width - 20 then
        text.AlignH = RogueElements.DirH.Right
        text.Loc = RogueElements.Loc(state.menu.Bounds.Width - 10, 7) 
    else
        text.AlignH = RogueElements.DirH.Left
        text.Loc = RogueElements.Loc(10, 7)
    end
end

local function update_contents(state)
    local by_index, by_key = {}, {}

    local fetch = entry_fetch[getmetatable(current_structure(state)).__title]
    if fetch == nil then error 'whar' end
    local keys, configs, values, value_pointers, translation_keys = fetch(current_structure(state), current_values(state))

    local entry, translation_key
    for i, key in ipairs(keys) do
        translation_key = translation_keys[key] or compile_translation_key(state, key.value.flat)
        entry = {
            texts = {
                {RogueEssence.Text.Strings:ContainsKey(translation_key) and STRINGS:FormatKey(translation_key) or translation_key, 12, (i - 1) * 12},
                {handlers.get(configs[key].__title).display(configs[key], values[key]), -2, (i - 1) * 12, RogueElements.DirH.Right}
            },
            setting = configs[key], value = values[key], keys = key, value_pointer = value_pointers[key], translation_key = translation_key
        }
        by_index[#by_index + 1] = entry
        by_key[key] = entry
    end

    state.contents = {by_index = by_index, by_key = by_key}
    return by_index
end

local function set_cursor_pos(state, x, y)
    x, y = (x or 0) + 10, y or 0
    local menu_height = state.menu.Bounds.Height - 29
    local v = math.floor(y - menu_height / 3 * 2 - 5)
    if state.position.scroll > v then
        if state.position.scroll - v > menu_height / 3 then
            state.position.scroll = math.max(
                0,
                math.floor(state.position.scroll - (state.position.scroll - v - menu_height / 3))
            ) 
        end
    elseif y > menu_height / 3 * 2 then
        state.position.scroll = v - 2
    end
    state.elements.cursor.Loc = RogueElements.Loc(x, y + 21 - state.position.scroll)
end

local function update_body(state)
    local lines = state.contents.by_index
    local texts = {}

    local from, to = math.max(1, math.ceil(state.position.scroll / 12)), math.floor((state.menu.Bounds.Height - 34) / 12)
    for i = from, to do
        if lines[i] == nil then break end
        for _, k in pairs(lines[i].texts) do
            k[3] = (i - 1) * 12 - state.position.scroll
            texts[#texts + 1] = k
        end
    end

    text_pool.update_text(state.menu, state.elements.pool, texts, 12, 21, 20, 12)
    set_cursor_pos(state, 0, (state.position.cursor - 1) * 12)
end

local function push(state, identifier, structure, values, translation_key)
    if #state.stack > 0 then
        state.stack[#state.stack].memory = {
            cursor = state.position.cursor,
            scroll = state.position.scroll
        }
    end
    state.stack[#state.stack + 1] = {
        id = identifier,
        translation_key = translation_key or compile_translation_key(state, identifier),
        structure = structure,
        values = values
    }
    state.position.cursor = 1
    state.position.scroll = 0
end

local function pop(state)
    _GAME:SE 'Menu/Cancel'
    local stack = state.stack
    if #stack == 1 then
        state.promises.on_exit:resolve()
        _MENU:RemoveMenu()
        return 
    end
    stack[#stack] = nil

    local last = stack[#stack]
    state.position.cursor = last.memory and last.memory.cursor or 1
    state.position.scroll = last.memory and last.memory.scroll or math.min(0, math.floor(state.position.cursor * 10 - state.menu.Bounds.Height / 3 * 2))
end

---@return boolean
local function interact_with_hovered(state, method, ...)
    local hovered = state.contents.by_index[state.position.cursor]
    if not hovered then
        return false
    end
    local handler = handlers.get(hovered.setting.__title)
    if type(handler[method]) ~= 'function' then
        return false
    end
    local res = handler[method](state, hovered, ...)
    return res ~= false
end

local inputs = {
    directions = {
        [RogueElements.Dir8.Up] = function(state)
            if state.position.cursor == 1 then
                state.position.cursor = #state.contents.by_index 
            else
                state.position.cursor = state.position.cursor - 1
            end
            update_body(state)
            play_sound('Menu/Select', state.input.sound_volume)
        end,
        [RogueElements.Dir8.Down] = function(state)
            if state.position.cursor == #state.contents.by_index then
                state.position.cursor = 1
            else
                state.position.cursor = state.position.cursor + 1
            end
            
            update_body(state)
            play_sound('Menu/Select', state.input.sound_volume)
        end,
        [RogueElements.Dir8.Left] = function(state, input)
            if interact_with_hovered(state, 'move', input, -1) then
                play_sound('Menu/Select', state.input.sound_volume) 
            else
                play_sound('Menu/Cancel', math.max(0.1, state.input.sound_volume))
                state.input.debounce = math.maxinteger
            end
            update_body(state)
        end,
        [RogueElements.Dir8.Right] = function(state, input)
            if interact_with_hovered(state, 'move', input, 1) then
                play_sound('Menu/Select', state.input.sound_volume) 
            else
                play_sound('Menu/Cancel', math.max(0.1, state.input.sound_volume))
                state.input.debounce = math.maxinteger
            end
            update_body(state)
        end
    },
    bindings = {
        [__InputType.Cancel] = function(state)
            pop(state)
            update_title(state)
            update_contents(state)
            update_body(state)
        end,
        [__InputType.Confirm] = function(state)
            if interact_with_hovered(state, 'select') then
                play_sound('Menu/Confirm', 0.8) 
            else
                play_sound('Menu/Cancel', 0.8) 
            end
            update_body(state)
        end
    }
}

local __Keys = luanet.namespace 'Microsoft.Xna.Framework.Input' .Keys
local SDL = luanet.namespace 'SDL2' .SDL
local function controls_listener(state, input)
    if input:JustPressed(__InputType.Menu) then
        _GAME:SE 'Menu/Cancel'
        state.promises.on_exit:resolve()
        _MENU:RemoveMenu()
    end
    if state.input.debounce > 0 then state.input.debounce = state.input.debounce - 1 end

    if input:BaseKeyDown(__Keys.LeftControl) and input:BaseKeyPressed(__Keys.C) then
        local key = state.contents.by_index[state.position.cursor].translation_key
        if key == nil then return _GAME:SE 'Menu/Cancel' end
        SDL.SDL_SetClipboardText(key)
        _GAME:SE 'Menu/Sort'
        return
    end

    for i,k in pairs(inputs.bindings) do
        if input:JustPressed(i) then
            state.elements.cursor:ResetTimeOffset()
            return k(state, input)
        end
    end

    local different_direction = input.Direction ~= state.input.last_direction
    if inputs.directions[input.Direction] and (state.input.debounce == 0 or different_direction) then
        state.elements.cursor:ResetTimeOffset()
        state.input.sound_volume = different_direction and 1 or (state.input.sound_volume - state.input.sound_volume * 0.05)
        state.input.debounce = different_direction and 18 or 6
        inputs.directions[input.Direction](state, input)
    end
    state.input.last_direction = input.Direction
end

local public = {}

function public.open(component, user_settings)
    local state = {
        component = component,
        stack = {},
        settings = {
            structure = component.settings,
            values = user_settings
        },
        position = {
            cursor = 1,
            scroll = 0
        },
        promises = {
            on_exit = async.promise()
        },
        input = {
            sound_volume = 1,
            debounce = 0,
            last_direction = nil
        },
        contents = {},
        elements = {
            frame = {},
            pool = {}
        },
        push = push, pop = pop,
        update_title = update_title,
        update_contents = update_contents,
        update_body = update_body,
        current_structure = current_structure,
        current_values = current_values
    }
    push(state, component.id, component.settings, user_settings, 'pmdorand/component:'.. component.id)

    local ww, wh = graphics.get_screen_dimensions()
    local mw, mh = ww - 24, wh - 16--math.floor(wh * 0.7)
    state.menu = RogueEssence.Menu.ScriptableMenu(16, 8, mw, mh, function(i) controls_listener(state, i) end)

    local realElements, stateElements = state.menu.Elements, state.elements

    stateElements.frame.title = create_text('?', 10, 7)
    update_title(state)

    realElements:Add(stateElements.frame.title)
    realElements:Add(RogueEssence.Menu.MenuDivider(RogueElements.Loc(10, 18), mw - 20))

    stateElements.cursor = RogueEssence.Menu.MenuCursor(state.menu)
    --set_cursor_pos(state, 0, 0)
    realElements:Add(stateElements.cursor)

    update_contents(state)
    update_body(state)

    _MENU:AddMenu(state.menu, true)

    return state.promises.on_exit
end

return public