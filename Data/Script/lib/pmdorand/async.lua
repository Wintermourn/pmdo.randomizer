---@diagnostic disable: duplicate-type, duplicate-doc-field, duplicate-set-field
local unpack = table.unpack or unpack

local async = {
    ---@type {[int]: Async.Task}
    tasks = {},
    next_id = 1,
    current_task = nil,
    current_time = 0
}

---@class Async.Condition
---@field length int?
---@field target int?

---@class Async.Task
---@field id int
---@field coroutine thread
---@field status "running"|"dead"|'wait:T'|'waiting'
---@field timer int
---@field condition Async.Condition
---@field blocking Async.Task[]
---@field continue_arguments any[]?
---@field promise Async.Promise
local _task = {}
_task.__index = _task

function _task:resume(...)
    async.current_task = self
    local out = {coroutine.resume(self.coroutine, ...)}
    local success, err = out[1], out[2]
    async.current_task = nil

    if not success then
        print(string.format("[async] task %d failed: %s", self.id, tostring(err))) 
        async.tasks[self.id] = nil
        self.promise:reject(tostring(err))
    elseif coroutine.status(self.coroutine) == 'dead' then
        self.status = 'dead'
        async.tasks[self.id] = nil
        if #self.blocking > 0 then
            for _,k in pairs(self.blocking) do
                k.continue_arguments = { unpack(out, 2) }
                k.status = 'waiting'
            end 
            self.blocking = {}
        end
        self.promise:resolve(unpack(out, 2))
    end
end

function _task:cancel(...)
    async.tasks[self.id] = nil
    if #self.blocking > 0 then
        for _i,k in ipairs(self.blocking) do
            k.continue_arguments = {...}
            k.status = 'waiting'
        end 
    end
end

---@class Async.Promise
local _promise = {
    finished = false,
    resolved = false,
    return_values = nil,
    subscribers = {
        on_resolved = {},
        on_rejected = {}
    }
}
_promise.__index = _promise

function _promise:resolve(...)
    if self.finished then return end
    self.finished = true
    self.resolved = true
    self.return_values = {...}
    for i,k in ipairs(self.subscribers.on_resolved) do
        k(...)
    end
end

function _promise:reject(...)
    if self.finished then return end
    self.finished = true
    self.resolved = false
    self.return_values = {...}
    for i,k in ipairs(self.subscribers.on_rejected) do
        k(...)
    end
end

---@param fn async fun(...)
function _promise:on_resolved(fn)
    if self.finished and self.resolved then fn(unpack(self.return_values)) end
    local on_res = self.subscribers.on_resolved
    on_res[#on_res + 1] = fn
    return self
end

---@param fn async fun(...)
function _promise:on_rejected(fn)
    if self.finished and not self.resolved then fn(unpack(self.return_values)) end
    local on_res = self.subscribers.on_rejected
    on_res[#on_res + 1] = fn
    return self
end

local public = {}

---@param fn async fun(...): ...
---@return Async.Promise promise
---@return int task_id
function public.spawn(fn, initially_blocking)
    local id = async.next_id
    async.next_id = async.next_id + 1

    local promise = public.promise()
    local o = {
        id = id,
        coroutine = coroutine.create(fn),
        status = "running",
        timer = 0,
        condition = nil,
        blocking = {initially_blocking},
        promise = promise
    }
    setmetatable(o, _task)

    async.tasks[id] = o

    o:resume()

    return promise, id
end

---@async
function public.wait(seconds)
    if not async.current_task then return end
    async.current_task.condition = {length = async.current_time + (seconds or 0)}
    async.current_task.status = "wait:T"
    return coroutine.yield()
end

---@async
function public.yield()
    if not async.current_task then return end
    async.current_task.status = "waiting"
    return coroutine.yield()
end

---@async
function public.wait_for(arg)
    if not async.current_task then return end

    if type(arg) == 'function' then
        local id, task = public.spawn(arg, async.current_task)
        task.blocking[#task.blocking+1] = async.current_task
        async.current_task.condition = {target = id}
    else
        if not async.tasks[arg] then return end
        local task = async.tasks[arg]
        task.blocking[#task.blocking+1] = async.current_task
        async.current_task.condition = {target = arg}
    end
    async.current_task.status = "wait:F"
    return coroutine.yield()
end

function public.cancel(id, ...)
    local target = async.tasks[id]
    if target then
        async.tasks[id] = nil
        if #target.blocking > 0 then
            for _i,k in ipairs(target.blocking) do
                k.continue_arguments = {...}
                k.status = 'waiting'
            end 
        end
    end
end

function public.update(time)
    local delta = time - async.current_time
    async.current_time = time

    ---@type {[number]: Async.Task}
    local clone = {}
    for i,k in pairs(async.tasks) do clone[i] = k end

    for id, task in pairs(clone) do
        if task.status == "wait:T" then
            if task.condition.length <= async.current_time then
                task.status = 'running'
                if task.continue_arguments then
                    task:resume(unpack(task.continue_arguments))
                    task.continue_arguments = nil
                else
                    task:resume(delta) 
                end
            end
        elseif task.status == 'waiting' then
            task:resume()
        end
    end
end

function public.promise()
    return setmetatable({
        finished = false,
        success = false,
        return_value = nil,
        subscribers = {
            on_resolved = {},
            on_rejected = {}
        }
    }, _promise)
end

return public