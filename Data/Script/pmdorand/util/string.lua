local helpers = {}

---@param s string|any
---@param len int
---@param pad string?
function helpers.pad_end(s, len, pad)
    s = tostring(s)
    pad = pad or ' '

    local current_length = utf8.len(s)
    if current_length == nil or current_length > len then return s end

    local pad_length = len - current_length
    local pad_string = string.rep(pad, math.ceil(pad_length / (utf8.len(pad) or 0)))
    local padding = string.sub(
        pad_string,
        1, utf8.offset(pad_string, pad_length)
    )

    return s .. padding
end

---@param s string|any
---@param len int
---@param pad string?
function helpers.pad_start(s, len, pad)
    s = tostring(s)
    pad = pad or ' '

    local current_length = utf8.len(s)
    if current_length == nil or current_length > len then return s end

    local pad_length = len - current_length
    local pad_string = string.rep(pad, math.ceil(pad_length / (utf8.len(pad) or 0)))
    local padding = string.sub(
        pad_string,
        1, utf8.offset(pad_string, pad_length)
    )

    return padding .. s
end

return helpers