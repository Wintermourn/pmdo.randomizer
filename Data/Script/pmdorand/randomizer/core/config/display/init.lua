---@class pmdorand.config.display
---@field title string
---@field display fun(structure: Config.Base, value: any): string

return {
    builder = require 'pmdorand.randomizer.core.config.display.builder'
}