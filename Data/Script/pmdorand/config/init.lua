---@alias Config.FromTable {[string]: Config.Base|Config.FromTable}

---@generic T
---@class ConfigModule
---Accepts any value of the following types. The first specified is used as the default.
---<br>Alternatively, you can use the bitwise or operator to combine values into this type. (`default | alternative1 | alternative2`)
---@field any fun(default: Config.Base, ...: Config.Base): Config.Any
---Accepts true or false. Can be configured to accept "boolable" numbers (0.0 - 1.0).
---@field boolean fun(default: boolean|number?): Config.Boolean
---Wraps another config value, modifying the bitwise or operator to create a `Config.Variant` instead.
---@field case fun(key: string, value: Config.Base): Config.Case
---Wraps another config value, changing how it is displayed in the in-game editor.
---@field custom_display fun(setting: Config.Base, display_method: fun(value: any): string): Config.CustomDisplay
---@field dynamic_int fun(default: integer?, minimum: integer?, maximum: integer?): Config.DynamicInteger
---Wraps a table with enabled and randomization chance values, as well as option key sorting. Good for features that can be turned on or off.
---@field feature fun(entries: Config.FromTable, enabled: boolean|number?, randomization_chance: number?, sorted_keys: string[]?): Config.Feature
---Accepts decimal numbers.
---@field float fun(default: number?, minimum: number?, maximum: number?, step_size: number?): Config.Floating
---Accepts integer numbers.
---@field integer fun(default: integer?, minimum: integer?, maximum: integer?, jump_size: integer?): Config.Integer
---Accepts objects with specific, dynamic keys.
---@field matchup_table fun(keying_function: (fun(key: string): boolean)?): Config.MatchupTable
---Only accepts null. Useful for placeholding.
---@field null fun(): Config.Null
---Only accepts specified values. The default value should match an entry in the list.
---@field option fun(default: any, choices: any[]): Config.Option
---Accepts numbers between 0.0 (0%) and 1.0 (100%).
---@field percentage fun(default: number?, step_size: number?): Config.Percentage
---Holds data for weighted stat randomization.
---@field stat fun(min: int?, max: int?, range_mode: Config.Stat.RangeMode?, range_value: number?, pull_strength: number?): Config.Stat
---Accepts strings. Specific characters can be excluded, which will be placed in a pattern.
---@field string fun(default: string?, illegal_characters: string?): Config.String
---Accepts a table of config values. Useful for organization.
---@field table fun(entries: Config.FromTable): Config.Table
---Similar to `Config.Any`, except the type has to be explicitly defined using keys. `default` must be a key in the variants table.
---@field variant fun(default: T, variants: {[T]: Config.Base}): Config.Variant
local r = setmetatable({}, {
    __index = function(_t, k)
        return require ('pmdorand.config.'.. k)
    end
})

return r