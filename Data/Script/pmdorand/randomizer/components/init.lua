local require_path, this_file = ...

local IO = luanet.namespace 'System.IO'
local this_dir = IO.Path.GetDirectoryName(this_file) 
--[[@cast this_dir -?]]

return {
    load_all = function()
        --require 'pmdorand.randomizer.components.monsters.stats'
        print 'loading all default components:'
        
        local req_path
        for file in luanet.each(IO.Directory.GetFiles(this_dir, "*.lua", IO.SearchOption.AllDirectories)) do
            req_path = file:sub(#this_dir + 1, -5):gsub('/', '.')
            if req_path:sub(-5) == '.init' then req_path = req_path:sub(1, -6) end
            if req_path ~= '' then
                print(" -\t".. req_path:sub(2))
                require(require_path .. req_path)
            end
        end
    end
}