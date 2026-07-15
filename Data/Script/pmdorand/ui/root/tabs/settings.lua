local component_registry = require 'pmdorand.randomizer.core.registry' .get 'components'
local provider_registry = require 'pmdorand.randomizer.core.registry' .get 'providers'
local strings = {
}

return {
    name = STRINGS:FormatKey 'pmdorand:tab.settings',
    ---@param menu pmdorand.ui.root
    entered = function(menu)
        menu.elements.cursor.Loc = RogueElements.Loc(11, menu.menu.Bounds.Height--[[@as int]] - 33)
        return {
        }
    end,
    ---@param menu pmdorand.ui.root
    left = function(menu)

    end,
    ---@param menu pmdorand.ui.root
    input = function(menu, input)

    end
}