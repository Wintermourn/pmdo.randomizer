local config = require 'pmdorand.config'
local interlace = require 'lib.pmdorand.interlace'
local header = require 'pmdorand.util.header'
local deepcopy = require 'pmdorand.util.deepcopy'
local nyaml = require 'lib.pmdorand.nyaml'
nyaml(header.Path, 'Libraries', 'SharpYaml.dll')

local IO = luanet.namespace 'System.IO'

local illegalChars = IO.Path.GetInvalidFileNameChars()
local illegalPattern = '['
do
    local char, code
    for i = 0, illegalChars.Length - 1 do
        char = string.char(illegalChars[i])

        if string.find(char, '[%$%%%^%*%(%)%-%+%.%?]') then
            illegalPattern = illegalPattern .. '%'.. char
        else
            illegalPattern = illegalPattern .. char
        end
    end
    illegalPattern = illegalPattern .. ']'
end

local components_mt = {
    __nyamlKeyOrder = function(a, b)
        return tostring(a) < tostring(b)
    end
}

local cache = {
    core = {
        public = {},
        personal = {}
    },
    ---@type {[string]: Config.Feature?}
    components = setmetatable({}, components_mt),
    structures = {
        core = require 'pmdorand.randomizer.core.settings' .structure,
        components = {}
    },
    ---@type {core: table, components: table}
    ---@diagnostic disable-next-line: missing-fields, assign-type-mismatch
    working_copy = {}
}

local base_path = IO.Path.Combine(
    RogueEssence.PathMod.APP_PATH,
    RogueEssence.Data.DataManager.SAVE_PATH,
    'MODS',
    'pmdo-randomizer'
)

local paths = {
    save = base_path,
    folder_exports = IO.Path.Combine(base_path, 'exports'),
    folder_configs = IO.Path.Combine(base_path, 'configurations'),
    folder_configs_local = IO.Path.Combine(base_path, 'configurations', 'personal'),
    folder_configs_shared = IO.Path.Combine(base_path, 'configurations', 'shared'),
    settings = IO.Path.Combine(base_path, 'settings.yml'),
    memory = IO.Path.Combine(base_path, 'memory.yml')
}

local function recursive_build_defaults(output, input)
    for i,k in pairs(input) do
        if k.is_configuration then
            ---@cast k Config.Base
            output[i] = k:get_default_value()
        else
            local o = {}
            recursive_build_defaults(o, k)
            output[i] = o
        end
    end

    return output
end

local function make_default( structure )
    return recursive_build_defaults( {}, structure )
end

local function safe_write(path, data)

    if IO.Path.Exists(path) then
        if IO.File.ReadAllText(path) == data then return end
        local temp_path = IO.Path.Combine(IO.Path.GetDirectoryName(path), IO.Path.GetRandomFileName())
        IO.File.WriteAllText(temp_path, data)
        IO.File.Move(temp_path, path, true)
    else
        IO.File.WriteAllText(path, data)
    end
end

local public = {}

---@param structure Config.Feature
function public.publish( component_id, structure )
    cache.structures.components[component_id] = structure
    cache.components[component_id] = structure:get_default_value()
end

function public.construct_defaults()
    cache.core.personal = make_default( cache.structures.core.personal )
    cache.core.public = make_default( cache.structures.core.public )
    for i,k in pairs(cache.structures.components) do
        cache.components[i] = k:get_default_value()
    end
    return { core = cache.core, components = cache.components }
end

function public.copy_to_working_path()
    local out = {
        core = deepcopy(cache.core),
        components = deepcopy(cache.components)
    }

    cache.working_copy = out
end

---@return fun(): string
function public.keys()
    local keys = {}
    for i in pairs(cache.components) do keys[#keys + 1] = i end
    local i = 0
    return function()
        i = i + 1
        return keys[i]
    end
end

--- Returns the user's settings. **These can be changed during generation.**
---@return ({public: table, personal: table})|Config.Feature
function public.get_master( identifier )
    if identifier == nil then return cache.core end
    return cache.components[identifier]
end

--- Returns a copy of the user's settings. These will not be changed by the player during generation.
---@return ({public: table, personal: table})|Config.Feature
function public.get( identifier )
    if identifier == nil then return cache.working_copy.core end
    return cache.working_copy.components[identifier]
end

---@param name string
function public.save( name, metadata )
    local save_path = IO.Path.Combine(paths.folder_configs_local, name:gsub(illegalPattern, '_') ..'.yml')
    local path = IO.Path.GetFullPath( save_path )
    if path:sub(1, #paths.folder_configs_local) ~= paths.folder_configs_local then
       return false
    end
    if not IO.Directory.Exists(paths.folder_configs_local) then
        IO.Directory.CreateDirectory(paths.folder_configs_local)
    end

    if metadata == nil then
        metadata = {
            name = name
        } 
    end

    safe_write(save_path, nyaml.serialize(
        setmetatable({
            versioning = {
                mod = header.Version:ToString(),
                game = interlace.get_game_header().Version:ToString()
            },
            metadata = metadata or {
                name = name
            },
            core = cache.core.public,
            components = cache.components
        }, {
            __nyamlKeyOrder = {
                'versioning',
                'metadata',
                'core',
                'components'
            }
        })
    ))
end

function public.save_core_settings()
    local path = paths.settings

    safe_write(path, nyaml.serialize(
        setmetatable({
            versioning = {
                mod = header.Version:ToString(),
                game = interlace.get_game_header().Version:ToString()
            },
            public = cache.core.public,
            personal = cache.core.personal
        }, {
            __nyamlKeyOrder = {
                'versioning',
                'public',
                'personal'
            }
        })
    ))
end

function public.save_memory()
    if cache.core.personal.remember_last ~= true then return end
    local path = paths.memory

    safe_write(path, nyaml.serialize(
        setmetatable({
            versioning = {
                mod = header.Version:ToString(),
                game = interlace.get_game_header().Version:ToString()
            },
            components = cache.components
        }, {
            __nyamlKeyOrder = {
                'versioning',
                'components'
            }
        })
    ))
end

---@param structure {[string]: Config.Base?}
local function merge_table(old_data, new_data, structure, enforce_limits)
    if type(new_data) ~= 'table' then return end

    for i,k in pairs(new_data) do
        if structure[i] then
            local success, message = structure[i]:validate(k, enforce_limits)
            if success then
                old_data[i] = k
            else
                print(string.format('failed comp! new is "%s" for a key "%s" with a data type of "%s":\n\t%s', tostring(k), i, structure[i].__title, tostring(message)))
            end
        else
            old_data[i] = k
        end
    end
end

local __Version = luanet.import_type 'System.Version'

function public.initial_load()
    public.construct_defaults()

    local path = paths.settings
    if IO.File.Exists(path) then
        local success, data = nyaml.parse_file(path)
        if success and type(data) == 'table' then
            merge_table(cache.core.public, data.public, cache.structures.core.public)
            merge_table(cache.core.personal, data.personal, cache.structures.core.personal)
        end
    end
    if cache.core.personal.remember_last ~= true then return end

    path = paths.memory
    if IO.File.Exists(path) then
        local success, data = nyaml.parse_file(path)
        if success and type(data) == 'table' then
            if data.components then
                for i,k in pairs(data.components) do
                    if cache.components[i] then
                        merge_table(cache.components[i], k, cache.structures.components[i])
                    else
                        cache.components[i] = k
                    end
                end 
            end
        end
    end
end

local SDL = luanet.namespace 'SDL2' .SDL
function public.open_save_folder()
    SDL.SDL_OpenURL("file:///".. paths.save)
end

function public.open_exports_folder()
    if not IO.Directory.Exists(paths.folder_exports) then
        IO.Directory.CreateDirectory(paths.folder_exports)
    end
    SDL.SDL_OpenURL("file:///".. paths.folder_exports)
end

---@param subdirectory 'local'|'shared'?
function public.open_configs(subdirectory)
    local dir

    if subdirectory then
        if subdirectory == 'local' then
            dir = paths.folder_configs_local
        elseif subdirectory == 'shared' then
            dir = paths.folder_configs_shared
        end
    else
        dir = paths.folder_configs
    end
    if not IO.Directory.Exists(dir) then
        IO.Directory.CreateDirectory(dir)
    end
    SDL.SDL_OpenURL("file:///".. dir)
end

function public.open_shared_configs()
    if not IO.Directory.Exists(paths.folder_configs_shared) then
        IO.Directory.CreateDirectory(paths.folder_configs_shared)
    end
    SDL.SDL_OpenURL("file:///".. paths.folder_configs_shared)
end

return public