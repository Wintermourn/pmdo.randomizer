---@diagnostic disable: unnecessary-if
local TAXONVERSION = 0.52

local IO = luanet.namespace 'System.IO'

---@alias Taxon.DataType
---| 'AI'
---| 'Item'
---| 'Monster'
---| 'Skill'
---| 'Intrinsic'
---| 'Zone'

---@class (partial) interlace.Carcass
---@field get_tag fun(data_type: Taxon.DataType, tag_name: string): Taxon.Tag

if not _G.wintermourn or not _G.wintermourn.interlace then
    _G.wintermourn = _G.wintermourn or {}

    _G.wintermourn.interlace = {
        _VERSION = 0.0,
        data = {
            configurations = {},
            mods_list = {
                by_namespace = {},
                by_uuid = {},
                by_path = {}
            }
        },
        components = {},
        carcass = {}
    }
end

local interlace = _G.wintermourn.interlace
local taxon = interlace.components.taxon
local first_init = false

if taxon and taxon._VERSION >= TAXONVERSION then
    return setmetatable({}, {
        __index = function(_self, index)
            return rawget(taxon.carcass, index)
        end,
        __newindex = function(_self, idx, _v)
            print(string.format ("attempt to insert index %s into taxon shell", idx))
        end
    }) --[[@as Taxon.Carcass]]
end

local data_categories = {
    {'AI', _DATA.GetAITactic},
    {'Item', _DATA.GetItem},
    {'Skill', _DATA.GetSkill, has_element = true},
    {'Intrinsic', _DATA.GetIntrinsic},
    {'Monster', _DATA.GetMonster, has_element = true},
    {'Zone', _DATA.GetZone}
}

---@class Taxon.Carcass
local carcass, bubbleup = {}, {}
if taxon then
    taxon._VERSION = TAXONVERSION
    taxon.carcass = carcass
    taxon.bubbleup = bubbleup
    if taxon._VERSION < 0.4 then taxon.scan_methods = {} end
else
    first_init = true
    taxon = {
        _VERSION = TAXONVERSION,
        constants = {
            tables = {
                no_property = {},
                array_mt = {__njsonType = "array"}
            },
            null = setmetatable({}, {
            __newindex = function()
                error("null_value is immutable")
                end
            })
        },
        property_cache = {},
        data = {},
        scan_methods = {},
        carcass = carcass,
        bubbleup = bubbleup
    }
    interlace.components.taxon = taxon
end
local NOPROP = taxon.constants.tables.no_property

local ctype = luanet.ctype
local import_type = luanet.import_type

local __Object = import_type 'System.Object'
local __Array = import_type 'System.Array'
local __DataType = RogueEssence.Data.DataManager.DataType
local __Json_Linq = import ("Newtonsoft.Json", "Newtonsoft.Json.Linq")
    local __JToken = __Json_Linq.JToken
    local __JObject = __Json_Linq.JObject
    local __JArray = __Json_Linq.JArray
    local __JValue = __Json_Linq.JValue
    local __JTokenType = __Json_Linq.JTokenType
local __Json = import ("Newtonsoft.Json", "Newtonsoft.Json")
    local __Formatting = __Json.Formatting

local __Type = import_type 'System.Type'
local type_Int64 = ctype(import_type 'System.Int64')
local type_Double = ctype(import_type 'System.Double')
local type_Boolean = ctype(import_type 'System.Boolean')
local type_String = ctype(import_type 'System.String')
local type_Byte = ctype(import_type 'System.Byte')

local type_JProperty = ctype(__Json_Linq.JProperty)
local method_get_Value = type_JProperty:GetMethod 'get_Value'

local __Convert = import_type 'System.Convert'
local System_Linq = import 'System.Linq'
    local __Enumerable = System_Linq.Enumerable
    local type_Enumerable = ctype(__Enumerable)
    local type_IEnumerable__Byte = ctype(import_type ('System.Collections.Generic.IEnumerable`1[[System.Byte]]'))
    local method_SequenceEqual

do
    local candidates = type_Enumerable:GetMethods()
    local m
    for i = 0, candidates.Length - 1 do
        m = candidates[i]
        if m.Name == 'SequenceEqual' and m:GetParameters().Length == 2 then
            method_SequenceEqual = m:MakeGenericMethod(type_Byte) 
            break
        end
    end 
end

local Text = luanet.namespace 'System.Text'
    local __Encoding = Text.Encoding

local type_IEnumerable__JProperty = ctype(import_type (('System.Collections.Generic.IEnumerable`1[[%s,%s]]'):format(
    type_JProperty.FullName,
    type_JProperty.Assembly:GetName().Name
)))
local method_GetEnumerator__JProperty = type_IEnumerable__JProperty:GetMethod("GetEnumerator")
local type_IEnumerator = ctype(import_type 'System.Collections.IEnumerator')
local method_MoveNext = type_IEnumerator:GetMethod("MoveNext")
local type_IEnumerator__JProperty = ctype(import_type (('System.Collections.Generic.IEnumerator`1[[%s,%s]]'):format(
    type_JProperty.FullName,
    type_JProperty.Assembly:GetName().Name
)))
local method_get_Current__JProperty = type_IEnumerator__JProperty:GetMethod 'get_Current'
local type_IEnumerable = ctype(import_type 'System.Collections.IEnumerable')
local method_GetEnumerator = type_IEnumerable:GetMethod("GetEnumerator")
local method_get_Current = type_IEnumerator:GetMethod 'get_Current'

local compatible_types = {
    Byte = {[__JTokenType.Integer] = true},
    SByte = {[__JTokenType.Integer] = true},
    Int16 = {[__JTokenType.Integer] = true},
    Int32 = {[__JTokenType.Integer] = true},
    Int64 = {[__JTokenType.Integer] = true},
    Int128 = {[__JTokenType.Integer] = true},
    UInt16 = {[__JTokenType.Integer] = true},
    UInt32 = {[__JTokenType.Integer] = true},
    UInt64 = {[__JTokenType.Integer] = true},
    UInt128 = {[__JTokenType.Integer] = true},
    Single = {[__JTokenType.Integer] = true, [__JTokenType.Float] = true},
    Double = {[__JTokenType.Integer] = true, [__JTokenType.Float] = true},
    String = {[__JTokenType.String] = true},
    Boolean = {[__JTokenType.Boolean] = true}
}

local jtype_conversions = {
    [__JTokenType.Integer] = type_Int64,
    [__JTokenType.Float] = type_Double,
    [__JTokenType.Boolean] = type_Boolean,
    [__JTokenType.String] = type_String
}

local scan_object_cache = {}
---@type fun(object: unknown, summary: unknown?, form: unknown?, scanObject: unknown, isRoot: boolean, getEntry: (fun(): unknown)?): boolean
local iterate_scan

local function get_property(object, propertyName)
    local type = object:GetType()
    local typeMemberCache = taxon.property_cache[type] or {}
    local prop = typeMemberCache[propertyName]
    if prop == NOPROP then return nil, NOPROP end
    local out, propType
    if prop then
        return object[propertyName], prop.type
    else
        prop = type:GetProperty(propertyName)

        if prop then
            propType = prop.PropertyType
            typeMemberCache[propertyName] = {property = prop, type = propType}
            out = object[propertyName]
        else
            prop = type:GetField(propertyName)
            if prop then
                propType = prop.FieldType
                typeMemberCache[propertyName] = {field = prop, type = propType}
                out = object[propertyName]
            else
                typeMemberCache[propertyName] = NOPROP
                if not taxon.property_cache[type] then taxon.property_cache[type] = typeMemberCache end
                return nil, NOPROP
            end
        end
    end
    if not taxon.property_cache[type] then taxon.property_cache[type] = typeMemberCache end
    return out, propType
end

---@alias Taxon.RequiredProperties {[string]: type|Taxon.RequiredProperties|{type: "array",values:type}}

---@param required_properties Taxon.RequiredProperties?
---@param fn fun(data: any, scan_info: unknown): boolean
---@param retained_properties string[]?
function carcass.create_scan_method(type_name, required_properties, fn, retained_properties)
    taxon.scan_methods[type_name] = {
        required_properties = required_properties,
        callback = fn,
        retain_properties = retained_properties
    }
end

carcass.create_scan_method(
    'string.starts_with',
    { value = 'string' },
    function(data, scan_info)
        if type(data) ~= 'string' then return false end
        local prefix = scan_info.value
        return data:sub(1,#prefix) == prefix
    end
)

carcass.create_scan_method(
    'string.ends_with',
    { value = 'string' },
    function (data, scan_info)
        if type(data) ~= 'string' then return false end
        local suffix = scan_info.value
        return data:sub(-#suffix) == suffix
    end
)

carcass.create_scan_method(
    'string.contains',
    { value = 'string' },
    function (data, scan_info)
        if type(data) ~= 'string' then return false end
        local suffix = scan_info.value
        return data:find(suffix) ~= nil
    end
)

carcass.create_scan_method(
    'greater_than',
    { value = 'number' },
    function (data, scan_info)
        if type(data) ~= 'number' then return false end
        return data > scan_info.value
    end
)

carcass.create_scan_method(
    'less_than',
    { value = 'number' },
    function (data, scan_info)
        if type(data) ~= 'number' then return false end
        return data < scan_info.value
    end
)

carcass.create_scan_method(
    'not',
    nil,
    function (data, scan_info)
        local val = scan_info.value
        if not val then return data == false end
        local ta, tb = type(data), type(val)
        if ta ~= tb then return true end
        return data ~= val
    end
)

local type_List = import_type 'System.Type' .GetType 'System.Collections.Generic.List`1'
local type_PriorityList = import_type 'System.Type' .GetType 'RogueElements.PriorityList`1, RogueElements'
carcass.create_scan_method(
    'contains',
    nil,
    function (data, scan_info)
        local cls = scan_info.class
        local val = scan_info.value
        if type(data) == 'userdata' then
            local ty = data:GetType()
            if not ty then return false end
            if ty.IsArray then
                if data.Length == 0 then return false end
                if cls then
                    if type(data[0]) ~= 'userdata' then return false end -- todo
                    if type(cls) ~= 'string' then return false end
                    local goal = __Type.GetType(cls)
                    for entry in luanet.each(data) do
                        ty = entry:GetType()
                        print(ty)
                        if ty == goal then
                            if val then
                                if val then
                                    if iterate_scan(entry, nil, nil, val, false, nil) then return true end
                                end
                            end
                            return true
                        end
                    end
                end
                if val then
                    if iterate_scan(data, nil, nil, val, false, nil) then return true end
                end
            elseif ty.IsGenericType then
                local gty = ty:GetGenericTypeDefinition()
                if gty == type_List then
                    if data.Count == 0 then return false end
                    if cls then
                        if type(data[0]) ~= 'userdata' then return false end -- todo
                        if type(cls) ~= 'string' then return false end
                        local goal = __Type.GetType(cls)
                        for i = 0, data.Count - 1 do
                            ty = data[i]:GetType()
                            if ty == goal then
                                if val then
                                    if iterate_scan(data[i], nil, nil, val, false, nil) then return true end
                                end
                                return true
                            end
                        end
                    end
                    if val then
                        if iterate_scan(data, nil, nil, val, false, nil) then return true end
                    end
                elseif gty == type_PriorityList then
                    if data.Count == 0 then return false end
                    if cls then
                        if type(cls) ~= 'string' then return false end
                        local goal = __Type.GetType(cls)
                        local enumerator = method_GetEnumerator:Invoke(data, nil)
                        local entry
                        while method_MoveNext:Invoke(enumerator, nil) do
                            entry = method_get_Current:Invoke(enumerator, nil).Value
                            ty = entry:GetType()
                            if ty == goal then
                                if val then
                                    if iterate_scan(entry, nil, nil, val, false, nil) then return true end
                                end
                                return true
                            end
                        end
                    end
                    if val then
                        if iterate_scan(data, nil, nil, val, false, nil) then return true end
                    end
                end
            end
        end
        return false
    end,
    { "value" }
)

carcass.create_scan_method(
    'not_empty',
    nil,
    function (data)
        if type(data) == 'userdata' then
            local ty = data:GetType()
            if ty.IsArray then
                return data.Length > 0
            elseif ty.IsGenericType and ty:GetGenericTypeDefinition() == type_List then
                return data.Count > 0
            end
            return false
        elseif type(data) == 'string' then return data == ''
        end
        return type(data) ~= 'nil'
    end
)

--#region njson
local array_mt, null_value = taxon.constants.tables.array_mt, taxon.constants.null
---@type fun(val: any): any
local deobjectify
local deobjectifications = {
    [__JTokenType.Object] = function(val)
        local out = {}

        local enumerator = method_GetEnumerator__JProperty:Invoke(val:Properties(), nil)
        local prop
        while method_MoveNext:Invoke(enumerator, nil) do
            prop = method_get_Current__JProperty:Invoke(enumerator, nil)--enumerator.Current
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
    [__JTokenType.Null] = function() return null_value end,
    [__JTokenType.Undefined] = function() return nil end
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
--#endregion njson

local function run_test(test_name, object_value, test_info)
    local method = taxon.scan_methods[test_name]
    if not method then return false end
    return method.callback(object_value, test_info)
end

local function print_warning(text)
    if DiagManager then 
        DiagManager.Instance:LogInfo('[taxon](warn) ' .. text) 
    else
        print('[taxon](warn) ' .. text)
    end
end

local function check_required_properties(test_name, native_value, required_props, pfx)
    local ty, should_return_false
    if pfx then
        pfx = pfx:sub(-1) == '.' and pfx or (pfx .. '.')
    else
        pfx = ''
    end
    for i,k in pairs(required_props) do
        if type(k) == 'table' then
            if k.type == 'array' and k.values then
                if getmetatable(native_value[i]) ~= array_mt then
                    print_warning(('value of property "%s" on test "%s" should be %s[] but instead is a %s.'):format(pfx .. i, test_name, k.values, ty))
                    should_return_false = true
                else
                    ty = type(native_value[i][1])
                    if ty ~= k.values then
                        print_warning(('value of property "%s" on test "%s" should be %s[] but instead is a %s[].'):format(pfx .. i, test_name, k.values, ty))
                        should_return_false = true
                    end
                end
            else
                ty = type(native_value[i])
                if ty ~= 'table' then
                    print_warning(('value of property "%s" on test "%s" should be a table but instead is a %s.'):format(pfx .. i, test_name, ty))
                    should_return_false = true
                end
                if not check_required_properties(test_name, native_value[i], k, pfx .. i) then should_return_false = true end
            end
        elseif type(k) == 'string' then
            ty = type(native_value[i])
            if ty ~= k then
                print_warning(('value of property "%s" on test "%s" should be a %s but instead is a %s.'):format(pfx .. i, test_name, k, ty))
                should_return_false = true
            end
        end
    end
    return should_return_false == true
end

local function compile_scan(scanObject, isRoot)
    local compiled = {}
    local enumerator = method_GetEnumerator__JProperty:Invoke(scanObject:Properties(), nil)

    local prop, propName, value, path, nativeValue, targetType
    local test_func, vType, jtc
    while method_MoveNext:Invoke(enumerator, nil) do
        prop        = method_get_Current__JProperty:Invoke(enumerator, nil)
        propName    = prop.Name
        value       = method_get_Value:Invoke(prop, nil)

        if isRoot then
            if propName:sub(1,6) == 'Object' then
                propName = propName:sub(8)
                targetType = 'object'
            elseif propName:sub(1,7) == 'Summary' then
                propName = propName:sub(9)
                targetType = 'summary'
            elseif propName:sub(1,4) == 'Form' then
                propName = propName:sub(6)
                targetType = 'form'
            end
        end

        path = {}
        if propName ~= '' then
            if propName:find '.' then
                for word in propName:gmatch '([^.%]]+)' do
                    ---@diagnostic disable-next-line: iter-variable-reassign
                    if word:sub(1,1) == '[' then word = tonumber(word:sub(2)) end
                    table.insert(path, word) 
                end
            else
                local word = propName
                if word:sub(1,1) == '[' then word = word:match '([^%[%]]+)' end
                table.insert(path, word)
            end
        end

        vType = value.Type
        if vType == __JTokenType.Object then
            nativeValue = deobjectify(value)
            local testType = nativeValue.type
            if testType and type(testType) == 'string' then
                local test = taxon.scan_methods[testType]
                local has_bad_args
                if test then
                    if test.required_properties then
                        has_bad_args = check_required_properties(testType, nativeValue, test.required_properties)
                    end
                    if test.retain_properties then
                        print 'cc'
                        for _,k in ipairs(test.retain_properties) do
                            if value[k] then
                                print(k, type(value[k]))
                                nativeValue[k] = value[k]
                            end
                        end 
                    end
                else
                    print (('[taxon] test type %s does not currently exist and may cause issues'):format(testType))
                end
                test_func = {is_test = true, method_name = testType, test_info = nativeValue, has_bad_args = has_bad_args}
            else
                test_func = {test_info = value}
            end
        else
            jtc = jtype_conversions[vType]
            -- primitive scan
            test_func = {is_primitive = true, primitive_value = jtc and value:ToObject(jtc), jtype = vType}
        end

        table.insert(compiled, {
            target_type = targetType,
            path = path,
            test = test_func
        })
    end
    return compiled
end

function iterate_scan(object, summary, form, scanObject, isRoot, getEntry)
    --if not scanObject or type(scanObject) ~= 'userdata' then error(tostring(scanObject) ..'\t'.. type(scanObject)) end
    local compiled = scan_object_cache[scanObject]
    if not compiled then
        compiled = compile_scan(scanObject, isRoot)
        scan_object_cache[scanObject] = compiled 
    end

    local currentTarget, objProp, test, compatibleTypes
    for _, rule in ipairs(compiled) do
        if isRoot then
            if rule.target_type == 'summary' then currentTarget = summary
            elseif rule.target_type == 'form' then currentTarget = form;
            else currentTarget = object or getEntry() end
        end
        if #rule.path > 0 then
            for _,word in ipairs(rule.path) do
                if currentTarget == nil then return false end
                currentTarget, objProp = get_property(currentTarget, word)
                if objProp == NOPROP then return false end
            end
        end

        test = rule.test
        if test.is_test then
            if test.has_bad_args or not run_test(test.method_name, currentTarget, test.test_info) then return false end
        elseif test.is_primitive then
            if objProp then
                compatibleTypes = compatible_types[objProp.Name]
                if not compatibleTypes or not compatibleTypes[test.jtype] or test.primitive_value ~= currentTarget then 
                    return false
                end
            end
        else
            if not iterate_scan(currentTarget, nil, nil, test.test_info, false, nil) then return false end
        end
    end
    return true
end

---@class Taxon.Tag
local _tag = {
    key = '',
    ---@type Taxon.DataType
    type = 'Item',
    values = {by_index = {}, by_value = {}, removed_values = {}}
}
_tag.__index = _tag

function _tag:__tostring()
    return ('Taxon.Tag <%s> (%s) :: %d Entries'):format(self.key, self.type, #self.values.by_index)
end

function _tag:__len()
    return #self.values.by_index
end

---@return string
function _tag:get_random_identifier()
    if #self.values.by_index == 0 then return nil end
    local rng = math.random(1, #self.values.by_index)
    return self.values.by_index[rng]
end

---@return string, integer
function _tag:get_random_form()
    if self.type ~= 'Monster' then return end
    local id = self:get_random_identifier()
    local sindex = id:find '/' or 2
    return id:sub(1, sindex - 1), math.floor(tonumber(id:sub(sindex + 1)) or 0)
end

---@return string
function _tag:get(index)
    return self.values.by_index[index]
end

---@param identifier string
---@return boolean
function _tag:contains(identifier)
    return self.values.by_value[identifier] ~= nil
end

---@return string, integer
function _tag:get_form(index)
    if self.type ~= 'Monster' then return end
    local id = self.values.by_index[index] --[[@as string]]
    if not id then return end
    local sindex = id:find '/' or 2
    return id:sub(1, sindex - 1), math.floor(tonumber(id:sub(sindex + 1)) or 0)
end

function _tag:iterate_keys()
    local i = 0
    local vbi = self.values.by_index
    return function()
        i=i+1
        return vbi[i]
    end
end

---@param data_type Taxon.DataType
---@param tag_name string
---@return Taxon.Tag
function carcass.get_tag(data_type, tag_name)
    return taxon.data[data_type] and taxon.data[data_type][tag_name]
end
bubbleup.get_tag = carcass.get_tag

local function get_category_hash(category)
    local __SHA256 = import_type 'System.Security.Cryptography.SHA256'
    local __BitConverter = import_type 'System.BitConverter'

    local sb = Text.StringBuilder()
    sb:Append(RogueEssence.Versioning.GetVersion():ToString())

    local qns = RogueEssence.PathMod.Quest.Namespace ~= '' and RogueEssence.PathMod.Quest.Namespace
    local basePath = IO.Path.Combine(RogueEssence.PathMod.APP_PATH, '%s', 'Data', category)
    local baseTagPath = IO.Path.Combine(RogueEssence.PathMod.APP_PATH, '%s', 'Data', 'Tags', 'origin', category)
    local questTagPath = IO.Path.Combine(RogueEssence.PathMod.APP_PATH, '%s', 'Data', 'Tags', qns or 'origin', category)

    for mod in luanet.each(RogueEssence.PathMod.GetEligibleMods(RogueEssence.PathMod.ModType.Mod)) do
        local modData, modTagBasePath, modTagQuestPath = basePath:format(mod.Path), baseTagPath:format(mod.Path), questTagPath:format(mod.Path)

        if IO.Directory.Exists(modData) then
            for file in luanet.each(IO.Directory.GetFiles(modData, "*.json", IO.SearchOption.AllDirectories)) do
                sb:Append(file):Append(IO.File.GetLastWriteTime(file).Ticks)
            end 
            for file in luanet.each(IO.Directory.GetFiles(modData, "*.jsonpatch", IO.SearchOption.AllDirectories)) do
                sb:Append(file):Append(IO.File.GetLastWriteTime(file).Ticks)
            end 
        end

        if IO.Directory.Exists(modTagBasePath) then
            for file in luanet.each(IO.Directory.GetFiles(modTagBasePath, '*.json', IO.SearchOption.AllDirectories)) do
                sb:Append(file):Append(IO.File.GetLastWriteTime(file).Ticks)
            end 
        end

        if IO.Directory.Exists(questTagPath) then
            for file in luanet.each(IO.Directory.GetFiles(questTagPath, '*.json', IO.SearchOption.AllDirectories)) do
                sb:Append(file):Append(IO.File.GetLastWriteTime(file).Ticks)
            end 
        end
    end

    local hashBytes = __SHA256.Create():ComputeHash(__Encoding.UTF8:GetBytes(sb:ToString()))
    --[[ local hashStr = Text.StringBuilder()
    local hexFormat = '%x'
    for i = 0, hashBytes.Length - 1 do
        hashStr:Append(hexFormat:format(hashBytes[i]))
    end ]]
    return hashBytes
end

local function load_tag_files(path, base_path, tag_cache, type, scan_cache)
    if not IO.Directory.Exists(path) then return end
    for file in luanet.each(IO.Directory.GetFileSystemEntries(path)) do
        if IO.Directory.Exists(file) then
            load_tag_files(file, path, tag_cache, type, scan_cache)
        elseif IO.Path.GetExtension(file) == '.json' then
            local tagName = IO.Path.GetRelativePath(base_path, file):sub(1,-6):lower()
            local o = tag_cache[tagName] and tag_cache[tagName].values or {by_index = {}, by_value = {}, removed_values = {}}
            local json = __JObject.Parse(IO.File.ReadAllText(file))

            if type == 'Monster' then
                local wants_temporary_forms = json['include_temporary_forms']
                if wants_temporary_forms and wants_temporary_forms.Type == __JTokenType.Boolean and wants_temporary_forms:ToObject(type_Boolean) == true then
                    o.include_temporary_forms = true
                end
            end
            
            local vals = json['values']
            if vals and vals.Type == __JTokenType.Array then
                local v
                for token in luanet.each(vals) do
                    if token.Type == __JTokenType.String then
                        v = token:ToString()
                        if not o.by_value[v] and not o.removed_values[v] and _DATA.DataIndices[__DataType[type]]:ContainsKey(v) then
                            table.insert(o.by_index, v)
                            o.by_value[v] = #o.by_index
                        end
                    else
                        print("invalid token in values array")
                    end
                end
            end
            
            vals = json['remove_values']
            if vals and vals.Type == __JTokenType.Array then
                local v
                for token in luanet.each(vals) do
                    if token.Type == __JTokenType.String then
                        v = token:ToString()
                        if o.by_value[v] then
                            table.remove(o.by_index, o.by_value[v])
                            o.by_value[v] = nil
                        o.removed_values[v] = true
                        end
                    else
                        print("invalid token in values array")
                    end
                end
            end
            
            local tests = json['scans']
            if tests and tests.Type == __JTokenType.Array then
                table.insert(scan_cache, {tag_name = tagName, tag_ref = o, scans = tests})
            end

            tag_cache[tagName] = setmetatable({key = tagName, type = type, values = o}, _tag)
        end
    end
end

function carcass.rebuild(force)

    local cacheDir = IO.Path.Combine(RogueEssence.PathMod.APP_PATH, 'SAVE', 'TAXON_CACHE')
    if not IO.Directory.Exists(cacheDir) then IO.Directory.CreateDirectory(cacheDir) end

    local verFile = IO.Path.Combine(cacheDir, 'version')
    local currentVersion = RogueEssence.Versioning.GetVersion():ToString()
    local versionInfo = IO.File.Exists(verFile) and IO.File.ReadAllLines(verFile)
    if not versionInfo or versionInfo[0] ~= currentVersion then
        for file in luanet.each(IO.Directory.GetFiles(cacheDir)) do
            IO.File.Delete(file)
        end
        IO.File.WriteAllText(verFile, currentVersion)
        force = true
    end

    local __Environment = import_type ('System.Environment') --[[@as unknown]]
    local startedAt = __Environment.TickCount64
    local prevMessage = RogueEssence.DiagManager.Instance.LoadMsg;
    RogueEssence.DiagManager.Instance.LoadMsg = "Scanning Tags";
    taxon.data = {}
    local qns = RogueEssence.PathMod.Quest.Namespace ~= '' and RogueEssence.PathMod.Quest.Namespace
    local basePath = IO.Path.Combine(RogueEssence.PathMod.APP_PATH, '%s', 'Data', 'Tags', 'origin')
    local questPath = IO.Path.Combine(RogueEssence.PathMod.APP_PATH, '%s', 'Data', 'Tags', qns or 'origin')

    ---@type {base_path: string?, quest_path: string?}[]
    local scandidates = {}
    if basePath == questPath then
        for mod in luanet.each(RogueEssence.PathMod.GetEligibleMods(RogueEssence.PathMod.ModType.Mod)) do
            local lBasePath = basePath:format(mod.Path)
            if IO.Path.Exists(lBasePath) then table.insert(scandidates, {base_path = lBasePath}) end
        end
    else
        for mod in luanet.each(RogueEssence.PathMod.GetEligibleMods(RogueEssence.PathMod.ModType.Mod)) do
            local lBasePath = basePath:format(mod.Path)
            local lQuestPath = questPath:format(mod.Path)
            if IO.Path.Exists(lBasePath) or IO.Path.Exists(lQuestPath) then table.insert(scandidates, {base_path=lBasePath,quest_path=lQuestPath}) end
        end
    end
    --if #scandidates == 0 then return end

    local pendingScans = {}
    local releaseTag, unreleaseTag, elementTags
    for _,temp in ipairs (data_categories) do
        local category = temp[1]
        local catHash = get_category_hash(category)
        local cachePath = IO.Path.Combine(cacheDir,  (qns or 'origin') ..' '.. category ..'.bin')
        local shouldRecache = true
        if IO.File.Exists(cachePath) then
            local stream = IO.FileStream(cachePath, IO.FileMode.Open)
            local buf = __Array.CreateInstance(type_Byte, 32)
            local read = stream:Read(buf, 0, 32)
            if read == 32 then
                if method_SequenceEqual:Invoke(nil, luanet.make_array(__Object, {buf, catHash})) then shouldRecache = false end
            end
        end
        local cache = {}
        taxon.data[category] = cache
        local s
        for _i,k in ipairs(scandidates) do
            if k.base_path then s = IO.Path.Combine(k.base_path, category); load_tag_files(s, s, cache, category, pendingScans) end
            if k.quest_path then s = IO.Path.Combine(k.quest_path, category); load_tag_files(s, s, cache, category, pendingScans) end
        end

        if not shouldRecache and not force then
            RogueEssence.DiagManager.Instance.LoadMsg = "Loading Tags - ".. category;
            --print ('loading '.. category)
            local cacheData = IO.File.ReadAllBytes(cachePath)
            local keySize = cacheData[32]
            local function getNumber(arr, pos, len, r)
                local n = 0
                for i = len-1, 0, -1 do
                    n = n * 256 + arr[pos + i]
                end
                return n
            end
            local keyCount = getNumber(cacheData, 33, keySize)
            local keys, cursor = {}, 33 + keySize
            local ln
            --print(category, keyCount, keySize)
            for ouh = 1, keyCount do
                ln = cacheData[cursor]
                table.insert(keys, __Encoding.UTF8:GetString(cacheData, cursor + 1, ln))
                cursor = cursor + 1 + ln
                --if ouh < 20 then print(ln, keys[#keys]) end
            end
            local is_default
            local tagName, key
            while cursor < cacheData.Length do
                local tag = {by_index = {}, by_value = {}, removed_values = {}}
                ln = cacheData[cursor]
                tagName = __Encoding.UTF8:GetString(cacheData, cursor + 1, ln)
                cursor = cursor + ln + 1
                is_default = cacheData[cursor] == 1
                ln = getNumber(cacheData, cursor + 1, keySize)
                cursor = cursor + 1 + keySize
                for i = 0, ln - 1 do
                    key = keys[getNumber(cacheData, cursor + i * keySize, keySize)]
                    table.insert(tag.by_index, key)
                    tag.by_value[key] = i + 1
                end
                cursor = cursor + ln * keySize
                cache[tagName] = setmetatable({key = tagName, type = category, values = tag, is_default_tag = is_default}, _tag)
            end
        else
            RogueEssence.DiagManager.Instance.LoadMsg = "Generating Tags - ".. category;
            _DATA:LoadIndex(__DataType[category]) -- ensure indices are reloaded before we generate tags -- previous load may have added or removed data, and we don't want errors

            local function makeTag(cache, tag_name)
                local tag_content = {by_index = {}, by_value = {}, removed_values = {}}
                local tag = setmetatable({key = tag_name, type = category, values = tag_content, is_default_tag = true}, _tag)
                cache[tag_name] = tag
                return tag
            end
            local function addToTag(tag, id)
                local vals = tag.values
                if vals.by_value[id] then return end
                vals.by_value[id] = #vals.by_index + 1
                table.insert(vals.by_index, id)
            end

            releaseTag = makeTag(cache, 'taxon:released')
            unreleaseTag = makeTag(cache, 'taxon:unreleased')
            elementTags = {}
            if temp.has_element then
                for element in luanet.each(_DATA.DataIndices[__DataType.Element]:GetOrderedKeys(true)) do
                    elementTags[element] = makeTag(cache, 'taxon:element/'.. element)
                end
            end

            local entry, summary, o, getEntry
            for id in luanet.each(_DATA.DataIndices[__DataType[category]]:GetOrderedKeys(true)) do
                getEntry = function() local s,v = pcall(temp[2], _DATA, id) if s then entry = entry or v; return v end end
                summary = _DATA.DataIndices[__DataType[category]]:Get(id)
                if summary.Released then
                    addToTag(releaseTag, id)
                else
                    addToTag(unreleaseTag, id)
                end
                if category == 'Skill' then
                    addToTag(elementTags[summary.Element], id)
                elseif category == 'Monster' then
                    getEntry()
                    local idx = 0
                    if entry then
                        for form in luanet.each(entry.Forms) do
                            if not form.Temporary then
                                addToTag(elementTags[form.Element1], id ..'/'.. idx)
                                if form.Element2 ~= 'none' then addToTag(elementTags[form.Element2], id ..'/'.. idx) end
                            end
                            idx = idx + 1
                        end
                    end
                end
                for _, scanData in ipairs(pendingScans) do
                    o = scanData.tag_ref
                    if not o.by_value[id] and not o.removed_values[id] then
                        getEntry()
                        if entry then
                            for test in luanet.each(scanData.scans) do
                                if test.Type == __JTokenType.Object then
                                    if category == 'Monster' then
                                        local idx = 0
                                        for form in luanet.each(entry.Forms) do
                                            if not o.include_temporary_forms or not form.Temporary then
                                                if iterate_scan(entry, summary, form, test, true, getEntry) then
                                                    table.insert(o.by_index, id ..'/'.. idx)
                                                    o.by_value[id] = #o.by_index
                                                    break
                                                end
                                            end
                                            idx = idx + 1
                                        end
                                    else
                                        if iterate_scan(entry, summary, nil, test, true, getEntry) then
                                            table.insert(o.by_index, id)
                                            o.by_value[id] = #o.by_index
                                            break
                                        end
                                    end
                                else
                                    print("invalid token in scans array")
                                end
                            end
                        end
                    end
                end
                entry = nil
            end
            local cacheBloq = {
                keys = {},
                tags = {}
            }
            local revKeys = {}
            for i,k in pairs(cache) do
                local entries = {}
                for _, id in ipairs(k.values.by_index) do
                    local idid = revKeys[id]
                    if not idid then table.insert(cacheBloq.keys, id); idid = #cacheBloq.keys; revKeys[id] = idid; end
                    table.insert(entries, idid)
                end
                cacheBloq.tags[i] = {entries = entries, is_default_tag = k.is_default_tag}
            end
            local keySize = math.ceil(math.ceil(math.log(#cacheBloq.keys + 1, 2))/8)
            local function byteify(n, size)
                local bytes = __Array.CreateInstance(type_Byte, size)
                for i=0, size-1 do
                    bytes[i] = n % 256--bytes:SetValue(n % 256, i)
                    n = math.floor(n / 256)
                end
                return bytes
            end
            local stream = IO.MemoryStream()
            stream:Write(catHash, 0, catHash.Length)
            stream:WriteByte(keySize)
            stream:Write(byteify(#cacheBloq.keys, keySize), 0, keySize)
            for _,k in ipairs(cacheBloq.keys) do
                stream:WriteByte(#k)
                stream:Write(__Encoding.UTF8:GetBytes(k), 0, #k)
            end
            for i,k in pairs(cacheBloq.tags) do
                ---@diagnostic disable-next-line: iter-variable-reassign
                i = tostring(i)
                stream:WriteByte(#i) stream:Write(__Encoding.UTF8:GetBytes(i), 0, #i)
                stream:WriteByte(k.is_default_tag and 1 or 0)
                stream:Write(byteify(#k.entries, keySize), 0, keySize)
                for _, idx in ipairs(k.entries) do
                    stream:Write(byteify(idx, keySize), 0, keySize)
                end
            end
            IO.File.WriteAllBytes(cachePath, stream:ToArray())
        end

        pendingScans = {}
    end
    ---@diagnostic disable-next-line: undefined-field
    RogueEssence.DiagManager.Instance.LoadMsg = prevMessage
    local span = __Environment.TickCount64 - startedAt
    print(('[taxon] Tag rebuild took around %dms (%.2fs)'):format(span, span/1000))
end
if first_init then carcass.rebuild() end

return setmetatable({}, {
    __index = function(_self, index)
        return rawget(taxon.carcass, index)
    end,
    __newindex = function(_self, idx, _v)
        print(string.format ("attempt to insert index %s into taxon shell", idx))
    end
}) --[[@as Taxon.Carcass]]