local component = require 'pmdorand.randomizer.core.component'
local config = require 'pmdorand.config'
local math_util = require 'pmdorand.util.math'

local __ElementTableState = luanet.import_type 'PMDC.Dungeon.ElementTableState'

component.builder()
    :with_id 'universal.stats'
    :associate_random 'universal.stats'
    :default_enabledness ( false )
    :using_provider 'universal'
    :with_dependencies()
    :with_settings {
        hunger_rate = config.feature {
            leader = config.any(
                config.integer(80, 0, 1000, 20),
                config.stat():with_defaults(10, 300, {mode = 'raw', value = 40}, 0.0)
            ),
            party = config.any(
                config.integer(0, 0, 1000, 20),
                config.stat():with_defaults(0, 300, {mode = 'raw', value = 40}, 0.0)
            )
        },
        natural_regeneration = config.feature {
            out_of_combat = config.any(
                config.integer(12, -1000, 1000, 20),
                config.stat():with_defaults(0, 20, {mode = 'relative', value = 0.2}, 1.0)
            ),
            in_combat = config.any(
                config.integer(0, -1000, 1000, 20),
                config.stat():with_defaults(0, 20, {mode = 'relative', value = 0.2}, 1.0)
            ),
            starving = config.any(
                config.integer(-60, -1000, 1000, 20),
                config.stat():with_defaults(0, 20, {mode = 'relative', value = 0.2}, 1.0)
            )
        }
    }
    :on_step(function(id, data, state)
    end)
    :register()