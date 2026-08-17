---@alias (internal) pmdorand.clipboard.Platform
---| -1 Unknown
---| 0 Windows
---| 1 MacOS
---| 2 X11
---| 3 Wayland

---@type {[string]: pmdorand.clipboard.Platform|(fun(): pmdorand.clipboard.Platform)?}
local platforms = {
    ['Windows'] = 0,
    ['Mac OS X'] = 1,
    ['Linux'] = function()
        local session_type = (os.getenv 'XDG_SESSION_TYPE' or ''):lower()
        if session_type == 'x11' then
            return 2
        elseif session_type == 'wayland' then
            return 3
        end
        return -1
    end
}

---@type pmdorand.clipboard.Platform
local platform
local SDL = luanet.namespace 'SDL2' .SDL
local function get_platform()
    if platform ~= nil then return end

    local sdl_plat = SDL.SDL_GetPlatform()
    local candidate = platforms[sdl_plat]
    if candidate then
        if type(candidate) == 'function' then
            platform = candidate()
        else
            platform = candidate
        end
    else
        platform = -1
    end
end

local function pipe_into(cmd, str)
    local pipe = io.popen(cmd, 'w')
    if not pipe then return false end

    pipe:write(str)
    local success = pipe:close()

    return success == true or success == 0
end

local public = {}

---@type {[pmdorand.clipboard.Platform]: fun(string)}
local clipboard_handlers = {
    [-1] = function(str)
        SDL.SDL_SetClipboardText(str)
    end
}

local function caching_method(platform_id, ...)
    local args = {...}
    return function(str)
        local i, len = 1, #args
        while i <= len do
            if pipe_into(args[i], str) then
                clipboard_handlers[platform_id] = function (str)
                    return pipe_into(args[i], str)
                end
                return
            end
            i = i + 1
        end

        clipboard_handlers[platform_id] = clipboard_handlers[-1]
        clipboard_handlers[-1](str)
    end
end

clipboard_handlers[2] = caching_method(
    2,
    'xclip -selection clipboard 2>/dev/null',
    'xsel --clipboard --input 2>/dev/null'
)

clipboard_handlers[3] = caching_method(
    3,
    'wl-copy 2>/dev/null',
    'xclip -selection clipboard 2>/dev/null',
    'xsel --clipboard --input 2>/dev/null'
)

function public.copy_text(txt)
    get_platform()
    local handler = clipboard_handlers[platform] or clipboard_handlers[-1]

    handler(txt)
end

return public