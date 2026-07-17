local __Input = luanet.namespace 'Microsoft.Xna.Framework.Input'
    local __Keys = __Input.Keys

return {
    title = 'Config.Int',
    display = function(c, v)
        return tostring(v)
    end,
    select = function() return false end,
    move = function(state, entry, input, delta)
        local lower_bound, upper_bound = entry.setting.minimum, entry.setting.maximum
        if (entry.value <= lower_bound and delta < 0) or (entry.value >= upper_bound and delta > 0) then
            return false 
        end
        local step = delta > 0 and 1 or -1
        if input:BaseKeyDown(__Keys.LeftShift) then
            step = entry.setting.jump_size and math.floor(entry.setting.jump_size * step + 0.5) or (step * math.ceil((upper_bound - lower_bound) / 10) )
        end
        local v = math.min(upper_bound, math.max(lower_bound, entry.value + step))
        entry.value_pointer[1][entry.value_pointer[2]] = v
        entry.value = v
        entry.texts[2][1] = tostring(v)
        return true
    end
}