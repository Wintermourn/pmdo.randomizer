local component = require 'pmdorand.randomizer.core.component'
local config = require 'pmdorand.config'
local math_util = require 'pmdorand.util.math'

component.builder()
    :with_id 'monster.promotions'
    :associate_random 'monster.promotions'
    :using_provider 'monsters'
    :with_dependencies()
    :with_settings {}
    :on_step(function(id, data, state)
    end)
    :register()