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

-- Connections
Visuals.fogConnection = nil
Visuals.fullbrightConnection = nil
Visuals.timeConnection = nil

function Visuals.init(config)
    Config = config
end

----------------------------------------------------------
-- 🔹 Remove Fog (with continuous monitoring)
function Visuals.removeFog()
    local lighting = game:GetService("Lighting")
    
    -- Backup original fog settings
    if not Visuals.originalLighting.fogBackup then
        Visuals.originalLighting.FogEnd = lighting.FogEnd
        Visuals.originalLighting.FogStart = lighting.FogStart
        Visuals.originalLighting.fogBackup = true
    end
    
    -- Remove fog immediately
    lighting.FogEnd = 100000
    lighting.FogStart = 100000
    
    -- Monitor and force remove fog every frame
    if not Visuals.fogConnection then
        Visuals.fogConnection = Config.RunService.Heartbeat:Connect(function()
            if Visuals.removeFogEnabled then
                lighting.FogEnd = 100000
                lighting.FogStart = 100000
            end
        end)
    end
    
    print("[Visuals] Fog removed (monitoring)")
end

function Visuals.restoreFog()
    -- Stop monitoring
    if Visuals.fogConnection then
        Visuals.fogConnection:Disconnect()
        Visuals.fogConnection = nil
    end
    
    if not Visuals.originalLighting.fogBackup then return end
    
    local lighting = game:GetService("Lighting")
    lighting.FogEnd = Visuals.originalLighting.FogEnd
    lighting.FogStart = Visuals.originalLighting.FogStart
    
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
-- 🔹 Fullbright (with continuous monitoring)
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
    
    -- Enable fullbright immediately
    lighting.Brightness = 2
    lighting.Ambient = Color3.fromRGB(255, 255, 255)
    lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
    lighting.GlobalShadows = false
    
    -- Monitor and force fullbright
    if not Visuals.fullbrightConnection then
        Visuals.fullbrightConnection = Config.RunService.Heartbeat:Connect(function()
            if Visuals.fullbrightEnabled then
                lighting.Brightness = 2
                lighting.Ambient = Color3.fromRGB(255, 255, 255)
                lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
                lighting.GlobalShadows = false
            end
        end)
    end
    
    print("[Visuals] Fullbright enabled (monitoring)")
end

function Visuals.disableFullbright()
    -- Stop monitoring
    if Visuals.fullbrightConnection then
        Visuals.fullbrightConnection:Disconnect()
        Visuals.fullbrightConnection = nil
    end
    
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
-- 🔹 Custom Time (Day/Night) (with continuous monitoring)
function Visuals.setCustomTime(timeValue)
    local lighting = game:GetService("Lighting")
    
    -- Backup original time
    if not Visuals.originalLighting.timeBackup then
        Visuals.originalLighting.ClockTime = lighting.ClockTime
        Visuals.originalLighting.timeBackup = true
    end
    
    lighting.ClockTime = timeValue
    Visuals.customTimeValue = timeValue
    
    -- Monitor and force time
    if not Visuals.timeConnection then
        Visuals.timeConnection = Config.RunService.Heartbeat:Connect(function()
            if Visuals.customTimeEnabled then
                lighting.ClockTime = Visuals.customTimeValue
            end
        end)
    end
    
    print(string.format("[Visuals] Time set to %d:00 (monitoring)", timeValue))
end

function Visuals.restoreTime()
    -- Stop monitoring
    if Visuals.timeConnection then
        Visuals.timeConnection:Disconnect()
        Visuals.timeConnection = nil
    end
    
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
    
    -- Disconnect all connections
    if Visuals.fogConnection then
        Visuals.fogConnection:Disconnect()
        Visuals.fogConnection = nil
    end
    
    if Visuals.fullbrightConnection then
        Visuals.fullbrightConnection:Disconnect()
        Visuals.fullbrightConnection = nil
    end
    
    if Visuals.timeConnection then
        Visuals.timeConnection:Disconnect()
        Visuals.timeConnection = nil
    end
end

return Visuals
