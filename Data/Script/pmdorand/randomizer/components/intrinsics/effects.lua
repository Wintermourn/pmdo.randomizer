local component = require 'pmdorand.randomizer.core.component'
local config = require 'pmdorand.config'
local math_util = require 'pmdorand.util.math'

component.builder()
    :with_id 'intrinsic.effects'
    :associate_random 'intrinsic.effects'
    :default_enabledness ( false )
    :using_provider 'intrinsics'
    :with_dependencies()
    :with_settings {}
    :on_step(function(id, data, state)
    end)
    :register()