--[[
    FPS Booster Module - Zombie Hyperloot
    Xóa effects/particles, giảm texture quality, tắt shadows/lighting
]]

local FPS = {}
local Config = nil

-- FPS Settings
FPS.removeEffectsEnabled = false
FPS.reduceLightingEnabled = false
FPS.reduceTextureEnabled = false

-- Backup
FPS.originalLighting = {}
FPS.removedEffects = {}

function FPS.init(config)
    Config = config
end

----------------------------------------------------------
-- 🔹 Remove Effects & Particles
function FPS.removeEffects()
    if not FPS.removeEffectsEnabled then return end
    
    local count = 0
    
    -- Xóa tất cả effects trong Workspace
    for _, obj in ipairs(Config.Workspace:GetDescendants()) do
        if obj:IsA("ParticleEmitter") or 
           obj:IsA("Trail") or 
           obj:IsA("Beam") or 
           obj:IsA("Fire") or 
           obj:IsA("Smoke") or 
           obj:IsA("Sparkles") or 
           obj:IsA("PointLight") or 
           obj:IsA("SpotLight") or 
           obj:IsA("SurfaceLight") then
            
            -- Backup để restore sau
            table.insert(FPS.removedEffects, {
                instance = obj,
                enabled = obj:IsA("ParticleEmitter") and obj.Enabled or true
            })
            
            -- Disable hoặc xóa
            if obj:IsA("ParticleEmitter") then
                obj.Enabled = false
            else
                pcall(function() obj:Destroy() end)
            end
            
            count = count + 1
        end
    end
    
    print(string.format("[FPS Booster] Removed %d effects/particles", count))
end

function FPS.restoreEffects()
    for _, data in ipairs(FPS.removedEffects) do
        if data.instance and data.instance.Parent then
            if data.instance:IsA("ParticleEmitter") then
                data.instance.Enabled = data.enabled
            end
        end
    end
    
    FPS.removedEffects = {}
    print("[FPS Booster] Restored effects")
end

----------------------------------------------------------
-- 🔹 Reduce Lighting Quality
function FPS.reduceLighting()
    if not FPS.reduceLightingEnabled then return end
    
    local lighting = game:GetService("Lighting")
    
    -- Backup original settings
    if not FPS.originalLighting.backed then
        FPS.originalLighting = {
            GlobalShadows = lighting.GlobalShadows,
            Brightness = lighting.Brightness,
            OutdoorAmbient = lighting.OutdoorAmbient,
            Ambient = lighting.Ambient,
            FogEnd = lighting.FogEnd,
            FogStart = lighting.FogStart,
            backed = true
        }
    end
    
    -- Tắt shadows và giảm lighting
    lighting.GlobalShadows = false
    lighting.Brightness = 2
    lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
    lighting.Ambient = Color3.fromRGB(128, 128, 128)
    lighting.FogEnd = 100000
    lighting.FogStart = 0
    
    -- Xóa các lighting effects
    for _, effect in ipairs(lighting:GetChildren()) do
        if effect:IsA("BloomEffect") or 
           effect:IsA("BlurEffect") or 
           effect:IsA("ColorCorrectionEffect") or 
           effect:IsA("DepthOfFieldEffect") or 
           effect:IsA("SunRaysEffect") then
            effect.Enabled = false
        end
    end
    
    print("[FPS Booster] Reduced lighting quality")
end

function FPS.restoreLighting()
    if not FPS.originalLighting.backed then return end
    
    local lighting = game:GetService("Lighting")
    
    lighting.GlobalShadows = FPS.originalLighting.GlobalShadows
    lighting.Brightness = FPS.originalLighting.Brightness
    lighting.OutdoorAmbient = FPS.originalLighting.OutdoorAmbient
    lighting.Ambient = FPS.originalLighting.Ambient
    lighting.FogEnd = FPS.originalLighting.FogEnd
    lighting.FogStart = FPS.originalLighting.FogStart
    
    -- Bật lại lighting effects
    for _, effect in ipairs(lighting:GetChildren()) do
        if effect:IsA("BloomEffect") or 
           effect:IsA("BlurEffect") or 
           effect:IsA("ColorCorrectionEffect") or 
           effect:IsA("DepthOfFieldEffect") or 
           effect:IsA("SunRaysEffect") then
            effect.Enabled = true
        end
    end
    
    print("[FPS Booster] Restored lighting")
end

----------------------------------------------------------
-- 🔹 Reduce Texture Quality
function FPS.reduceTextures()
    if not FPS.reduceTextureEnabled then return end
    
    local count = 0
    
    -- Giảm chất lượng texture của tất cả parts
    for _, obj in ipairs(Config.Workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            -- Đơn giản hóa material
            if obj.Material ~= Enum.Material.SmoothPlastic then
                obj.Material = Enum.Material.SmoothPlastic
                count = count + 1
            end
            
            -- Xóa textures
            for _, child in ipairs(obj:GetChildren()) do
                if child:IsA("Decal") or 
                   child:IsA("Texture") or 
                   child:IsA("SurfaceAppearance") then
                    child:Destroy()
                    count = count + 1
                end
            end
        end
        
        -- Xóa MeshPart textures
        if obj:IsA("MeshPart") then
            obj.TextureID = ""
            count = count + 1
        end
    end
    
    print(string.format("[FPS Booster] Reduced %d textures", count))
end

----------------------------------------------------------
-- 🔹 Toggle Functions
function FPS.toggleRemoveEffects(enabled)
    FPS.removeEffectsEnabled = enabled
    
    if enabled then
        FPS.removeEffects()
    else
        FPS.restoreEffects()
    end
end

function FPS.toggleReduceLighting(enabled)
    FPS.reduceLightingEnabled = enabled
    
    if enabled then
        FPS.reduceLighting()
    else
        FPS.restoreLighting()
    end
end

function FPS.toggleReduceTextures(enabled)
    FPS.reduceTextureEnabled = enabled
    
    if enabled then
        FPS.reduceTextures()
    end
end

----------------------------------------------------------
-- 🔹 Apply All Optimizations
function FPS.applyAll()
    if FPS.removeEffectsEnabled then
        FPS.removeEffects()
    end
    
    if FPS.reduceLightingEnabled then
        FPS.reduceLighting()
    end
    
    if FPS.reduceTextureEnabled then
        FPS.reduceTextures()
    end
end

----------------------------------------------------------
-- 🔹 Cleanup
function FPS.cleanup()
    FPS.restoreEffects()
    FPS.restoreLighting()
end

return FPS
