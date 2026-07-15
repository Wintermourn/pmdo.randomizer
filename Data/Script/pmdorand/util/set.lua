return {
    from_table = function(t)
        local s = {}
        for i,k in pairs(t) do
            if type(i) == 'string' then s[i] = true else s[k] = true end
        end
        return s
    end
}