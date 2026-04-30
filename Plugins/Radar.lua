-- Radar plugin
-- Draws a minimap-style radar in the corner showing enemy positions relative to the local player.
-- The radar has no MemoryTemplate/DrawingMemory because it manages its own drawings globally
-- rather than per-entry. It overrides UpdateEntry to be a no-op and handles everything itself.

local Camera    = workspace.CurrentCamera;
local LocalPlr  = game.Players.LocalPlayer;

local SIZE      = 150;   -- radar circle diameter in pixels
local RANGE     = 100;   -- stud radius shown on radar
local DOT_SIZE  = 5;     -- enemy dot diameter

-- Radar-level drawings (not per-entry, created once)
local Background = Drawing.new("Circle");
Background.Filled      = true;
Background.Color       = Color3.fromRGB(20, 20, 20);
Background.Transparency = 0.5;
Background.Radius      = SIZE / 2;
Background.Visible     = false;

local Border = Drawing.new("Circle");
Border.Filled       = false;
Border.Color        = Color3.fromRGB(255, 255, 255);
Border.Transparency = 0.8;
Border.Thickness    = 1;
Border.Radius       = SIZE / 2;
Border.Visible      = false;

local PlayerDot = Drawing.new("Circle");
PlayerDot.Filled       = true;
PlayerDot.Color        = Color3.fromRGB(0, 200, 255);
PlayerDot.Transparency = 1;
PlayerDot.Radius       = DOT_SIZE / 2;
PlayerDot.Visible      = false;

-- Pool of dots, grown as needed
local DotPool: { any } = {};

local function GetDot(index: number)
    if not DotPool[index] then
        local dot = Drawing.new("Circle");
        dot.Filled       = true;
        dot.Color        = Color3.fromRGB(255, 60, 60);
        dot.Transparency = 1;
        dot.Radius       = DOT_SIZE / 2;
        dot.Visible      = false;
        DotPool[index]   = dot;
    end;
    return DotPool[index];
end;

return {
    Name = "Radar";
    -- Radar has no per-entry drawings so MemoryTemplate is empty
    MemoryTemplate = {};
    Bindings = nil;
    Settings = {
        Enabled      = true;
        -- Corner: "topright" | "topleft" | "bottomright" | "bottomleft"
        Corner       = "topright";
        Margin       = 20;
        Range        = RANGE;
        Size         = SIZE;
        Color        = Color3.fromRGB(255, 60, 60);
        Transparency = 1;
    };
    -- No per-entry validation needed — radar doesn't care about individual entries
    Validate = nil;
    OnSettingChanged = function(self, entry, key, value)
        -- No per-entry drawings to update
    end;
    UpdateEntry = function(self, registry, math)
        -- UpdateEntry is called per-entry by the manager but radar works globally.
        -- The actual radar draw happens in a RunService connection set up below.
        -- This is intentionally a no-op.
    end;
    -- Called once by Example.lua after pushing the plugin to start the radar loop
    Start = function(self, GetRegistry: () -> { any })
        local RunService = game:GetService("RunService");

        RunService.RenderStepped:Connect(function()
            if not self.Settings.Enabled then
                Background.Visible = false;
                Border.Visible     = false;
                PlayerDot.Visible  = false;
                for _, dot in DotPool do dot.Visible = false end;
                return;
            end;

            local viewport = Camera.ViewportSize;
            local margin   = self.Settings.Margin or 20;
            local size     = self.Settings.Size   or SIZE;
            local radius   = size / 2;

            -- Position radar based on Corner setting
            local cx, cy;
            local corner = self.Settings.Corner or "topright";
            if corner == "topright" then
                cx = viewport.X - margin - radius;
                cy = margin + radius;
            elseif corner == "topleft" then
                cx = margin + radius;
                cy = margin + radius;
            elseif corner == "bottomright" then
                cx = viewport.X - margin - radius;
                cy = viewport.Y - margin - radius;
            else -- bottomleft
                cx = margin + radius;
                cy = viewport.Y - margin - radius;
            end;

            local center = Vector2.new(cx, cy);

            Background.Position     = center;
            Background.Radius       = radius;
            Background.Visible      = true;

            Border.Position         = center;
            Border.Radius           = radius;
            Border.Visible          = true;

            PlayerDot.Position      = center;
            PlayerDot.Visible       = true;

            local localChar = LocalPlr.Character;
            local localRoot = localChar and localChar:FindFirstChild("HumanoidRootPart") :: BasePart?;

            local registry = GetRegistry();
            local dotIndex = 0;

            for _, entry in registry do
                local char = entry.Object :: Model;
                if char == localChar then continue end;

                local root = char:FindFirstChild("HumanoidRootPart") :: BasePart?;
                if not root or not localRoot then continue end;

                local humanoid = char:FindFirstChildWhichIsA("Humanoid");
                if not humanoid or humanoid.Health <= 0 then continue end;

                local range = self.Settings.Range or RANGE;

                -- World offset from local player to enemy, projected onto XZ plane
                local offset = root.Position - localRoot.Position;
                local dist   = Vector2.new(offset.X, offset.Z).Magnitude;
                if dist > range then continue end;

                -- Rotate offset by camera's Y angle so radar is camera-relative
                local camAngle = -Camera.CFrame.LookVector;
                local angle    = math.atan2(camAngle.X, camAngle.Z);
                local cos, sin = math.cos(angle), math.sin(angle);
                local rx = offset.X * cos - offset.Z * sin;
                local ry = offset.X * sin + offset.Z * cos;

                -- Scale to radar size
                local scale = (radius - DOT_SIZE) / range;
                local dotPos = center + Vector2.new(rx, -ry) * scale;

                -- Clamp to circle edge
                local delta = dotPos - center;
                if delta.Magnitude > radius - DOT_SIZE then
                    dotPos = center + delta.Unit * (radius - DOT_SIZE);
                end;

                dotIndex += 1;
                local dot = GetDot(dotIndex);
                dot.Color        = self.Settings.Color or Color3.fromRGB(255, 60, 60);
                dot.Transparency = self.Settings.Transparency or 1;
                dot.Position     = dotPos;
                dot.Visible      = true;
            end;

            -- Hide unused dots
            for i = dotIndex + 1, #DotPool do
                DotPool[i].Visible = false;
            end;
        end);
    end;
};
