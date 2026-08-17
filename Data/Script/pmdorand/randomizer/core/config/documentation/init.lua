---@class pmdorand.config.documentation<T>
---@field title string
---@field documentation fun(structure: Config.Base, value: any, entry: pmdorand.config.entry<T>?): (string[]...)

return {
    builder = require 'pmdorand.randomizer.core.config.documentation.builder'
}