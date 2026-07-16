local graphics = require 'pmdorand.util.graphics'
local play_sound = require 'pmdorand.util.play_sound'
local create_text = require 'pmdorand.util.create_text'
local text_pool = require 'pmdorand.util.text_pool'
local input_type = RogueEssence.FrameInput.InputType

local handlers = require 'pmdorand.ui.configure.handlers'

local function update_title(state)
    local segments = {
        STRINGS:FormatKey('pmdorand/provider:'.. state.component.provider_id)
    }
    for _, level in ipairs(state.stack) do
        segments[#segments + 1] = STRINGS:FormatKey(level.translation_key)
    end

    state.elements.frame.title:SetText(table.concat(segments, ' [color=#777777]>[color] '))
end

local priority_keys = {
    enabled = 1,
    randomization_chance = 2 
}

local function sort_values(a, b)
    if type(a) == 'table' then a = table.concat(a, '.') end
    if type(b) == 'table' then b = table.concat(b, '.') end
    local prio_a, prio_b = priority_keys[a], priority_keys[b]

    if prio_a and prio_b then
        return prio_a < prio_b
    elseif prio_a then
        return true
    elseif prio_b then
        return false
    end
    return a < b
end

local function compile_translation_key(state, key)
    local path = {}
    for _, level in ipairs(state.stack) do
        path[#path + 1] = level.key
    end
    path[#path + 1] = key
    return 'pmdorand/settings:'.. table.concat(path, '/')
end

local function current(state)
    return state.stack[#state.stack][1]
end
local function current_structure(state)
    return state.stack[#state.stack][2]
end

local function push(state, key)
    local next = current_structure(state)[key]
    if type(next) == 'table' and getmetatable(next).is_configuration then
        state.stack[#state.stack].cursor = state.cursor
        state.stack[#state.stack].current_scroll = state.current_scroll
        state.stack[#state.stack + 1] = {current(state)[key], next, translation_key = compile_translation_key(state, key), key = key}
    end
end

local function pop(state)
    _GAME:SE 'Menu/Cancel'
    ---@type table
    local stack = state.stack
    if #stack == 1 then 
        _MENU:RemoveMenu()
        return
    end
    stack[#stack] = nil

    ---@type table
    local top = stack[#stack]
    state.cursor = top.cursor or 1
    if top.current_scroll then
        state.current_scroll = top.current_scroll
    else
        local fallback = state.cursor * 10
        local max_height = (state.menu.Bounds.Height - 32) / 3 * 2
        if fallback > max_height then
            fallback = math.floor(max_height)
        end
        state.current_scroll = fallback
    end
end

---@type (fun(c: Config.Base, v: table): (fun(): any, Config.Base, any))[]
local body_iterators = {
    ['Config.Table'] = function(c, v)
        local key, next_key, conf
        return function()
            next_key, conf = next(c.content, key)
            if next_key == nil then return end
            key = next_key
            return key, conf, v[key]
        end
    end,
    ['Config.Feature'] = function(c, v)
        local preliminary = {'enabled', 'randomization_chance'}
        local prelim, prelim_max = 0, 2
        local index, next_index, key
        return function()
            if prelim < prelim_max then
                prelim = prelim + 1
                local key = preliminary[prelim]
                return preliminary[prelim], c[key], v[key], 'pmdorand/settings:standard/'.. key
            end
            next_index, key = next(c.ordered_keys, index)
            if next_index == nil then return end
            index = next_index
            return {'options', key}, c.content[key], v.options[key]
        end
    end
}

local entry_fetch = {
    ['Config.Table'] = function(c, v)
        local keys, configs, values, reserved_translations = {}, {}, {}, {}

        for key, conf in pairs(c.content) do
            keys[#keys + 1] = key
            configs[key] = conf
            values[key] = v[key]
        end
        table.sort(keys, sort_values)

        return keys, configs, values, reserved_translations
    end,
    ['Config.Feature'] = function(c, v)
        local keys, configs, values, reserved_translations = {}, {}, {}, {}

        for _, key in ipairs {'enabled', 'randomization_chance'} do
            keys[#keys + 1] = key
            configs[key] = c[key]
            values[key] = v[key]
            reserved_translations[key] = 'pmdorand/settings:standard/'.. key
        end
        for _, key in ipairs(c.ordered_keys) do
            print(key)
            local out_key = {'options', key}
            keys[#keys + 1] = out_key
            configs[out_key] = c.content[key]
            values[out_key] = v.options[key]
        end

        return keys, configs, values, reserved_translations
    end
}

local function update_contents(state)
    local by_index, by_key = {}, {}

    local fetch = entry_fetch[getmetatable(current_structure(state)).__title]
    if fetch == nil then error 'whar' end
    local keys, configs, values, reserved_translations = fetch(current_structure(state), current(state))

    local entry
    for i, key in ipairs(keys) do
        entry = {
            texts = {
                {STRINGS:FormatKey(reserved_translations[key] or compile_translation_key(state, type(key) ~= 'table' and tostring(key) or table.concat(key, '.'))), 12, (i - 1) * 12},
                {handlers.get(configs[key].__title).display(configs[key], values[key]), -2, (i - 1) * 12, RogueElements.DirH.Right}
            },
            setting = configs[key], value = values[key]
        }
        by_index[#by_index + 1] = entry
        by_key[key] = entry
    end

    state.current_contents = {by_index = by_index, by_key = by_key}
    return by_index
end

local function update_body(state)
    local lines = state.current_contents.by_index
    local texts = {}

    local from, to = math.ceil(state.current_scroll / 10 + 1), math.floor((state.menu.Bounds.Height - 34) / 10)
    for i = from, to do
        if lines[i] == nil then break end
        for _, k in pairs(lines[i].texts) do
            k[3] = (i - 1) * 12 - state.current_scroll
            texts[#texts + 1] = k
        end
    end

    text_pool.update_text(state.menu, state.elements.pool, texts, 12, 21, 20, 12)
end

local function set_cursor_pos(state, x, y)
    x, y = (x or 0) + 10, y or 0
    local menu_height = state.menu.Bounds.Height - 50
    local v = math.floor(y - menu_height / 3 * 2)
    if state.current_scroll > v then
        if state.current_scroll - v > menu_height / 3 then
            state.current_scroll = math.max(0, math.floor(state.current_scroll - (state.current_scroll - v - menu_height / 3)))
        end
    elseif y > menu_height / 3 * 2 then
        state.current_scroll = v
    end
    state.elements.cursor.Loc = RogueElements.Loc(x, y + 21 - state.current_scroll)
end

local last_dir
local sound_volume = 1.00
local inputs = {
    directions = {
        [RogueElements.Dir8.Up] = function(state)
            if state.cursor == 1 then state.cursor = #state.current_contents else state.cursor = state.cursor - 1 end
            set_cursor_pos(state, 0, (state.cursor - 1) * 12)
            update_body(state)
            play_sound('Menu/Select', sound_volume)
        end,
        [RogueElements.Dir8.Down] = function(state)
            if state.cursor == #state.current_contents then state.cursor = 1 else state.cursor = state.cursor + 1 end
            set_cursor_pos(state, 0, (state.cursor - 1) * 12)
            update_body(state)
            play_sound('Menu/Select', sound_volume)
        end
    },
    bindings = {
        [input_type.Cancel] = function(state)
            pop(state)
        end
    }
}

local function close_menu()
    _GAME:SE("Menu/Cancel")
    _MENU:RemoveMenu()
end
local function controls_listener(menu, input)
    if menu.input_debounce > 0 then menu.input_debounce = menu.input_debounce - 1 end
    if input:JustPressed(input_type.Menu) then
        close_menu()
        return
    end

    for i, k in pairs(inputs.bindings) do
        if input:JustPressed(i) then
            menu.elements.cursor:ResetTimeOffset()
            return k(menu, input)
        end
    end
    local pending
    if inputs.directions[input.Direction] and (menu.input_debounce == 0 or input.Direction ~= last_dir) then
        menu.elements.cursor:ResetTimeOffset()
        if input.Direction == last_dir then
            sound_volume = sound_volume - (sound_volume * 0.05)
        else
            sound_volume = 1
        end
        pending = inputs.directions[input.Direction](menu, input)
        menu.input_debounce = input.Direction == last_dir and 6 or 18
    end
    last_dir = input.Direction
end

local public = {}

---@param component pmdorand.component
function public.open(component, settings)
    local state = {
        input_debounce = 0,
        cursor = 1,
        current_scroll = 0,
        component = component,
        settings = settings,
        structure = component.settings,
        stack = {{settings, component.settings, translation_key = 'pmdorand/component:'.. component.id, key = component.id}},
        elements = {
            frame = {},
            pool = {}
        },
        current_contents = {
            by_index = {},
            by_key = {}
        }
    }
    
    local ww, wh = graphics.get_screen_dimensions()
    local mw, mh = ww - 24, wh - 16--math.floor(wh * 0.7)
    state.menu = RogueEssence.Menu.ScriptableMenu(16, 8, mw, mh, function(i) controls_listener(state, i) end)

    state.elements.frame.title = create_text('', 10, 7, RogueElements.DirH.Left)
    update_title(state)

    state.menu.Elements:Add(state.elements.frame.title)
    state.menu.Elements:Add(RogueEssence.Menu.MenuDivider(RogueElements.Loc(10, 18), mw - 20))

    state.elements.cursor = RogueEssence.Menu.MenuCursor(state.menu)
    set_cursor_pos(state, 0, 0)
    state.menu.Elements:Add(state.elements.cursor)

    update_contents(state)
    update_body(state)

    _MENU:AddMenu(state.menu, true)
end

return public