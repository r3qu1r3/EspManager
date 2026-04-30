-- Chams plugin
-- Draws filled bounding-box quads over each character using Lines to fake 3D chams.

local Camera = workspace.CurrentCamera

-- 8 corners of a bounding box, 12 edges
local EDGES = {
    {1,2},{2,3},{3,4},{4,1}, -- front face
    {5,6},{6,7},{7,8},{8,5}, -- back face
    {1,5},{2,6},{3,7},{4,8}, -- connecting edges
}

local template = {}
for i in EDGES do
    template["Edge_" .. i] = "Line"
end

local function GetBoxCorners(char)
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return nil end

    local cf, size = char:GetBoundingBox()
    local s = size / 2

    return {
        (cf * CFrame.new(-s.X, -s.Y,  s.Z)).Position,
        (cf * CFrame.new(-s.X,  s.Y,  s.Z)).Position,
        (cf * CFrame.new( s.X,  s.Y,  s.Z)).Position,
        (cf * CFrame.new( s.X, -s.Y,  s.Z)).Position,
        (cf * CFrame.new(-s.X, -s.Y, -s.Z)).Position,
        (cf * CFrame.new(-s.X,  s.Y, -s.Z)).Position,
        (cf * CFrame.new( s.X,  s.Y, -s.Z)).Position,
        (cf * CFrame.new( s.X, -s.Y, -s.Z)).Position,
    }
end

return {
    Name = "Chams";

    MemoryTemplate = template;

    Bindings = nil;

    Settings = {
        Enabled      = true;
        Color        = Color3.fromRGB(255, 60, 60);
        Thickness    = 2;
        Transparency = 1;
    };

    Validate = function(entry)
        local obj = entry.Object
        if not obj or not obj.Parent then return false end
        local humanoid = obj:FindFirstChildWhichIsA("Humanoid")
        return humanoid ~= nil and humanoid.Health > 0
    end;

    OnSettingChanged = function(self, entry, key, value)
        for i in EDGES do
            local line = entry.DrawingMemory["Edge_" .. i]
            if not line then continue end
            if key == "Color"        then line.Color        = value end
            if key == "Thickness"    then line.Thickness    = value end
            if key == "Transparency" then line.Transparency = value end
        end
    end;

    UpdateEntry = function(self, entry, mathFns)
        local char   = entry.Object
        local corners = GetBoxCorners(char)

        if not corners then
            for i in EDGES do
                local line = entry.DrawingMemory["Edge_" .. i]
                if line then line.Visible = false end
            end
            return
        end

        for i, edge in EDGES do
            local line = entry.DrawingMemory["Edge_" .. i]
            if not line then continue end

            local a3 = corners[edge[1]]
            local b3 = corners[edge[2]]

            local screenA, onA = Camera:WorldToViewportPoint(a3)
            local screenB, onB = Camera:WorldToViewportPoint(b3)

            -- Hide edge if either end is behind the camera
            if screenA.Z < 0 or screenB.Z < 0 then
                line.Visible = false
                continue
            end

            line.From        = Vector2.new(screenA.X, screenA.Y)
            line.To          = Vector2.new(screenB.X, screenB.Y)
            line.Color       = self.Settings.Color
            line.Thickness   = self.Settings.Thickness
            line.Transparency = self.Settings.Transparency
            line.Visible     = true
        end
    end;
}
