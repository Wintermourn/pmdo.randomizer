---@class pmdorand.config.display<T>
---@field title string
---@field display fun(structure: Config.Base, value: any, entry: pmdorand.config.entry<T>?): string

return {
    builder = require 'pmdorand.randomizer.core.config.display.builder'
}