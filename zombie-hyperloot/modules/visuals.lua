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
end

function Visuals.disableFullbright()
    if not Visuals.originalLighting.fullbrightBackup then return end
    
    local lighting = game:GetService("Lighting")
    lighting.Brightness = Visuals.originalLighting.Brightness
    lighting.Ambient = Visuals.originalLighting.Ambient
    lighting.OutdoorAmbient = Visuals.originalLighting.OutdoorAmbient
    lighting.GlobalShadows = Visuals.originalLighting.GlobalShadows
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
end

function Visuals.restoreTime()
    if not Visuals.originalLighting.timeBackup then return end
    
    local lighting = game:GetService("Lighting")
    lighting.ClockTime = Visuals.originalLighting.ClockTime
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
end

function Visuals.disableAll()
    Visuals.toggleRemoveFog(false)
    Visuals.toggleFullbright(false)
    Visuals.toggleCustomTime(false)
end

----------------------------------------------------------
-- 🔹 Remove Effects
Visuals.removedEffects = {}
Visuals.effectsRemoved = false

function Visuals.removeAllEffects()
    local success, err = pcall(function()
        local replicatedFirst = game:GetService("ReplicatedFirst")
        local baseEffectPath = replicatedFirst:WaitForChild("Scripts"):WaitForChild("Object"):WaitForChild("Data"):WaitForChild("BaseEffect")
        
        -- Danh sách các effect cần xóa
        local effectNames = {
            "ShotEntityEffect",
            "ShotHitEffect",
            "HitEffect"
        }
        
        -- Xóa từng effect
        for _, effectName in ipairs(effectNames) do
            local effect = baseEffectPath:FindFirstChild(effectName)
            if effect then
                -- Backup effect trước khi xóa
                table.insert(Visuals.removedEffects, {
                    name = effectName,
                    parent = effect.Parent,
                    clone = effect:Clone()
                })
                
                -- Xóa effect
                effect:Destroy()
            end
        end
        
        Visuals.effectsRemoved = true
    end)
    
    if not success then
        warn("[Visuals] Lỗi khi xóa effects: " .. tostring(err))
    end
end

function Visuals.restoreAllEffects()
    if #Visuals.removedEffects == 0 then
        return
    end
    
    local success, err = pcall(function()
        -- Khôi phục từng effect
        for _, effectData in ipairs(Visuals.removedEffects) do
            local restored = effectData.clone:Clone()
            restored.Parent = effectData.parent
        end
        
        Visuals.removedEffects = {}
        Visuals.effectsRemoved = false
    end)
    
    if not success then
        warn("[Visuals] Lỗi khi khôi phục effects: " .. tostring(err))
    end
end

function Visuals.toggleRemoveEffects(enabled)
    if enabled then
        Visuals.removeAllEffects()
    else
        Visuals.restoreAllEffects()
    end
end

----------------------------------------------------------
-- 🔹 Cleanup
function Visuals.cleanup()
    Visuals.restoreFog()
    Visuals.disableFullbright()
    Visuals.restoreTime()
    
    -- Khôi phục effects khi unload script
    if Visuals.effectsRemoved then
        Visuals.restoreAllEffects()
    end
end

return Visuals
