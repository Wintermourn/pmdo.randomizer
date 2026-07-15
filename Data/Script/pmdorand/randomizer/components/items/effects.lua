local component = require 'pmdorand.randomizer.core.component'
local config = require 'pmdorand.config'
local math_util = require 'pmdorand.util.math'

component.builder()
    :with_id 'item.effects'
    :associate_random 'item.effects'
    :using_provider 'items'
    :with_dependencies()
    :with_settings {}
    :on_step(function(id, data, state)
    end)
    :register()