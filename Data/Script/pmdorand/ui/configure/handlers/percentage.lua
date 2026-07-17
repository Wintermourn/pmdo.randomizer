local __Input = luanet.namespace 'Microsoft.Xna.Framework.Input'
    local __Keys = __Input.Keys

return {
    title = 'Config.Percent',
    display = function(c, v)
        return string.format('%.1f%%', v * 100)
    end,
    select = function() return false end,
    move = function(state, entry, input, delta)
        local step = delta
        if (entry.value <= 0 and delta < 0) or (entry.value >= 1 and delta > 0) then return false end
        if input:BaseKeyDown(__Keys.LeftShift) then
            step = step * 5
        elseif input:BaseKeyDown(__Keys.LeftControl) then
            step = step / 10
        end
        local v = math.max(0, math.min(1, entry.value + math.floor(step * 10)/1000))
        entry.value_pointer[1][entry.value_pointer[2]] = v
        entry.value = v
        entry.texts[2][1] = string.format('%.1f%%', v * 100)
    end
}