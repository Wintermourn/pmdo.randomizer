require 'pmdorand.service'

require 'pmdorand.randomizer.registries' ()
require 'pmdorand.randomizer.providers' .load_all()
require 'pmdorand.randomizer.components' .load_all()

local components = require 'pmdorand.randomizer.core.registry' .get 'components'

local pass = require 'pmdorand.randomizer.core.pass'
local manager = pass.generate_passes {
    components:get 'monster.stats'
}

local interlace = require 'lib.pmdorand.interlace'
interlace.dependency_test()
    :at_or_after( interlace.get_mod_by_namespace 'mentoolkit', '2.0' )
    :if_valid(function (info)
        local gfxman = RogueEssence.Content.GraphicsManager
        ---@type int, int
        local screen_width, screen_height = gfxman.ScreenWidth, gfxman.ScreenHeight
        require 'mentoolkit' .add_to_menu("top_menu", '[$pmdorand:topmenu]', function ()
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
            menu.object = RogueEssence.Menu.ScriptableMenu(4, 38, screen_width - 8, screen_height - 96 - 38, function(i) controls_listener(menu, i) end)
            menu.text = require 'pmdorand.util.create_text' ('', 8, 8)
            menu.object.Elements:Add(menu.text)
            require 'pmdorand.randomizer.cache.configurations' .construct_defaults()
            require 'pmdorand.randomizer.cache.random' .construct_all()
            manager:run():on_resolved(promise_listener)
            _MENU:AddMenu(menu.object, false)
        end)
    end)
    :test()