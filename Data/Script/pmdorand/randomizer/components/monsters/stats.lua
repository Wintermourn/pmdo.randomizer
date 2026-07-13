local component = require 'pmdorand.randomizer.core.component'
local config = require 'pmdorand.config'
local math_util = require 'pmdorand.util.math'

component.builder()
    :with_id 'monster.stats'
    :associate_random 'monster.stats'
    :using_provider 'monsters'
    :with_dependencies()
    :with_settings {
        health = config.stat(),
        speed = config.stat(),
        attack = config.stat(),
        defense = config.stat(),
        special_attack = config.stat(),
        special_defense = config.stat()
    }
    :on_step(function(id, data, state)
        local forms = data.Forms
        if forms.Count > 0 then
            local form = data.Forms[0]
            form.BaseHP = math_util.round(state:get_random():origin_weighted(0, 255, form.BaseHP, 0.5))
        end
    end)
    :register()