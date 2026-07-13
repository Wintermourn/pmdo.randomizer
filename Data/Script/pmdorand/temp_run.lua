return function()
    local components = require 'pmdorand.randomizer.core.registry' .get 'components'

    local pass = require 'pmdorand.randomizer.core.pass'
    local manager = pass.generate_passes {
        components:get 'monster.stats'
    }

    local function promise_listener()
        _MENU:RemoveMenu()
    end
    local function controls_listener(menu, i)
        if i:JustPressed(RogueEssence.FrameInput.InputType.Cancel) or i:JustPressed(RogueEssence.FrameInput.InputType.Menu) then
            _GAME:SE("Menu/Cancel")
            _MENU:RemoveMenu()
            return
        end
        if menu.text then
            menu.text:SetText(manager.state) 
        end
    end
    local menu = {}

    local gfxman = RogueEssence.Content.GraphicsManager
    ---@type int, int
    local screen_width, screen_height = gfxman.ScreenWidth, gfxman.ScreenHeight
    menu.object = RogueEssence.Menu.ScriptableMenu(4, 38, screen_width - 8, screen_height - 96 - 38, function(i) controls_listener(menu, i) end)
    menu.text = require 'pmdorand.util.create_text' ('', 8, 8)
    menu.object.Elements:Add(menu.text)
    require 'pmdorand.randomizer.cache.configurations' .construct_defaults()
    require 'pmdorand.randomizer.cache.random' .construct_all()
    manager:run():on_resolved(promise_listener)

    _MENU:AddMenu(menu.object, false)
end