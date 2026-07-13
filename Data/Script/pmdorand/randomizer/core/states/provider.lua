local interlace = require 'lib.pmdorand.interlace'
local IO = luanet.namespace 'System.IO'

local BASE_PATH = IO.Path.Combine(
    RogueEssence.PathMod.APP_PATH,
    interlace.get_mod_by_namespace ('pmdorand') --[[@as -nil]] .Path,
    RogueEssence.Data.DataManager.DATA_PATH
)

local function create_directory(path)

end

---@class pmdorand.state.provider
local provider_state = {
    cache = {}
}
provider_state.__index = provider_state

function provider_state:serialize_jsonpatch(type, key, data)
    local patch_path = IO.Path.Combine(BASE_PATH, type, key ..'.jsonpatch')
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

local public = {}

---@return pmdorand.state.provider
function public.new()
    local o = {
        cache = {}
    }

    return setmetatable(o, provider_state)
end

return public