local component = require 'pmdorand.randomizer.core.component'
local config = require 'pmdorand.config'
local math_util = require 'pmdorand.util.math'

local names = {
    STRINGS:FormatKey 'pmdorand/settings:type/no_effect',
    STRINGS:FormatKey 'pmdorand/settings:type/not_effective',
    STRINGS:FormatKey 'pmdorand/settings:type/neutral',
    STRINGS:FormatKey 'pmdorand/settings:type/super_effective'
}
local function effectivity_to_name(val)
    if val < 4 then
        return names[val + 1]
    else
        return names[4]
    end
    return names[1]
end

local function display_name(val)
    return effectivity_to_name(val)
end

component.builder()
    :mark_not_implemented()
    :with_id 'monster.typing'
    :associate_random 'monster.typing'
    :default_enabledness ( false )
    :using_provider 'monsters'
    :with_dependencies()
        :after 'universal.type_matchups' :is 'soft'
    :with_settings {
        retained_type   = config.enum( false, {false, 1, 2, true} ),
        dual_type_chance = config.percentage(0.20),
        selection_rules = {
            enforce_different_types = config.boolean(true),
            banned_types = config.null(), -- todo: replace with config.list()
        },
        restrictions = {
            allow_none  = config.boolean(false):permit_boolable(true),
            type_effectivity = config.feature {
                mode = config.enum(1, {1, 2, 3}),
                minimum = config.custom_display(config.integer(0, 0, 3, 1), display_name),
                maximum = config.custom_display(config.integer(5, 0, 3, 1), display_name)
            } :with_sorted_keys {'mode', 'minimum', 'maximum'}
        }
    }
    :on_step(function(id, data, state)
    end)
    :register()