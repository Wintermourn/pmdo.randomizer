local graphics = require 'pmdorand.util.graphics'
local play_sound = require 'pmdorand.util.play_sound'
local create_text = require 'pmdorand.util.create_text'
local text_pool = require 'pmdorand.util.text_pool'
local input_type = RogueEssence.FrameInput.InputType

local function update_title(state)
    local segments = {
        STRINGS:FormatKey('pmdorand/provider:'.. state.component.provider_id)
    }
    for _, level in ipairs(state.path) do
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
    for _, level in ipairs(state.path) do
        path[#path + 1] = level.key
    end
    path[#path + 1] = key
    return 'pmdorand/settings:'.. table.concat(path, '/')
end

local function current(state)
    return state.path[#state.path][1]
end
local function current_structure(state)
    return state.path[#state.path][2]
end

local function push(state, key)
    local next = current_structure(state)[key]
    if type(next) == 'table' and getmetatable(next).is_configuration then
        state.path[#state.path + 1] = {current(state)[key], next, translation_key = compile_translation_key(state, key), key = key}
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
        local key, next_key, conf
        return function()
            if prelim < prelim_max then
                prelim = prelim + 1
                local key = preliminary[prelim]
                return preliminary[prelim], c[key], v[key], 'pmdorand/settings:standard/'.. key
            end
            next_key, conf = next(c.content, key)
            if next_key == nil then return end
            key = next_key
            return {'options', key}, conf, v.options[key]
        end
    end
}

local function update_body(state)
    local iterator = body_iterators[getmetatable(current_structure(state)).__title]
    if iterator == nil then error 'whar' end
    iterator = iterator(current_structure(state), current(state))
    local keys, configs, values, reserved_translations = {}, {}, {}, {}
    local key, config, value, reserved
    while true do
        key, config, value, reserved = iterator()
        if key == nil then break end
        keys[#keys + 1] = key
        configs[key] = config
        values[key] = value
        reserved_translations[key] = reserved
    end
    table.sort(keys, sort_values)

    local texts = {}
    for i, key in ipairs(keys) do
        texts[#texts + 1] = {STRINGS:FormatKey(reserved_translations[key] or compile_translation_key(state, type(key) ~= 'table' and tostring(key) or table.concat(key, '.'))), 12, (i - 1) * 12}
    end

    text_pool.update_text(state.menu, state.elements.pool, texts, 12, 19, 20, 12)
end

local last_dir
local sound_volume = 1.00
local inputs = {
    directions = {
        [RogueElements.Dir8.Up] = function(menu)
            play_sound('Menu/Select', sound_volume)
        end,
        [RogueElements.Dir8.Down] = function(menu)
            play_sound('Menu/Select', sound_volume)
        end
    },
    bindings = {
    }
}

local function close_menu()
    _GAME:SE("Menu/Cancel")
    _MENU:RemoveMenu()
end
local function controls_listener(menu, input)
    if input:JustPressed(input_type.Cancel) or input:JustPressed(input_type.Menu) then
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
    if inputs.directions[input.Direction] and menu.input_debounce == 0 then
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
        current_height = 0,
        component = component,
        settings = settings,
        structure = component.settings,
        path = {{settings, component.settings, translation_key = 'pmdorand/component:'.. component.id, key = component.id}},
        elements = {
            frame = {},
            pool = {}
        }
    }
    
    local ww, wh = graphics.get_screen_dimensions()
    local mw, mh = ww - 24, wh - 16--math.floor(wh * 0.7)
    state.menu = RogueEssence.Menu.ScriptableMenu(16, 8, mw, mh, function(i) controls_listener(state.menu, i) end)

    state.elements.frame.title = create_text('', 10, 7, RogueElements.DirH.Left)
    update_title(state)

    state.menu.Elements:Add(state.elements.frame.title)

    update_body(state)

    _MENU:AddMenu(state.menu, true)
end

return public