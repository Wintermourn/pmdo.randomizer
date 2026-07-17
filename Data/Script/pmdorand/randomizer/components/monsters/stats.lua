local component = require 'pmdorand.randomizer.core.component'
local config = require 'pmdorand.config'
local math_util = require 'pmdorand.util.math'
local format_form_key = require 'pmdorand.util.form_key'
local s = require 'pmdorand.util.string'

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

local placeholders = {
    line = '| %s| %-5s| %-14s| %-14s| %-14s| %-14s| %-14s| %-14s|\n',
    line_nop = '| %s| %-5s| %s|\n',
    stat = '%4s -> %4s',
    stat_nop = '%12s'
}

local function format_stat(old, new)
    if old == new then
        return placeholders.stat_nop:format(old)
    else
        return placeholders.stat:format(old, new)
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
            local form, form_key, new
            for i = 0, data.Forms.Count - 1 do
                form, form_key = data.Forms[i], {id, i}
                if random:bool(state:get_randomization_chance()) then
                    for stat = 1, 6 do
                        entry = key_and_prop[stat] --[[@as table]]
                        new = randomize_stat(random, form[entry[2]], conf[entry[1]])
                        state:log_spoiler(form_key, entry[1], {old = form[entry[2]], new = new})
                        form[entry[2]] = new
                    end
                else
                    state:log_spoiler(form_key, 'nop', true)
                end
            end
        end
    end)
    :log_spoilers(function(file, state)
        local split = string.rep('=', 125)
        local header = {
            split,
            string.format('| %s|', s.pad_end('- Monster Stats', 122)),
            split,
            string.format('| %-19s| %-5s| %-14s| %-14s| %-14s| %-14s| %-14s| %-14s|',
                'Identifier', 'Form', 'Health', 'Attack', 'Defense', 'SpAttack', 'SpDefense', 'Speed'
            )
        }
        file:write(table.concat(header, '\n'), '\n')

        local keys = {}
        for i, k in pairs(state.spoilers) do
            keys[#keys + 1] = i
        end

        table.sort(keys, function(a, b)
            if a[1] == b[1] then return a[2] < b[2] end
            return a[1] < b[1]
        end)

        for _, key in ipairs(keys) do
            local changes = state.spoilers[key]
            if changes.nop then
                file:write(placeholders.line_nop:format(s.pad_end(key[1], 19), key[2], s.pad_end('no change', 94))) 
            else
                file:write(placeholders.line:format(
                    s.pad_end(key[1], 19), key[2],
                    format_stat(changes.health.old, changes.health.new),
                    format_stat(changes.attack.old, changes.attack.new),
                    format_stat(changes.defense.old, changes.defense.new),
                    format_stat(changes.special_attack.old, changes.special_attack.new),
                    format_stat(changes.special_defense.old, changes.special_defense.new),
                    format_stat(changes.speed.old, changes.speed.new)
                ))
            end
        end
    end)
    :register()