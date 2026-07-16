local component = require 'pmdorand.randomizer.core.component'
local config = require 'pmdorand.config'
local math_util = require 'pmdorand.util.math'

local function randomize_stat(random, current_value, conf)
    local min, max
    if conf.range.mode == 'r' then
        min = math.max(conf.minimum, current_value - conf.range.value)
        max = math.min(conf.maximum, current_value + conf.range.value)
        return math_util.round(random:origin_weighted(min, max, current_value, conf.originalPull))
    elseif conf.range.mode == 'e' then
        local percent = conf.range.value / 100
        min = math.max(conf.minimum, current_value * (1 - percent))
        max = math.min(conf.maximum, current_value * (1 + percent))
        return math_util.round(random:origin_weighted(min, max, current_value, conf.originalPull))
    end
end

local key_and_prop = {
    {'health', 'BaseHP'},
    {'attack', 'BaseAtk'},
    {'defense', 'BaseDef'},
    {'special_attack', 'BaseMAtk'},
    {'special_defense', 'BaseMDef'},
    {'speed', 'BaseSpeed'}
}

---@type table
local entry
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
    :sorted_keys {
        'health', 'attack', 'defense', 'special_attack', 'special_defense', 'speed'
    }
    :on_step(function(id, data, state)
        local forms = data.Forms
        local random, conf = state:get_random(), state:get_config()
        if forms.Count > 0 then
            local form = data.Forms[0]
            for i = 1, 6 do
                entry = key_and_prop[i] --[[@as table]]
                form[entry[2]] = randomize_stat(random, form[entry[2]], conf[entry[1]])
            end
        end
    end)
    :register()