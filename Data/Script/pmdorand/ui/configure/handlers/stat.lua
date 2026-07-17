return {
    title = 'Config.Stat',
    display = function(c, v)
        return c.stringify_value(v, true)
    end,
    select = function(state, entry)
        state:push( entry.keys.value.flat, entry.setting, entry.value )
        state:update_title()
        state:update_contents()
        return true
    end
}