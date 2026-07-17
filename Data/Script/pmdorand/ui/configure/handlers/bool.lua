local __Input = luanet.namespace 'Microsoft.Xna.Framework.Input'
    local __Keys = __Input.Keys

local async = require 'lib.pmdorand.async'

local strings = {
    enabled = STRINGS:FormatKey 'pmdorand:enabled',
    disabled = STRINGS:FormatKey 'pmdorand:disabled',
    dynamic = STRINGS:FormatKey 'pmdorand:dynamic'
}

local function display(c, v)
    local ty = type(v)
    if ty == "boolean" then
        return v and strings.enabled or strings.disabled
    elseif ty == 'number' then
        if v < 0 then
            return strings.disabled
        elseif v > 1 then
            return strings.enabled
        else
            return strings.dynamic .. ('[color] (%02d%%)'):format(math.floor(v * 100 + 0.5))
        end
    end
end

return {
    title = 'Config.Boolean',
    display = display,
    select = function(state, entry)
        local promise = async.promise()
        local value_parent, value_key = state:current_values(), entry.keys.value[#entry.keys.value]
        for i = 1, #entry.keys.value - 1 do
            value_parent = value_parent[entry.keys.value[i]]
        end
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
        actions[#actions+1] = {STRINGS:FormatKey 'pmdorand:set_to' .. STRINGS:FormatKey 'pmdorand:dynamic', true, function()
            promise:resolve(0.5)
            _MENU:RemoveMenu()
        end}

        local function close()
            promise:reject()
            _MENU:RemoveMenu()
        end
        actions[#actions + 1] = {'Cancel', true, close}
        require 'pmdorand.ui.choice' .open(
            function() promise:reject() end,
            table.unpack(actions)
        )

        promise:on_resolved(function(out_value)
            value_parent[value_key] = out_value
            entry.value = out_value
            entry.texts[2][1] = display(entry.structure, out_value)
            state:update_body()
        end)

        return true
    end,
    move = function(state, entry, input, delta)
        local step = delta > 0 and 1 or -1
        if input:BaseKeyDown(__Keys.LeftShift) then
            step = step * 5
        end

        local ty, v = type(entry.value)
        if ty == 'boolean' then
            v = not entry.value
        elseif ty == 'number' then
            v = math.max(0, math.min(1, entry.value + step / 100))
            if v == 0 then v = false elseif v == 1 then v = true end
        else
            return false
        end
        entry.value_pointer[1][entry.value_pointer[2]] = v
        entry.value = v
        entry.texts[2][1] = display(entry.structure, v)
        return true
    end
}