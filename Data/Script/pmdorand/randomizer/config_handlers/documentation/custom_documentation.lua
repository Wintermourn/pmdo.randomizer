local documentation = require 'pmdorand.randomizer.core.config.documentation'

return documentation.builder() --[[@as ConfigDocumentationBuilder<Config.CustomDocumentation>]]
    :with_title 'Config.CustomDocumentation'
    :with_documentation(function(s, v, e)
        return s.method(s, v, e)
    end)
    :register()