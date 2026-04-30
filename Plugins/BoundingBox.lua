return {
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
    Validate = function(entry)
        local obj = entry.Object;
        if not obj or not obj.Parent then return false end;
        local humanoid = obj:FindFirstChildWhichIsA("Humanoid");
        return humanoid ~= nil and humanoid.Health > 0;
    end;
    UpdateEntry = function(self, entry, math)
        local box = entry.DrawingMemory.Box;
        local minX, minY, _, _, size = math.Get2DBoundingBox(entry.Object);
        if minX == -1 then box.Visible = false; return end;
        box.Visible  = true;
        box.Size     = size;
        box.Position = Vector2.new(minX, minY);
    end;
};
