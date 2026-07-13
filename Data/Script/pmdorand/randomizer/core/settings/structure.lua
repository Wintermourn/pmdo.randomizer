local config = require 'pmdorand.config'

return {
    always_flush = config.boolean(false),
    seeding = {
        propagation_offsets = config.integer(0, math.mininteger, math.maxinteger)
    }
}