local Plugin = loadstring(game:HttpGet("https://raw.githubusercontent.com/r3qu1r3/EspManager/refs/heads/main/Assets/plugin.lua"))();

local function radarInitialize(self)
    -- Radar background
    local radar = Drawing.new("Circle");
    radar.Radius = 100;
    radar.Position = Vector2.new(200, 200);
    radar.Filled = true;
    radar.Color = Color3.fromRGB(0, 0, 0);
    radar.Thickness = 2;
    radar.Visible = true;

    local radarOutline = Drawing.new("Circle");
    radarOutline.Radius = 100;
    radarOutline.Position = radar.Position;
    radarOutline.Color = Color3.fromRGB(255, 255, 255);
    radarOutline.Visible = true;
    radarOutline.Thickness = 3;

    local centerTriangle = Drawing.new("Triangle");
    centerTriangle.Visible = true;
    centerTriangle.Color = Color3.fromRGB(255, 255, 255);
    centerTriangle.Filled = true;
    centerTriangle.Thickness = 1;

    local triangleSize = 8;
    centerTriangle.PointA = Vector2.new(radar.Position.X, radar.Position.Y - triangleSize);
    centerTriangle.PointB = Vector2.new(radar.Position.X - triangleSize/2, radar.Position.Y + triangleSize/2);
    centerTriangle.PointC = Vector2.new(radar.Position.X + triangleSize/2, radar.Position.Y + triangleSize/2);

    self.Radar = radar;
    self.RadarOutline = radarOutline;
    self.CenterMarker = centerTriangle;
    self.RadarObjects = {};
end

local function radarInstall(self, object)
    local blip = Drawing.new("Circle");
    blip.Radius = 5;
    blip.Filled = true;
    blip.Visible = true;
    object.Drawings.Radar = blip;
end

local function radarUpdate(self, pool, object, target)
    if not pool.Settings.Radar then
        self.Radar.Visible = false;
        self.RadarOutline.Visible = false;
        self.CenterMarker.Visible = false;
        if object.Drawings.Radar then
            object.Drawings.Radar.Visible = false;
        end;
        return;
    end;

    target = (target:IsA("Model") and target.PrimaryPart) or ((target:IsA("BasePart") or target:IsA("MeshPart")) and target);
    if not target then return; end;

    local camera = workspace.CurrentCamera;
    local radar = self.Radar;
    local radarRadius = radar.Radius;
    local radarCenter = radar.Position;

    local flatLook = Vector3.new(camera.CFrame.LookVector.X, 0, camera.CFrame.LookVector.Z).Unit;
    local cameraCFrame = CFrame.new(camera.CFrame.Position, camera.CFrame.Position + flatLook);

    local relative = cameraCFrame:PointToObjectSpace(target.Position);
    local relX, relZ = relative.X, relative.Z;

    local distance = math.sqrt(relX^2 + relZ^2);
    local clampedDist = math.min(distance * (radarRadius / 100), radarRadius);
    local offset = Vector2.new(relX, relZ).Unit * clampedDist;

    local blip = object.Drawings.Radar;
    if blip then
        blip.Position = Vector2.new(radarCenter.X + offset.X, radarCenter.Y + offset.Y);
        blip.Visible = true;
    end;
end

return Plugin.new("Radar", radarInstall, radarInitialize, radarUpdate, 
    { Radar = true },
    { Color = Color3.fromRGB(11, 124, 216), Radius = 5, Filled = true },
    {}
)
