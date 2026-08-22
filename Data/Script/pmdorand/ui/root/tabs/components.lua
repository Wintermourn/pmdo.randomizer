local input_type = RogueEssence.FrameInput.InputType

local async = require 'lib.pmdorand.async'
local clipboard = require 'pmdorand.util.clipboard'
local component_registry = require 'pmdorand.randomizer.core.registry' .get 'components'
local configurations = require 'pmdorand.randomizer.cache.configurations'
local configure = require 'pmdorand.ui.configure'
local math_util = require 'pmdorand.util.math'
local play_sound = require 'pmdorand.util.play_sound'
local soft_translate = require 'pmdorand.util.soft_translate'
local text_pool = require 'pmdorand.util.text_pool'

local strings = {
    component_count = soft_translate 'pmdorand:stats.components.count',
    component_span = soft_translate 'pmdorand:stats.components.span',
    nyi = soft_translate 'pmdorand:nyi.short',
    enabled = soft_translate 'pmdorand:enabled',
    disabled = soft_translate 'pmdorand:disabled',
    dynamic = soft_translate 'pmdorand:dynamic'
}

local info = {
    title = STRINGS:FormatKey 'pmdorand:tab/components'
}

local state = {
    info = info,
    position = {cursor = 0, height = 0},
    lines = {base_texts = {}, at = {}}
}
state.__index = state

---todo: update
function state:set_cursor_pos(menu, x, y)
    x, y = (x or 0) + 10, y or 0
    local menu_height = menu.menu.Bounds.Height - 36
    local v = math.floor(y - menu_height / 3 * 2)
    local max = math.maxinteger
    if #self.lines.at > 0 then
        max = self.lines.at[#self.lines.at][2] + 2 - menu_height
    end
    if self.position.height > v then
        if self.position.height - v > menu_height / 3 then
            self.position.height = math.min(max, math.max(0, math.floor(self.position.height - (self.position.height - v - menu_height / 3))))
        end
    elseif y > menu_height / 3 * 2 then
        self.position.height = math.min(max, v)
    end
    menu.elements.cursor.Loc = RogueElements.Loc(x, y + 19 - self.position.height)
end

function state:update_cursor(menu, dy)
    local at = self.lines.at[self.position.cursor]
    if not at then
        local pos = ((dy or 0) > 0) and 1 or #self.lines.at
        at = self.lines.at[pos]
        if not at then
            pos = 1
            at = self.lines.at[1] 
        end
        self.position.cursor = pos
    end
    self:set_cursor_pos(menu, at[1], at[2])
end

function state:create_text(menu)
    local texts, at = {}, {}
    local providers, components, enabled_counts = {}, {}, {}

    local current_components_list, current_counts, enabledness
    for id, component in pairs(component_registry.content.by_key) do
        if components[component.provider_id] == nil then
            providers[#providers+1] = component.provider_id
            current_components_list = {}
            current_counts = {min = 0, max = 0}
            components[component.provider_id] = current_components_list
            enabled_counts[component.provider_id] = current_counts
        else
            current_components_list = components[component.provider_id]
            current_counts = enabled_counts[component.provider_id]
        end
        --[[@cast current_components_list -?]]
        --[[@cast current_counts -?]]

        current_components_list[#current_components_list + 1] = id
        enabledness = configurations.get_master(id).enabled
        if enabledness == true then
            current_counts.min = current_counts.min + 1
            current_counts.max = current_counts.max + 1 
        elseif type(enabledness) == 'number' and enabledness > 0 then
            current_counts.max = current_counts.max + 1
            if enabledness >= 1 then
                current_counts.min = current_counts.min + 1 
            end
        end
    end
    state.components = components

    table.sort(providers, function(a, b)
        return soft_translate('pmdorand/provider:'.. a) < soft_translate('pmdorand/provider:'.. b)
    end)

    local current_height = 0
    local dynamic_text, component_names, provider_enabled_count
    local left, right
    for _, provider_id in ipairs(providers) do
        ---@type table
        component_names = components[provider_id]
        ---@type {min: int, max: int}
        provider_enabled_count = enabled_counts[provider_id]
        table.sort(component_names, function(a, b)
            return soft_translate('pmdorand/component:'.. a) < soft_translate('pmdorand/component:'.. b)
        end)

        if provider_enabled_count.min == provider_enabled_count.max then
            dynamic_text = strings.component_count:format(#component_names, provider_enabled_count.min)
        else
            dynamic_text = strings.component_span:format(#component_names, provider_enabled_count.min, provider_enabled_count.max)
        end

        current_height = current_height + 2
        left = {soft_translate('pmdorand/provider:'.. provider_id), 6, current_height, RogueElements.DirH.Left}
        right = {dynamic_text, -2, current_height, RogueElements.DirH.Right}
        texts[#texts + 1] = left
        texts[#texts + 1] = right
        at[#at + 1] = {0, current_height, type = 'provider', id = provider_id, left = left, right = right}
        current_height = current_height + 12
        for _, component_id in ipairs(component_names) do
            enabledness = configurations.get_master(component_id).enabled

            if enabledness == true then
                dynamic_text = strings.enabled
            elseif enabledness == false then
                dynamic_text = strings.disabled
            elseif type(enabledness) == 'number' then
                dynamic_text = strings.dynamic .. ('[color] (%02d%%)'):format(math_util.round(enabledness * 100))
            end
            if component_registry:get(component_id).not_implemented then
               dynamic_text = string.format("%s %s", strings.nyi, dynamic_text)
            end

            left = {soft_translate('pmdorand/component:'.. component_id), 10, current_height, RogueElements.DirH.Left}
            right = {dynamic_text, -2, current_height, RogueElements.DirH.Right}
            texts[#texts + 1] = left
            texts[#texts + 1] = right
            at[#at + 1] = {4, current_height, type = 'component', id = component_id, left = left, right = right}
            current_height = current_height + 10
        end
    end

    self.components = components
    self.lines = {
        base_texts = texts,
        at = at
    }
    self:update_text(menu)
end

function state:update_text(menu)
    local base_texts = self.lines.base_texts
    local texts = {}

    local offset
    for i,k in ipairs(base_texts) do
        offset = k[3] - self.position.height
        if offset < 0 then goto continue_update_text end
        texts[#texts + 1] = {k[1], k[2], offset, k[4], k[5]}
        ::continue_update_text::
    end

    text_pool.update_text(
        menu.menu,
        menu.elements.pool,
        texts,
        12, 19, 20, 20
    )
end

function state:entered(menu)
    self:create_text(menu)
    self:update_cursor(menu)
end



local function prompt_enabledness(self, menu, id)
    local promise = async.promise()
    ---@type table
    local actions
    actions = {
        {soft_translate 'pmdorand:set_all_to' .. soft_translate 'pmdorand:enabled', true, function()
            for _, component_id in ipairs(self.components[id]) do
                configurations.get_master(component_id).enabled = true
            end
            promise:resolve()
            _MENU:RemoveMenu()
        end},
        {soft_translate 'pmdorand:set_all_to' .. soft_translate 'pmdorand:dynamic', true, function()
            for _, component_id in ipairs(self.components[id]) do
                configurations.get_master(component_id).enabled = 0.5
            end
            promise:resolve()
            _MENU:RemoveMenu()
        end},
        {soft_translate 'pmdorand:set_all_to' .. soft_translate 'pmdorand:disabled', true, function()
            for _, component_id in ipairs(self.components[id]) do
                configurations.get_master(component_id).enabled = false
            end
            promise:resolve()
            _MENU:RemoveMenu()
        end}
    }

    local function close()
        promise:reject()
        _MENU:RemoveMenu()
    end
    actions[#actions + 1] = {'Cancel', true, close}
    require 'pmdorand.ui.choice' .open(
        function() promise:reject() end,
        table.unpack(actions)
    )
    return promise
end

local function prompt_component(self, menu, id)
    local component = component_registry:get(id)
    configure.open(component, configurations.get_master(id)):on_resolved(function()
        self:create_text(menu)
    end)
end

local function jump_to_previous_provider(self, menu)
    if #self.lines.at > 1 then
        self.position.cursor = (self.position.cursor - 2) % #self.lines.at + 1
    else
        self.position.cursor = 1
        self:update_cursor(menu, -1)
        _GAME:SE 'Menu/Skip'
        self:update_text(menu)
        return
    end

    while self.lines.at[self.position.cursor].type ~= 'provider' do
        self.position.cursor = (self.position.cursor - 2) % #self.lines.at + 1
    end

    self:update_cursor(menu, -1)
    _GAME:SE 'Menu/Skip'
    self:update_text(menu)
end

local function jump_to_next_provider(self, menu)
    if #self.lines.at > 1 then
        self.position.cursor = self.position.cursor % #self.lines.at + 1
    else
        self.position.cursor = 1
        self:update_cursor(menu, 1)
        _GAME:SE 'Menu/Skip'
        self:update_text(menu)
        return
    end

    while self.lines.at[self.position.cursor].type ~= 'provider' do
        self.position.cursor = self.position.cursor % #self.lines.at + 1
    end

    self:update_cursor(menu,-1)
    _GAME:SE 'Menu/Skip'
    self:update_text(menu)
end

local bindings = {
    [input_type.Confirm] = function(self, menu, _i)
        _GAME:SE("Menu/Confirm")
        local at = self.lines.at[self.position.cursor]
        if at == nil then return end
        if at.type == 'component' then
            prompt_component(self, menu, at.id)
        else
            prompt_enabledness(self, menu, at.id):on_resolved(function()
                self:create_text(menu)
            end)
        end
    end,
    [input_type.LeaderSwap1] = jump_to_previous_provider,
    [input_type.LeaderSwap2] = jump_to_next_provider,
    [input_type.LeaderSwapBack] = jump_to_previous_provider,
    [input_type.LeaderSwapForth] = jump_to_next_provider
}

local __Keys = luanet.namespace 'Microsoft.Xna.Framework.Input' .Keys
function state:update(menu, input)
    if input:BaseKeyDown(__Keys.LeftControl) and input:BaseKeyPressed(__Keys.C) then
        local at = self.lines.at[self.position.cursor]
        local key = string.format('pmdorand/%s:%s', at.type, at.id)
        if key == nil then return _GAME:SE 'Menu/Cancel' end
        clipboard.copy_text(key)--SDL.SDL_SetClipboardText(key)
        _GAME:SE 'Menu/Sort'
        return
    end

    for i, k in pairs(bindings) do
        if input:JustPressed(i) then
            menu.elements.cursor:ResetTimeOffset()
            return k(self, menu, input)
        end
    end
end

function state:left(menu) end

function state:move(menu, dy)
    self.position.cursor = self.position.cursor + dy
    self:update_cursor(menu, dy)

    self:update_text(menu)
    play_sound('Menu/Select', menu.input.sound_volume, math.random() * (1/12) - (1/24))
end

local public = {}
function public.new()
    return setmetatable({
        position = {
            cursor = 1,
            height = 0
        }
    }, state)
end
return public