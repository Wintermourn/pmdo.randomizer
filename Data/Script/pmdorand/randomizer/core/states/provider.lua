local IO = luanet.namespace 'System.IO'

local function create_directory(path)

end

---@class pmdorand.state.provider
local provider_state = {
    cache = {}
}
provider_state.__index = provider_state

local output_path

function provider_state:serialize_jsonpatch(type, key, data)
    local patch_path = IO.Path.Combine(output_path, type, key ..'.jsonpatch')
    ---@diagnostic disable-next-line: param-type-mismatch
    if not IO.Directory.Exists(patch_path) then IO.Directory.CreateDirectory(IO.Path.GetDirectoryName(patch_path)) end
    RogueEssence.Data.Serializer.SerializeDataAsDiff(
        patch_path,
        RogueEssence.PathMod.NoMod(
            IO.Path.Combine(
                RogueEssence.Data.DataManager.DATA_PATH,
                type, key ..'.json'
            )
        ),
        data
    )
end

function provider_state:serialize_universal()
    local file_path = IO.Path.Combine(output_path, 'Universal.jsonpatch')
    ---@diagnostic disable-next-line: param-type-mismatch
    if not IO.Directory.Exists(file_path) then IO.Directory.CreateDirectory(IO.Path.GetDirectoryName(file_path)) end
    RogueEssence.Data.Serializer.SerializeDataAsDiff(
        file_path,
        RogueEssence.PathMod.NoMod(
            IO.Path.Combine(
                RogueEssence.Data.DataManager.DATA_PATH,
                'Universal.json'
            )
        ),
        _DATA.UniversalEvent
    )
end

local public = {}

---@return pmdorand.state.provider
function public.new()
    local o = {
        cache = {}
    }

    return setmetatable(o, provider_state)
end

function public.update_output_path(path)
    local relative_path = IO.Path.GetRelativePath(RogueEssence.PathMod.APP_PATH, path)
    if relative_path:find('%.%.') or relative_path == '.' then error("Suspicious output path\n".. relative_path) end
    output_path = path
end

return public