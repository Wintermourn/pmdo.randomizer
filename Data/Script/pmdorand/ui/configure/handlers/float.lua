local __Input = luanet.namespace 'Microsoft.Xna.Framework.Input'
    local __Keys = __Input.Keys

return {
    title = 'Config.Float',
    display = function(c, v)
        return string.format('%.4g', v)
    end,
    select = function() return false end,
    move = function(state, entry, input, delta)
        local lower_bound, upper_bound = entry.setting.minimum, entry.setting.maximum
        if (entry.value <= lower_bound and delta < 0) or (entry.value >= upper_bound and delta > 0) then
            return false 
        end
        local step = delta * entry.setting.step_size
        if input:BaseKeyDown(__Keys.LeftShift) then
            step = step * 5
        elseif input:BaseKeyDown(__Keys.LeftControl) then
            step = step / 10
        end
        ---@type number
        local v = math.min(upper_bound, math.max(lower_bound, entry.value + step))
        entry.value_pointer[1][entry.value_pointer[2]] = v
        entry.value = v
        entry.texts[2][1] = tostring(v)
        return true
    end
}