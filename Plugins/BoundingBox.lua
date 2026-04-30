local BoundingBoxPlugin: Plugin = {
    Name = "BoundingBox";
    Settings = {
        Enabled      = true;
        Color        = Color3.fromRGB(255, 255, 255);
        Thickness    = 1;
        Transparency = 1;
    };
    MemoryTemplate = { Box = "Square" };
    Bindings = {
        Color        = { DrawingKey = "Box"; Property = "Color" };
        Thickness    = { DrawingKey = "Box"; Property = "Thickness" };
        Transparency = { DrawingKey = "Box"; Property = "Transparency" };
    };
    UpdateEntry = function(self: Plugin, Entry: RegistryEntry, Math: MathFunctionsType)
        local Box: DrawingObject = Entry.DrawingMemory.Box;
        local MinX, MinY, _, _, Size = Math.Get2DBoundingBox(Entry.Object);

        if MinX == -1 then Box.Visible = false; return end;

        Box.Visible  = true;
        Box.Size     = Size;
        Box.Position = Vector2.new(MinX, MinY);
    end;
};

return BoundingBoxPlugin;
