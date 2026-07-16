return {
    title = 'Config.Percent',
    display = function(c, v)
        return string.format('%.1f%%', v * 100)
    end
}