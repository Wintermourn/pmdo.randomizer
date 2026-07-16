local strings = {
    enabled = STRINGS:FormatKey 'pmdorand:enabled',
    disabled = STRINGS:FormatKey 'pmdorand:disabled',
    dynamic = STRINGS:FormatKey 'pmdorand:dynamic'
}
return {
    title = 'Config.Boolean',
    display = function(c, v)
        local ty = type(v)
        if ty == "boolean" then
            return v and strings.enabled or strings.disabled
        elseif ty == 'number' then
            if v < 0 then
                return strings.disabled
            elseif v > 1 then
                return strings.enabled
            else
                return strings.dynamic .. ('[color] (%02d%%)'):format(math.floor(v * 100))
            end
        end
    end,
    select = function() return false end
}