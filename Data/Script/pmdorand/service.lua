---@diagnostic disable: undefined-global
require 'origin.services.baseservice'
local async = require 'lib.pmdorand.async'

local menuClasses = {
    top_menu = luanet.ctype(RogueEssence.Menu.TopMenu)
}

local name = "RandomizerService"
local service = Class(name, BaseService) --[[@as table]]
service.dependencies = {
    mtk2 = false
}

service.Subscribe = function(_, med)
    med:Subscribe(name, EngineServiceEvents.Update, function(_, args)
        async.update(args[0].TotalGameTime.TotalSeconds)
    end)
    med:Subscribe(name, EngineServiceEvents.AddMenu, function(_, args)
        local menu = args[0]
        local class = menu:GetType()

        if service.dependencies.mtk2 == true then return end

        if class == menuClasses.top_menu then
            menu.Choices:Add(RogueEssence.Menu.MenuTextChoice(
                "RANDOMIZER",
                "Randomize (temp)",
                function()
                    require 'pmdorand.temp_run'()
                end
            ))
        end
    end)
end

SCRIPT:AddService(name, service:new())
return service