local input_type = RogueEssence.FrameInput.InputType

local generation_manager = require 'pmdorand.randomizer.core.manager'

local component_registry = require 'pmdorand.randomizer.core.registry' .get 'components'
local create_text = require 'pmdorand.util.create_text'
local play_sound = require 'pmdorand.util.play_sound'
local provider_registry = require 'pmdorand.randomizer.core.registry' .get 'providers'
local text_pool = require 'pmdorand.util.text_pool'

local strings = {
    component_title = STRINGS:FormatKey 'pmdorand:stats.components.title',
    provider_count = STRINGS:FormatKey 'pmdorand:stats.providers.count',
    component_count = STRINGS:FormatKey 'pmdorand:stats.components.count',
    component_span = STRINGS:FormatKey 'pmdorand:stats.components.span',
    start_randomizer = STRINGS:FormatKey 'pmdorand:randomize',
    start_randomizer_grayed = '[color=#999999]'.. STRINGS:FormatKey 'pmdorand:randomize',
    browse_configurations = '[color=#999999]'.. STRINGS:FormatKey 'pmdorand:configurations.browse',
    states = {
        idle = '[color=#333333]'.. STRINGS:FormatKey 'pmdorand/state:idle',
        generating = STRINGS:FormatKey 'pmdorand/state:generating',
        finished = STRINGS:FormatKey 'pmdorand/state:finished',
        failed = '[color=#ff4499]'.. STRINGS:FormatKey 'pmdorand/state:failed'
    },
    progress = {
        idle = '[color=#333333]'.. STRINGS:FormatKey 'pmdorand/status:idle',
        finished = '[color=#44ff99]'.. STRINGS:FormatKey 'pmdorand/status:finished',
        failed = STRINGS:FormatKey 'pmdorand/status:failed'
    }
}

---@type {[int]: fun(self, menu): string?, string?}
local state_mapping = {
    function(self, menu)
        if self.last_state == 0 then return end
        return strings.states.idle, strings.progress.idle
    end,
    function()
        return strings.states.generating, generation_manager.get_status()
    end,
    function(self, menu)
        if self.last_state == 2 then return end
        return strings.states.finished, strings.progress.finished
    end,
    function(self, menu)
        if self.last_state == 3 then return end
        return strings.states.failed, strings.progress.failed
    end
}

local info = {
    title = STRINGS:FormatKey 'pmdorand:tab/status'
}

local state = {
    info = info,
    position = {},
    elements = {},
    lines = {}
}
state.__index = state

local texts = {
    {strings.component_title, 0, 2, RogueElements.DirH.Left},
    {'', -2, 2, RogueElements.DirH.Right},
    {'', 0, 14, RogueElements.DirH.Left},
    {strings.browse_configurations, 7, -16, RogueElements.DirH.Left},
    {strings.start_randomizer, 7, -4, RogueElements.DirH.Left}
}

local __Keys = luanet.namespace 'Microsoft.Xna.Framework.Input' .Keys
local at = {
    {0, -4, function(self, menu, input)
        if generation_manager.get_state() ~= 1 then
            generation_manager.start(input:BaseKeyDown(__Keys.LeftAlt))
            state.update_text(self, menu)
        end
    end},
    {0, -16, function(self, menu)
    
    end}
}

local function on_generation_finished()

end

function state:update_text(menu)
    texts[5][1] = (generation_manager.get_state() == 1 or select(2, generation_manager.get_enabled_count()) == 0) and strings.start_randomizer_grayed or strings.start_randomizer
    text_pool.update_text( menu.menu, menu.elements.pool, texts, 12, 19, 20, 48 )
end

function state:update_footer(menu)
    local state = generation_manager.get_state()
    local mapping_candidate = state_mapping[state + 1] or state_mapping[1]
    local left, right = mapping_candidate(self, menu)
    if left then
        self.elements.status:SetText(left)
    end
    if right then
        self.elements.progress:SetText(right)
    end
    self.last_state = state
end

function state:entered(menu)
    ---@type integer, integer
    local mw, mh = menu.menu.Bounds.Width, menu.menu.Bounds.Height
    self.elements.divider.Loc = RogueElements.Loc(10, mh - 20)
    self.elements.divider.Length = menu.menu.Bounds.Width - 20
    self.elements.status.Loc = RogueElements.Loc(10, mh - 17)
    self.elements.progress.Loc = RogueElements.Loc(mw - 10, mh - 17)

    local enabled_count_min, enabled_count_max = generation_manager.get_enabled_count()
    texts[2][1] = enabled_count_min == enabled_count_max and
                strings.component_count:format(component_registry.count, enabled_count_min) or 
                strings.component_span:format(component_registry.count, enabled_count_min, enabled_count_max)
    texts[3][1] = strings.provider_count:format(provider_registry.count)
    self:update_text(menu)

    local elements = menu.menu.Elements
    elements:Add(self.elements.divider)
    elements:Add(self.elements.status)
    elements:Add(self.elements.progress)

    ---@diagnostic disable-next-line: undefined-field
    local selection = at[self.position.cursor]
    if selection ~= nil then
        menu:set_cursor_pos(selection[1], selection[2] >= 0 and selection[2] or (menu.menu.Bounds.Height + selection[2]) - 50)
    else
        menu:set_cursor_pos(8,0)
    end

    if self.generation_callback == nil then
        self.generation_callback = function()
            self:update_text(menu) 
        end
    end
    generation_manager.on_success(self.generation_callback)
    generation_manager.on_failed(self.generation_callback)
end

function state:update(menu, input)
    if input:JustPressed(input_type.Confirm) then
        ---@diagnostic disable-next-line: undefined-field
        local selection = at[self.position.cursor]
        if selection ~= nil then
            selection[3](self, menu, input)
        else
            _GAME:SE 'Menu/Cancel'
        end
    end
    self:update_footer(menu)
end

function state:left(menu)
    local elements = menu.menu.Elements
    elements:Remove(self.elements.divider)
    elements:Remove(self.elements.status)
    elements:Remove(self.elements.progress)

    if self.generation_callback then
        generation_manager.off_success(self.generation_callback)
        generation_manager.off_failed(self.generation_callback)
    end
end

function state:on_exit(_menu)
    return generation_manager.get_state() ~= 1
end

function state:move(menu, dy)
    self.position.cursor = self.position.cursor + dy
    ---@diagnostic disable-next-line: undefined-field
    local selection = at[self.position.cursor]
    if selection == nil then
        self.position.cursor = dy < 0 and #at or 1
        selection = at[self.position.cursor]
    end
    menu:set_cursor_pos(selection[1], selection[2] >= 0 and selection[2] or (menu.menu.Bounds.Height + selection[2]) - 50)
    play_sound('Menu/Select', menu.input.sound_volume, math.random() * (1/12) - (1/24))
end

local public = {}
function public.new()
    return setmetatable({
        position = { cursor = 1 },
        elements = {
            divider = RogueEssence.Menu.MenuDivider(RogueElements.Loc(10, 0), 1),
            status = create_text('?', 8, 12),
            progress = create_text('?', 128, 12, RogueElements.DirH.Right)
        }
    }, state)
end
return public