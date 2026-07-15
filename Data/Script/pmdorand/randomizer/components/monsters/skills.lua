local component = require 'pmdorand.randomizer.core.component'
local config = require 'pmdorand.config'
local math_util = require 'pmdorand.util.math'

component.builder()
    :with_id 'monster.skills'
    :associate_random 'monster.skills'
    :default_enabledness ( false )
    :using_provider 'monsters'
    :with_dependencies()
    :with_settings {
        maximum_moves   = config.integer(20, 1, 50),
        stab_leaning    = config.float(0.0, -1.0, 1.0, 0.01),
        starting_moves  = config.feature {
            minimum_moves           = config.integer(4, 1, 50),
            minimum_attacking_moves = config.integer(2, 0, 50)
        },
        learnset        = config.feature {
            shuffle_existing        = config.boolean(false),
            minimum_spacing         = config.integer(1, 0, 99),
            level_weighting         = config.null()
        },
        type_matching   = config.feature {
            target_rate             = config.percentage(0.20),
            mismatch_limit          = config.percentage(0.90)
        }
    }
    :on_step(function(id, data, state)
    end)
    :register()