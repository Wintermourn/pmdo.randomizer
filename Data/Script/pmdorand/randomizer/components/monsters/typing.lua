local component = require 'pmdorand.randomizer.core.component'
local config = require 'pmdorand.config'
local math_util = require 'pmdorand.util.math'

component.builder()
    :with_id 'monster.typing'
    :associate_random 'monster.typing'
    :default_enabledness ( false )
    :using_provider 'monsters'
    :with_dependencies()
    :with_settings {
        retained_type   = config.option( false, {false, 1, 2, true} ),
        dual_type_chance = config.percentage(0.20),
        selection_rules = {
            enforce_different_types = config.boolean(true),
            banned_types = config.null(), -- todo: replace with config.list()
        }
    }
    :on_step(function(id, data, state)
    end)
    :register()