local public = {}

function public.show()
    _MENU:AddMenu(require 'pmdorand.ui.root' .create(), false)
end

return public