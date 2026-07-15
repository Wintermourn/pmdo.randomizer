local config = require 'pmdorand.config'
local interlace = require 'lib.pmdorand.interlace'
local header = interlace .get_active_mod_by_uuid '019f4afe-e16e-734e-aebb-05e908454357'
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

local cache = {
    core = {
        public = {},
        personal = {}
    },
    ---@type {[string]: Config.Feature}
    components = {},
    structures = {
        core = require 'pmdorand.randomizer.core.settings' .structure,
        components = {}
    }
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

local public = {}

---@param structure Config.FromTable
function public.publish( component_id, structure )
    local wrapped =config.feature( structure )
    cache.structures.components[component_id] = wrapped
    cache.components[component_id] = wrapped:get_default_value()
end

function public.construct_defaults()
    cache.core.personal = make_default( cache.structures.core.personal )
    cache.core.public = make_default( cache.structures.core.public )
    for i,k in pairs(cache.structures.components) do
        cache.components[i] = k:get_default_value()
    end
    return { core = cache.core, components = cache.components }
end

function public.get( identifier )
    if identifier == nil then return cache.core end
    return cache.components[identifier]
end

local base_path = IO.Path.Combine(
    RogueEssence.PathMod.APP_PATH,
    RogueEssence.Data.DataManager.SAVE_PATH,
    'MODS',
    'pmdo-randomizer',
    'configurations'
)

---@param name string
function public.save( name, metadata )
    local save_path = IO.Path.Combine(base_path, name:gsub(illegalPattern, '_') ..'.yml')
    local path = IO.Path.GetFullPath( save_path )
    if path:sub(1, #base_path) ~= base_path then
       return false
    end
    if not IO.Directory.Exists(base_path) then
        IO.Directory.CreateDirectory(base_path)
    end

    if metadata == nil then
        metadata = {
            name = name
        } 
    end

    IO.File.WriteAllText(save_path, nyaml.serialize(
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
    local path = IO.Path.Combine(base_path, '..', 'settings.yml')

    IO.File.WriteAllText(path, nyaml.serialize(
        setmetatable({
            public = cache.core.public,
            personal = cache.core.personal
        }, {
            __nyamlKeyOrder = {
                'public',
                'personal'
            }
        })
    ))
end

return public