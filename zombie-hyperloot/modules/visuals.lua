--[[
    Visuals Module - Zombie Hyperloot
    Remove Fog, Day/Night Time, Fullbright
]]

local Visuals = {}
local Config = nil

-- Settings
Visuals.removeFogEnabled = false
Visuals.fullbrightEnabled = false
Visuals.customTimeEnabled = false
Visuals.customTimeValue = 14 -- 14 = day, 0 = midnight

-- Backup
Visuals.originalLighting = {}

function Visuals.init(config)
    Config = config
end

----------------------------------------------------------
-- 🔹 Remove Fog
Visuals.removedAtmospheres = {}

function Visuals.removeFog()
    local lighting = game:GetService("Lighting")
    
    -- Backup original fog settings
    if not Visuals.originalLighting.fogBackup then
        Visuals.originalLighting.FogEnd = lighting.FogEnd
        Visuals.originalLighting.FogStart = lighting.FogStart
        Visuals.originalLighting.fogBackup = true
    end
    
    -- Remove fog
    lighting.FogEnd = 100000
    
    -- Remove all Atmosphere objects
    for _, v in pairs(lighting:GetDescendants()) do
        if v:IsA("Atmosphere") then
            -- Backup atmosphere
            table.insert(Visuals.removedAtmospheres, v:Clone())
            v:Destroy()
        end
    end
    
    print("[Visuals] Fog and atmosphere removed")
end

function Visuals.restoreFog()
    if not Visuals.originalLighting.fogBackup then return end
    
    local lighting = game:GetService("Lighting")
    lighting.FogEnd = Visuals.originalLighting.FogEnd
    
    -- Restore atmospheres
    for _, atmosphere in ipairs(Visuals.removedAtmospheres) do
        local restored = atmosphere:Clone()
        restored.Parent = lighting
    end
    Visuals.removedAtmospheres = {}
    
    print("[Visuals] Fog restored")
end

function Visuals.toggleRemoveFog(enabled)
    Visuals.removeFogEnabled = enabled
    
    if enabled then
        Visuals.removeFog()
    else
        Visuals.restoreFog()
    end
end

----------------------------------------------------------
-- 🔹 Fullbright
function Visuals.enableFullbright()
    local lighting = game:GetService("Lighting")
    
    -- Backup original settings
    if not Visuals.originalLighting.fullbrightBackup then
        Visuals.originalLighting.Brightness = lighting.Brightness
        Visuals.originalLighting.Ambient = lighting.Ambient
        Visuals.originalLighting.OutdoorAmbient = lighting.OutdoorAmbient
        Visuals.originalLighting.GlobalShadows = lighting.GlobalShadows
        Visuals.originalLighting.fullbrightBackup = true
    end
    
    -- Enable fullbright
    lighting.Brightness = 2
    lighting.Ambient = Color3.fromRGB(255, 255, 255)
    lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
    lighting.GlobalShadows = false
    
    print("[Visuals] Fullbright enabled")
end

function Visuals.disableFullbright()
    if not Visuals.originalLighting.fullbrightBackup then return end
    
    local lighting = game:GetService("Lighting")
    lighting.Brightness = Visuals.originalLighting.Brightness
    lighting.Ambient = Visuals.originalLighting.Ambient
    lighting.OutdoorAmbient = Visuals.originalLighting.OutdoorAmbient
    lighting.GlobalShadows = Visuals.originalLighting.GlobalShadows
    
    print("[Visuals] Fullbright disabled")
end

function Visuals.toggleFullbright(enabled)
    Visuals.fullbrightEnabled = enabled
    
    if enabled then
        Visuals.enableFullbright()
    else
        Visuals.disableFullbright()
    end
end

----------------------------------------------------------
-- 🔹 Custom Time (Day/Night)
function Visuals.setCustomTime(timeValue)
    local lighting = game:GetService("Lighting")
    
    -- Backup original time
    if not Visuals.originalLighting.timeBackup then
        Visuals.originalLighting.ClockTime = lighting.ClockTime
        Visuals.originalLighting.timeBackup = true
    end
    
    lighting.ClockTime = timeValue
    Visuals.customTimeValue = timeValue
    
    print(string.format("[Visuals] Time set to %d:00", timeValue))
end

function Visuals.restoreTime()
    if not Visuals.originalLighting.timeBackup then return end
    
    local lighting = game:GetService("Lighting")
    lighting.ClockTime = Visuals.originalLighting.ClockTime
    
    print("[Visuals] Time restored")
end

function Visuals.toggleCustomTime(enabled)
    Visuals.customTimeEnabled = enabled
    
    if enabled then
        Visuals.setCustomTime(Visuals.customTimeValue)
    else
        Visuals.restoreTime()
    end
end

----------------------------------------------------------
-- 🔹 Apply All
function Visuals.applyAll()
    Visuals.toggleRemoveFog(true)
    Visuals.toggleFullbright(true)
    Visuals.toggleCustomTime(true)
    
    print("[Visuals] Applied all visual enhancements")
end

function Visuals.disableAll()
    Visuals.toggleRemoveFog(false)
    Visuals.toggleFullbright(false)
    Visuals.toggleCustomTime(false)
    
    print("[Visuals] Disabled all visual enhancements")
end

----------------------------------------------------------
-- 🔹 Cleanup
function Visuals.cleanup()
    Visuals.restoreFog()
    Visuals.disableFullbright()
    Visuals.restoreTime()
end

return Visuals
