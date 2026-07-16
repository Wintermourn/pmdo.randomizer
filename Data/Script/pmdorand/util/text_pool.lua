local create_text = require 'pmdorand.util.create_text'

---@generic T
---@param element T
---@return T
local function handle_aligned_coordinates(element, menu_width, menu_height, right, bottom)
    element[1] = tostring(element[1])
    if element[2] and element[2] < 0 then
        element[2] = menu_width + element[2] - right
    end
    if element[3] and element[3] < 0 then
        element[3] = menu_height + element[3] - bottom
    end
    return element
end

return {
    ---@param new_text {[1]: string, [2]: integer, [3]: integer, [4]: RogueElements.DirH?, [5]: RogueElements.DirV?}[]
    update_text = function(menu, pool, new_text, left, top, right, bottom)
        left, top, right, bottom = left or 10, top or 8, right or 10, bottom or 8
        if new_text == nil then return end
        if #new_text == 0 then
            for i = 1, #pool do
                pool[i]:SetText ''
            end 
            return
        end
        local new_elements = #new_text - #pool
        local starting_new_element = #pool + 1
        local element, output
        local menu_bounds = menu.Bounds
        if new_elements > 0 then
            local real_index
            for i = 1, new_elements do
                real_index = starting_new_element + i - 1
                output = handle_aligned_coordinates(new_text[real_index], menu_bounds.Width, menu_bounds.Height, right, bottom)
                element = create_text(output[1], (output[2] or 8) + left, (output[3] or 0) + top, output[4] or RogueElements.DirH.Left, output[5] or RogueElements.DirV.Up)
                pool[real_index] = element
                menu.Elements:Add(element)
            end
        else
            for i = #new_text + 1, #pool do
                pool[i]:SetText ''
            end
        end
        local offset = new_elements > 0 and new_elements or 0
        if #new_text - offset > 0 then
            for i = 1, #new_text - offset do
                output = handle_aligned_coordinates(new_text[i], menu_bounds.Width, menu_bounds.Height, right, bottom)
                element = pool[i]
                element:SetText(output[1])
                element.Loc = #output > 1 and RogueElements.Loc(output[2] and (output[2] + left) or element.Loc.X, output[3] and (output[3] + top) or element.Loc.Y) or element.Loc
                element.AlignH = output[4] or RogueElements.DirH.Left
                element.AlignV = output[5] or RogueElements.DirV.Up
            end
        end
    end
}