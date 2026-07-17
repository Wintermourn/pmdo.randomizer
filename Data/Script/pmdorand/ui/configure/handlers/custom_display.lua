local handlers

local dummy = ''
return {
    title = 'Config.CustomDisplay',
    display = function(c, v)
        return c.method(v)
    end,
    select = function(state, entry)
        handlers = handlers or require 'pmdorand.ui.configure.handlers'
        local pseudo_entry = {}
        for i, k in pairs(entry) do
            pseudo_entry[i] = k
        end
        pseudo_entry.setting = entry.setting.config
        return handlers.get(entry.setting.config.__title).select(state, pseudo_entry)
    end,
    move = function(state, entry, input, delta)
        handlers = handlers or require 'pmdorand.ui.configure.handlers'
        local handler = handlers.get(entry.setting.config.__title)
        local pseudo_entry = {}
        for i, k in pairs(entry) do
            pseudo_entry[i] = k
        end
        pseudo_entry.setting = entry.setting.config
        local res = handler.move(state, pseudo_entry, input, delta)
        entry.value = pseudo_entry.value
        entry.texts[2][1] = entry.setting.method(entry.value)
        return res
    end
}