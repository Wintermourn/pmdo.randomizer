local function deepcopy(tbl)
    local out = {}

    local ty
    for key, value in next, tbl, nil do
        ty = type(value)
        if ty == 'table' then
            out[key] = deepcopy(value)
        else--if ty == 'userdata' then
            out[key] = value
        end
    end

    return out
end

return deepcopy