---@class Disowner.Specification
---@field path {[number]: string}|any
---@field handler fun(wrapped: table, unwrapped: table, fn: function, ...: any): any
local __spec = {}
__spec.__index = __spec
---@class Disowner.Wrapper
---@field spec Disowner.Specification
---@field fn function
local __wrapper = {}
__wrapper.__index = __wrapper

function __wrapper:__call(wrapped, ...)
    local spec = self.spec
    local target = self.fn

    local unwrapped = wrapped
    local path = spec.path

    if type(path) == 'table' then
        for i = 1, #path do
            unwrapped = rawget(unwrapped, path[i])
        end 
    elseif path ~= nil then
        unwrapped = rawget(unwrapped, path)
    end

    return spec.handler(wrapped, unwrapped, target, ...)
end

function __spec:__tostring()
    return string.format('Disowner Specification <%s, %s>', type(self.path) == 'table' and table.concat(self.path, '.') or tostring(self.path), tostring(self.handler))
end

function __wrapper:__tostring()
    return string.format('Disowner <%s, %s>', type(self.spec.path) == 'table' and table.concat(self.spec.path, '.') or tostring(self.spec.path), tostring(self.fn))
end

local disowner = {}

--- Creates a static disowner specification.
---@param path {[number]: string}|any
---@param handler fun(wrapped: table, unwrapped: table, fn: function, ...: any): any
---@return Disowner.Specification
function disowner.new(path, handler)
    return setmetatable({ path = path, handler = handler }, __spec)
end

--- Creates a wrapper around the chosen function to aid in unwrapping a table.
---@param spec Disowner.Specification
---@param target function
---@return Disowner.Wrapper
function disowner.wrap(spec, target)
    return setmetatable({ spec = spec, fn = target }, __wrapper)
end

return disowner