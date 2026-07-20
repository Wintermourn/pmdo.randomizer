local component = require 'pmdorand.randomizer.core.component'
local config = require 'pmdorand.config'
local math_util = require 'pmdorand.util.math'

component.builder()
    :with_id 'zone.items'
    :associate_random 'zone.items'
    :default_enabledness ( false )
    :using_provider 'zones'
    :with_dependencies()
        :after 'item.effects' :is 'soft'
        :after 'item.stats' :is 'soft'
    :with_settings {}
    :on_step(function(id, data, state)
    end)
    :register()