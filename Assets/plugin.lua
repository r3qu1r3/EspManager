type PluginData = {
    Install: (object: any) -> ();
    Update: (pool: any, target: any, boundingBox: any) -> ();
    Style: any?; 
    Settings: any?; 

}

local Plugin = { }; 
Plugin.__index = Plugin;

function Plugin.new(Name, Install, Initialize, Update, Settings, Style, OutlineStyle): PluginData
    local newPlugin = setmetatable({
        Name = Name;
        Install = Install; 
        Initialize = Initialize;
        Update = Update; 
        Style = Style;
        OutlineStyle = OutlineStyle;
        Settings = Settings;
    }, Plugin);

    return newPlugin;
end; 

return Plugin;
