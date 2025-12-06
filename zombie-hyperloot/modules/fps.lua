--[[
    FPS Booster Module - Zombie Hyperloot
    Xóa effects/particles, giảm texture quality, tắt shadows/lighting
    Không có restore - xóa luôn cho đơn giản
]]

local FPS = {}
local Config = nil

-- FPS Settings
FPS.removeEffectsEnabled = false
FPS.reduceLightingEnabled = false
FPS.reduceTextureEnabled = false
FPS.removeWeaponEffectsEnabled = false

-- Connections
FPS.weaponEffectsConnection = nil
FPS.continuousEffectsConnection = nil
FPS.lastWeaponCheck = 0
FPS.lastEffectsCheck = 0
FPS.weaponCheckInterval = 0.5 -- Check mỗi 0.5s thay vì mỗi frame
FPS.effectsCheckInterval = 0.1 -- Check effects mỗi 0.1s để xóa ngay

function FPS.init(config)
    Config = config
end

----------------------------------------------------------
-- 🔹 Remove Effects & Particles (Xóa luôn + Continuous monitoring)
function FPS.removeEffects()
    if not FPS.removeEffectsEnabled then return end
    
    local count = 0
    local effectTypes = {
        "ParticleEmitter", "Trail", "Beam", "Fire", "Smoke", 
        "Sparkles", "PointLight", "SpotLight", "SurfaceLight",
        "Explosion", "Sound" -- Thêm Explosion và Sound
    }
    
    -- Xóa tất cả effects 1 lần
    for _, obj in ipairs(Config.Workspace:GetDescendants()) do
        local className = obj.ClassName
        
        for _, effectType in ipairs(effectTypes) do
            if className == effectType then
                pcall(function() obj:Destroy() end)
                count = count + 1
                break
            end
        end
    end
    
    print(string.format("[FPS Booster] Removed %d effects/particles", count))
end

-- Monitor liên tục để xóa effects mới spawn
function FPS.startContinuousEffectsRemoval()
    if FPS.continuousEffectsConnection then return end
    
    local effectTypes = {
        "ParticleEmitter", "Trail", "Beam", "Fire", "Smoke", 
        "Sparkles", "PointLight", "SpotLight", "SurfaceLight",
        "Explosion", "Sound"
    }
    
    FPS.continuousEffectsConnection = Config.RunService.Heartbeat:Connect(function()
        if not FPS.removeEffectsEnabled then return end
        
        local currentTime = tick()
        if currentTime - FPS.lastEffectsCheck < FPS.effectsCheckInterval then
            return
        end
        FPS.lastEffectsCheck = currentTime
        
        -- Xóa effects mới spawn trong Workspace
        for _, obj in ipairs(Config.Workspace:GetDescendants()) do
            local className = obj.ClassName
            
            for _, effectType in ipairs(effectTypes) do
                if className == effectType then
                    pcall(function() obj:Destroy() end)
                    break
                end
            end
        end
        
        -- Xóa effects trong character của player
        local character = Config.localPlayer.Character
        if character then
            for _, obj in ipairs(character:GetDescendants()) do
                local className = obj.ClassName
                
                for _, effectType in ipairs(effectTypes) do
                    if className == effectType then
                        pcall(function() obj:Destroy() end)
                        break
                    end
                end
            end
        end
    end)
    
    print("[FPS Booster] Continuous effects removal started")
end

function FPS.stopContinuousEffectsRemoval()
    if FPS.continuousEffectsConnection then
        FPS.continuousEffectsConnection:Disconnect()
        FPS.continuousEffectsConnection = nil
    end
    print("[FPS Booster] Continuous effects removal stopped")
end

----------------------------------------------------------
-- 🔹 Reduce Lighting Quality (Xóa luôn)
function FPS.reduceLighting()
    if not FPS.reduceLightingEnabled then return end
    
    local lighting = game:GetService("Lighting")
    
    -- Tắt shadows và giảm lighting
    lighting.GlobalShadows = false
    lighting.Brightness = 2
    lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
    lighting.Ambient = Color3.fromRGB(128, 128, 128)
    lighting.FogEnd = 100000
    lighting.FogStart = 0
    
    -- Xóa luôn các lighting effects
    for _, effect in ipairs(lighting:GetChildren()) do
        local className = effect.ClassName
        if className == "BloomEffect" or 
           className == "BlurEffect" or 
           className == "ColorCorrectionEffect" or 
           className == "DepthOfFieldEffect" or 
           className == "SunRaysEffect" then
            pcall(function() effect:Destroy() end)
        end
    end
    
    print("[FPS Booster] Reduced lighting quality")
end

----------------------------------------------------------
-- 🔹 Reduce Texture Quality (Xóa luôn)
function FPS.reduceTextures()
    if not FPS.reduceTextureEnabled then return end
    
    local count = 0
    
    -- Giảm chất lượng texture của tất cả parts
    for _, obj in ipairs(Config.Workspace:GetDescendants()) do
        local className = obj.ClassName
        
        if className == "Part" or className == "MeshPart" or className == "UnionOperation" then
            -- Đơn giản hóa material
            if obj.Material ~= Enum.Material.SmoothPlastic then
                obj.Material = Enum.Material.SmoothPlastic
                count = count + 1
            end
            
            -- Xóa MeshPart textures
            if className == "MeshPart" and obj.TextureID ~= "" then
                obj.TextureID = ""
                count = count + 1
            end
            
            -- Xóa textures
            for _, child in ipairs(obj:GetChildren()) do
                local childClass = child.ClassName
                if childClass == "Decal" or childClass == "Texture" or childClass == "SurfaceAppearance" then
                    child:Destroy()
                    count = count + 1
                end
            end
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
        FPS.startContinuousEffectsRemoval() -- Bật monitoring liên tục
    else
        FPS.stopContinuousEffectsRemoval()
    end
end

function FPS.toggleReduceLighting(enabled)
    FPS.reduceLightingEnabled = enabled
    if enabled then
        FPS.reduceLighting()
    end
end

function FPS.toggleReduceTextures(enabled)
    FPS.reduceTextureEnabled = enabled
    if enabled then
        FPS.reduceTextures()
    end
end

----------------------------------------------------------
-- 🔹 Remove Weapon Effects (Optimized với interval)
function FPS.removeWeaponEffects()
    if FPS.weaponEffectsConnection then return end
    
    -- Xóa effects hiện tại trong character
    local function cleanCharacterEffects(character)
        if not character then return end
        
        for _, obj in ipairs(character:GetDescendants()) do
            local className = obj.ClassName
            if className == "ParticleEmitter" or 
               className == "Trail" or 
               className == "Beam" or 
               className == "PointLight" or 
               className == "SpotLight" then
                pcall(function() obj:Destroy() end)
            end
        end
    end
    
    -- Clean character hiện tại
    cleanCharacterEffects(Config.localPlayer.Character)
    
    -- Monitor và xóa effects mới (với interval)
    FPS.weaponEffectsConnection = Config.RunService.Heartbeat:Connect(function()
        if not FPS.removeWeaponEffectsEnabled then return end
        
        local currentTime = tick()
        if currentTime - FPS.lastWeaponCheck < FPS.weaponCheckInterval then
            return
        end
        FPS.lastWeaponCheck = currentTime
        
        local character = Config.localPlayer.Character
        if not character then return end
        
        -- Xóa effects trong tools/weapons
        for _, tool in ipairs(character:GetChildren()) do
            if tool.ClassName == "Tool" then
                for _, obj in ipairs(tool:GetDescendants()) do
                    local className = obj.ClassName
                    if className == "ParticleEmitter" or className == "Trail" or className == "Beam" then
                        pcall(function() obj:Destroy() end)
                    end
                end
            end
        end
    end)
    
    print("[FPS Booster] Weapon effects removal enabled")
end

function FPS.stopRemoveWeaponEffects()
    if FPS.weaponEffectsConnection then
        FPS.weaponEffectsConnection:Disconnect()
        FPS.weaponEffectsConnection = nil
    end
    print("[FPS Booster] Weapon effects removal disabled")
end

function FPS.toggleRemoveWeaponEffects(enabled)
    FPS.removeWeaponEffectsEnabled = enabled
    
    if enabled then
        FPS.removeWeaponEffects()
    else
        FPS.stopRemoveWeaponEffects()
    end
end

----------------------------------------------------------
-- 🔹 Additional Optimizations
function FPS.reduceRenderDistance()
    -- Giảm render quality
    pcall(function()
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
        settings().Rendering.MeshPartDetailLevel = Enum.MeshPartDetailLevel.Level01
    end)
    print("[FPS Booster] Reduced render quality")
end

function FPS.disablePlayerEffects()
    -- Tắt effects của players khác
    for _, player in ipairs(Config.Players:GetPlayers()) do
        if player ~= Config.localPlayer and player.Character then
            for _, obj in ipairs(player.Character:GetDescendants()) do
                if obj.ClassName == "ParticleEmitter" then
                    pcall(function() obj:Destroy() end)
                end
            end
        end
    end
    print("[FPS Booster] Disabled other players' effects")
end

function FPS.enableAllOptimizations()
    FPS.toggleRemoveEffects(true)
    FPS.toggleReduceLighting(true)
    FPS.toggleReduceTextures(true)
    FPS.toggleRemoveWeaponEffects(true)
    FPS.reduceRenderDistance()
    FPS.disablePlayerEffects()
    print("[FPS Booster] All optimizations enabled!")
end

----------------------------------------------------------
-- 🔹 Cleanup
function FPS.cleanup()
    FPS.stopRemoveWeaponEffects()
    FPS.stopContinuousEffectsRemoval()
    FPS.lastWeaponCheck = 0
    FPS.lastEffectsCheck = 0
end

return FPS
