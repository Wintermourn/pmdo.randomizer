--[[
    json library for NLua
    made by Wintermourn

    notes:
        - null values must be explicitly inserted (Lua does not tell the difference between null and undefined):
            - use `njson.values.null`
            - use a metatable with the key `__njsonType = "null"`
            - if creating an array with `nil` gaps in keys, give it a metatable with the key `__njsonType = "array"`
        - arrays must have sequential keys without gaps of `nil`
            - arrays can be explicitly defined by giving them a metatable with key `__njsonType = "array"`
        - some types of values or tokens might not be supported in conversion. Please report this either as an issue or message @wintermourn on discord
        - if some keys are missing after conversion (hopefully not), please report either as an issue on the repository or message @wintermourn on discord
]]

if luanet == nil then
    error "njson is only compatible with NLua, requiring `luanet` to run"
end

local ctype = luanet.ctype
local import_type = luanet.import_type
local namespace = luanet.namespace
local import = import

if not (ctype and import_type and namespace) then
    error "`luanet` global is malformed and will not work with njson"
end
if not (import) then
    error "import function is required"
end

local __IO = namespace 'System.IO'
    local __Path = __IO.Path
    local __Directory = __IO.Directory
    local __File = __IO.File
local __Json_Linq = import ("Newtonsoft.Json", "Newtonsoft.Json.Linq")
    local __JToken = __Json_Linq.JToken
    local __JObject = __Json_Linq.JObject
    local __JArray = __Json_Linq.JArray
    local __JValue = __Json_Linq.JValue
    local __JTokenType = __Json_Linq.JTokenType
local __Json = import ("Newtonsoft.Json", "Newtonsoft.Json")
    local __Formatting = __Json.Formatting
    local __JsonConvert = __Json.JsonConvert -- used to turn the config back into text

local type_Int64 = ctype(import_type 'System.Int64')
local type_Double = ctype(import_type 'System.Double')
local type_Boolean = ctype(import_type 'System.Boolean')

---#region Iterating a JObject and getting JProperty Value (resolving conflict with JToken.Value<T>(), among other things)
local type_JProperty = ctype(__Json_Linq.JProperty)
local method_get_Value = type_JProperty:GetMethod 'get_Value'

local type_IEnumerable__JProperty = ctype(import_type (('System.Collections.Generic.IEnumerable`1[[%s,%s]]'):format(
    type_JProperty.FullName,
    type_JProperty.Assembly:GetName().Name
)))
local method_GetEnumerator = type_IEnumerable__JProperty:GetMethod("GetEnumerator")
local type_IEnumerator = ctype(import_type 'System.Collections.IEnumerator')
local method_MoveNext = type_IEnumerator:GetMethod("MoveNext")
local type_IEnumerator__JProperty = ctype(import_type (('System.Collections.Generic.IEnumerator`1[[%s,%s]]'):format(
    type_JProperty.FullName,
    type_JProperty.Assembly:GetName().Name
)))
local method_get_Current = type_IEnumerator__JProperty:GetMethod 'get_Current'
---#endregion

---Explicit `null` value for/from JSON conversion
local null_value = setmetatable({}, {
__newindex = function()
    error("null_value is immutable")
    end
})

local array_mt = {__njsonType = "array"}


local out = {
    __VERSION = 1.1,
    values = {
        null = null_value
    },
    helpers = {}
}

---@type fun(val: any): any
local deobjectify
local deobjectifications = {
    [__JTokenType.Object] = function(val)
        local out = {}

        local enumerator = method_GetEnumerator:Invoke(val:Properties(), nil)
        local prop
        while method_MoveNext:Invoke(enumerator, nil) do
            prop = method_get_Current:Invoke(enumerator, nil)--enumerator.Current
            out[prop.Name] = deobjectify(method_get_Value:Invoke(prop, nil))
        end

        return out
    end,
    [__JTokenType.Array] = function(val)
        local out = {}

        for entry in luanet.each(val) do
            table.insert(out, deobjectify(entry))
        end

        return setmetatable(out, array_mt)
    end,
    [__JTokenType.Integer] = function(val) return val:ToObject(type_Int64) end,
    [__JTokenType.Float] = function(val) return val:ToObject(type_Double) end,
    [__JTokenType.Boolean] = function(val) return val:ToObject(type_Boolean) end,
    [__JTokenType.String] = function(val) return val:ToString() end,
    [__JTokenType.Null] = function(val) return null_value end,
    [__JTokenType.Undefined] = function(val) return nil end
}

deobjectify = function(value)
    if type(value) ~= "userdata" then
        return value
    end
    local vtype = value.Type
    if deobjectifications[vtype] ~= nil then
        return deobjectifications[vtype](value)
    else
        error (("Token of type %s is not supported by njson"):format(vtype))
    end
end

---Parses a string into a table
---@param string string
---@return any
function out.parse_string(string)
    return deobjectify(__JToken.Parse(string))
end

---Checks if file exists, then parses its contents into a table.
---@param path string
---@return any|nil, string?
function out.parse_file(path)
    if not __File.Exists(path) then return nil, ("File %s does not exist"):format(path) end
    return deobjectify(__JToken.Parse(__File.ReadAllText(path)))
end

local function is_sequential_table(tbl)
    local final_size = 0
    local max_key = 0

    for i in pairs(tbl) do
        if type(i) ~= 'number' then return false end

        if i < 1 or i % 1 ~= 0 then return false end
        ---@cast i integer

        if i > max_key then max_key = i end
        final_size = final_size + 1
    end

    return max_key == final_size
end

local function get_max_key(tbl)
    local max_key = 0

    for i in pairs(tbl) do if i > max_key and i%1==0 then max_key = i end end

    return max_key
end

local empty_table = {}

--- You can't be doing that in this day and age!
---@type fun(val: any): any
local objectify
---@type {[std.type]: fun(val): unknown}
local objectifications = {
    ['nil'] = function()
        return __JValue.CreateNull()
    end,
    ['table'] = function(val)
        local mtt = getmetatable(val) or empty_table
        if val == null_value or mtt.__njsonType == "null" then return __JValue.CreateNull() end
        local obj
        if mtt.__njsonType == "array" then
            obj = __JArray()

            local max_key = get_max_key(val)
            for i = 1, max_key do
                if val[i] == nil then
                    obj:Add(__JValue.CreateNull())
                else 
                    obj:Add(objectify(val[i]))
                end
            end
        elseif is_sequential_table(val) then
            obj = __JArray()

            for _, k in ipairs(val) do
                obj:Add(objectify(k))
            end
        else
            obj = __JObject()

            for i, k in pairs(val) do
                obj:Add(i, objectify(k))
            end
        end

        return obj
    end,
    ['string'] = function(val)
        return __JValue (val)
    end,
    ['number'] = function(val)
        return __JValue (val)
    end,
    ['boolean'] = function(val)
        return __JValue (val)
    end,
}

objectify = function(value)
    local vtype = type(value)
    if objectifications[vtype] ~= nil then
        return objectifications[vtype](value)
    else
        error (("Value of type %s is not supported by njson"):format(vtype))
    end
end

---@param tbl table|any
---@param beautify boolean?
---@return string
function out.serialize(tbl, beautify)
    local object = objectify(tbl)

    return __JsonConvert.SerializeObject(object, beautify and __Formatting.Indented or nil)
end

local unpack = unpack or table.unpack
---Combines any number of arguments into a path suitable for the current Operating System.
---@param ... any
---@return string
function out.helpers.combine_path(...)
    local clean_args = {}
    for i,k in ipairs {...} do
        clean_args[i] = tostring(k)
    end

    return __Path.Combine(unpack(clean_args))
end


if RogueEssence ~= nil then
    local pathmod = RogueEssence.PathMod
    local modfromnamespace = pathmod.GetModFromNamespace
    local modfromuuid = pathmod.GetModFromUuid
    ---Resolves the full path to a mod's folder using its namespace
    ---@param mod_namespace string
    ---@return string?
    function out.helpers.get_mod_path_from_namespace(mod_namespace)
        local mod = modfromnamespace(mod_namespace)
        if mod.Path == "" then return nil end
        return __Path.Combine(pathmod.APP_PATH, mod.Path)
    end

    ---Resolves the full path to a mod's folder using its namespace
    ---@param mod_uuid string
    ---@return string?
    function out.helpers.get_mod_path_from_uuid(mod_uuid)
        local mod = modfromuuid(mod_uuid)
        if mod.Path == "" then return nil end
        return __Path.Combine(pathmod.APP_PATH, mod.Path)
    end
end

return out