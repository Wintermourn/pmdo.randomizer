local config = require 'pmdorand.config'

return {
    personal = {
        default_name = config.null() | config.string(''),
        always_flush = config.boolean(false),
        export_to_mod = config.boolean(false),
        log_spoilers = config.boolean(true)
    },
    public = {
        enforce_config_limits = config.boolean(false)
    }
}