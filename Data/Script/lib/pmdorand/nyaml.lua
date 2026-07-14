--[[
    sharpyaml wrapping library for NLua
    made by Wintermourn

    dependencies:
        - A compiled copy of SharpYaml 2.1.

    notes:
        - The path to SharpYaml must be passed to the library by calling the returned function with the path, or segments of it, as arguments, ending with the filename.
            e.g. `require 'nyaml' ('MODS/my_mod', 'Libraries', 'SharpYaml.dll')`
            - The game's base APP_PATH will be added to the start automatically.
        - Various values can be added to metatables to adjust how the library works:
            - `__nyamlTag`: Applies a tag to the attached table.
            - `__nyamlUnwrap`: Used to apply things like tags to non-table values. The value can be a function or a string.
                - e.g. `{alpha = setmetatable({value = "test"}, {__nyamlUnwrap = "test", __nyamlTag = "tag"})}` creates `alpha: !tag "test"`
            - `__nyamlType`: Can be used to force the output type. Supports the following values:
                - `null`: explicitly outputs null instead of skipping.
                - `array`: forces the output to fill gaps between keys with null.
                - `object`: forces a table to always output keys.
            - `__nyamlKeyOrder`: Can be used to force the order of an object's keys. Must be a list of keys (`string[]`).
                - Keys not defined in the list will still be included in the output.
]]

if luanet == nil then
    error "njson is only compatible with NLua, requiring `luanet` to run"
end

---@alias nyaml.to_yaml table|string|number|boolean|(nyaml.to_yaml[])

local ctype = luanet.ctype
local import_type = luanet.import_type
local namespace = luanet.namespace
local import = import
local unpack = unpack or table.unpack

local __Activator = import_type 'System.Activator'
local IO = namespace 'System.IO'
    local __StringReader = IO.StringReader
    local __StringWriter = IO.StringWriter
    local __Path = IO.Path
    local __File = IO.File
local __Guid = import_type "System.Guid"

--- language server complains if I don't have this
_G.__nyaml_load_context = _G.__nyaml_load_context or nil
_G.__nyaml_sharpyaml_instance = _G.__nyaml_sharpyaml_instance or nil
_G.__nyaml_sentinel = _G.__nyaml_sentinel or nil

local previous_load_context = _G.__nyaml_load_context
local previous_sharpyaml_instance = _G.__nyaml_sharpyaml_instance
local sentinel = _G.__nyaml_sentinel

local null_value = setmetatable({ __nyamlType = 'null' }, { __newindex = function() error 'null value is immutable' end, __tostring = function() return 'null' end })
local array_mt = { __nyamlType = 'array' }
local object_mt = { __nyamlType = 'object' }
local blank = {}

local keywords = {
    null = null_value,
    Null = null_value,
    ['~'] = null_value,
    ['true'] = true,
    ['false'] = false,
}

local mt = {}
---@class nyaml
---@overload fun(path: string, ...: string)
local out = setmetatable({
    __VERSION = 1.3,
    values = {
        null = null_value
    },
    helpers = {}
}, mt)

---@param path string?
---@return nyaml
function mt.__call( self, path, ... )
    local app_path = RogueEssence.PathMod.APP_PATH
    path = __Path.GetFullPath(__Path.Combine( app_path, path, ... ))
    if path:sub(1, #app_path) ~= app_path then
        error("SharpYaml assembly must be in the game folder") 
    end

    luanet.load_assembly 'System.Runtime.Loader'
    local __AssemblyLoadContext = import_type 'System.Runtime.Loader.AssemblyLoadContext'

    if previous_load_context == nil then
        previous_load_context = __AssemblyLoadContext("NyamlContext", true)
        previous_sharpyaml_instance = previous_load_context:LoadFromAssemblyPath(path)
        sentinel = setmetatable({}, {
            __gc = function()
                print 'unloading sharpyaml...'
                pcall(function()
                    previous_load_context:Unload()
                end)
            end
        })
        _G.__nyaml_load_context = previous_load_context
        _G.__nyaml_sharpyaml_instance = previous_sharpyaml_instance
        _G.__nyaml_sentinel = sentinel
    end

    local type_YamlDocument = previous_sharpyaml_instance:GetType 'SharpYaml.Serialization.YamlDocument'
    local type_YamlStream = previous_sharpyaml_instance:GetType 'SharpYaml.Serialization.YamlStream'
    local type_YamlMappingNode = previous_sharpyaml_instance:GetType 'SharpYaml.Serialization.YamlMappingNode'
    local type_YamlSequenceNode = previous_sharpyaml_instance:GetType 'SharpYaml.Serialization.YamlSequenceNode'
    local type_YamlScalarNode = previous_sharpyaml_instance:GetType 'SharpYaml.Serialization.YamlScalarNode'
    local type_YamlAliasNode = previous_sharpyaml_instance:GetType 'SharpYaml.Serialization.YamlAliasNode'


    do -- Deserialization
        local function deobjectify_node(node, handlers, visited)
            visited = visited or {}
            if visited[node] then return visited[node] end

            local node_type = node:GetType()
            local tag = node.Tag
            local result

            if node_type == type_YamlScalarNode then
                local value, style = node.Value, node.Style:ToString()

                if style == 'Plain' or style == 'Any' then
                    if keywords[value] then
                        result = keywords[value]
                    elseif tonumber(value) ~= nil then
                        result = tonumber(value)
                    else
                        result = value
                    end
                else
                    result = value
                end
            elseif node_type == type_YamlSequenceNode then
                result = {}
                visited[node] = result
                for child in luanet.each(node.Children) do
                    result[#result+1] = deobjectify_node(child, handlers, visited)
                end
                setmetatable(result, array_mt)
            elseif node_type == type_YamlMappingNode then
                result = {}
                visited[node] = result
                local k, v
                for kvp in luanet.each(node.Children) do
                    k = deobjectify_node(kvp.Key, handlers, visited)
                    v = deobjectify_node(kvp.Value, handlers, visited)
                    if k ~= null_value then
                        result[k] = v
                    end
                end
            end

            if tag and tag ~= '' and handlers and handlers[tag] then
                result = handlers[tag](result)
                visited[node] = result 
            end

            return result
        end

        ---@param input string
        ---@param tag_handlers {[string]: (fun(input: any): any)}
        ---@return table...?
        ---@return string?
        function out.parse_string(input, tag_handlers)
            local stream = __Activator.CreateInstance(type_YamlStream)
            local string_reader = __StringReader(input)
            stream:Load(string_reader)
            string_reader:Close()

            if stream.Documents.Count == 0 then return nil, 'File does not contain any documents'
            elseif stream.Documents.Count == 1 then
                return deobjectify_node(stream.Documents[0].RootNode, tag_handlers) 
            else
                local docs = stream.Documents
                local out = {}
                for i = 1, docs.Count do
                    out[i] = deobjectify_node(docs[i - 1].RootNode, tag_handlers)
                end
                return unpack(out)
            end
        end

        ---@param path string
        ---@param tag_handlers {[string]: (fun(input: any): any)}
        ---@return table...|nil results
        ---@return string? error_message
        function out.parse_file(path, tag_handlers)
            if not __File.Exists(path) then return nil, ('File %s does not exist'):format(path) end
            return out.parse_string(__File.ReadAllText(path), tag_handlers)
        end
    end

    do -- Serialization
        local function is_sequential_table( tbl )
            local final_size, max_key = 0,0
            for i in pairs(tbl) do
                if type(i) ~= 'number' or i < 1 or i % 1 ~= 0 then return false end
                if i > max_key then max_key = 1 end
                final_size = final_size + 1
            end
            return final_size == max_key
        end

        local function get_max_key( tbl )
            local max_key = 0
            for i in pairs(tbl) do
                if type(i) == 'number' and i > max_key and i % 1 == 0 then max_key = i --[[@as integer]] end
            end
            return max_key
        end

        local objectifications = {}
        local function objectify_node(val, visited, anchor_state)
            visited = visited or {}
            anchor_state = anchor_state or { count = 1 }

            local vtype = type(val)
            local objectify = objectifications[vtype]
            if objectify ~= nil then
                return objectify(val, visited, anchor_state)
            end

            error(('Value of type \'%s\' is not supported by nyaml'):format(vtype))
        end

        objectifications['nil'] = function()
            return __Activator.CreateInstance(type_YamlScalarNode, 'null')
        end
        objectifications['string'] = function(v)
            return __Activator.CreateInstance(type_YamlScalarNode, v)
        end
        objectifications['number'] = function(v)
            return __Activator.CreateInstance(type_YamlScalarNode, tostring(v))
        end
        objectifications['boolean'] = function(v)
            return __Activator.CreateInstance(type_YamlScalarNode, tostring(v))
        end
        objectifications['table'] = function(v, visited, anchor_state)
            if v == null_value then return __Activator.CreateInstance(type_YamlScalarNode, 'null') end

            local visitation = visited[v]
            if visitation then
                local v_type = visitation:GetType()

                if not visitation.Anchor or visitation.Anchor == '' then
                    visitation.Anchor = 'ref'.. anchor_state.count
                    anchor_state.count = anchor_state.count + 1
                end

                local aliased
                if v_type == type_YamlSequenceNode then
                    aliased = __Activator.CreateInstance(type_YamlSequenceNode)
                elseif v_type == type_YamlMappingNode then
                    aliased = __Activator.CreateInstance(type_YamlMappingNode)
                end
                aliased.Anchor = visitation.Anchor
                return aliased
            end

            local mtt = getmetatable(v) or blank
            if mtt.__nyamlType == null_value.__nyamlType then return __Activator.CreateInstance(type_YamlScalarNode, 'null') end

            local node
            if mtt.__nyamlUnwrap then
                local unwrapped_value
                local unwrap_type = type(mtt.__nyamlUnwrap)

                if unwrap_type == 'function' then
                    unwrapped_value = mtt.__nyamlUnwrap(v)
                elseif unwrap_type == 'string' and v[mtt.__nyamlUnwrap] ~= nil then
                    unwrapped_value = v[mtt.__nyamlUnwrap] 
                else
                    unwrapped_value = mtt.__nyamlUnwrap
                end

                node = objectify_node(unwrapped_value, visited, anchor_state)

                if visited[unwrapped_value] == nil and mtt.__nyamlTag then
                    node.Tag = (string.sub(mtt.__nyamlTag, 1, 1) ~= '!' and '!' or '') .. mtt.__nyamlTag
                end

                visited[v] = node
                return node
            end

            if mtt.__nyamlType == array_mt.__nyamlType or (mtt.__nyamlType ~= object_mt.__nyamlType and is_sequential_table(v)) then
                node = __Activator.CreateInstance(type_YamlSequenceNode)
                local max = get_max_key(v)
                local item
                for i = 1, max do
                    item = v[i]
                    if item ~= nil then
                        node:Add(objectify_node(item, visited, anchor_state)) 
                    else
                        node:Add(__Activator.CreateInstance(type_YamlScalarNode, 'null'))
                    end
                end
            else
                node = __Activator.CreateInstance(type_YamlMappingNode)
                if type(mtt.__nyamlKeyOrder) == 'table' then
                    local keys = {}
                    for k in pairs(v) do
                        keys[k] = true
                    end
                    for _, k in ipairs(mtt.__nyamlKeyOrder) do
                        if keys[k] then
                            node:Add(objectify_node(k, visited, anchor_state), objectify_node(v[k], visited, anchor_state))
                            keys[k] = nil
                        end
                    end
                    for k in pairs(keys) do
                        node:Add(objectify_node(k, visited, anchor_state), objectify_node(v[k], visited, anchor_state))
                    end
                else
                    for k, v in pairs(v) do
                        node:Add(objectify_node(k, visited, anchor_state), objectify_node(v, visited, anchor_state))
                    end
                end
            end
            visited[v] = node

            if type(mtt.__nyamlTag) == 'string' then
                node.Tag = (string.sub(mtt.__nyamlTag, 1, 1) ~= '!' and '!' or '') .. mtt.__nyamlTag 
            end

            return node
        end

        ---@param ... nyaml.to_yaml
        ---@return string
        function out.serialize(...)
            local stream = __Activator.CreateInstance(type_YamlStream)

            for _, raw_doc in ipairs {...} do
                stream:Add(__Activator.CreateInstance(type_YamlDocument, objectify_node(raw_doc)))
            end

            local string_writer = __StringWriter()
            stream:Save(string_writer, false)
            local res = string_writer:ToString()
            string_writer:Close()
            return res
        end
    end

    return out
end

do -- Helpers
    function out.helpers.combine_path(...)
        local args = {}
        for i, k in ipairs {...} do args[i] = tostring(k) end
        return __Path.Combine(unpack(args))
    end

    if RogueEssence ~= nil then
        local pathmod = RogueEssence.PathMod
        local getmodfromns = pathmod.GetModFromNamespace
        local getmodfromuuid = pathmod.GetModFromUuid

        function out.helpers.get_mod_path_from_namespace( namespace )
            local mod = getmodfromns(namespace)
            if mod.Path == '' then return end
            return __Path.Combine(pathmod.APP_PATH, mod.Path)
        end

        function out.helpers.get_mod_path_from_uuid( uuid )
            local success, uuid = pcall(__Guid, uuid)
            if not success then return end
            local mod = getmodfromuuid(uuid)
            if mod.Path == '' then return end
            return __Path.Combine(pathmod.APP_PATH, mod.Path)
        end
    end
end

return out