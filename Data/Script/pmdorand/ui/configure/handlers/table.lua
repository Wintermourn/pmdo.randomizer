return {
    title = 'Config.Table',
    display = function(c, v)
        return '[color=#aaaaaa]>'
    end,
    select = function(state, entry)
        state:push( entry.keys.value.flat, entry.setting, entry.value )
        state:update_title()
        state:update_contents()
        state:update_body()
        return true
    end
}