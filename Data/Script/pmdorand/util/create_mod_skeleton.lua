local mod_xml
do
    local segments = {
        "<Namespace>%s</Namespace>",
        "<Name>%s</Name>",
        "<Author>PMDO Randomizer \u{E08A}</Author>",
        "<Description>%s</Description>",
        '',
        "<UUID>%s</UUID>",
        '',
        "<Version>%s</Version>",
        "<GameVersion>%s</GameVersion>",
        "<ModType>Mod</ModType>"
    }
    mod_xml = string.format('<Header>\n\t%s\n</Header>', table.concat(segments, '\n\t'))
end

local IO = luanet.namespace 'System.IO'
local configuration = require 'pmdorand.randomizer.cache.configurations'
return function(name)
    local id = string.format("pmdorand_%d", os.time())
    local mod_root = IO.Path.Combine(RogueEssence.PathMod.APP_PATH, RogueEssence.PathMod.MODS_FOLDER, id)
    IO.Directory.CreateDirectory(mod_root)
    IO.Directory.CreateDirectory(IO.Path.Combine(mod_root, _DATA.DATA_PATH))
    IO.File.WriteAllText(
        IO.Path.Combine(mod_root, 'Mod.xml'),
        string.format(
            mod_xml,
            id,
            name ..' \u{E08A}',
            STRINGS:FormatKey ('pmdorand:genmod_description', os.date '%c'),
            luanet.import_type 'System.Guid' .NewGuid():ToString(),
            os.date '%Y.%m.%d.%H',
            RogueEssence.Versioning.GetVersion():ToString()
        )
    )
    configuration.export(mod_root, 'config', {
        date = os.date '%c'
    })

    return id
end