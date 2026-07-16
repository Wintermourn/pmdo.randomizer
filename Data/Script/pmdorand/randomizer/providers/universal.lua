local provider = require 'pmdorand.randomizer.core.provider'
local DataType = RogueEssence.Data.DataManager.DataType

provider.builder()
    :with_id "universal"
    :with_methods()
        :count_keys(function(_state)
            return 1
        end)
        :iterate_keys(function(_state)
            local ret = true
            return function()
                if ret then ret = false else return end
                return 'Universal'
            end
        end)
        :get(function(_key, _state)
            return _DATA.UniversalEvent
        end)
        :flush(function(_key, _data, state)
            state:serialize_universal()
        end)
    :register()