local provider = require 'pmdorand.randomizer.core.provider'
local DataType = RogueEssence.Data.DataManager.DataType

local function get_tile(id)
    return _DATA:GetTile(id)
end

provider.builder()
    :with_id "tiles"
    :with_methods()
        :count_keys(function(_state)
            return _DATA.DataIndices[DataType.Tile].Count
        end)
        :iterate_keys(function(_state)
            local indices = _DATA.DataIndices[DataType.Tile]:GetOrderedKeys(false)
            local idx, max = 0, indices.Count
            return function()
                if idx >= max then return end
                idx = idx + 1
                return indices[idx - 1]
            end
        end)
        :get(function(key, _state)
            return get_tile(key)
        end)
        :flush(function(key, data, state)
            state:serialize_jsonpatch('Tile', key, data)
        end)
    :register()