local component = require 'pmdorand.randomizer.core.component'
local config = require 'pmdorand.config'
local math_util = require 'pmdorand.util.math'
local set = require 'pmdorand.util.set'
local s = require 'pmdorand.util.string'

local data_type = RogueEssence.Data.DataManager.DataType
local __ElementTableState = luanet.import_type 'PMDC.Dungeon.ElementTableState'

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

local internal_effectivity = {
    [0] = 0,
    3,
    4,
    5
}

---@param allowed_types {[string]: int}
---@return {[string]: string[]}
---@return {[string]: string[]}?
local function get_pairings(type_chart, reverse_map, allowed_types, allow_none, allow_duplicate_types, min, max)
    local attacking_pairings = {}
    local defending_pairings = {}

    for i = 0, #reverse_map do
        defending_pairings[reverse_map[i]] = {}
    end
    for i = 0, #reverse_map do
        local attacker = reverse_map[i]
        if allow_none or attacker ~= 'none' then
            local matchups = type_chart[i]
            local these_pairings = {}
            for c = 0, matchups.Length - 1 do
                local matchup = matchups[c]
                local defender = reverse_map[c]
                if (defender ~= attacker or allow_duplicate_types) and matchup >= min and matchup <= max and allowed_types[defender] then
                    table.insert(these_pairings, defender)
                    table.insert(defending_pairings[defender], attacker)
                end
            end
            attacking_pairings[attacker] = these_pairings
        end
    end

    return attacking_pairings, defending_pairings
end

local element_keys = {
    'Element1',
    'Element2'
}

---@type {[1|2|3]: (fun(form, state: pmdorand.state.component, conf, random: pmdorand.random, allowed_types: {by_index: string[], by_name: {[string]: int}}, unlocked_index: false|1|2, locked_element: string?))}
local te_methods = {
    -- First vs. Second
    function(form, state, conf, random, allowed_types, unlocked_index, locked_element)
        if locked_element then
            ---@cast unlocked_index -?
            local selections = state.data[unlocked_index == 1 and "defenders" or "attackers"]

            local choices = selections[locked_element]
            if #choices > 0 then
                form[element_keys[unlocked_index]] = choices[random:next_integer(1, #choices)]
            else
                if conf.restrictions.enforce_different_types then
                    local selection = random:next_integer(1, #allowed_types.by_index - 1)
                    if selection >= allowed_types.by_name[locked_element] then selection = selection + 1 end
                    form[element_keys[unlocked_index]] = allowed_types.by_index[selection]
                else
                    form[element_keys[unlocked_index]] = allowed_types.by_index[random:next_integer(1, #allowed_types.by_index)]
                end
            end
        else
            local has_second_type = form[element_keys[2]] ~= 'none' or random:bool(conf.dual_type_chance)

            local pool = {}
            for i = 1, #allowed_types.by_index do
                local ty = allowed_types.by_index[i]
                if #state.data.attackers[ty] > 0 then
                    pool[#pool + 1] = ty
                end
            end
            while #pool > 0 do
                local index = random:next_integer(1, #pool)
                local first_type = pool[index]
                if has_second_type then
                    local choices = state.data.attackers[first_type]
                    if #choices > 0 then
                        local second_type = choices[random:next_integer(1, #choices)]
                        form[element_keys[1]] = first_type
                        form[element_keys[2]] = second_type
                        return
                    else
                        table.remove(pool, index)
                    end
                else
                    form[element_keys[1]] = first_type
                    return
                end
            end
            print 'Could not find a type with the selected restrictions!'
            conf.restrictions.type_effectivity.enabled = false
            local first_index = random:next_integer(1, #allowed_types.by_index)
            form[element_keys[1]] = allowed_types.by_index[first_index]
            if has_second_type then
                if conf.restrictions.enforce_different_types then
                    local selection = random:next_integer(1, #allowed_types.by_index - 1)
                    if selection >= first_index then selection = selection + 1 end
                    form[element_keys[2]] = allowed_types.by_index[selection]
                else
                    form[element_keys[2]] = allowed_types.by_index[random:next_integer(1, #allowed_types.by_index)]
                end
            end
        end
    end,
    -- Second vs. First
    function(form, state, conf, random, allowed_types, unlocked_index, locked_element)
        if locked_element then
            ---@cast unlocked_index -?
            local selections = state.data[unlocked_index == 2 and "defenders" or "attackers"]

            local choices = selections[locked_element]
            if #choices > 0 then
                form[element_keys[unlocked_index]] = choices[random:next_integer(1, #choices)]
            else
                if conf.restrictions.enforce_different_types then
                    local selection = random:next_integer(1, #allowed_types.by_index - 1)
                    if selection >= allowed_types.by_name[locked_element] then selection = selection + 1 end
                    form[element_keys[unlocked_index]] = allowed_types.by_index[selection]
                else
                    form[element_keys[unlocked_index]] = allowed_types.by_index[random:next_integer(1, #allowed_types.by_index)]
                end
            end
        else
            local has_second_type = form[element_keys[2]] ~= 'none' or random:bool(conf.dual_type_chance)

            local pool = {}
            for i = 1, #allowed_types.by_index do
                local ty = allowed_types.by_index[i]
                if #state.data.defenders[ty] > 0 then
                    pool[#pool + 1] = ty
                end
            end
            while #pool > 0 do
                local index = random:next_integer(1, #pool)
                local first_type = pool[index]
                if has_second_type then
                    local choices = state.data.defenders[first_type]
                    if #choices > 0 then
                        local second_type = choices[random:next_integer(1, #choices)]
                        form[element_keys[1]] = first_type
                        form[element_keys[2]] = second_type
                        return
                    else
                        table.remove(pool, index)
                    end
                else
                    form[element_keys[1]] = first_type
                    return
                end
            end
            print 'Could not find a type with the selected restrictions!'
            conf.restrictions.type_effectivity.enabled = false
            local first_index = random:next_integer(1, #allowed_types.by_index)
            form[element_keys[1]] = allowed_types.by_index[first_index]
            if has_second_type then
                if conf.restrictions.enforce_different_types then
                    local selection = random:next_integer(1, #allowed_types.by_index - 1)
                    if selection >= first_index then selection = selection + 1 end
                    form[element_keys[2]] = allowed_types.by_index[selection]
                else
                    form[element_keys[2]] = allowed_types.by_index[random:next_integer(1, #allowed_types.by_index)]
                end
            end
        end
    end,
    -- Both vs. Random
    function(form, state, conf, random, allowed_types, unlocked_index, locked_element)
        local selections = state.data.defenders
        if locked_element then
            local potential_targets = state.data.attackers[locked_element]

            if #potential_targets > 0 then
                local allowed_targets = {}
                for i = 1, #potential_targets do
                    if #selections[potential_targets[i]] > (conf.restrictions.enforce_different_types and 1 or 0) then
                        allowed_targets[#allowed_targets + 1] = potential_targets[i]
                    end
                end

                if #allowed_targets > 0 then
                    local target = allowed_targets[random:next_integer(1, #allowed_targets)]
                    local choices = selections[target]
                    if conf.restrictions.enforce_different_types then
                        local locked_index
                        for i = 1, #choices do if choices[i] == locked_element then locked_index = i; break end end
                        local selection = random:next_integer(1, #choices - 1)
                        if selection >= locked_index then selection = selection + 1 end
                        form[element_keys[unlocked_index]] = choices[selection]
                    else
                        form[element_keys[unlocked_index]] = choices[random:next_integer(1, #choices)]
                    end
                    return
                end
            end
            
            if conf.restrictions.enforce_different_types then
                local selection = random:next_integer(1, #allowed_types.by_index - 1)
                if selection >= allowed_types.by_name[locked_element] then selection = selection + 1 end
                form[element_keys[unlocked_index]] = allowed_types.by_index[selection]
            else
                form[element_keys[unlocked_index]] = allowed_types.by_index[random:next_integer(1, #allowed_types.by_index)]
            end
        else
            local has_second_type = form[element_keys[2]] ~= 'none' or random:bool(conf.dual_type_chance)

            local pool = {}
            local requires_multiple = has_second_type and conf.restrictions.enforce_different_types
            for i = 1, #allowed_types.by_index do
                local ty = allowed_types.by_index[i]
                if #selections[ty] > (requires_multiple and 1 or 0) then
                    pool[#pool + 1] = ty
                end
            end
            while #pool > 0 do
                local index = random:next_integer(1, #pool)
                local choices = selections[pool[index]]
                local first_choice = random:next_integer(1, #choices)
                form[element_keys[1]] = choices[first_choice]
                if has_second_type then
                    if conf.restrictions.enforce_different_types then
                        local selection = random:next_integer(1, #choices - 1)
                        if selection >= first_choice then selection = selection + 1 end
                        form[element_keys[2]] = choices[selection]
                    else
                        form[element_keys[2]] = choices[random:next_integer(1, #choices)]
                    end
                end
                return
            end
            print 'Could not find a type with the selected restrictions!'
            conf.restrictions.type_effectivity.enabled = false
            local first_index = random:next_integer(1, #allowed_types.by_index)
            form[element_keys[1]] = allowed_types.by_index[first_index]
            if has_second_type then
                if conf.restrictions.enforce_different_types then
                    local selection = random:next_integer(1, #allowed_types.by_index - 1)
                    if selection >= first_index then selection = selection + 1 end
                    form[element_keys[2]] = allowed_types.by_index[selection]
                else
                    form[element_keys[2]] = allowed_types.by_index[random:next_integer(1, #allowed_types.by_index)]
                end
            end
        end
    end
}

component.builder()
    :with_id 'monster.typing'
    :associate_random 'monster.typing'
    :default_enabledness ( false )
    :using_provider 'monsters'
    :with_dependencies()
        :after 'universal.type_matchups' :is 'soft'
    :with_settings {
        retained_type   = config.enum( false, {false, 1, 2, true} ),
        dual_type_chance = config.percentage(0.20),
        restrictions = {
            allow_none  = config.boolean(false):permit_boolable(true),
            enforce_different_types = config.boolean(true):permit_boolable(true),
            type_effectivity = config.feature {
                mode = config.enum(1, {1, 2, 3}),
                minimum = config.custom_display(config.integer(0, 0, 3, 1), display_name),
                maximum = config.custom_display(config.integer(3, 0, 3, 1), display_name)
            } :with_sorted_keys {'mode', 'minimum', 'maximum'},
            banned_types = config.limited_list({}, function(t)
                if type(t) ~= 'string' then return false end
                return (_DATA.DataIndices[data_type.Element]:TryGetValue(t))
            end)
        }
    }
    :pre_pass(function(state)
        local conf = state:get_config()
        if conf.retained_type == true then return end
        local random = state:get_random()

        local allowed_types = {
            by_index = {},
            by_name = {}
        }
        local banned_set = set.from_table(conf.restrictions.banned_types)
        local allow_none = random:bool(conf.restrictions.allow_none)
        conf.restrictions.allow_none = allow_none
        local enforce_different_types = random:bool(conf.restrictions.enforce_different_types)
        conf.restrictions.enforce_different_types = enforce_different_types

        local elements = _DATA.DataIndices[data_type.Element]:GetOrderedKeys(false)
        for i = 0, elements.Count - 1 do
            local index = #allowed_types.by_index + 1
            local element = elements[i]
            if not banned_set[element] and (element ~= 'none' or allow_none) then
                allowed_types.by_index[index] = element
                allowed_types.by_name[element] = index
            end
        end
        state.data.allowed_types = allowed_types

        if conf.restrictions.type_effectivity.enabled then
            local te_conf = conf.restrictions.type_effectivity.options
            if te_conf.maximum < te_conf.minimum then
                te_conf.minimum, te_conf.maximum = te_conf.maximum, te_conf.minimum
            end

            local element_table_state = _DATA.UniversalEvent.UniversalStates:GetWithDefault(luanet.ctype(__ElementTableState))
            ---@type {[string]: int}
            local type_map = element_table_state.TypeMap
            ---@type System.Array<System.Array<int>>
            local type_chart = element_table_state.TypeMatchup
            ---@type string[]
            local reverse_map = {}

            for element in luanet.each(type_map) do
                reverse_map[element.Value] = element.Key
            end
            
            state.data.attackers, state.data.defenders = get_pairings(
                    type_chart,
                    reverse_map,
                    allowed_types.by_name,
                    allow_none,
                    not enforce_different_types,
                    internal_effectivity[te_conf.minimum],
                    internal_effectivity[te_conf.maximum]
                )
        end
    end)
    :on_step(function(id, data, state)
        ---@diagnostic disable-next-line: assign-type-mismatch
        ---@type {retained_type: true|1|2|false, [any]: any}
        local conf = state:get_config()
        if conf.retained_type == true then return end
        local random = state:get_random()
        local allowed_types = state.data.allowed_types

        local forms = data.Forms
        if forms.Count == 0 then return end

        for i = 0, forms.Count - 1 do
            local form = forms[i]
            local enforce_different_types = random:bool(conf.restrictions.enforce_different_types)

            ---@type string?
            local locked_element = conf.retained_type and data[element_keys[conf.retained_type]]
            local unlocked_element_index = conf.retained_type and 3 - conf.retained_type
            ---@type string?
            local unlocked_element = conf.retained_type and data[element_keys[unlocked_element_index]]

            if conf.restrictions.type_effectivity.enabled then
                local te_conf = conf.restrictions.type_effectivity.options

                local method = te_methods[te_conf.mode]
                ---@diagnostic disable-next-line: unnecessary-if
                if method then
                    method(form, state, conf, random, allowed_types, unlocked_element_index, locked_element)
                else
                    error 'what!?!?!? no method????'
                end
            else
                if locked_element then
                    ---@cast unlocked_element_index 1|2
                    if unlocked_element_index == 1 or unlocked_element ~= 'none' or random:bool(conf.dual_type_chance) then
                        local selection = random:next_integer(1, #allowed_types.by_index - (enforce_different_types and 1 or 0))
                        if enforce_different_types and selection >= allowed_types.by_name[locked_element] then
                            selection = selection + 1
                        end
                        form[element_keys[unlocked_element_index]] = allowed_types.by_index[selection]
                    end
                else
                    local selection = random:next_integer(1, #allowed_types.by_index)
                    local first_element = allowed_types.by_index[selection]
                    form[element_keys[1]] = first_element

                    local second_element = form[element_keys[2]]
                    if second_element ~= 'none' or random:bool(conf.dual_type_chance) then
                        selection = random:next_integer(1, #allowed_types.by_index - (enforce_different_types and 1 or 0))
                        if enforce_different_types and selection >= allowed_types.by_name[first_element] then
                            selection = selection + 1
                        end
                        form[element_keys[2]] = allowed_types.by_index[selection]
                    end
                end
            end
            state:log_spoiler({id, i}, 'type', {form.Element1, form.Element2})
        end
    end)
    :log_spoilers(function(file, state)
        local longest_name = 8
        for key in luanet.each(_DATA.DataIndices[data_type.Element]:GetOrderedKeys(false)) do
            longest_name = math.max(longest_name, #_DATA:GetElement(key).Name:ToLocal())
        end
        local width = 29 + (3 + longest_name) * 2
        local split = string.rep('=', width)
        local template = '| %-19s| %-5s| %-'.. longest_name ..'s | %-'.. longest_name ..'s |'
        local header = {
            split,
            string.format('| %s|', s.pad_end('- Monster Types', width - 3)),
            split,
            string.format(template,
                'Identifier', 'Form', '1st Type', '2nd Type'
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
            local changes = state.spoilers[key].type
            file:write(
                string.format(template, key[1], key[2], changes[1], changes[2]),
                '\n'
            )
        end
    end)
    :register()