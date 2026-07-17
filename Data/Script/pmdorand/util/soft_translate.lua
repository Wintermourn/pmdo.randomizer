return function(key)
    return (select(2, RogueEssence.Text.Strings:TryGetValue(key))) or key
end