local input_type = RogueEssence.FrameInput.InputType

local async = require 'lib.pmdorand.async'

local clipboard = require 'pmdorand.util.clipboard'
local create_text = require 'pmdorand.util.create_text'
local graphics = require 'pmdorand.util.graphics'
local play_sound = require 'pmdorand.util.play_sound'
local soft_translate = require 'pmdorand.util.soft_translate'
local text_pool = require 'pmdorand.util.text_pool'

local strings = {
    setting = soft_translate 'pmdorand:documentation.setting',
    config = soft_translate 'pmdorand:documentation.config'
}

local function exit(state)
    _GAME:SE 'Menu/Cancel'
    state.promises.on_exit:resolve()
    _MENU:RemoveMenu()
end

local function update_title(state)
    local page = state.pages[state.position.page]
    if page then
        state.elements.frame.title:SetText(state.pages[state.position.page][1])
        state.elements.frame.info:SetText(string.format('[color=#dddddd]%s [color=#999999](%d/%d)', page.is_setting and strings.setting or strings.config, state.position.page, #state.pages))
    else
        state.elements.frame.info:SetText(string.format('[color=#999999](%d/%d)', state.position.page, #state.pages))
    end
end

local function create_body(state)
    local page = state.pages[state.position.page]
    if page then
        local texts = RogueEssence.Menu.MenuText.BreakIntoLines(page[2], state.menu.Bounds.Width - 18)
        local lines = {}
        for i = 0, texts.Length - 1, 1 do
            lines[i + 1] = {texts[i], 0, i * 12}
        end
        state.lines = lines
        text_pool.update_text(state.menu, state.elements.pool, lines, 10, 20)
    else
        text_pool.hide_all(state.menu, state.elements.pool)
    end
end

local function update_body(state)
    local page = state.pages[state.position.page]
    if page then
        state.elements.frame.title:SetText(state.pages[state.position.page][1])
        state.elements.frame.info:SetText(string.format('[color=#dddddd]%s [color=#999999](%d/%d)', page.is_setting and strings.setting or strings.config, state.position.page, #state.pages))
    else
        state.elements.frame.info:SetText(string.format('[color=#999999](%d/%d)', state.position.page, #state.pages))
    end
end

local directions = {
    [RogueElements.Dir8.Left] = function(state)
        state.position.page = (state.position.page - 2) % #state.pages + 1
        play_sound('Menu/Select', state.input.sound_volume)
        update_title(state)
        create_body(state)
    end,
    [RogueElements.Dir8.Right] = function(state)
        state.position.page = state.position.page % #state.pages + 1
        play_sound('Menu/Select', state.input.sound_volume)
        update_title(state)
        create_body(state)
    end,
    [RogueElements.Dir8.Up] = function(state)
        play_sound('Menu/Speak', state.input.sound_volume)
    end,
    [RogueElements.Dir8.Down] = function(state)
        play_sound('Menu/Speak', state.input.sound_volume)
    end
}

local __Keys = luanet.namespace 'Microsoft.Xna.Framework.Input' .Keys
local function controls_listener(state, input)
    if input:JustPressed(input_type.Menu) or input:JustPressed(input_type.Cancel) then
        exit(state)
        return
    end
    if state.input.debounce > 0 then state.input.debounce = state.input.debounce - 1 end

    if input:BaseKeyDown(__Keys.LeftControl) and input:BaseKeyPressed(__Keys.C) then
        local key = state.pages[state.position.page].key
        if key == nil then return _GAME:SE 'Menu/Cancel' end
        clipboard.copy_text(key)
        _GAME:SE 'Menu/Sort'
        return
    end

    local different_direction = input.Direction ~= state.input.last_direction
    if directions[input.Direction] and (state.input.debounce == 0 or different_direction) then
        state.input.sound_volume = different_direction and 1 or (state.input.sound_volume - state.input.sound_volume * 0.05)
        state.input.debounce = different_direction and 18 or 6
        directions[input.Direction](state, input)
    end
    state.input.last_direction = input.Direction
end

local public = {}

function public.open(...)
    local state = {
        pages = {...},
        lines = {},
        input = {
            sound_volume = 1,
            debounce = 0,
            last_direction = nil
        },
        position = {
            page = 1,
            height = 0
        },
        elements = {
            frame = {},
            pool = {}
        },
        promises = {
            on_exit = async.promise()
        }
    }

    local ww, wh = graphics.get_screen_dimensions()
    local mw, mh = ww, math.max(128, wh - 128)
    state.menu = RogueEssence.Menu.ScriptableMenu(0, wh - mh, mw, mh, function(i) controls_listener(state, i) end)

    local realElements, stateElements = state.menu.Elements, state.elements

    stateElements.frame.title = create_text('?', 10, 7)
    stateElements.frame.info = create_text('?', mw - 10, 7, RogueElements.DirH.Right)
    update_title(state)
    create_body(state)

    realElements:Add(stateElements.frame.title)
    realElements:Add(stateElements.frame.info)
    realElements:Add(RogueEssence.Menu.MenuDivider(RogueElements.Loc(10, 18), mw - 20))

    _MENU:AddMenu(state.menu, true)
    return state.promises.on_exit
end

return public