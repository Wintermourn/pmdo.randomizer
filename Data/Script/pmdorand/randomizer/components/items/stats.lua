local component = require 'pmdorand.randomizer.core.component'
local config = require 'pmdorand.config'
local math_util = require 'pmdorand.util.math'

component.builder()
    :mark_not_implemented()
    :with_id 'item.stats'
    :associate_random 'item.stats'
    :default_enabledness ( false )
    :using_provider 'items'
    :with_dependencies()
    :with_settings {}
    :on_step(function(id, data, state)
    end)
    :register()