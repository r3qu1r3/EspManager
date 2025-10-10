--// Services
local Players = game:GetService("Players");
local RunService = game:GetService("RunService");
local Camera = workspace.CurrentCamera;

--// Player reference
local LocalPlayer = Players.LocalPlayer;

--// Utility functions
local function Vec2(x, y)
    return Vector2.new(math.floor(x), math.floor(y));
end

local function Lerp(a, b, t)
    return a + (b - a) * t;
end

local Draw = Drawing.new;

--// Types
type userdata = typeof(Draw("Square"));

type SettingsProfile = {
    BarPadding: number,
    Box3D: boolean,
    CornerBox: boolean,
    Box: boolean,
    Tracer: boolean,
    TopTag: boolean,
    BottomTag: boolean,
    Bars: { 
        Left: boolean,
        Right: boolean,
        Top: boolean,
        Bottom: boolean
    }
};

type DrawingObjects = {
    Box: userdata,
    Tracer: userdata,
    TopTag: userdata,
    BottomTag: userdata,
    Bars: {
        Left: {},
        Right: {},
        Top: {},
        Bottom: {}
    },
    Box3D: {
        Top: userdata,
        Bottom: userdata,
        Left: userdata,
        Right: userdata,
        Front: userdata,
        Back: userdata
    },
    CornerBox: {
        TL: userdata,
        TR: userdata,
        BL: userdata,
        BR: userdata
    }
};

type PoolStyle = {
    Box: { Color: Color3, Thickness: number }?,
    Tracer: { Color: Color3, Thickness: number }?,
    TopTag: { Color: Color3, Size: number, Center: boolean, Outline: boolean, Font: Enum.Font }?,
    Bars: {
        Left: { FillColor: Color3, BackgroundColor: Color3, Thickness: number, BackgroundThickness: number }?,
        Right: { FillColor: Color3, BackgroundColor: Color3, Thickness: number, BackgroundThickness: number }?,
        Top: { FillColor: Color3, BackgroundColor: Color3, Thickness: number, BackgroundThickness: number }?,
        Bottom: { FillColor: Color3, BackgroundColor: Color3, Thickness: number, BackgroundThickness: number }?
    },
    Box3D: { Color: Color3, Thickness: number, Filled: boolean }?,
    BottomTag: { Color: Color3, Size: number, Center: boolean, Outline: boolean, Font: Enum.Font }?,
    CornerBox: { Color: Color3, Thickness: number }?
};

type ObjectData = {
    Instance: Instance,
    Drawings: DrawingObjects
};

--// Default settings
local DefaultSettings: SettingsProfile = {
    BarPadding = 3,
    CornerBox = true,
    Box = false,
    Tracer = false,
    TopTag = true,
    BottomTag = false,
    Bars = {
        Left = true
    }
};

local DefaultPoolStyle: PoolStyle = {
    Box = { Color3 = Color3.new(1, 0, 0), Thickness = 2 },
    Tracer = { Color3 = Color3.new(1, 0, 0), Thickness = 1 },
    TopTag = { Color3 = Color3.new(1, 1, 1), Size = 14, Center = true, Outline = true, Font = Enum.Font.SourceSansBold },
    BottomTag = { Color3 = Color3.new(1, 1, 1), Size = 14, Center = true, Outline = true, Font = Enum.Font.SourceSansBold },
    CornerBox = { Color3 = Color3.new(1, 0, 0), Thickness = 2 },
    Box3D = { Color3 = Color3.new(1, 0, 0), Thickness = 1, Filled = false },
    Bars = {
        Left = { FillColor = Color3.new(0, 1, 0), BackgroundColor = Color3.new(1, 0, 0), Thickness = 4, BackgroundThickness = 4 },
        Right = { FillColor = Color3.new(0, 1, 0), BackgroundColor = Color3.new(1, 0, 0), Thickness = 4, BackgroundThickness = 4 },
        Top = { FillColor = Color3.new(0, 1, 0), BackgroundColor = Color3.new(1, 0, 0), Thickness = 4, BackgroundThickness = 4 },
        Bottom = { FillColor = Color3.new(0, 1, 0), BackgroundColor = Color3.new(1, 0, 0), Thickness = 4, BackgroundThickness = 4 }
    }
};

local DefaultOutlineStyle: PoolStyle = {
    Box = { Color3 = Color3.new(0, 0, 0), Thickness = 4 },
    Tracer = { Color3 = Color3.new(0, 0, 0), Thickness = 2 },
    CornerBox = { Color3 = Color3.new(0, 0, 0), Thickness = 4 },
    BottomBar = { FillColor = Color3.new(0, 0, 0), BackgroundColor = Color3.new(0, 0, 0), Thickness = 6 }
};

local CubeFaces = {
    {1, 2, 3, 4}, -- Front
    {5, 6, 7, 8}, -- Back
    {1, 5, 8, 4}, -- Left
    {2, 6, 7, 3}, -- Right
    {1, 2, 6, 5}, -- Top
    {4, 3, 7, 8}  -- Bottom
};

--// Utility Functions
local function GetBoundingBox(object)
    if not object then return nil; end

    local cf, size;

    if object:IsA("BasePart") or object:IsA("MeshPart") then
        cf = object.CFrame;
        size = object.Size;
    elseif object:IsA("Model") then
        cf, size = object:GetBoundingBox();
    else
        return nil;
    end

    local half = size * 0.5;
    local extents = {
        Vector3.new(-half.X, -half.Y, -half.Z),
        Vector3.new(-half.X, -half.Y, half.Z),
        Vector3.new(-half.X, half.Y, -half.Z),
        Vector3.new(-half.X, half.Y, half.Z),
        Vector3.new(half.X, -half.Y, -half.Z),
        Vector3.new(half.X, -half.Y, half.Z),
        Vector3.new(half.X, half.Y, -half.Z),
        Vector3.new(half.X, half.Y, half.Z)
    };

    local points = {};
    for _, offset in ipairs(extents) do
        local worldPoint = cf.Position + cf:VectorToWorldSpace(offset);
        local screenPoint, visible = Camera:WorldToViewportPoint(worldPoint);
        if visible then
            table.insert(points, Vec2(screenPoint.X, screenPoint.Y));
        end
    end

    if #points == 0 then return nil; end

    local minX, minY = math.huge, math.huge;
    local maxX, maxY = -math.huge, -math.huge;

    for _, p in ipairs(points) do
        minX = math.min(minX, p.X);
        maxX = math.max(maxX, p.X);
        minY = math.min(minY, p.Y);
        maxY = math.max(maxY, p.Y);
    end

    return {
        TopLeft = Vec2(minX, minY),
        BottomRight = Vec2(maxX, maxY),
        Size = Vec2(maxX - minX, maxY - minY)
    };
end

local function Get3DInstanceCorners(object)
    if not object then return nil; end

    local cframe, size;
    
    if object:IsA("Model") and object.PrimaryPart then
        cframe, size = object:GetBoundingBox();
    elseif object:IsA("BasePart") or object:IsA("MeshPart") then
        cframe = object.CFrame;
        size = object.Size;
    else
        return nil;
    end

    local X, Y, Z = size.X / 2, size.Y / 2, size.Z / 2;
    return {
        cframe * CFrame.new(-X, Y, Z),   -- Top left front
        cframe * CFrame.new(X, Y, Z),    -- Top right front
        cframe * CFrame.new(X, -Y, Z),   -- Bottom right front
        cframe * CFrame.new(-X, -Y, Z),  -- Bottom left front
        cframe * CFrame.new(-X, Y, -Z),  -- Top left back
        cframe * CFrame.new(X, Y, -Z),   -- Top right back
        cframe * CFrame.new(X, -Y, -Z),  -- Bottom right back
        cframe * CFrame.new(-X, -Y, -Z)  -- Bottom left back
    };
end

local function RemoveDrawings(drawings)
    if not drawings then return; end
    
    for _, drawing in pairs(drawings) do
        if typeof(drawing) == "table" then
            RemoveDrawings(drawing);
        else
            drawing:Remove();
        end
    end
end

local function ChangeDrawingProperties(drawings, properties)
    if not drawings or not properties then return; end

    if typeof(drawings) == "userdata" then
        for prop, val in pairs(properties) do
            drawings[prop] = val;
        end
        return;
    end

    for _, drawing in pairs(drawings) do
        if typeof(drawing) == "table" then
            ChangeDrawingProperties(drawing, properties);
        else
            for prop, val in pairs(properties) do
                if drawing[prop] ~= nil then
                    drawing[prop] = val;
                end
            end
        end
    end
end

local function ApplyBars(drawings, props)
    for position, barProps in pairs(props) do
        local bar = drawings[position];
        if not bar then continue; end

        local back, fill = bar[1], bar[2];
        if back then
            back.Color = barProps.BackgroundColor or Color3.new(0, 0, 0);
            back.Thickness = barProps.BackgroundThickness or (barProps.Thickness or 4);
        end
        
        if fill then
            fill.Color = barProps.FillColor or Color3.new(0, 1, 0);
            fill.Thickness = barProps.Thickness or 4;
        end
    end
end

local function ApplyStyleToObjects(objects, styleTable, drawingsField)
    for name, props in pairs(styleTable) do
        for _, obj in pairs(objects) do
            local drawings = obj[drawingsField][name];
            if not drawings then continue; end

            if name == "Bars" then
                ApplyBars(drawings, props);
            else
                ChangeDrawingProperties(drawings, props);
            end
        end
    end
end

--// Object Class
local Object = {};
Object.__index = Object;

function Object.new(instance)
    local drawings = {
        Box = Draw("Square"),
        Tracer = Draw("Line"),
        BottomTag = Draw("Text"),
        TopTag = Draw("Text"),
        CornerBox = {
            Draw("Line"), Draw("Line"), Draw("Line"), Draw("Line"),
            Draw("Line"), Draw("Line"), Draw("Line"), Draw("Line")
        }, 
        Box3D = {
            Draw("Quad"), Draw("Quad"),
            Draw("Quad"), Draw("Quad"),
            Draw("Quad"), Draw("Quad")
        },
        Bars = { 
            Top = { Draw("Square"), Draw("Square") },
            Bottom = { Draw("Square"), Draw("Square") },
            Left = { Draw("Square"), Draw("Square") },
            Right = { Draw("Square"), Draw("Square") }
        }
    };

    local drawingOutlines = {
        Box = Draw("Square"),
        Tracer = Draw("Line"),
        CornerBox = {
            Draw("Line"), Draw("Line"), Draw("Line"), Draw("Line"),
            Draw("Line"), Draw("Line"), Draw("Line"), Draw("Line")
        }
    };

    ChangeDrawingProperties(drawingOutlines, { ZIndex = 0 });
    ChangeDrawingProperties(drawings.Bars, { Filled = true });

    return setmetatable({
        Instance = instance,
        Drawings = drawings,
        DrawingOutlines = drawingOutlines
    }, Object);
end

function Object:ChangeVisibility(visible)
    ChangeDrawingProperties(self.Drawings, { Visible = visible }); 
    ChangeDrawingProperties(self.DrawingOutlines, { Visible = visible });
    ChangeDrawingProperties(self.DrawingDependents, { Visible = visible });
end

function Object:Update(settings, pool)
    local target = self.Instance;
    if not (target and target:IsDescendantOf(workspace)) then
        return self:Destroy();
    end

    local box = GetBoundingBox(target);
    if not box then
        self:ChangeVisibility(false);
        for _, plugin in pairs(pool.Plugins) do 
            plugin:Update(pool, self, target, box);
        end;
        return;
    end

    for _, plugin in pairs(pool.Plugins) do 
        plugin:Update(pool, self, target, box);
    end

    --// 3D Box 
    if settings.Box3D and self.Drawings.Box3D then
        local corners = Get3DInstanceCorners(target);
        if corners then
            for faceIndex, indices in ipairs(CubeFaces) do
                local face = self.Drawings.Box3D[faceIndex];
                local a, b, c, d = corners[indices[1]], corners[indices[2]], corners[indices[3]], corners[indices[4]];

                local a2D = Camera:WorldToViewportPoint(a.Position);
                local b2D = Camera:WorldToViewportPoint(b.Position);
                local c2D = Camera:WorldToViewportPoint(c.Position);
                local d2D = Camera:WorldToViewportPoint(d.Position);

                face.PointA = Vector2.new(a2D.X, a2D.Y);
                face.PointB = Vector2.new(b2D.X, b2D.Y);
                face.PointC = Vector2.new(c2D.X, c2D.Y);
                face.PointD = Vector2.new(d2D.X, d2D.Y);
                face.Visible = true;
            end
        end
    end

    --// Box
    if settings.Box then
        local b = self.Drawings.Box;
        local bo = self.DrawingOutlines.Box;
        b.Visible = true;
        b.Position, b.Size = box.TopLeft, box.Size;
        bo.Visible = true;
        bo.Position, bo.Size = b.Position, b.Size;
    end

    --// Corner Box
    local lines = self.Drawings.CornerBox;
    if settings.CornerBox then
        local x, y, w, h = box.TopLeft.X, box.TopLeft.Y, box.Size.X, box.Size.Y;
        local len = math.min(w, h) * 0.25;

        --// Corner Geometry
        local data = {
            {x, y, len, 0, 0, len},        -- TL
            {x + w, y, -len, 0, 0, len},   -- TR
            {x, y + h, len, 0, 0, -len},   -- BL
            {x + w, y + h, -len, 0, 0, -len} -- BR
        };

        for i, d in ipairs(data) do
            local lx, ly, dx, dy, vx, vy = table.unpack(d);

            local l1, l2 = lines[i * 2 - 1], lines[i * 2];
            local lo1, lo2 = self.DrawingOutlines.CornerBox[i * 2 - 1], self.DrawingOutlines.CornerBox[i * 2];

            l1.From, l1.To = Vec2(lx, ly), Vec2(lx + dx, ly + dy);
            l2.From, l2.To = Vec2(lx, ly), Vec2(lx + vx, ly + vy);
            lo1.From, lo1.To = l1.From, l1.To;
            lo2.From, lo2.To = l2.From, l2.To;

            l1.Visible, l2.Visible = true, true;
            lo1.Visible, lo2.Visible = true, true;
        end
    end

    --// Tracer 
    if settings.Tracer then
        local t = self.Drawings.Tracer;
        local to = self.DrawingOutlines.Tracer;

        t.Visible = true;
        t.From = Vec2(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y);
        t.To = Vec2(box.BottomRight.X - box.Size.X / 2, box.BottomRight.Y);

        to.Visible = true;
        to.From = t.From;
        to.To = t.To;
    end

    --// Calculate tag offsets
    local topTagOffset, bottomTagOffset = 0, 0;

    do
        local topBar = settings.Bars.Top;
        local bottomBar = settings.Bars.Bottom;
        local barStyles = pool.Style.Bars or {};

        if topBar then
            local style = barStyles.Top or {};
            topTagOffset = (style.Thickness or 4) + 6;
        end
        
        if bottomBar then
            local style = barStyles.Bottom or {};
            bottomTagOffset = (style.Thickness or 4) + 6;
        end
    end

    --// Top Tag
    if settings.TopTag then
        local topTag = self.Drawings.TopTag;
        topTag.Visible = true;
        topTag.Text = pool:GetTagData(0, target) or "N/A";
        topTag.Position = Vec2(
            box.TopLeft.X + box.Size.X / 2,
            box.TopLeft.Y - 15 - topTagOffset
        );
    end

    --// Bottom Tag
    if settings.BottomTag then
        local bottomTag = self.Drawings.BottomTag;
        bottomTag.Visible = true;
        bottomTag.Text = pool:GetTagData(1, target) or "N/A";
        
        local yOffset = 2 + (bottomTagOffset > 0 and (bottomTagOffset - 4) or 0);
        
        bottomTag.Position = Vec2(
            box.TopLeft.X + box.Size.X / 2,
            box.BottomRight.Y + yOffset
        );
    end

    --// Bars
    for position, enabled in pairs(settings.Bars) do
        if not enabled then continue; end

        local bar = self.Drawings.Bars[position];
        local fill, back = bar[2], bar[1];

        local dataFunc = pool["Get" .. position .. "BarData"];
        local data = dataFunc and dataFunc(pool, target) or 100;
        data = math.clamp(data, 0, 100);

        local barStyle = pool.Style.Bars and pool.Style.Bars[position] or {};
        local thickness = barStyle.Thickness or 4;
        local fillColor = barStyle.FillColor or Color3.new(0, 1, 0);
        local backgroundColor = barStyle.BackgroundColor or Color3.new(0, 0, 0);
        local padding = settings.BarPadding or 3;
        local outlineSize = barStyle.OutlineSize or 1;

        local origin, size, vertical;

        if position == "Left" then
            origin = Vec2(box.TopLeft.X - (thickness + padding), box.TopLeft.Y);
            size = Vec2(thickness, box.Size.Y);
            vertical = true;
        elseif position == "Right" then
            origin = Vec2(box.BottomRight.X + padding, box.TopLeft.Y);
            size = Vec2(thickness, box.Size.Y);
            vertical = true;
        elseif position == "Top" then
            origin = Vec2(box.TopLeft.X, box.TopLeft.Y - (thickness + padding));
            size = Vec2(box.Size.X, thickness);
            vertical = false;
        elseif position == "Bottom" then
            origin = Vec2(box.BottomRight.X - box.Size.X, box.BottomRight.Y + padding);
            size = Vec2(box.Size.X, thickness);
            vertical = false;
        end
        
        if not origin then continue; end

        local fillSize, fillPos;
        if vertical then
            local fillHeight = size.Y * (data / 100);
            fillSize = Vec2(size.X - outlineSize * 2, fillHeight - outlineSize * 2);
            fillPos = Vec2(origin.X + outlineSize, origin.Y + (size.Y - fillHeight) + outlineSize);
        else
            local fillWidth = size.X * (data / 100);
            fillSize = Vec2(fillWidth - outlineSize * 2, size.Y - outlineSize * 2);
            fillPos = Vec2(origin.X + outlineSize, origin.Y + outlineSize);
        end

        back.Visible = true;
        back.Position = origin;
        back.Size = size;

        fill.Visible = true;
        fill.Position = fillPos;
        fill.Size = fillSize;
    end
end

function Object:Destroy()
    RemoveDrawings(self.Drawings);
    RemoveDrawings(self.DrawingOutlines);
    RemoveDrawings(self.DrawingDependents);
end

--// Pool Class
local Pool = { __pools = {} };
Pool.__index = Pool;

function Pool.new(settings, style, outlineStyle)
    local self = setmetatable({
        Settings = settings or DefaultSettings,
        Style = style or DefaultPoolStyle,
        OutlineStyle = outlineStyle or DefaultOutlineStyle,
        Objects = {},
        Plugins = {}
    }, Pool);

    table.insert(Pool.__pools, self);
    return self;
end

function Pool:Add(instance)
    if self.Objects[instance] then return; end
    
    local newObject = Object.new(instance);
    for _, plugin in pairs(self.Plugins) do 
        plugin:Install(newObject);
    end
    
    self.Objects[instance] = newObject;
end

function Pool:Remove(instance)
    local object = self.Objects[instance];
    if not object then return; end
    
    object:Destroy();
    self.Objects[instance] = nil;
end

function Pool:Clear()
    for instance in pairs(self.Objects) do
        self:Remove(instance);
    end
end

function Pool:ApplyStyle(style, outlineStyle)
    self.Style = style;
    self.OutlineStyle = outlineStyle;

    ApplyStyleToObjects(self.Objects, style, "Drawings");
    if outlineStyle then
        ApplyStyleToObjects(self.Objects, outlineStyle, "DrawingOutlines");
    end
end

function Pool:EditStyle(partialStyle, outlineStyle)
    for name, props in pairs(partialStyle) do
        self.Style[name] = props;
    end

    ApplyStyleToObjects(self.Objects, partialStyle, "Drawings");

    if outlineStyle then
        self.OutlineStyle = self.OutlineStyle or {};
        for name, props in pairs(outlineStyle) do
            self.OutlineStyle[name] = props;
        end
        ApplyStyleToObjects(self.Objects, outlineStyle, "DrawingOutlines");
    end
end

function Pool:Update()
    for instance, object in pairs(self.Objects) do
        if not instance:IsDescendantOf(workspace) then
            self:Remove(instance);
        else
            object:Update(self.Settings, self);
        end
    end
end

function Pool.UpdateAll()
    for _, pool in ipairs(Pool.__pools) do
        pool:Update();
    end
end

function Pool:InstallPlugin(plugin)
    --// Plugin Settings & Styles 
    for setting, value in pairs(plugin.Settings) do 
        self.Settings[setting] = value;
    end

    for _, style in pairs(plugin.Style) do 
        self.Style[style] = plugin.Style[style];
    end

    for _, style in pairs(plugin.OutlineStyle) do 
        self.OutlineStyle[style] = plugin.OutlineStyle[style];
    end

    self:EditStyle(plugin.Style, plugin.OutlineStyle);

    if (plugin.Initialize) then 
        plugin:Initialize(); 
    end;

    table.insert(self.Plugins, plugin);
end

--// Pool Hooks 
function Pool:GetTagData(pos, instance)
    if pos == 0 then 
        return instance.Name;
    elseif pos == 1 then
        local targetPos = instance.PrimaryPart and instance.PrimaryPart.Position or instance.Position;
        local dist = (Camera.CFrame.Position - targetPos).Magnitude;
        return string.format("%dft", dist);
    end
end

function Pool:GetLeftBarData(instance)
    return Lerp(0, 100, math.abs(math.sin(tick()))) * 2;
end

function Pool:GetTopBarData(instance)
    return Lerp(0, 100, math.abs(math.cos(tick()))) * 2;
end

function Pool:GetRightBarData(instance)
    return Lerp(0, 100, math.abs(math.sin(tick() * 0.5))) * 2;
end

function Pool:GetBottomBarData(instance)
    return Lerp(0, 100, math.abs(math.cos(tick() * 0.5))) * 2;
end

return {
    Pool = Pool, 
    Object = Object    
}
