--- basic utility for wrapping a function in a way that will replace the first argument

---@class Disowner
local __disowner = {
    ---@type function
    ---@diagnostic disable-next-line: assign-type-mismatch
    fn = nil,
    new_self = nil
}
function __disowner:__call(_, ...)
    return self.fn(self.new_self, ...)
end

function __disowner:__tostring()
    return string.format('Disowner <%s, %s>', tostring(self.fn), tostring(self.new_self))
end

---@param new_self table
---@param fn function
---@return Disowner
return function(new_self, fn)
    return setmetatable({
        new_self = new_self,
        fn = fn
    }, __disowner)
end