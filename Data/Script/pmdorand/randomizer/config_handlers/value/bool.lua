local async = require 'lib.pmdorand.async'
local setter = require 'pmdorand.randomizer.core.config.setter'
local displays = require 'pmdorand.randomizer.core.registry' .get 'config.display'

return setter.builder() --[[@as ConfigSetterBuilder<Config.Boolean>]]
    :with_title 'Config.Boolean'
    :with_select(function(entry)
        local promise = async.promise()

        promise:on_resolved(function(out_value)
            entry:set(out_value)
            if #entry.texts > 1 then
                entry.texts[2][1] = displays:get 'Config.Boolean' .display(entry.setting, entry.value)
            end
            entry:update_text()
        end)

        local actions = {}

        if entry.value ~= true then
            actions[#actions+1] = {STRINGS:FormatKey 'pmdorand:set_to' .. STRINGS:FormatKey 'pmdorand:enabled', true, function()
                promise:resolve(true)
                _MENU:RemoveMenu()
            end}
        end
        if entry.value ~= false then
            actions[#actions+1] = {STRINGS:FormatKey 'pmdorand:set_to' .. STRINGS:FormatKey 'pmdorand:disabled', true, function()
                promise:resolve(false)
                _MENU:RemoveMenu()
            end}
        end
        if entry.setting.allow_boolable then
            actions[#actions+1] = {STRINGS:FormatKey 'pmdorand:set_to' .. STRINGS:FormatKey 'pmdorand:dynamic', true, function()
                promise:resolve(0.5)
                _MENU:RemoveMenu()
            end}
        end

        local function close()
            promise:reject()
            _MENU:RemoveMenu()
        end
        actions[#actions + 1] = {'Cancel', true, close}
        require 'pmdorand.ui.choice' .open(
            function() promise:reject() end,
            table.unpack(actions)
        )

        return true
    end)
    :with_move(function(entry, input, delta)
        if type(entry.value) == 'boolean' then
            entry:set(not entry.value)
        else
            ---@type boolean|number
            local out = entry.value + delta / 100
            if out <= 0 then out = false elseif out >= 1 then out = true end
            entry:set(out)
        end
        if #entry.texts > 1 then
            entry.texts[2][1] = displays:get 'Config.Boolean' .display(entry.setting, entry.value)
        end
        return true
    end)
    :register()