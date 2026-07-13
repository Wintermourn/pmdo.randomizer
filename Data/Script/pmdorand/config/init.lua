---@alias Config.FromTable {[string]: Config.Base|Config.FromTable}

---@class ConfigModule
---@field stat fun(): Config.Stat
---@field matchup_table fun(keying_function: (fun(key: string): boolean)?): Config.MatchupTable
---@field integer fun(default: integer?, minimum: integer?, maximum: integer?): Config.Integer
---@field float fun(default: number?, minimum: number?, maximum: number?, step_size: number?): Config.Floating
---@field dynamic_int fun(default: integer?, minimum: integer?, maximum: integer?): Config.DynamicInteger
---@field percentage fun(default: number?, step_size: number?): Config.Percentage
---@field boolean fun(default: boolean?): Config.Boolean
---@field table fun(entries: {[string]: Config.Base}): Config.Table
---@field option fun(default: any, choices: any[]): Config.Option
local r = setmetatable({}, {
    __index = function(_t, k)
        return require ('pmdorand.config.'.. k)
    end
})

return r