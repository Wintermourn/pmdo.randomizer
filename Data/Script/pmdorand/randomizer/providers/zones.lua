local provider = require 'pmdorand.randomizer.core.provider'
local DataType = RogueEssence.Data.DataManager.DataType

local function get_zone(id)
    return _DATA:GetZone(id)
end

provider.builder()
    :with_id "zones"
    :with_methods()
        :count_keys(function(_state)
            return _DATA.DataIndices[DataType.Zone].Count
        end)
        :iterate_keys(function(_state)
            local indices = _DATA.DataIndices[DataType.Zone]:GetOrderedKeys(false)
            local idx, max = 0, indices.Count
            return function()
                if idx >= max then return end
                idx = idx + 1
                return indices[idx - 1]
            end
        end)
        :get(function(key, _state)
            return get_zone(key)
        end)
        :flush(function(key, data, state)
            state:serialize_jsonpatch('Zone', key, data)
        end)
    :register()