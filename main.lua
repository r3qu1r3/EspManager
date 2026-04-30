local Camera = workspace.CurrentCamera;

-- // Types

export type DrawingObject = {
    Visible: boolean;
    Color: Color3;
    Size: Vector2;
    Position: Vector2;
    Thickness: number?;
    Transparency: number?;
    Filled: boolean?;
    From: Vector2?;
    To: Vector2?;
};

export type MemoryTemplate = { [string]: string };
export type DrawingMemory = { [string]: DrawingObject };

export type SettingBinding = {
    DrawingKey: string;
    Property: string;
};

export type PluginSettings = {
    Enabled: boolean;
    Color: Color3?;
    Transparency: number?;
    Thickness: number?;
    [string]: any;
};

export type Plugin = {
    Name: string;
    Settings: PluginSettings;
    Bindings: { [string]: SettingBinding }?;
    MemoryTemplate: MemoryTemplate;
    UpdateEntry: (self: Plugin, entry: RegistryEntry, math: MathFunctionsType) -> ();
    OnSettingChanged: ((self: Plugin, entry: RegistryEntry, key: string, value: any) -> ())?;
};

export type RegistryEntry = {
    Object: Instance;
    DrawingMemory: DrawingMemory;
    Data: { [string]: any };
};

export type ManagerSettings = {
    Plugins: { Plugin }?;
};

export type ESPManagerType = {
    Registry: { RegistryEntry };
    Plugins: { [string]: Plugin };
    new: (settings: ManagerSettings) -> ESPManagerType;
    PushPlugin: (self: ESPManagerType, plugin: string | Plugin) -> ();
    RemovePlugin: (self: ESPManagerType, name: string) -> ();
    SetPluginEnabled: (self: ESPManagerType, name: string, enabled: boolean) -> ();
    SetPluginSetting: (self: ESPManagerType, name: string, key: string, value: any) -> ();
    SetAllEnabled: (self: ESPManagerType, enabled: boolean) -> ();
    PushInstanceToRegistry: (self: ESPManagerType, object: Instance, data: { [string]: any }?) -> number;
    RemoveInstanceFromRegistry: (self: ESPManagerType, object: Instance) -> ();
    UpdateRegistry: (self: ESPManagerType) -> ();
};

export type MathFunctionsType = {
    Get2DBoundingBox: (object: Instance) -> (number, number, number, number, Vector2);
    GetScreenPosition: (object: Instance) -> (Vector2, boolean);
    GetPartScreenPosition: (part: BasePart) -> (Vector2, boolean);
};

-- // Math

local MathFunctions = {};

local function GetMinMaxPointsXYZ(Points: { Vector3 }): (number, number, number, number, Vector2)
    local MinX, MinY, MaxX, MaxY = 1e9, 1e9, -1e9, -1e9;
    local AnyOnScreen = false;

    for _, Point: Vector3 in Points do
        local ScreenPoint, OnScreen = Camera:WorldToViewportPoint(Point);
        if not OnScreen then continue end;
        AnyOnScreen = true;

        if ScreenPoint.X > MaxX then MaxX = ScreenPoint.X end;
        if ScreenPoint.X < MinX then MinX = ScreenPoint.X end;
        if ScreenPoint.Y > MaxY then MaxY = ScreenPoint.Y end;
        if ScreenPoint.Y < MinY then MinY = ScreenPoint.Y end;
    end;

    if not AnyOnScreen then return -1, -1, -1, -1, Vector2.zero end;
    return MinX, MinY, MaxX, MaxY, Vector2.new(MaxX - MinX, MaxY - MinY);
end;

local function Get2DPartBoundingBox(Part: BasePart): (number, number, number, number, Vector2)
    local CF, S = Part.CFrame, Part.Size / 2;
    return GetMinMaxPointsXYZ({
        (CF * CFrame.new(-S.X, -S.Y,  S.Z)).Position;
        (CF * CFrame.new(-S.X,  S.Y,  S.Z)).Position;
        (CF * CFrame.new( S.X, -S.Y,  S.Z)).Position;
        (CF * CFrame.new( S.X,  S.Y,  S.Z)).Position;
        (CF * CFrame.new(-S.X, -S.Y, -S.Z)).Position;
        (CF * CFrame.new(-S.X,  S.Y, -S.Z)).Position;
        (CF * CFrame.new( S.X, -S.Y, -S.Z)).Position;
        (CF * CFrame.new( S.X,  S.Y, -S.Z)).Position;
    });
end;

local function Get2DModelBoundingBox(Model: Model): (number, number, number, number, Vector2)
    local CF, S = Model:GetBoundingBox();
    S = S / 2;
    return GetMinMaxPointsXYZ({
        (CF * CFrame.new(-S.X, -S.Y,  S.Z)).Position;
        (CF * CFrame.new(-S.X,  S.Y,  S.Z)).Position;
        (CF * CFrame.new( S.X, -S.Y,  S.Z)).Position;
        (CF * CFrame.new( S.X,  S.Y,  S.Z)).Position;
        (CF * CFrame.new(-S.X, -S.Y, -S.Z)).Position;
        (CF * CFrame.new(-S.X,  S.Y, -S.Z)).Position;
        (CF * CFrame.new( S.X, -S.Y, -S.Z)).Position;
        (CF * CFrame.new( S.X,  S.Y, -S.Z)).Position;
    });
end;

function MathFunctions.Get2DBoundingBox(Object: Instance): (number, number, number, number, Vector2)
    if Object:IsA("Model") then
        return Get2DModelBoundingBox(Object :: Model);
    elseif Object:IsA("BasePart") then
        return Get2DPartBoundingBox(Object :: BasePart);
    end;
    return -1, -1, -1, -1, Vector2.zero;
end;

function MathFunctions.GetScreenPosition(Object: Instance): (Vector2, boolean)
    local Part: BasePart?;
    if Object:IsA("Model") then
        Part = (Object :: Model).PrimaryPart or (Object :: Model):FindFirstChildWhichIsA("BasePart");
    elseif Object:IsA("BasePart") then
        Part = Object :: BasePart;
    end;
    if not Part then return Vector2.zero, false end;
    local ScreenPoint, OnScreen = Camera:WorldToViewportPoint(Part.Position);
    return Vector2.new(ScreenPoint.X, ScreenPoint.Y), OnScreen;
end;

function MathFunctions.GetPartScreenPosition(Part: BasePart): (Vector2, boolean)
    local ScreenPoint, OnScreen = Camera:WorldToViewportPoint(Part.Position);
    return Vector2.new(ScreenPoint.X, ScreenPoint.Y), OnScreen;
end;

-- // Internal helpers

-- Reads from the raw settings table directly (bypasses proxy) and applies to drawings
local function FlushSettingsToEntry(rawSettings: { [string]: any }, bindings: { [string]: SettingBinding }?, memory: DrawingMemory, onSettingChanged: ((key: string, value: any) -> ())?)
    if bindings then
        for settingKey: string, binding: SettingBinding in bindings do
            local obj: DrawingObject? = memory[binding.DrawingKey];
            local value = rawSettings[settingKey];
            if obj and value ~= nil then
                (obj :: any)[binding.Property] = value;
            end;
        end;
    end;

    -- Also call onSettingChanged for anything not covered by bindings
    if onSettingChanged then
        for key: string, value: any in rawSettings do
            if key == "Enabled" then continue end;
            onSettingChanged(key, value);
        end;
    end;
end;

local function MakeReactiveSettings(
    rawSettings: { [string]: any },
    bindings: { [string]: SettingBinding }?,
    GetRegistry: () -> { RegistryEntry },
    GetPlugin: () -> Plugin
): { [string]: any }
    return setmetatable({}, {
        __index = rawSettings;
        __newindex = function(_, key: string, value: any)
            rawSettings[key] = value;

            local registry = GetRegistry();
            local plugin = GetPlugin();

            if key == "Enabled" then
                for _, entry: RegistryEntry in registry do
                    for drawingKey: string in plugin.MemoryTemplate do
                        local obj: DrawingObject? = entry.DrawingMemory[drawingKey];
                        if obj then obj.Visible = value end;
                    end;
                end;
                return;
            end;

            if bindings and bindings[key] then
                local binding = bindings[key];
                for _, entry: RegistryEntry in registry do
                    local obj: DrawingObject? = entry.DrawingMemory[binding.DrawingKey];
                    if obj then (obj :: any)[binding.Property] = value end;
                end;
                return;
            end;

            if plugin.OnSettingChanged then
                for _, entry: RegistryEntry in registry do
                    plugin:OnSettingChanged(entry, key, value);
                end;
            end;
        end;
    });
end;

-- // Manager

local ESPManager: ESPManagerType = {} :: ESPManagerType;
ESPManager.__index = ESPManager;

function ESPManager.new(ManagerSettings: ManagerSettings): ESPManagerType
    local Manager = setmetatable({
        Registry = {} :: { RegistryEntry };
        Plugins  = {} :: { [string]: Plugin };
    }, ESPManager);

    if ManagerSettings.Plugins then
        for _, plugin: Plugin in ManagerSettings.Plugins do
            Manager:PushPlugin(plugin);
        end;
    end;

    return Manager;
end;

function ESPManager:PushPlugin(LinkOrTable: string | Plugin)
    local plugin: Plugin = (typeof(LinkOrTable) == "string" and loadstring(game:HttpGet(LinkOrTable))()) or (LinkOrTable :: Plugin);
    assert(plugin.Name, "Plugin must have a Name field");

    -- Capture raw before wrapping
    local rawSettings = plugin.Settings;
    local bindings = plugin.Bindings;

    plugin.Settings = MakeReactiveSettings(
        rawSettings,
        bindings,
        function() return self.Registry end,
        function() return plugin end
    );

    for _, entry: RegistryEntry in self.Registry do
        for drawingKey: string, drawingType: string in plugin.MemoryTemplate do
            local obj = Drawing.new(drawingType);
            obj.Visible = false;
            entry.DrawingMemory[drawingKey] = obj :: DrawingObject;
        end;
        -- Flush AFTER drawings are in memory
        FlushSettingsToEntry(rawSettings, bindings, entry.DrawingMemory, 
            if plugin.OnSettingChanged 
            then function(key, value) plugin:OnSettingChanged(entry, key, value) end 
            else nil
        );
    end;

    self.Plugins[plugin.Name] = plugin;
end;

function ESPManager:RemovePlugin(Name: string)
    local plugin: Plugin? = self.Plugins[Name];
    if not plugin then return end;

    for _, entry: RegistryEntry in self.Registry do
        for drawingKey: string in plugin.MemoryTemplate do
            local obj: DrawingObject? = entry.DrawingMemory[drawingKey];
            if obj then
                (obj :: any):Remove();
                entry.DrawingMemory[drawingKey] = nil;
            end;
        end;
    end;

    self.Plugins[Name] = nil;
end;

function ESPManager:SetPluginEnabled(Name: string, Enabled: boolean)
    local plugin: Plugin? = self.Plugins[Name];
    if plugin then plugin.Settings.Enabled = Enabled end;
end;

function ESPManager:SetPluginSetting(Name: string, Key: string, Value: any)
    local plugin: Plugin? = self.Plugins[Name];
    if plugin then plugin.Settings[Key] = Value end;
end;

function ESPManager:SetAllEnabled(Enabled: boolean)
    for _, plugin: Plugin in self.Plugins do
        plugin.Settings.Enabled = Enabled;
    end;
end;

function ESPManager:PushInstanceToRegistry(Object: Instance, Data: { [string]: any }?): number
    local Entry: RegistryEntry = {
        Object = Object;
        DrawingMemory = {} :: DrawingMemory;
        Data = Data or {};
    };

    for _, plugin: Plugin in self.Plugins do
        local rawSettings = getmetatable(plugin.Settings).__index :: { [string]: any };

        for drawingKey: string, drawingType: string in plugin.MemoryTemplate do
            local obj = Drawing.new(drawingType);
            obj.Visible = false;
            Entry.DrawingMemory[drawingKey] = obj :: DrawingObject;
        end;

        -- Flush AFTER all drawings inserted
        FlushSettingsToEntry(rawSettings, plugin.Bindings, Entry.DrawingMemory,
            if plugin.OnSettingChanged
            then function(key, value) plugin:OnSettingChanged(Entry, key, value) end
            else nil
        );
    end;

    table.insert(self.Registry, Entry);
    return #self.Registry;
end;

function ESPManager:RemoveInstanceFromRegistry(Object: Instance)
    for i, entry: RegistryEntry in self.Registry do
        if entry.Object ~= Object then continue end;
        for _, drawingObj: DrawingObject in entry.DrawingMemory do
            (drawingObj :: any):Remove();
        end;
        table.remove(self.Registry, i);
        return;
    end;
end;

function ESPManager:UpdateRegistry()
    for _, entry: RegistryEntry in self.Registry do
        for _, plugin: Plugin in self.Plugins do
            if not plugin.Settings.Enabled then
                for drawingKey: string in plugin.MemoryTemplate do
                    local obj: DrawingObject? = entry.DrawingMemory[drawingKey];
                    if obj then obj.Visible = false end;
                end;
                continue;
            end;
            plugin:UpdateEntry(entry, MathFunctions);
        end;
    end;
end;

return ESPManager;
