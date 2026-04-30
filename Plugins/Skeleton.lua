local Bones = {
    { "Head",          "Torso" };
    { "Head",          "UpperTorso" };
    { "Torso",         "HumanoidRootPart" };
    { "UpperTorso",    "LowerTorso" };
    { "LowerTorso",    "HumanoidRootPart" };
    { "Torso",         "Left Arm" };
    { "UpperTorso",    "LeftUpperArm" };
    { "LeftUpperArm",  "LeftLowerArm" };
    { "LeftLowerArm",  "LeftHand" };
    { "Torso",         "Right Arm" };
    { "UpperTorso",    "RightUpperArm" };
    { "RightUpperArm", "RightLowerArm" };
    { "RightLowerArm", "RightHand" };
    { "Torso",         "Left Leg" };
    { "LowerTorso",    "LeftUpperLeg" };
    { "LeftUpperLeg",  "LeftLowerLeg" };
    { "LeftLowerLeg",  "LeftFoot" };
    { "Torso",         "Right Leg" };
    { "LowerTorso",    "RightUpperLeg" };
    { "RightUpperLeg", "RightLowerLeg" };
    { "RightLowerLeg", "RightFoot" };
};

local template = {};
for i in Bones do
    template["Bone_" .. i] = "Line";
end;

return {
    Name = "Skeleton";
    Settings = {
        Enabled      = true;
        Color        = Color3.fromRGB(255, 255, 255);
        Thickness    = 1;
        Transparency = 1;
    };
    MemoryTemplate = template;
    Bindings = nil;
    Validate = function(entry)
        local obj = entry.Object;
        if not obj or not obj.Parent then return false end;
        local humanoid = obj:FindFirstChildWhichIsA("Humanoid");
        return humanoid ~= nil and humanoid.Health > 0;
    end;
    OnSettingChanged = function(self, entry, key, value)
        for i in Bones do
            local line = entry.DrawingMemory["Bone_" .. i];
            if not line then continue end;
            if key == "Color"        then line.Color        = value end;
            if key == "Thickness"    then line.Thickness    = value end;
            if key == "Transparency" then line.Transparency = value end;
        end;
    end;
    UpdateEntry = function(self, entry, math)
        local char = entry.Object;
        for i, bone in Bones do
            local line = entry.DrawingMemory["Bone_" .. i];
            local partA = char:FindFirstChild(bone[1]);
            local partB = char:FindFirstChild(bone[2]);
            if not partA or not partB then line.Visible = false; continue end;
            local screenA, onA = math.GetPartScreenPosition(partA);
            local screenB, onB = math.GetPartScreenPosition(partB);
            if not onA or not onB then line.Visible = false; continue end;
            line.Visible = true;
            line.From    = screenA;
            line.To      = screenB;
        end;
    end;
};
