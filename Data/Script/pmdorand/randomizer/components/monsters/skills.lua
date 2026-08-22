local component = require 'pmdorand.randomizer.core.component'
local config = require 'pmdorand.config'
local math_util = require 'pmdorand.util.math'

local data_type = RogueEssence.Data.DataManager.DataType

component.builder()
    :mark_not_implemented()
    :with_id 'monster.skills'
    :associate_random 'monster.skills'
    :default_enabledness ( false )
    :using_provider 'monsters'
    :with_dependencies()
        :after 'monster.typing' :is 'soft'
    :with_settings {
        maximum_moves       = config.dynamic_int(20, 1, 50, 5):dynamic_max(function() return _DATA.DataIndices[data_type.Skill].Count end),
        stab_leaning        = config.custom_display(
            config.float(0.0, -1.0, 1.0, 0.01),
            function(val)
                if type(val) ~= 'number' then return tostring(val) end
                local rounded_val = math_util.round(val * 1000) / 10
                if rounded_val > 0 then
                    return STRINGS:FormatKey('pmdorand/config:stab_towards'):format(rounded_val)
                elseif rounded_val < 0 then
                    return STRINGS:FormatKey('pmdorand/config:stab_against'):format(-rounded_val)
                end
                return '0%'
            end
        ),
        supplementary_types = config.feature {
            maximum                 = config.dynamic_int(1, 1, 10):dynamic_max(function() return _DATA.DataIndices[data_type.Element].Count end),
            bias                    = config.float(0, 0, 5, 0.2),
            frequency               = config.percentage(0.25, 0.01),
            global_types            = config.limited_list( {'normal'}, function(t)
                if type(t) ~= 'string' then return false end
                return (_DATA.DataIndices[data_type.Element]:TryGetValue(t))
            end)
        },
        starting_moves      = config.feature {
            minimum_moves           = config.integer(4, 1, 50),
            minimum_attacking_moves = config.integer(2, 0, 50)
        },
        learnset            = config.feature {
            shuffle_existing        = config.boolean(false),
            minimum_spacing         = config.integer(1, 0, 99),
            level_weighting         = config.null()
        }
    }
    :sorted_keys {
        'maximum_moves',
        'stab_leaning',
        'starting_moves',
        'learnset',
        'supplementary_types'
    }
    --[[ :pre_pass(function(state)
        -- collapse dynamic features
        local conf = state:get_config()
        local random = state:get_random()
        local feature_config
        for _, feature in ipairs {'supplementary_types', 'starting_moves', 'learnset'} do
            ---@type {enabled: boolean|number}
            feature_config = conf[feature]
            if type(feature_config.enabled) == 'number' then
                feature_config.enabled = random:bool(feature_config.enabled)
                print(string.format("feature %s has collapsed to '%s'", feature, feature_config.enabled))
            end
        end
    end) ]]
    :on_step(function(id, data, state)
    end)
    :register()