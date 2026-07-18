local __Type = luanet.import_type 'System.Type'
    local __IEnumerable = __Type.GetType 'System.Collections.IEnumerable'
    local __IEnumerator = __Type.GetType 'System.Collections.IEnumerator'
local method_IEnumerable_GetEnumerator = __IEnumerable:GetMethod 'GetEnumerator'
local method_IEnumerator_MoveNext = __IEnumerator:GetMethod 'MoveNext'
local method_IEnumerator_Current = __IEnumerator:GetProperty 'Current'

local out = {}

function out.enumerate_ienumerableable(ienumerable_implementing_object)
    local enumerator = method_IEnumerable_GetEnumerator:Invoke(ienumerable_implementing_object, nil)

    return function()
        if method_IEnumerator_MoveNext:Invoke(enumerator, nil) == true then
            return method_IEnumerator_Current:GetValue(enumerator, nil)
        end
    end
end

return out