local graphics = require 'pmdorand.util.graphics'
local create_text = require 'pmdorand.util.create_text'
local header = require 'pmdorand.util.header'
local generation_manager = require 'pmdorand.randomizer.core.manager'

local input_type = RogueEssence.FrameInput.InputType

local function close_menu(menu, inputs)
    if generation_manager.get_status() ~= nil then return end
    _GAME:SE("Menu/Cancel")
    _MENU:RemoveMenu()
end
local controls = {
    [input_type.Cancel] = close_menu,
    [input_type.Menu] = close_menu,
    [input_type.Confirm] = function()
        generation_manager.start()
    end
}

local last_state = 0
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

local function controls_listener(menu, inputs)
    local state = generation_manager.get_state()
    local text_fn = state_texts[state + 1]
    if text_fn then
        text_fn(menu)
        last_state = state
    end
    for i, k in pairs(controls) do
        if inputs:JustPressed(i) then
            k(menu, inputs)
            return
        end
    end
end

local public = {}

function public.create()
    local out = {
        elements = {
            frame = {},
            contents = {},
            generation_status = {}
        }
    }

    local ww, wh = graphics.get_screen_dimensions()
    local mw, mh = math.floor(ww * 0.6), math.floor(wh * 0.7)
    out.menu = RogueEssence.Menu.ScriptableMenu(8, 8, mw, mh, function(i) controls_listener(out, i) end)

    out.elements.frame.title = create_text('Randomizer [color=#aaaaaa]'.. header.Version:ToString(), 10, 7, RogueElements.DirH.Left)
    out.elements.frame.tab = create_text('STATUS', mw - 10, 7, RogueElements.DirH.Right)
    out.elements.generation_status[1] = create_text('[color=#333333]Idle', 10, mh - 17, RogueElements.DirH.Left)
    out.elements.generation_status[2] = create_text('[color=#333333]Not Generating', mw - 10, mh - 17, RogueElements.DirH.Right)

    out.menu.Elements:Add(out.elements.frame.title)
    out.menu.Elements:Add(out.elements.frame.tab)
    out.menu.Elements:Add(RogueEssence.Menu.MenuDivider(RogueElements.Loc(10, 18), mw - 20))
    out.menu.Elements:Add(RogueEssence.Menu.MenuDivider(RogueElements.Loc(10, mh - 20), mw - 20))
    out.menu.Elements:Add(out.elements.generation_status[1])
    out.menu.Elements:Add(out.elements.generation_status[2])

    return out.menu
end

return public