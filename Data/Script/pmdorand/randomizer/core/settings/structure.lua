local config = require 'pmdorand.config'

return {
    always_flush = config.boolean(false),
    export_to_mod = config.boolean(false),
    log_spoilers = config.boolean(true),
    enforce_config_limits = config.boolean(false)
}