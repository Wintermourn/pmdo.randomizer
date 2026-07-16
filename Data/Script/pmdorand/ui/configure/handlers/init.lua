local require_path, this_file = ...

local IO = luanet.namespace 'System.IO'
local this_dir = IO.Path.GetDirectoryName(this_file) 
--[[@cast this_dir -?]]

local handlers = {}
local req_path, results
for file in luanet.each(IO.Directory.GetFiles(this_dir, "*.lua", IO.SearchOption.AllDirectories)) do
    req_path = file:sub(#this_dir + 1, -5):gsub('/', '.')
    if req_path:sub(-5) == '.init' then req_path = req_path:sub(1, -6) end
    if req_path ~= '' then
        print(" -\t".. req_path:sub(2))
        results = require(require_path .. req_path)
        if results.title then
            handlers[results.title] = results 
        end
    end
end

local default = {
    title = '',
    display = function() return '' end
}

return {
    get = function( title )
        return handlers[title] or default
    end
}