local none = function() end
---@generic T
---@type {[T]: fun(structure: T, value: any, random: pmdorand.random, backup_name: string?, parent_name: string?)?}
local handlers = {}

---@param structure Config.Table
handlers['Config.Table'] = function(structure, value, random--[[ , _, parent ]])
    for i, k in pairs(structure.content) do
        (handlers[k.__title] or none)(k, value[i], random--[[ , i, parent ]])
    end
end

---@param structure Config.Feature
handlers['Config.Feature'] = function(structure, value, random--[[ , backup_name, parent_name ]])
    local ty = type(value.enabled)
    if ty == 'number' then
        value.enabled = random:bool(value.enabled)
        --[[ if parent_name then
            print(string.format('in %s, feature %s has collapsed to %s', parent_name, backup_name or structure, value.enabled))
        else
            print(string.format('feature %s has collapsed to %s', backup_name or structure, value.enabled))
        end ]]
    end
    local opts = value.options
    for i, k in pairs(structure.options.content) do
        (handlers[k.__title] or none)(k, opts[i], random--[[ , i, parent_name ]])
    end
end

---@param structure Config.Variant
handlers['Config.Variant'] = function(structure, value, random--[[ , backup_name, parent_name ]])
    local ty = type(value.type)
    local variant = structure.variants[ty]
    if variant then
        (handlers[variant.__title] or none)(variant, value.value, random--[[ , backup_name, parent_name ]])
    end
end

---Converts numeric enabledness on variants to booleans. Automatically run on all components before a pass.
---@param structure Config.Table|Config.Feature|Config.Variant
---@param random pmdorand.random
return function (structure, values, random--[[ , parent_name ]])
    local ty = structure.__title
    if handlers[ty] then
        handlers[ty](structure, values, random, nil--[[ , parent_name ]])
    end
end