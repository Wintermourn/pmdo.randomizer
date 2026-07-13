return function (text, x, y, horizontal_align, vertical_align)
    if vertical_align and horizontal_align then
        return RogueEssence.Menu.MenuText(
            text, RogueElements.Loc(x, y),
            vertical_align,
            horizontal_align, Color.White);
    elseif horizontal_align then
        return RogueEssence.Menu.MenuText(
            text, RogueElements.Loc(x, y),
            horizontal_align);
    else
        return RogueEssence.Menu.MenuText(
            text, RogueElements.Loc(x, y));
    end
end