---@alias Config.FromTable {[string]: Config.Base|Config.FromTable}

---@class ConfigModule
---@field any fun(default: Config.Base, ...: Config.Base): Config.Any
---@field boolean fun(default: boolean|number?): Config.Boolean
---@field dynamic_int fun(default: integer?, minimum: integer?, maximum: integer?): Config.DynamicInteger
---@field feature fun(entries: Config.FromTable, enabled: boolean|number?, randomization_chance: number?, sorted_keys: string[]?): Config.Feature
---@field float fun(default: number?, minimum: number?, maximum: number?, step_size: number?): Config.Floating
---@field integer fun(default: integer?, minimum: integer?, maximum: integer?, jump_size: integer?): Config.Integer
---@field matchup_table fun(keying_function: (fun(key: string): boolean)?): Config.MatchupTable
---@field null fun(): Config.Null
---@field option fun(default: any, choices: any[]): Config.Option
---@field percentage fun(default: number?, step_size: number?): Config.Percentage
---@field stat fun(): Config.Stat
---@field string fun(default: string?, illegal_characters: string?): Config.String
---@field table fun(entries: Config.FromTable): Config.Table
---@field custom_display fun(setting: Config.Base, display_method: fun(value: any): string): Config.CustomDisplay
local r = setmetatable({}, {
    __index = function(_t, k)
        return require ('pmdorand.config.'.. k)
    end
})

return r