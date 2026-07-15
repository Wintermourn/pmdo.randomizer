local component = require 'pmdorand.randomizer.core.component'
local config = require 'pmdorand.config'
local math_util = require 'pmdorand.util.math'

component.builder()
    :with_id 'zone.tiles'
    :associate_random 'zone.tiles'
    :default_enabledness ( false )
    :using_provider 'zones'
    :with_dependencies()
    :with_settings {}
    :on_step(function(id, data, state)
    end)
    :register()