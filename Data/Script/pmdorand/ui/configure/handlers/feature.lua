return {
    title = 'Config.Feature',
    display = function(c, v)
        return require 'pmdorand.ui.configure.handlers.bool'.display(c.enabled, v.enabled) ..' [color=#aaaaaa]>'
    end
}