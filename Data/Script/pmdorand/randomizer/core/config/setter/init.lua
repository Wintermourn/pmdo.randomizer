---@class pmdorand.config.setter<T>
---@field title string
---@field select (fun(entry: pmdorand.config.entry): boolean?)?
---@field move (fun(entry: pmdorand.config.entry, input: RogueEssence.InputManager, delta: int): boolean?)?

---@class pmdorand.config.entry<T>
---@field keys pmdorand.config.entry.keys
---@field texts {[1]: string, [2]: int, [3]: int, [4]: RogueElements.DirH?, [5]: RogueElements.DirV?}[]
---@field setting T
---@field value any
---@field value_pointer {[1]: table, [2]: any} Provides the owner of the config value, to allow changing it more permanently in case of non-object values.
---@field translation_key string
---@field push fun(entry: pmdorand.config.entry) Moves the menu into this entry.
---@field set fun(entry: pmdorand.config.entry, value: any)
---Updates body texts.
---<br>Since updates are automatically handled after setter calls finish, this is best used if the update has to be deferred for some reason (e.g. showing a prompt).
---@field update_text fun()

---@class pmdorand.config.entry.keys
---@field config string[]|{flat: string}
---@field value string[]|{flat: string}

return {
    builder = require 'pmdorand.randomizer.core.config.setter.builder'
}