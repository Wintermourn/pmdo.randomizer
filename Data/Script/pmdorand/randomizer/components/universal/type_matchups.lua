local component = require 'pmdorand.randomizer.core.component'
local config = require 'pmdorand.config'
local math_util = require 'pmdorand.util.math'

local __ElementTableState = luanet.import_type 'PMDC.Dungeon.ElementTableState'

component.builder()
    :with_id 'universal.type_matchups'
    :associate_random 'universal.type_matchups'
    :default_enabledness ( false )
    :using_provider 'universal'
    :with_dependencies()
    :with_settings {
        symmetrical = config.boolean(true)
    }
    :on_step(function(id, data, state)
        local element_state = data.UniversalStates:GetWithDefault(luanet.ctype(__ElementTableState))
        element_state.TypeMatchup[0][0] = 8
    end)
    :register()