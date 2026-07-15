local service = require 'pmdorand.service'

require 'pmdorand.randomizer.registries' ()
require 'pmdorand.randomizer.providers' .load_all()
require 'pmdorand.randomizer.components' .load_all()

local interlace = require 'lib.pmdorand.interlace'
interlace.dependency_test()
    :at_or_after( interlace.get_mod_by_namespace 'mentoolkit', '2.0' )
    :if_valid(function (info)
        service.dependencies.mtk2 = true

        -- very temporary menu
        require 'mentoolkit' .add_to_menu("top_menu", '[$pmdorand:topmenu]', function ()
            require 'pmdorand.ui' .show() --require 'pmdorand.temp_run'()
        end)
    end)
    :test()

-- test code
local conf = require 'pmdorand.randomizer.cache.configurations'
conf.construct_defaults()
conf.save('test')