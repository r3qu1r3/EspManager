-- Chams plugin (per-limb, R6 + R15 compatible)

local Camera = workspace.CurrentCamera

local EDGES = {
    {1,2},{2,3},{3,4},{4,1}, -- front
    {5,6},{6,7},{7,8},{8,5}, -- back
    {1,5},{2,6},{3,7},{4,8}, -- sides
}

-- Parts to draw chams on per rig type
local R6_PARTS = {
    "Head", "Torso",
    "Left Arm", "Right Arm",
    "Left Leg", "Right Leg",
}

local R15_PARTS = {
    "Head",
    "UpperTorso", "LowerTorso",
    "LeftUpperArm", "LeftLowerArm", "LeftHand",
    "RightUpperArm", "RightLowerArm", "RightHand",
    "LeftUpperLeg", "LeftLowerLeg", "LeftFoot",
    "RightUpperLeg", "RightLowerLeg", "RightFoot",
}

-- Build template: 12 edges per part, worst case is R15 (15 parts)
local ALL_PARTS = R15_PARTS -- superset; R6 parts just won't find matches
local template = {}
for _, partName in ALL_PARTS do
    for i in EDGES do
        template[partName .. "_Edge_" .. i] = "Line"
    end
end

local function GetPartCorners(part)
    local cf = part.CFrame
    local s  = part.Size / 2
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

local function HidePartEdges(memory, partName)
    for i in EDGES do
        local line = memory[partName .. "_Edge_" .. i]
        if line then line.Visible = false end
    end
end

local function DrawPartEdges(memory, partName, part, color, thickness, transparency)
    local corners = GetPartCorners(part)

    for i, edge in EDGES do
        local line = memory[partName .. "_Edge_" .. i]
        if not line then continue end

        local a = corners[edge[1]]
        local b = corners[edge[2]]

        local screenA = Camera:WorldToViewportPoint(a)
        local screenB = Camera:WorldToViewportPoint(b)

        if screenA.Z < 0 or screenB.Z < 0 then
            line.Visible = false
            continue
        end

        line.From        = Vector2.new(screenA.X, screenA.Y)
        line.To          = Vector2.new(screenB.X, screenB.Y)
        line.Color       = color
        line.Thickness   = thickness
        line.Transparency = transparency
        line.Visible     = true
    end
end

-- Detect rig type by checking for a known R15-only part
local function GetRigParts(char)
    if char:FindFirstChild("UpperTorso") then
        return R15_PARTS
    else
        return R6_PARTS
    end
end

return {
    Name = "Chams";

    MemoryTemplate = template;

    Bindings = nil;

    Settings = {
        Enabled      = true;
        Color        = Color3.fromRGB(255, 60, 60);
        Thickness    = 1;
        Transparency = 1;
    };

    Validate = function(entry)
        local obj = entry.Object
        if not obj or not obj.Parent then return false end
        local humanoid = obj:FindFirstChildWhichIsA("Humanoid")
        return humanoid ~= nil and humanoid.Health > 0
    end;

    OnSettingChanged = function(self, entry, key, value)
        for _, partName in ALL_PARTS do
            for i in EDGES do
                local line = entry.DrawingMemory[partName .. "_Edge_" .. i]
                if not line then continue end
                if key == "Color"        then line.Color        = value end
                if key == "Thickness"    then line.Thickness    = value end
                if key == "Transparency" then line.Transparency = value end
            end
        end
    end;

    UpdateEntry = function(self, entry, mathFns)
        local char     = entry.Object
        local memory   = entry.DrawingMemory
        local rigParts = GetRigParts(char)
        local rigSet   = {}
        for _, n in rigParts do rigSet[n] = true end

        local color        = self.Settings.Color
        local thickness    = self.Settings.Thickness
        local transparency = self.Settings.Transparency

        -- Draw boxes for parts that exist in this rig
        for _, partName in ALL_PARTS do
            local part = char:FindFirstChild(partName)
            if part and rigSet[partName] then
                DrawPartEdges(memory, partName, part, color, thickness, transparency)
            else
                HidePartEdges(memory, partName)
            end
        end
    end;
}
