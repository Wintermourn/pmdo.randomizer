---@diagnostic disable: assign-type-mismatch

local setter = require 'pmdorand.randomizer.core.config.setter'
local setters = require 'pmdorand.randomizer.core.registry' .get 'config.setter'
local displays = require 'pmdorand.randomizer.core.registry' .get 'config.display'

return setter.builder() --[[@as ConfigSetterBuilder<Config.CustomDisplay>]]
    :with_title 'Config.CustomDisplay'
    :with_select(function(entry)
        local internal_setter = setters:get(entry.setting.config.__title)
        if internal_setter == nil or internal_setter.select == nil then return false end

        local this = entry.setting
        entry.setting = this.config
        local res = internal_setter.select(entry)
        entry.setting = this

        if #entry.texts > 1 then
            entry.texts[2][1] = displays:get 'Config.CustomDisplay' .display(this, entry.value)
            entry:update_text()
        end
        return res
    end)
    :with_move(function(entry, input, delta)
        local internal_setter = setters:get(entry.setting.config.__title)
        if internal_setter == nil or internal_setter.move == nil then return false end

        local this = entry.setting
        entry.setting = this.config
        local res = internal_setter.move(entry, input, delta)
        entry.setting = this

        if #entry.texts > 1 then
            entry.texts[2][1] = displays:get 'Config.CustomDisplay' .display(this, entry.value)
        end
        return res
    end)
    :register()