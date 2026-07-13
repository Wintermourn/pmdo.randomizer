local registries = {}

---@class pmdorand.registry<T>
---@field register fun(self, ...: T): boolean
---@field get fun(self, key: string): T
---@field contains fun(self, obj: T): boolean
---@field contains_key fun(self, key: string): boolean
local registry = {
    content = {
        by_key = {},
        by_value = {}
    },
    ---@type fun(object: T): boolean
    filter = function() return true end,
    ---@type fun(object: T): string
    indexer = function(obj) return obj.id end
}
registry.__index = registry

function registry:get(key)
    return self.content.by_key[key]
end

function registry:contains(obj)
    return self.content.by_value[obj] ~= nil
end

function registry:contains_key(key)
    return self.content.by_key[key] ~= nil
end

function registry:register(...)
    local ct = select('#', ...)
    local all_success = true
    local entry
    for i = 1, ct do
        entry = select(i, ...)

        if self.filter(entry) then
            local id = self.indexer(entry)
            self.content.by_key[id] = entry
            self.content.by_value[entry] = id
        else
            all_success = false
        end
    end
    return all_success
end

local public = {}

---@generic T
---@param name string
---@param filter fun(obj: `T`): boolean
---@param indexer fun(obj: T): string
---@return pmdorand.registry<T>
function public.create(name, filter, indexer)
    ---@diagnostic disable-next-line: missing-return-value
    if registries[name] then return end

    ---@diagnostic disable-next-line: missing-fields
    ---@type pmdorand.registry<T>
    local o = {
        content = {
            by_key = {},
            by_value = {}
        },
        filter = filter or function() return true end,
        indexer = indexer or function(obj) return obj.id end
    }

    setmetatable(o, registry)
    registries[name] = o
    return o
end

---@param name string
---@return pmdorand.registry<any>
---@overload fun(name: 'providers'): pmdorand.registry<pmdorand.provider<any>>
function public.get(name)
    return registries[name]
end

return public