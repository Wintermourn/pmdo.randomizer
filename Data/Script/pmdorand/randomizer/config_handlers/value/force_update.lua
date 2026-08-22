---@diagnostic disable: assign-type-mismatch

local setter = require 'pmdorand.randomizer.core.config.setter'
local setters = require 'pmdorand.randomizer.core.registry' .get 'config.setter'

return setter.builder() --[[@as ConfigSetterBuilder<Config.ForceUpdate>]]
    :with_title 'Config.ForceUpdate'
    :with_select(function(entry)
        local internal_setter = setters:get(entry.setting.config.__title)
        if internal_setter == nil or internal_setter.select == nil then return false end

        local this = entry.setting
        entry.setting = this.config
        local res = internal_setter.select(entry)
        entry.setting = this

        entry:full_update_text()
        return res
    end)
    :with_move(function(entry, input, delta)
        local internal_setter = setters:get(entry.setting.config.__title)
        if internal_setter == nil or internal_setter.move == nil then return false end

        local this = entry.setting
        entry.setting = this.config
        local res = internal_setter.move(entry, input, delta)
        entry.setting = this

        entry:full_update_text()
        return res
    end)
    :register()