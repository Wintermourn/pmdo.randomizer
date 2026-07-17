local component = require 'pmdorand.randomizer.core.component'
local config = require 'pmdorand.config'
local math_util = require 'pmdorand.util.math'

component.builder()
    :with_id 'skill.stats'
    :associate_random 'skill.stats'
    :default_enabledness ( false )
    :using_provider 'skills'
    :with_dependencies()
    :with_settings {
        charges = config.feature {
            amount = config.stat():with_defaults(1, 30, {mode = 'anchor', value = 10}, 1.0),
            overrides = config.null()
        },
        base_power = config.feature {
            amount = config.stat():with_defaults(1, 120, {mode = 'anchor', value = 60}, 1.0),
            overrides = config.null()
        },
        category = config.feature {
            leaning = config.null()
        }
    }
    :on_step(function(id, data, state)
    end)
    :register()