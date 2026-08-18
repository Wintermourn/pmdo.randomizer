local async = require 'lib.pmdorand.async'

local create_text = require 'pmdorand.util.create_text'
local graphics = require 'pmdorand.util.graphics'
local header = require 'pmdorand.util.header'
local play_sound = require 'pmdorand.util.play_sound'

local __InputType = RogueEssence.FrameInput.InputType

local has_bgm_pitcher = luanet.ctype(RogueEssence.Content.SoundManager):GetMethod("SetBGMPitch") ~= nil
--- Holds local data for the menu, made accessible for other scripts in case changes need to be made.
local global_state = {
    --- Holds the last song playing before the menu is first opened. This is set once.
    ---@type string?
    last_song = nil,
    ---@type string[]
    music_pool = {
        'Rescue.ogg',
        'Lava Floe Island Water.ogg',
        'Shop.ogg',
        'Mysterious Passage.ogg',
        'Demonstration 3.ogg'
    },
    placeholders = {
        tab_title = select(2, RogueEssence.Text.Strings:TryGetValue('pmdorand:tab.number')) or '%s [color=#aaaaaa](%d/%d)'
    },
    --- Holds the constructors for all of the menu's tabs. Each entry should be a table containing `new()`.
    --- The order of entries decides the order of tabs in the menu.
    tabs = {
        (require 'pmdorand.ui.root.tabs.status'),
        (require 'pmdorand.ui.root.tabs.archipelago'),
        (require 'pmdorand.ui.root.tabs.settings'),
        (require 'pmdorand.ui.root.tabs.components')
    }
}

local function exit(state)
    local tab = state.tabs[state.position.tab]
    if tab then
        if tab.on_exit and tab:on_exit(state) == false then
            _GAME:SE 'Menu/Cancel'
            return
        end
    end
    _GAME:SE 'Menu/Cancel'
    state.promises.on_exit:resolve()
    --service.set_music_pitch()
    if has_bgm_pitcher then RogueEssence.Content.SoundManager.SetBGMPitch(0) end
    if global_state.last_song ~= nil then _GAME:BGM(global_state.last_song, true) end
    _MENU:RemoveMenu()
end

local function update_title(state, content)
    local text = state.elements.frame.title
    text:SetText(content)
end

local function set_cursor_pos(state, x, y)
    x, y = (x or 0) + 10, y or 0
    state.elements.cursor.Loc = RogueElements.Loc(x, y + 21)
end

local inputs = {
    directions = {
        [RogueElements.Dir8.Up] = function(state)
            local tab = state.tabs[state.position.tab]
            if tab then
                tab:move(state, -1) 
            end
        end,
        [RogueElements.Dir8.Down] = function(state)
            local tab = state.tabs[state.position.tab]
            if tab then
                tab:move(state, 1) 
            end
        end,
        [RogueElements.Dir8.Left] = function(state, input)
            local tab = state.tabs[state.position.tab]
            if tab then
                tab:left(state)
            end
            state.position.tab = (state.position.tab - 2) % #state.tabs + 1
            tab = state.tabs[state.position.tab]
            if tab then
                update_title(state, global_state.placeholders.tab_title:format ( tab.info.title, state.position.tab, #state.tabs ) )
                tab:entered(state)
            end
            play_sound('Menu/Select', 1, math.random() * (1/12) - (1/24))
        end,
        [RogueElements.Dir8.Right] = function(state, input)
            local tab = state.tabs[state.position.tab]
            if tab then
                tab:left(state)
            end
            state.position.tab = state.position.tab % #state.tabs + 1
            tab = state.tabs[state.position.tab]
            if tab then
                update_title(state, global_state.placeholders.tab_title:format ( tab.info.title, state.position.tab, #state.tabs ) )
                tab:entered(state)
            end
            play_sound('Menu/Select', 1, math.random() * (1/12) - (1/24))
        end
    },
    bindings = {
        [__InputType.Cancel] = function(state)
            exit(state)
        end
    }
}

local __Keys = luanet.namespace 'Microsoft.Xna.Framework.Input' .Keys
local SDL = luanet.namespace 'SDL2' .SDL
local function controls_listener(state, input)
    if input:JustPressed(__InputType.Menu) then
        exit(state)
        return
    end
    if state.input.debounce > 0 then state.input.debounce = state.input.debounce - 1 end

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

    local tab = state.tabs[state.position.tab]
    if tab then
        tab:update(state, input)
    end
end

local public = {}

function public.open()
    local state = {
        memory = {},
        tabs = {},
        position = {
            tab = 1
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
        promises = {
            on_exit = async.promise()
        },
        set_cursor_pos = set_cursor_pos
    }

    for i, k in ipairs(global_state.tabs) do state.tabs[i] = k.new() end

    local ww, wh = graphics.get_screen_dimensions()
    local mw, mh = math.floor(ww * 0.7), wh - 16
    state.menu = RogueEssence.Menu.ScriptableMenu(8, 8, mw, mh, function(i) controls_listener(state, i) end)

    local realElements, stateElements = state.menu.Elements, state.elements

    stateElements.frame.window_name = create_text('Randomizer [color=#aaaaaa]'.. header.Version:ToString(), 10, 7)
    stateElements.frame.title = create_text('?', mw - 10, 7, RogueElements.DirH.Right)

    realElements:Add(stateElements.frame.window_name)
    realElements:Add(stateElements.frame.title)
    realElements:Add(RogueEssence.Menu.MenuDivider(RogueElements.Loc(10, 18), mw - 20))

    stateElements.cursor = RogueEssence.Menu.MenuCursor(state.menu)
    set_cursor_pos(state, 0, 0)
    realElements:Add(stateElements.cursor)

    --service.set_music_pitch(0.16667 * (math.random() < 0.01 and (math.random() * 2 - 1) or -1))
    if has_bgm_pitcher then
        RogueEssence.Content.SoundManager.SetBGMPitch(-2/12)
    end
    if global_state.last_song == nil then
        global_state.last_song = _GAME.Song
    end

    state.tabs[1]:entered(state)
    update_title(state, global_state.placeholders.tab_title:format ( state.tabs[1].info.title, 1, #state.tabs ) )

    _GAME:BGM(global_state.music_pool[math.random(1, #global_state.music_pool)], true)
    _MENU:AddMenu(state.menu, true)

    return state.promises.on_exit
end

public.global_state = global_state
return public