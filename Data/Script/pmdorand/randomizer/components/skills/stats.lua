local component = require 'pmdorand.randomizer.core.component'
local config = require 'pmdorand.config'
local math_util = require 'pmdorand.util.math'

component.builder()
    :with_id 'skill.stats'
    :associate_random 'skill.stats'
    :using_provider 'skills'
    :with_dependencies()
    :with_settings {}
    :on_step(function(id, data, state)
    end)
    :register()