return {
    title = 'Config.Feature',
    display = function(c, v)
        return require 'pmdorand.ui.configure.handlers.bool'.display(c.enabled, v.enabled) ..' [color=#aaaaaa]>'
    end,
    select = function(state, entry)
        state:push( entry.keys.value.flat, entry.setting, entry.value )
        state:update_title()
        state:update_contents()
        state:update_body()
        return true
    end
}