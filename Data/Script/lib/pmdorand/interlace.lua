---@diagnostic disable: duplicate-type, duplicate-set-field, unnecessary-if
local INTERLACEVERSION = 0.11

local __Version = luanet.import_type "System.Version"
local __Guid = luanet.import_type "System.Guid"
--[[ local __IO = namespace 'System.IO'
    local __Directory = __IO.Directory ]]

if not _G.wintermourn or not _G.wintermourn.interlace or _G.wintermourn.interlace._VERSION < INTERLACEVERSION then
    _G.wintermourn = _G.wintermourn or {}

    ---@class Interlace.ModHandle
    local modHandle = {
        uuid = "",
        namespace = "",
        version = {},
        is_available    = false,
        is_loaded       = false,
        header          = nil
    }

    ---@class (partial) Interlace.Carcass
    local carcass = {}
    ---@diagnostic disable-next-line: unnecessary-if
    if _G.wintermourn.interlace then
        local tbl = _G.wintermourn.interlace
        tbl._VERSION = INTERLACEVERSION
        tbl.carcass = carcass
    else
        _G.wintermourn.interlace = {
            _VERSION = INTERLACEVERSION,
            data = {
                configurations = {},
                mods_list = {
                    by_namespace = {},
                    by_uuid = {},
                    by_path = {}
                }
            },
            components = {},
            carcass = carcass
        }


        local function addHeaderToList(tbl, mod)
            local old_item = tbl.by_namespace[mod.Namespace]
            if old_item then
                if type(old_item) == "table" then
                    table.insert(old_item, mod)
                else
                    local old = tbl.by_namespace[mod.Namespace]
                    tbl.by_namespace[mod.Namespace] = {old, mod}
                end
            else
                tbl.by_namespace[mod.Namespace] = mod
            end
            local uuids = mod.UUID:ToString()
            old_item = tbl.by_uuid[uuids]
            if old_item then
                if type(old_item) == "table" then
                    table.insert(old_item, mod)
                else
                    local old = tbl.by_uuid[uuids]
                    tbl.by_uuid[uuids] = {old, mod}
                end
            else
                tbl.by_uuid[uuids] = mod
            end
            tbl.by_path[mod.Path] = mod
        end

        local ml = _G.wintermourn.interlace.data.mods_list
        for mod in luanet.each(RogueEssence.PathMod.GetEligibleMods(RogueEssence.PathMod.ModType.Mod)) do
            addHeaderToList(ml, mod)
        end
    end

    local gameHeader = RogueEssence.ModHeader(
        RogueEssence.PathMod.APP_PATH,
        RogueEssence.PathMod.ExeName,
        "",
        "",
        RogueEssence.PathMod.BaseNamespace,
        __Guid.Empty,
        RogueEssence.Versioning.GetVersion(),
        RogueEssence.Versioning.GetVersion(),
        RogueEssence.PathMod.ModType.Quest,
        luanet.make_array(RogueEssence.RelatedMod, {})
    )
    local gameHandle = {
        uuid = gameHeader.UUID:ToString(),
        namespace = gameHeader.Namespace,
        version = gameHeader.Version,
        is_available = true,
        is_loaded = true,
        header = gameHeader
    }
    --- Returns a fake header filled with game related information, such as version.
    function carcass.get_game_header()
        return gameHeader
    end

    ---@return Interlace.ModHandle
    local function makeModHandleWithHeader(modHeader)
        if modHeader == gameHeader then return gameHandle end
        if type(modHeader) == 'table' then
            local candidate = RogueEssence.PathMod.GetModFromNamespace(modHeader[1].Namespace)
            if candidate:IsFilled() then
                modHeader = candidate
            else
                candidate = modHeader[1]
                for _,k in ipairs(modHeader) do
                    if k.Version > candidate.Version then
                        candidate = k
                    end
                end
                modHeader = candidate
            end
        end
        if modHeader == nil then
            return {
                uuid = "", namespace = "", version = __Version(0, 0),
                is_available = false,
                is_loaded = false,
                header = nil
            }
        else
            return {
                uuid = modHeader.UUID:ToString(),
                namespace = modHeader.Namespace,
                version = modHeader.Version,
                is_available = true,
                is_loaded = RogueEssence.PathMod.GetModFromNamespace(modHeader.Namespace):IsFilled() or modHeader == RogueEssence.PathMod.Quest,
                header = modHeader
            }
        end
    end

    --[[ local configBuilder = {}
    configBuilder.__index = configBuilder

    function configBuilder:structure(struct) end -- defines the shape of the config
    function configBuilder:default(struct) end -- defines the default values of the config
    function configBuilder:preset(preset_name, struct) end -- defines presets for the config; builds off of the default values
    function configBuilder:build() end ]]

--#region Dependency Testing
    
    ---@class Interlace.DependencyBuilder.TestInfo
    local dependencyTestInfo = {
        current_layer = 0,
        passed_layers = 0,
        failed_layers = 0,
        passed_checks = 0,
        failed_checks = 0,
        should_continue = true
    }
    dependencyTestInfo.__index = dependencyTestInfo
    function dependencyTestInfo:stop_test() self.should_continue = false end

    ---@class Interlace.DependencyBuilder
    local dependencyBuilder = {
        _layers = {},
        _working_conditions = { has_conditions = false }
    }
    dependencyBuilder.__index = dependencyBuilder

    function dependencyBuilder:after(mod_header, version)
        if self._working_conditions.after then
            table.insert(self._working_conditions.after, {
                header = mod_header, version = version
            })
        else
            self._working_conditions.after = {{
                header = mod_header, version = version
            }}
            self._working_conditions.has_conditions = true
        end
        return self
    end
    function dependencyBuilder:before(mod_header, version)
        if self._working_conditions.before then
            table.insert(self._working_conditions.before, {
                header = mod_header, version = version
            })
        else
            self._working_conditions.before = {{
                header = mod_header, version = version
            }}
            self._working_conditions.has_conditions = true
        end
        return self
    end
    function dependencyBuilder:at_or_after(mod_header, version)
        if self._working_conditions.at_or_after then
            table.insert(self._working_conditions.at_or_after, {
                header = mod_header, version = version
            })
        else
            self._working_conditions.at_or_after = {{
                header = mod_header, version = version
            }}
            self._working_conditions.has_conditions = true
        end
        return self
    end
    function dependencyBuilder:at_or_before(mod_header, version)
        if self._working_conditions.at_or_before then
            table.insert(self._working_conditions.at_or_before, {
                header = mod_header, version = version
            })
        else
            self._working_conditions.at_or_before = {{
                header = mod_header, version = version
            }}
            self._working_conditions.has_conditions = true
        end
        return self
    end
    function dependencyBuilder:requires(mod_header)
        if self._working_conditions.requires then
            table.insert(self._working_conditions.requires, {
                header = mod_header
            })
        else
            self._working_conditions.requires = {{
                header = mod_header
            }}
            self._working_conditions.has_conditions = true
        end
        return self
    end
    function dependencyBuilder:exact(mod_header, version)
        if self._working_conditions.exactly then
            table.insert(self._working_conditions.exactly, {
                header = mod_header, version = version
            })
        else
            self._working_conditions.exactly = {{
                header = mod_header, version = version
            }}
            self._working_conditions.has_conditions = true
        end
        return self
    end
    function dependencyBuilder:incompatible(mod_header)
        if self._working_conditions.incompatible then
            table.insert(self._working_conditions.incompatible, {
                header = mod_header
            })
        else
            self._working_conditions.incompatible = {{
                header = mod_header
            }}
            self._working_conditions.has_conditions = true
        end
        return self
    end
    ---@param callback fun(info: Interlace.DependencyBuilder.TestInfo)
    function dependencyBuilder:if_valid(callback)
        local ptr
        if self._working_conditions.has_conditions then
            ptr = self._working_conditions
            table.insert(self._layers, self._working_conditions)
            self._working_conditions = {has_conditions = false}
        else
            if #self._layers == 0 then error("Cannot create a test for no dependencies", 2) end
            ptr = self._layers[#self._layers]
        end
        if ptr.on_valid then
            table.insert(ptr.on_valid, callback)
        else
            ptr.on_valid = {callback}
        end
        return self
    end
    ---@param callback fun(info: Interlace.DependencyBuilder.TestInfo)
    function dependencyBuilder:if_invalid(callback)
        local ptr
        if self._working_conditions.has_conditions then
            ptr = self._working_conditions
            table.insert(self._layers, self._working_conditions)
            self._working_conditions = {has_conditions = false}
        else
            if #self._layers == 0 then error("Cannot create a test for no dependencies", 2) end
            ptr = self._layers[#self._layers]
        end
        if ptr.on_invalid then
            table.insert(ptr.on_invalid, callback)
        else
            ptr.on_invalid = {callback}
        end
        return self
    end
    ---@param valid_callback fun(info: Interlace.DependencyBuilder.TestInfo)
    ---@param invalid_callback fun(info: Interlace.DependencyBuilder.TestInfo)
    function dependencyBuilder:on_result(valid_callback, invalid_callback)
        local ptr
        if self._working_conditions.has_conditions then
            ptr = self._working_conditions
            table.insert(self._layers, self._working_conditions)
        else
            if #self._layers == 0 then error("Cannot create a test for no dependencies", 2) end
            ptr = self._layers[#self._layers]
        end
        if ptr.on_valid then
            table.insert(ptr.on_valid, valid_callback)
        else
            ptr.on_valid = {valid_callback}
        end
        if ptr.on_invalid then
            table.insert(ptr.on_invalid, invalid_callback)
        else
            ptr.on_invalid = {invalid_callback}
        end
        return self
    end
    function dependencyBuilder:test()
        ---@type Interlace.DependencyBuilder.TestInfo
        local testInfo = setmetatable({}, dependencyTestInfo)
        local handles = {}
        local function getHandle(header)
            if header == nil then
                return {
                    is_loaded = false,
                    is_available = false,
                    version = __Version(0, 0)
                }
            end
            if handles[header] then return handles[header] end
            local handle = makeModHandleWithHeader(header)
            handles[header] = handle
            return handle
        end

        for _, k in pairs(self._layers) do
            if not testInfo.should_continue then break end
            if k.incompatible then
                for _, entry in ipairs(k.incompatible) do
                    if getHandle(entry.header).is_loaded then -- todo
                        goto failed
                    end
                end
            end
            if k.requires then
                for _, entry in ipairs(k.requires) do
                    if not getHandle(entry.header).is_loaded then -- todo
                        goto failed
                    end
                end
            end
            if k.exactly then
                for _, entry in ipairs(k.exactly) do
                    if not getHandle(entry.header).is_loaded or getHandle(entry.header).version ~= __Version(entry.version) then -- todo
                        goto failed
                    end
                end
            end
            if k.after then
                for _, entry in ipairs(k.after) do
                    if not getHandle(entry.header).is_loaded or getHandle(entry.header).version <= __Version(entry.version) then -- todo
                        goto failed
                    end
                end
            end
            if k.before then
                for _, entry in ipairs(k.before) do
                    if not getHandle(entry.header).is_loaded or getHandle(entry.header).version >= __Version(entry.version) then
                        goto failed
                    end
                end
            end
            if k.at_or_after then
                for _, entry in ipairs(k.at_or_after) do
                    if not getHandle(entry.header).is_loaded or getHandle(entry.header).version < __Version(entry.version) then -- todo
                        goto failed
                    end
                end
            end
            if k.at_or_before then
                for _, entry in ipairs(k.at_or_before) do
                    if not getHandle(entry.header).is_loaded or getHandle(entry.header).version > __Version(entry.version) then
                        goto failed
                    end
                end
            end

            if k.on_valid then
                for _, c in ipairs(k.on_valid) do
                    c(testInfo)
                    if not testInfo.should_continue then goto end_test end
                end
            end
            goto continue
            ::failed::
            if k.on_invalid then
                for _, c in ipairs(k.on_invalid) do
                    c(testInfo)
                    if not testInfo.should_continue then goto end_test end
                end
            end
            ::continue::
        end
        ::end_test::
    end
    --function dependencyBuilder:stop_test() end
    
--#endregion Dependency Testing

    ---@return RogueEssence.ModHeader
    function carcass.get_mod_by_namespace(namespace)
        return _G.wintermourn.interlace.data.mods_list.by_namespace[namespace]
        --return RogueEssence.PathMod.GetModFromNamespace(namespace)
    end
    ---Returns the current quest's mod header, if one is active.
    ---@return RogueEssence.ModHeader | false
    function carcass.get_quest_header()
        return RogueEssence.PathMod.Quest ~= RogueEssence.ModHeader.Invalid and RogueEssence.PathMod.Quest
        --return RogueEssence.PathMod.GetModFromNamespace(namespace)
    end
    ---Returns the current quest's mod header if the namespace provided matches
    ---@return RogueEssence.ModHeader
    function carcass.is_active_quest_of_namespace(namespace)
        return RogueEssence.PathMod.Quest.Namespace == namespace
    end
    --- Returns true if the current quest's uuid matches.
    ---@return boolean
    function carcass.is_active_quest_of_uuid(uuid)
        local success
        if type(uuid) == "string" then
            success, uuid = pcall(__Guid, uuid)
            if not success then return nil end
            uuid = uuid:ToString()
        end
        return RogueEssence.PathMod.Quest.UUID == uuid
    end
    ---@return RogueEssence.ModHeader?
    function carcass.get_mod_by_uuid(uuid)
        local success
        if type(uuid) == "string" then
            success, uuid = pcall(__Guid, uuid)
            if not success then return nil end
            uuid = uuid:ToString()
        end
        return _G.wintermourn.interlace.data.mods_list.by_uuid[uuid]
        --return RogueEssence.PathMod.GetModFromUuid(id)
    end
    ---@return RogueEssence.ModHeader?
    function carcass.get_active_mod_by_uuid(uuid)
        local success
        if type(uuid) == "string" then
            success, uuid = pcall(__Guid, uuid)
            if not success then return nil end
        end
        return RogueEssence.PathMod.GetModFromUuid(uuid)
    end

    function carcass.dependency_test()
        local data = {
            _layers = {},
            _working_conditions = { has_conditions = false }
        }
        return setmetatable(data, dependencyBuilder)
    end

    --[[ function carcass.create_config(id)
        -- todo: builder
    end ]]
end

return setmetatable({}, {
    __index = function(_self, index)
        local interlace = _G.wintermourn.interlace
        local candidate = rawget(interlace.carcass, index)
        if candidate then return candidate end
        for _i,k in pairs(interlace.components) do
            if k.bubbleup then
                candidate = rawget(k.bubbleup, index)
                if candidate then return candidate end
            end
        end
    end,
    __newindex = function(self, idx, _v)
        print(string.format ("attempt to insert index %s into interlace shell", idx))
    end
}) --[[@as Interlace.Carcass]]