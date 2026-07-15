local graphics = require 'pmdorand.util.graphics'
local create_text = require 'pmdorand.util.create_text'
local header = require 'pmdorand.util.header'
local generation_manager = require 'pmdorand.randomizer.core.manager'
local text_pool = require 'pmdorand.util.text_pool'

local input_type = RogueEssence.FrameInput.InputType

local strings = {
    tab_count = STRINGS:FormatKey 'pmdorand:tab.number'
}

local function refresh_text(menu)
    menu.elements.frame.tab:SetText(strings.tab_count:format(menu.tabs[menu.state.current_tab].name:upper(), menu.state.current_tab, #menu.tabs))
end

local directions = {
    [RogueElements.Dir8.Left] = function(menu)
        menu.tabs[menu.state.current_tab].left(menu)
        menu.state.current_tab = (menu.state.current_tab - 2) % #menu.tabs + 1
        text_pool.update_text(menu.menu, menu.elements.text_pool, menu.tabs[menu.state.current_tab].entered(menu), 12, 19, 20, 48)
        _GAME:SE("Menu/Select")
        refresh_text(menu)
    end,
    [RogueElements.Dir8.Right] = function(menu)
        menu.tabs[menu.state.current_tab].left(menu)
        menu.state.current_tab = menu.state.current_tab % #menu.tabs + 1
        text_pool.update_text(menu.menu, menu.elements.text_pool, menu.tabs[menu.state.current_tab].entered(menu), 12, 19, 20, 48)
        _GAME:SE("Menu/Select")
        refresh_text(menu)
    end
}

local last_state, last_direction = 0
local state_texts = {
    function(menu)
        if last_state == 0 then return end
        menu.elements.generation_status[1]:SetText '[color=#333333]Idle'
        menu.elements.generation_status[2]:SetText '[color=#333333]Not Generating'
    end,
    function(menu)
        menu.elements.generation_status[1]:SetText 'Generating'
        menu.elements.generation_status[2]:SetText (generation_manager.get_status()) 
    end,
    function(menu)
        if last_state == 2 then return end
        menu.elements.generation_status[1]:SetText 'Finished'
        menu.elements.generation_status[2]:SetText '[color=#44ff99]Done!'
    end,
    function(menu)
        if last_state == 3 then return end
        menu.elements.generation_status[1]:SetText '[color=#ff4499]Failed'
        menu.elements.generation_status[2]:SetText 'Check logs!'
    end
}

local function close_menu(menu, inputs)
    if generation_manager.get_state() == 1 then return end
    _GAME:SE("Menu/Cancel")
    _MENU:RemoveMenu()
end
local function controls_listener(menu, inputs)

    local state = generation_manager.get_state()
    local text_fn = state_texts[state + 1]
    if text_fn then
        text_fn(menu)
        last_state = state
    end

    if inputs.Direction ~= last_direction then
        menu.state.input_debounce = 0
    else
        if menu.state.input_debounce > 0 then menu.state.input_debounce = menu.state.input_debounce - 1 end
    end
    last_direction = inputs.Direction
    if inputs:JustPressed(input_type.Cancel) or inputs:JustPressed(input_type.Menu) then
        close_menu(menu, inputs)
        return
    end
    if directions[inputs.Direction] and menu.state.input_debounce == 0 then
        menu.elements.cursor:ResetTimeOffset()
        directions[inputs.Direction](menu, inputs)
        menu.state.input_debounce = 20
    end

    text_pool.update_text(menu.menu, menu.elements.text_pool, menu.tabs[menu.state.current_tab].input(menu, inputs), 12, 19, 20, 48)
end

local public = {}

function public.create()
    ---@class pmdorand.ui.root
    local out = {
        state = {
            current_tab = 1,
            input_debounce = 0,
        },
        elements = {
            frame = {},
            text_pool = {},
            generation_status = {}
        },
        tabs = {
            (require 'pmdorand.ui.root.tabs.status'),
            (require 'pmdorand.ui.root.tabs.settings'),
            (require 'pmdorand.ui.root.tabs.components')
        }
    }
    last_state = -1

    local ww, wh = graphics.get_screen_dimensions()
    local mw, mh = math.floor(ww * 0.7), wh - 16--math.floor(wh * 0.7)
    out.menu = RogueEssence.Menu.ScriptableMenu(8, 8, mw, mh, function(i) controls_listener(out, i) end)

    out.elements.cursor = RogueEssence.Menu.MenuCursor(out.menu)
    out.elements.frame.title = create_text('Randomizer [color=#aaaaaa]'.. header.Version:ToString(), 10, 7, RogueElements.DirH.Left)
    out.elements.frame.tab = create_text(strings.tab_count:format(out.tabs[out.state.current_tab].name:upper(), out.state.current_tab, #out.tabs), mw - 10, 7, RogueElements.DirH.Right)
    out.elements.generation_status[1] = create_text('[color=#333333]Idle', 10, mh - 17, RogueElements.DirH.Left)
    out.elements.generation_status[2] = create_text('[color=#333333]Not Generating', mw - 10, mh - 17, RogueElements.DirH.Right)

    out.menu.Elements:Add(out.elements.frame.title)
    out.menu.Elements:Add(out.elements.frame.tab)
    out.menu.Elements:Add(RogueEssence.Menu.MenuDivider(RogueElements.Loc(10, 18), mw - 20))
    out.menu.Elements:Add(RogueEssence.Menu.MenuDivider(RogueElements.Loc(10, mh - 20), mw - 20))
    out.menu.Elements:Add(out.elements.generation_status[1])
    out.menu.Elements:Add(out.elements.generation_status[2])
    out.menu.Elements:Add(out.elements.cursor)

    text_pool.update_text(out.menu, out.elements.text_pool, out.tabs[out.state.current_tab].entered(out), 12, 19, 20, 48)

    return out.menu
end

return public