---@diagnostic disable: cast-type-mismatch
local setter = require 'pmdorand.randomizer.core.config.setter'
local registry = require 'pmdorand.randomizer.core.registry'
local displays = registry .get 'config.display'
local setters = registry .get 'config.setter'

return setter.builder() --[[@as ConfigSetterBuilder<Config.Feature>]]
    :with_title 'Config.Feature'
    :with_select(function(entry)
        entry:push()
    end)
    :with_move(function(entry, input, delta)
        local internal_setter = setters :get 'Config.Boolean'
        if internal_setter == nil or internal_setter.move == nil then return false end

        local temp = {
            value_pointer = entry.value_pointer,
            value = entry.value,
            setting = entry.setting
        }
        ---@cast entry pmdorand.config.entry<Config.Boolean>

        entry.value_pointer = {entry.value, 'enabled'}
        entry.value = entry.value.enabled
        entry.setting = temp.setting.enabled

        ---@diagnostic disable-next-line: need-check-nil
        local res = internal_setter .move(entry, input, delta)
        ---@cast entry pmdorand.config.entry<Config.Feature>

        entry.value_pointer = temp.value_pointer
        entry.value = temp.value
        entry.setting = temp.setting

        if #entry.texts > 1 then
            entry.texts[2][1] = displays :get 'Config.Feature' .display(entry.setting, entry.value)
        end
        return res
    end)
    :register()