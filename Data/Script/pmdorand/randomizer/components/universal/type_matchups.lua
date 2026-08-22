local component = require 'pmdorand.randomizer.core.component'
local config = require 'pmdorand.config'

local s = require 'pmdorand.util.string'

local data_type = RogueEssence.Data.DataManager.DataType
local __ElementTableState = luanet.import_type 'PMDC.Dungeon.ElementTableState'

local function element_count_fn() return _DATA.DataIndices[data_type.Element].Count end

local abs, floor = math.abs, math.floor

local function scale_to_int(...)
    local args = {...}
    local n = #args
    local multiplier = 1

    for i = 1, n do
        local v = args[i]
        local scaled = v * multiplier

        local val, frac, denominator
        if abs(scaled - floor(scaled + 0.5)) > 1e-9 then
            val = abs(v)
            frac, denominator = val - floor(val), 1

            if frac > 1e-9 and 1 - frac > 1e-9 then
                local h1, h2, k1, k2, b = 1, 0, 0, 1, frac
                local a, h, k
                for _ = 1, 15 do
                    a = floor(b)
                    h = a * h1 + h2
                    k = a * k1 + k2
                    h2, h1 = h1, h
                    k2, k1 = k1, k

                    if abs(frac - h / k) < 1e-9 or b - a < 1e-9 then
                        denominator = k
                        break
                    end
                    b = 1 / (b - a)
                end
            end
            local a_gcd, b_gcd = multiplier, denominator
            while b_gcd ~= 0 do
                a_gcd, b_gcd = b_gcd, a_gcd % b_gcd
            end
            multiplier = (multiplier * denominator) / a_gcd
        end
    end

    local res = {}
    for i = 1, n do
        res[i] = floor(args[i] * multiplier + 0.5)
    end
    return res, multiplier
end

local function display_multiplier(v)
    return string.format('%gx', v)
end

local matchups = {
    IMMUNE  = 0,
    WEAK    = 3,
    NEUTRAL = 4,
    STRONG  = 5
}
local reciprocal_matchups = {
    [matchups.IMMUNE    ] = 5,
    [matchups.WEAK      ] = 5,
    [matchups.NEUTRAL   ] = 4,
    [matchups.STRONG    ] = 3
}
local matchup_symbols = {
    [matchups.IMMUNE    ] = 'X',
    [matchups.WEAK      ] = 'W',
    [matchups.NEUTRAL   ] = 'N',
    [matchups.STRONG    ] = 'S'
}

local function calculate_matchup_limit(config, type_count)
    if config.type == 'constant' then
        return config.value
    elseif config.type == 'percentage' then
        return floor(config.value * type_count + 0.5)
    end
end

local function get_reciprocal(matchup)
    return reciprocal_matchups[matchup] or 4
end

local function shuffle_in_place(t)
    local n = #t
    for i = #t, 2, -1 do
        local j = math.random(i)
        t[i], t[j] = t[j], t[i]
    end
end

---@param pool {matchup: {[1]: int, [2]: int}, weight: int}[]
---@param random pmdorand.random
---@return {[1]: int, [2]: int}
local function roll_matchup(pool, random)
    if #pool == 1 then return pool[1].matchup end

    local total_weight = 0
    for i = 1, #pool do
        total_weight = total_weight + pool[i].weight
    end

    local roll = random:next_integer(1, total_weight)

    for i = 1, #pool do
        roll = roll - pool[i].weight
        if roll <= 0 then
            return pool[i].matchup 
        end
    end
    return pool[#pool].matchup
end

component.builder()
    :with_id 'universal.type_matchups'
    :associate_random 'universal.type_matchups'
    :default_enabledness ( false )
    :using_provider 'universal'
    :with_dependencies()
    :with_settings {
        elements    = config.feature {
            symmetry        = config.enum(false, {false, 'mirror', 'reciprocal'}),
            generate_none   = config.boolean(false),
            weighting   = config.table {
                immune          = config.integer(1, 0, math.maxinteger, 10),
                not_effective   = config.integer(7, 0, math.maxinteger, 10),
                neutral         = config.integer(24, 0, math.maxinteger, 10),
                super_effective = config.integer(6, 0, math.maxinteger, 10)
            },
            limits      = config.table {
                immune          =
                    config.case('constant', config.dynamic_int(1, 0, 10, 1):dynamic_max(element_count_fn)) |
                    config.case('percentage', config.percentage(1 / 18)),
                not_effective   =
                    config.case('constant', config.dynamic_int(7, 0, 10, 1):dynamic_max(element_count_fn)) |
                    config.case('percentage', config.percentage(7/18)),
                super_effective =
                    config.case('constant', config.dynamic_int(4, 0, 10, 1):dynamic_max(element_count_fn)) |
                    config.case('percentage', config.percentage(4/18))
            },
            minimums    = config.table {
                immune          =
                    config.case('constant', config.dynamic_int(0, 0, 10, 1):dynamic_max(element_count_fn)) |
                    config.case('percentage', config.percentage(0)),
                not_effective   =
                    config.case('constant', config.dynamic_int(2, 0, 10, 1):dynamic_max(element_count_fn)) |
                    config.case('percentage', config.percentage(2/18)),
                super_effective =
                    config.case('constant', config.dynamic_int(2, 0, 10, 1):dynamic_max(element_count_fn)) |
                    config.case('percentage', config.percentage(2/18))
            }
        }:with_sorted_keys {
            'symmetry',
            'generate_none',
            'limits',
            'weighting'
        },
        rebalancing = config.feature {
            immune          = config.custom_display(config.float(0,   -99, 99, 0.1), display_multiplier),
            not_effective   = config.custom_display(config.float(0.5, -99, 99, 0.1), display_multiplier),
            super_effective = config.custom_display(config.float(1.5, -99, 99, 0.1), display_multiplier)
        }
    }
    :on_step(function(id, data, state)
        local conf, random = state:get_config(), state:get_random()
        local element_state = data.UniversalStates:GetWithDefault(luanet.ctype(__ElementTableState))

        if conf.elements.enabled then
            local budgets = {}
            local element_count = _DATA.DataIndices[data_type.Element].Count - (conf.elements.options.generate_none and 0 or 1)
            local immune_limit = calculate_matchup_limit(conf.elements.options.limits.immune, element_count)
            local weak_limit = calculate_matchup_limit(conf.elements.options.limits.not_effective, element_count)
            local strong_limit = calculate_matchup_limit(conf.elements.options.limits.super_effective, element_count)
            local default_symmetry = conf.elements.options.symmetry

            ---@diagnostic disable-next-line: missing-fields, assign-type-mismatch
            ---@type {[0]: int, [3]: int, [4]: int, [5]: int}
            local weights = {
                [matchups.IMMUNE    ] = conf.elements.options.weighting.immune,
                [matchups.WEAK      ] = conf.elements.options.weighting.not_effective,
                [matchups.NEUTRAL   ] = conf.elements.options.weighting.neutral,
                [matchups.STRONG    ] = conf.elements.options.weighting.super_effective
            }

            local minimums = {
                [matchups.IMMUNE    ] = calculate_matchup_limit(conf.elements.options.minimums.immune, element_count),
                [matchups.WEAK      ] = calculate_matchup_limit(conf.elements.options.minimums.not_effective, element_count),
                [matchups.STRONG    ] = calculate_matchup_limit(conf.elements.options.minimums.super_effective, element_count)
            }
            local drafting_order = { matchups.IMMUNE, matchups.WEAK, matchups.STRONG }
            table.sort(drafting_order, function(a, b)
                return minimums[a] < minimums[b]
            end)

            for i = 1, element_count do
                budgets[i] = {
                    [matchups.IMMUNE    ]  = immune_limit,
                    [matchups.WEAK      ]  = weak_limit,
                    [matchups.STRONG    ]  = strong_limit
                }
            end

            local chart, pairings = {}, {}
            if default_symmetry == false then
                for a = 1, element_count do
                    chart[a] = {}
                    for b = 1, element_count do
                        pairings[#pairings + 1] = {a, b}
                    end
                end
            else
                for a = 1, element_count do
                    chart[a] = {}
                    for b = a, element_count do
                        pairings[#pairings + 1] = {a, b}
                    end
                end
            end
            shuffle_in_place(pairings)

            do -- "drafting" for minimums
                
                for _, draft_type in ipairs(drafting_order) do
                    local min_required = minimums[draft_type]
                    if min_required > 0 then
                        local needs_amount, drafters = {}, {}
                        for i = 1, element_count do
                            needs_amount[i] = min_required
                            drafters[i] = i
                        end

                        for _pass = 1, min_required do
                            shuffle_in_place(drafters)

                            for _, a in ipairs(drafters) do
                                if needs_amount[a] > 0 then
                                    local valid_targets = {}

                                    for b = 1, element_count do
                                        if a ~= b and chart[a][b] == nil then
                                            local other_target = default_symmetry == 'reciprocal' and get_reciprocal(draft_type) or draft_type
                                            if budgets[a][draft_type] > 0 and budgets[b][other_target] > 0 then
                                                valid_targets[#valid_targets + 1] = b
                                            end
                                        end
                                    end

                                    if #valid_targets > 0 then
                                        local b = valid_targets[random:next_integer(1, #valid_targets)]
                                        local other_target = default_symmetry == 'reciprocal' and get_reciprocal(draft_type) or draft_type

                                        chart[a][b] = draft_type
                                        budgets[a][draft_type] = budgets[a][draft_type] - 1
                                        needs_amount[a] = needs_amount[a] - 1

                                        if default_symmetry then
                                            chart[b][a] = other_target
                                            budgets[b][other_target] = budgets[b][other_target] - 1

                                            if default_symmetry == 'mirror' and other_target == draft_type then
                                                needs_amount[b] = needs_amount[b] - 1
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end

            end

            local n = #pairings
            for i = 1, n do
                ---@type {[1]: int, [2]: int}
                local matchup = pairings[i]
                if not chart[matchup[1]][matchup[2]] then
                    local isnt_self = matchup[1] ~= matchup[2]
                    local symmetry = isnt_self and default_symmetry

                    ---@type {matchup: {[1]: int, [2]: int}, weight: int}[]
                    local pool = {
                        {matchup = {matchups.NEUTRAL, matchups.NEUTRAL}, weight = weights[matchups.NEUTRAL]}
                    }
                    for _i, k in ipairs {matchups.IMMUNE, matchups.WEAK, matchups.STRONG} do
                        ---@type int
                        local other_target = symmetry == 'reciprocal' and get_reciprocal(k) or k
                        if budgets[matchup[1]][k] > 0 and budgets[matchup[2]][other_target] > 0 then
                            pool[#pool + 1] = {matchup = {k --[[@as int]], other_target}, weight = weights[k] --[[@as int]]}
                        end
                    end

                    local chosen_matchup = roll_matchup(pool, random)
                    local our_result = chosen_matchup[1]
                    chart[matchup[1]][matchup[2]] = our_result
                    if our_result ~= matchups.NEUTRAL then
                        local our_budgets = budgets[matchup[1]]
                        our_budgets[our_result] = our_budgets[our_result] - 1
                    end

                    if symmetry ~= false then
                        local their_result = chosen_matchup[2]
                        chart[matchup[2]][matchup[1]] = their_result
                        if their_result ~= matchups.NEUTRAL then
                            local their_budgets = budgets[matchup[2]]
                            their_budgets[their_result] = their_budgets[their_result] - 1
                        end
                    end
                end
            end

            -- Send to C#
            local offset = (conf.elements.options.generate_none and 1 or 0)
            for i = 1, element_count do
                local working_array = element_state.TypeMatchup[i - offset]
                for c = 1, element_count do
                    working_array[c - offset] = chart[i][c]
                end
            end
        end
        if conf.rebalancing.enabled then
            ---@type table
            local options = conf.rebalancing.options
            local scaled_values, baseline = scale_to_int(
                options.immune,
                options.not_effective * options.not_effective,
                options.not_effective,
                options.super_effective,
                options.super_effective * options.super_effective
            )
            for i = 0, 5 do
                element_state.Effectiveness[i] = scaled_values[1]
            end
            element_state.Effectiveness[6] = scaled_values[2]
            element_state.Effectiveness[7] = scaled_values[3]
            element_state.Effectiveness[8] = baseline
            element_state.Effectiveness[9] = scaled_values[4]
            element_state.Effectiveness[10] = scaled_values[5]
        end
    end)
    :log_spoilers(function(file, state)
        local conf = state:get_config()
        local element_state = _DATA.UniversalEvent.UniversalStates:GetWithDefault(luanet.ctype(__ElementTableState))
        local element_map = element_state.TypeMap
        local type_matchups = element_state.TypeMatchup

        if conf.elements.enabled then
            local longest_name = 0
            local elements = {
                {'none', _DATA:GetElement 'none' }
            }
            for pair in luanet.each(element_map) do
                local element = _DATA:GetElement(pair.Key)
                elements[pair.Value + 1] = {pair.Key, element}
                longest_name = math.max(longest_name, #element.Name:ToLocal())
            end
            local required_width = 3 + 2 * #elements
            local element_num_length = #tostring(#elements)
            local name_offset = 4 + element_num_length
            longest_name = longest_name + name_offset
            required_width = required_width + longest_name

            local split = string.rep('=', required_width)
            file:write(table.concat(
                {
                    split,
                    string.format('| %s|', s.pad_end('- Type Matchups', required_width - 3)),
                    split,
                    s.pad_end(' CHART', required_width, ' CHART'),
                    split,
                    string.format('| %s| %s|', s.pad_end('Element', longest_name), s.pad_end('Defending', required_width - longest_name - 5)),
                    ''
                },
                '\n'
            ))
            local header = {
                string.format("| %s|", s.pad_end('Attacking', longest_name))
            }
            for i = 1, #elements do
                local name = elements[i][2].Name:ToLocal()
                header[#header + 1] = string.sub(name, 1, utf8.offset(name, 2) - 1) ..'|'
            end
            file:write(table.concat(header) ..'\n'.. split ..'\n')
            local thin_split = string.rep('-', required_width)
            for i = 1, #elements do
                local oot = {}
                local type = type_matchups[i - 1]
                for c = 1, #elements do
                    oot[c] = matchup_symbols[type[c - 1]] ..'|'
                end
                if i > 1 then
                    file:write(string.format('%s\n| %-'.. (longest_name - name_offset) ..'s (%-'.. element_num_length ..'s) |%s\n', thin_split, elements[i][2].Name:ToLocal(), i - 1, table.concat(oot)))
                else
                    file:write(string.format('| %-'.. (longest_name - name_offset) ..'s (%-'.. element_num_length ..'s) |%s\n', elements[i][2].Name:ToLocal(), i - 1, table.concat(oot)))
                end
            end
            file:write(table.concat(
                {
                    split,
                    'Key =',
                    string.format('\t%s = IMMUNE', matchup_symbols[matchups.IMMUNE]),
                    string.format('\t%s = WEAK', matchup_symbols[matchups.WEAK]),
                    string.format('\t%s = NEUTRAL', matchup_symbols[matchups.NEUTRAL]),
                    string.format('\t%s = STRONG', matchup_symbols[matchups.STRONG])
                },
                '\n'
            ))
        end
    end)
    :register()