local component = require 'pmdorand.randomizer.core.component'
local config = require 'pmdorand.config'
local math_util = require 'pmdorand.util.math'

component.builder()
    :with_id 'monster.promotions'
    :associate_random 'monster.promotions'
    :default_enabledness ( false )
    :using_provider 'monsters'
    :with_dependencies()
    :with_settings {
        restrictions = config.table {
            maximum_depth = config.integer(2, 1, 5),
            allow_cycles = config.boolean(false),
            matches_type = config.boolean(true)
        },
        conditions = config.table {
            level = config.table {
                weight = config.integer(100, math.mininteger, math.maxinteger, 10)
            },
            item = config.table {
                weight = config.integer(10, math.mininteger, math.maxinteger, 10)
            },
            promoted_friends = config.table {
                weight = config.integer(10, math.mininteger, math.maxinteger, 10),
                minimum = config.integer(1, 1, 20),
                maximum = config.integer(4, 1, 20)
            }
        }
    }
    :on_step(function(id, data, state)
    end)
    :register()