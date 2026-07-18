local component = require 'pmdorand.randomizer.core.component'
local config = require 'pmdorand.config'
local math_util = require 'pmdorand.util.math'
local enumerate = require 'pmdorand.util.enumerate'

local steps = {
    ['PMDC.Dungeon.NaturalPercentRegenEvent'] = function(id, value, state, conf, random)
        if conf.natural_regeneration.enabled and random:bool(conf.natural_regeneration.randomization_chance) then
            for _i, k in ipairs {
                {conf.natural_regeneration.options.out_of_combat, "RegenPercent"},
                {conf.natural_regeneration.options.in_combat, "RegenPercentCombat"},
                {conf.natural_regeneration.options.starving, "StarvePercent"}
            } do
                if type(k[1]) == 'number' then
                    value[k[2]] = k[1]
                else
                    -- todo
                end
            end
        end
    end
}

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
        local conf, random = state:get_config(), state:get_random()

        --print(data.OnTurnEnds:GetEnumerator())
        for entry in enumerate.enumerate_ienumerableable(data.OnTurnEnds) do
            print(entry.Key, entry.Value)
            local step = steps[entry.Value:GetType().FullName]
            if step ~= nil then
                step(id, entry.Value, state, conf, random) 
            end
        end
    end)
    :register()