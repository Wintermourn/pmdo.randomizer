local bool = require 'pmdorand.ui.configure.handlers.bool'

local dummy = ''
return {
    title = 'Config.Feature',
    display = function(c, v)
        return bool.display(c.enabled, v.enabled) ..' [color=#aaaaaa]>'
    end,
    select = function(state, entry)
        state:push( entry.keys.value.flat, entry.setting, entry.value )
        state:update_title()
        state:update_contents()
        state:update_body()
        return true
    end,
    move = function(state, entry, input, delta)
        local pseudo_entry = {
            value_pointer = {entry.value, 'enabled'},
            value = entry.value.enabled,
            texts = {nil, {dummy}}
        }
        local succ = bool.move(state, pseudo_entry, input, delta)
        entry.texts[2][1] = bool.display(entry.setting.enabled, entry.value.enabled) ..' [color=#aaaaaa]>'
        return succ
    end
}