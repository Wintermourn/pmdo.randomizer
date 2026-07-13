---@diagnostic disable: undefined-global
require 'origin.services.baseservice'
local async = require 'lib.pmdorand.async'

local name = "RandomizerService"
local service = Class(name, BaseService)

service.Subscribe = function(_, med)
    med:Subscribe(name, EngineServiceEvents.Update, function(_, args)
        async.update(args[0].TotalGameTime.TotalSeconds)
    end)
end

SCRIPT:AddService(name, service:new())
return service