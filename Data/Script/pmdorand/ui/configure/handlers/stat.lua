return {
    title = 'Config.Stat',
    display = function(c, v)
        return c:stringify(true)
    end,
    select = function() return false end
}