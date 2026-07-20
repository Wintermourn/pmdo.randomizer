local component = require 'pmdorand.randomizer.core.component'
local config = require 'pmdorand.config'
local math_util = require 'pmdorand.util.math'

component.builder()
    :with_id 'zone.monsters'
    :associate_random 'zone.monsters'
    :default_enabledness ( false )
    :using_provider 'zones'
    :with_dependencies()
        :after 'monster.typing' :is 'soft'
        :after 'monster.stats' :is 'soft'
        :after 'monster.promotions' :is 'soft'
    :with_settings {}
    :on_step(function(id, data, state)
    end)
    :register()