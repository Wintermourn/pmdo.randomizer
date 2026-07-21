local component = require 'pmdorand.randomizer.core.component'
local config = require 'pmdorand.config'
local math_util = require 'pmdorand.util.math'
local state_cache = require 'pmdorand.randomizer.cache.states'

component.builder()
    :with_id 'monster.texts'
    :associate_random 'monster.texts'
    :using_provider 'monsters'
    :with_dependencies()
    :with_settings {
        names = config.feature {
            per_form = config.boolean(true):permit_boolable(true),
            include_existing = config.boolean(true):permit_boolable(true),
            prioritize_custom_names = config.boolean(true),
            allow_duplicates = config.boolean(false)
        },
        species = config.feature {
            include_existing = config.boolean(true):permit_boolable(true),
            prioritize_custom_names = config.boolean(true),
            allow_duplicates = config.boolean(false)
        },
        titles = config.feature {
            include_existing = config.boolean(true):permit_boolable(true),
            prioritize_custom_names = config.boolean(true),
            allow_duplicates = config.boolean(false)
        }
    }
    :pre_pass(function(state)
        local conf = state:get_config()
        local random = state:get_random()

        local names_enabled = random:bool(conf.names.enabled)
        local titles_enabled = random:bool(conf.titles.enabled)
        local species_enabled = random:bool(conf.species.enabled)
        if not names_enabled and not titles_enabled and not species_enabled then return end

        local species_pool, name_pool, title_pool = {}, {}, {}
        local provider = state.get_provider 'monsters'
        local provider_state = state_cache.provider(provider.id)

        local monster
        for key in provider.methods.iterate_keys(provider_state) do
            monster = provider:get_and_cache(key, provider_state)
            if monster then
                if species_enabled and random:bool(conf.species.options.include_existing) then species_pool[#species_pool + 1] = monster.Name end
                if titles_enabled and random:bool(conf.titles.options.include_existing) then title_pool[#title_pool + 1] = monster.Title end
                if names_enabled then
                    for form in luanet.each(monster.Forms) do
                        if random:bool(conf.names.options.include_existing) then name_pool[#name_pool + 1] = form.FormName end
                    end
                end
            end
        end
        
        state.data.name_pool = names_enabled and name_pool
        state.data.species_pool = species_enabled and species_pool
        state.data.title_pool = titles_enabled and title_pool
    end)
    :on_step(function(id, data, state)
        local conf = state:get_config()
        local random = state:get_random()
        
        local replacement
        if state.data.species_pool and #state.data.species_pool > 0 then
            if conf.species.options.allow_duplicates then
                replacement = state.data.species_pool[random:next_integer(1, #state.data.species_pool)] 
            else
                replacement = table.remove(state.data.species_pool, random:next_integer(1, #state.data.species_pool))
            end
            if type(replacement) == 'string' then
                
            else
                data.Name = replacement
            end
        end
        
        if state.data.name_pool and #state.data.name_pool > 0 then
            local per_form = random:bool(conf.names.options.per_form)
            local last_name --[[@type any]]
            for form in luanet.each(data.Forms) do
                if last_name and not per_form then
                    form.FormName = last_name
                    goto skip_name
                end
                if conf.names.options.allow_duplicates then
                    replacement = state.data.name_pool[random:next_integer(1, #state.data.name_pool)] 
                else
                    if #state.data.name_pool == 0 then break end
                    replacement = table.remove(state.data.name_pool, random:next_integer(1, #state.data.name_pool))
                end
                if type(replacement) == 'string' then
                    form.FormName = replacement
                end
                form.FormName = replacement
                last_name = replacement
                ::skip_name::
            end
        else
            print '???'
        end
        
        if state.data.title_pool and #state.data.title_pool > 0 then
            if conf.titles.options.allow_duplicates then
                replacement = state.data.title_pool[random:next_integer(1, #state.data.title_pool)] 
            else
                replacement = table.remove(state.data.title_pool, random:next_integer(1, #state.data.title_pool))
            end
            if type(replacement) == 'string' then
                
            else
                data.Title = replacement
            end
        end
    end)
    :register()