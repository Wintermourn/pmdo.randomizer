local component = require 'pmdorand.randomizer.core.component'
local config = require 'pmdorand.config'
local math_util = require 'pmdorand.util.math'

component.builder()
    :with_id 'monster.intrinsics'
    :associate_random 'monster.intrinsics'
    :default_enabledness ( false )
    :using_provider 'monsters'
    :with_dependencies()
    :with_settings {
        slot_limit = config.integer(3, 1, 3),
        slot_fill_chance = config.percentage(0.5),
    }
    :on_step(function(id, data, state)
    end)
    :register()